pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // List of parsed calendar events: [{ summary: string, start: string, end: string }]
    property var events: []
    property bool isLoading: false

    // Optional: override if your CalDAV sync directory is in a custom path
    property string customCalendarPath: ""

    // Polling interval to re-scan for new/modified events (default: 15 minutes)
    property int refreshIntervalMs: 15 * 60 * 1000

    // Python extractor script (uses Python 3 standard library only; zero dependencies)
    readonly property string _script: `
import os, glob, re, json

search_paths = [
    os.path.expanduser('~/.local/share/calendars'),
    os.path.expanduser('~/.calendars'),
    os.path.expanduser('~/.cache/calendars'),
    os.path.expanduser('~/.local/share/vdirsyncer/calendars/')
]

custom = os.path.expanduser("${root.customCalendarPath}")
if custom and os.path.exists(custom):
    search_paths.insert(0, custom)

def parse_ics_date(raw_val):
    val = raw_val.split(':')[-1].strip()
    m = re.match(r'^(\\d{4})(\\d{2})(\\d{2})(?:T(\\d{2})(\\d{2})(\\d{2})Z?)?', val)
    if m:
        y, mo, d, h, mi, s = m.groups()
        return f"{y}-{mo}-{d}T{h or '00'}:{mi or '00'}:{s or '00'}"
    return None

events = []
seen = set()

for path in search_paths:
    if not os.path.exists(path):
        continue
    for ics in glob.glob(os.path.join(path, '**/*.ics'), recursive=True):
        try:
            with open(ics, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            # Unfold multiline fields (lines wrapped with spaces/tabs)
            unfolded = re.sub(r'\\r?\\n[ \\t]', '', content)

            for block in re.findall(r'BEGIN:VEVENT(.*?)END:VEVENT', unfolded, re.DOTALL):
                summary_match = re.search(r'^SUMMARY.*?:(.*)$', block, re.M)
                start_match = re.search(r'^DTSTART.*?:(.*)$', block, re.M)
                end_match = re.search(r'^DTEND.*?:(.*)$', block, re.M)

                if not start_match:
                    continue

                summary = summary_match.group(1).strip() if summary_match else 'Untitled Event'
                summary = summary.replace('\\\\,', ',').replace('\\\\;', ';').replace('\\\\n', ' ')

                dt_start = parse_ics_date(start_match.group(1))
                dt_end = parse_ics_date(end_match.group(1)) if end_match else dt_start

                key = f"{summary}_{dt_start}_{dt_end}"
                if dt_start and key not in seen:
                    seen.add(key)
                    events.append({
                        'summary': summary,
                        'start': dt_start,
                        'end': dt_end
                    })
        except Exception:
            pass

print(json.dumps(events))
`

    Process {
        id: fetchProcess

        command: ["python3", "-c", root._script]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim();
                if (!trimmed)
                    return;

                try {
                    root.events = JSON.parse(trimmed);
                } catch (err) {
                    console.warn("CalendarService: Failed to parse events JSON:", err);
                }
            }
        }

        onExited: (code, status) => {
            root.isLoading = false;
        }
    }

    Timer {
        id: pollTimer

        interval: root.refreshIntervalMs
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    function refresh(): void {
        if (fetchProcess.running)
            return;

        root.isLoading = true;
        fetchProcess.running = true;
    }

    /**
     * Checks if a target date has any events occurring on it.
     */
    function hasEvents(targetDate: date): bool {
        return getEventsForDate(targetDate).length > 0;
    }

    /**
     * Returns an array of events that occur on or span across targetDate.
     */
    function getEventsForDate(targetDate: date): var {
        if (!targetDate || root.events.length === 0)
            return [];

        const ty = targetDate.getFullYear();
        const tm = targetDate.getMonth();
        const td = targetDate.getDate();
        const targetTime = new Date(ty, tm, td).getTime();

        return root.events.filter(ev => {
            if (!ev.start)
                return false;

            const s = new Date(ev.start);
            const startTime = new Date(s.getFullYear(), s.getMonth(), s.getDate()).getTime();

            let endTime = startTime;
            if (ev.end) {
                const e = new Date(ev.end);
                endTime = new Date(e.getFullYear(), e.getMonth(), e.getDate()).getTime();
            }

            return targetTime >= startTime && targetTime <= endTime;
        });
    }
}