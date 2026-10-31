pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n

// Tailscale state from `tailscale status --json` and `tailscale debug prefs`,
// actions through the tailscale CLI. Changing settings needs the user to be the
// tailscaled operator (`tailscale set --operator=$USER`, granted from the popout).
Singleton {
    id: root

    property bool installed: true
    property string backendState: "Unknown" // Running | Stopped | NeedsLogin | NeedsMachineAuth | Starting | NoState
    readonly property bool running: backendState === "Running"
    property bool daemonOnline: false
    property var self: null
    property list<var> peers: []
    property var tailnet: null
    property string account
    property list<string> health: []
    property var prefs: ({})
    property list<var> accounts: []
    property bool isOperator: true
    property string user: Quickshell.env("USER")

    readonly property list<var> exitNodes: peers.filter(p => p.exitNodeOption)
    readonly property var currentExitNode: peers.find(p => p.exitNode) ?? null
    readonly property int onlineCount: peers.filter(p => p.online).length
    readonly property list<string> selfIps: self?.ips ?? []

    // UI state kept here so it survives the popout unloading
    property string page: "devices" // devices | exit | accounts | settings
    property string filter: "online" // online | all
    property string pending // action currently running
    property string lastError
    property string loginUrl

    property alias settings: settingsAdapter

    readonly property url logo: Qt.resolvedUrl("../assets/tailscale/tailscale.svg")

    // ---------- Helpers ----------

    function shortName(dns: string, host: string): string {
        return (dns || "").split(".")[0] || host;
    }

    function lastSeenText(iso: string): string {
        if (!iso || iso.startsWith("0001"))
            return Tr.tr("never seen");
        const s = Math.max(0, Math.round((Date.now() - new Date(iso).getTime()) / 1000));
        if (s < 120)
            return Tr.tr("seen just now");
        if (s < 3600)
            return Tr.tr("seen %1 min ago").arg(Math.floor(s / 60));
        if (s < 86400)
            return Tr.tr("seen %1 h ago").arg(Math.floor(s / 3600));
        return Tr.tr("seen %1 d ago").arg(Math.floor(s / 86400));
    }

    function formatBytes(bytes: real): string {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (bytes >= 1024 && i < units.length - 1) {
            bytes /= 1024;
            i++;
        }
        return `${bytes.toFixed(i === 0 || bytes >= 10 ? 0 : 1)} ${units[i]}`;
    }

    function osIcon(os: string): string {
        switch ((os || "").toLowerCase()) {
        case "android":
        case "ios":
            return "smartphone";
        case "windows":
        case "macos":
            return "laptop";
        case "linux":
            return "computer";
        }
        return "devices";
    }

    function copy(text: string, what: string): void {
        Quickshell.clipboardText = text;
        if (settings.notifications)
            Toaster.toast(Tr.tr("Copied"), what ? `${what}: ${text}` : text, "content_copy", Toast.Info);
    }

    function fail(message: string): void {
        lastError = message;
        if (settings.notifications)
            Toaster.toast(Tr.tr("Tailscale"), message, "vpn_lock", Toast.Error);
    }

    // Runs a tailscale command; onDone(ok, stdout, stderr)
    function run(args: var, onDone: var): void {
        const proc = procComp.createObject(root, {
            command: ["tailscale", ...args],
            onDone: onDone ?? null
        });
        proc.running = true;
    }

    // State-changing command with pending state, operator detection and refresh
    function act(name: string, args: var, onOk: var): void {
        pending = name;
        lastError = "";
        run(args, (ok, out, err) => {
            pending = "";
            if (ok) {
                onOk?.(out);
            } else if (/access denied|permission denied|operator/i.test(err)) {
                isOperator = false;
                fail(Tr.tr("Not allowed to control Tailscale. Select “Allow control” to fix this once."));
            } else {
                fail(err.trim().split("\n")[0] || Tr.tr("tailscale %1 failed").arg(args[0]));
            }
            refresh();
        });
    }

    // ---------- Polling ----------

    function refresh(): void {
        run(["status", "--json"], (ok, out, err) => {
            if (!ok && !out) {
                daemonOnline = false;
                backendState = "NoState";
                return;
            }
            let d;
            try {
                d = JSON.parse(out);
            } catch (e) {
                return;
            }
            daemonOnline = true;
            const wasRunning = running;
            backendState = d.BackendState ?? "Unknown";
            tailnet = d.CurrentTailnet ?? null;
            health = d.Health ?? [];
            const users = d.User ?? {};
            const node = n => ({
                        id: n.ID,
                        name: shortName(n.DNSName, n.HostName),
                        host: n.HostName,
                        dns: (n.DNSName || "").replace(/\.$/, ""),
                        os: n.OS,
                        ips: n.TailscaleIPs ?? [],
                        online: n.Online ?? false,
                        active: n.Active ?? false,
                        lastSeen: n.LastSeen ?? "",
                        exitNode: n.ExitNode ?? false,
                        exitNodeOption: n.ExitNodeOption ?? false,
                        relay: n.Relay ?? "",
                        direct: !!n.CurAddr,
                        rx: n.RxBytes ?? 0,
                        tx: n.TxBytes ?? 0,
                        owner: users[n.UserID]?.LoginName ?? "",
                        expired: n.Expired ?? false
                    });
            self = d.Self ? node(d.Self) : null;
            account = users[d.Self?.UserID]?.LoginName ?? "";
            peers = Object.values(d.Peer ?? {}).map(node).sort((a, b) => (b.online - a.online) || a.name.localeCompare(b.name));
            if (settings.notifications && wasRunning !== running && backendState !== "Unknown")
                Toaster.toast(running ? Tr.tr("Tailscale connected") : Tr.tr("Tailscale disconnected"), tailnet?.Name ?? "", running ? "vpn_lock" : "vpn_lock_2", Toast.Info);
        });

        run(["debug", "prefs"], (ok, out) => {
            if (!ok)
                return;
            try {
                const p = JSON.parse(out);
                prefs = {
                    shieldsUp: p.ShieldsUp ?? false,
                    acceptRoutes: p.RouteAll ?? false,
                    acceptDns: p.CorpDNS ?? true,
                    exitNodeAllowLan: p.ExitNodeAllowLANAccess ?? false,
                    runSsh: p.RunSSH ?? false,
                    wantRunning: p.WantRunning ?? false,
                    advertiseExitNode: (p.AdvertiseRoutes ?? []).includes("0.0.0.0/0"),
                    operator: p.OperatorUser ?? ""
                };
                if (prefs.operator)
                    isOperator = prefs.operator === user;
            } catch (e) {}
        });
    }

    function refreshAccounts(): void {
        run(["switch", "--list"], (ok, out, err) => {
            if (!ok) {
                if (/access denied/i.test(err))
                    isOperator = false;
                return;
            }
            // ID  Tailnet  Account (current marked with *)
            accounts = out.split("\n").slice(1).filter(l => l.trim()).map(l => {
                const cols = l.trim().split(/\s+/);
                const current = l.trim().endsWith("*");
                return {
                    id: cols[0],
                    tailnet: cols[1] ?? "",
                    account: (cols[cols.length - 1] ?? "").replace(/\*$/, ""),
                    current
                };
            });
        });
    }

    // ---------- Actions ----------

    function setRunning(up: bool): void {
        act(up ? "up" : "down", [up ? "up" : "down"]);
    }

    function setExitNode(peer: var): void {
        act("exitNode", ["set", `--exit-node=${peer ? peer.ips[0] : ""}`]);
    }

    function setPref(name: string, flag: string, value: bool): void {
        act(name, ["set", `--${flag}=${value}`]);
    }

    function switchAccount(acc: var): void {
        act("switch", ["switch", acc.id], () => refreshAccounts());
    }

    function cycleAccount(): void {
        if (accounts.length < 2)
            return;
        const i = accounts.findIndex(a => a.current);
        switchAccount(accounts[(i + 1) % accounts.length]);
    }

    // `tailscale login` prints an auth URL and waits until it's used
    function addAccount(): void {
        pending = "login";
        loginUrl = "";
        loginProc.running = true;
    }

    function grantOperator(): void {
        pending = "operator";
        const proc = procComp.createObject(root, {
            command: ["pkexec", "tailscale", "set", `--operator=${user}`],
            onDone: (ok, out, err) => {
                pending = "";
                if (ok) {
                    isOperator = true;
                    lastError = "";
                    refreshAccounts();
                    if (settings.notifications)
                        Toaster.toast(Tr.tr("Tailscale"), Tr.tr("%1 can now control Tailscale").arg(user), "vpn_lock", Toast.Success);
                } else {
                    fail(err.trim() || Tr.tr("Not granted"));
                }
                refresh();
            }
        });
        proc.running = true;
    }

    function openAdmin(): void {
        Qt.openUrlExternally("https://login.tailscale.com/admin/machines");
    }

    Component {
        id: procComp

        Process {
            id: proc

            property var onDone
            property int exitCode: -1
            property int remaining: 3 // exit + both streams

            function part(): void {
                if (--remaining === 0) {
                    onDone?.(exitCode === 0, out.text, err.text);
                    Qt.callLater(() => proc.destroy());
                }
            }

            stdout: StdioCollector {
                id: out

                onStreamFinished: proc.part()
            }
            stderr: StdioCollector {
                id: err

                onStreamFinished: proc.part()
            }
            onExited: code => {
                exitCode = code;
                part();
            }
        }
    }

    Process {
        id: loginProc

        command: ["tailscale", "login"]
        stderr: SplitParser {
            onRead: line => {
                const url = line.match(/https:\/\/\S+/)?.[0];
                if (url && !root.loginUrl) {
                    root.loginUrl = url;
                    Qt.openUrlExternally(url);
                }
            }
        }
        stdout: SplitParser {
            onRead: line => {
                const url = line.match(/https:\/\/\S+/)?.[0];
                if (url && !root.loginUrl) {
                    root.loginUrl = url;
                    Qt.openUrlExternally(url);
                }
            }
        }
        onExited: code => {
            root.pending = "";
            root.loginUrl = "";
            if (code !== 0)
                root.fail(Tr.tr("Adding an account was cancelled or failed"));
            root.refresh();
            root.refreshAccounts();
        }
    }

    FileView {
        path: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/caelestia/tailscale.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: settingsAdapter

            property bool notifications: true
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v tailscale"]
        onExited: code => root.installed = code === 0
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refreshAccounts()
}
