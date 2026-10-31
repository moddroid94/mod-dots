pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

CustomMouseArea {
    id: root

    required property ScreenState screenState

    // CalDAV service reference: resolves CalDavService or CalendarService from qs.services
    readonly property var calDavService: (typeof CalDavService !== "undefined" ? CalDavService : null)
        ?? (typeof CalendarService !== "undefined" ? CalendarService : null)

    property date currentDate: screenState.dashboardDate
    readonly property int currMonth: currentDate.getMonth()
    readonly property int currYear: currentDate.getFullYear()
    readonly property int nonAnimCurrMonth: screenState.dashboardDate.getMonth()
    readonly property int nonAnimCurrYear: screenState.dashboardDate.getFullYear()

    readonly property int animDirection: screenState.dashboardDate > currentDate ? -1 : 1
    property real animTranslate
    property real animOpacity: 1

    // Process to launch the calendar application
    Process {
        id: calendarAppLauncher

        command: [
            "sh", "-c",
            `
            detach_run() {
                if command -v systemd-run >/dev/null 2>&1; then
                    systemd-run --user --quiet "$@" >/dev/null 2>&1
                elif command -v setsid >/dev/null 2>&1; then
                    setsid -f "$@" >/dev/null 2>&1
                else
                    nohup "$@" >/dev/null 2>&1 &
                fi
            }

            APP="$1"
            if [ -z "$APP" ]; then
                for candidate in gnome-calendar merkuro-calendar kalendar thunderbird evolution korganizer; do
                    if command -v "$candidate" >/dev/null 2>&1; then
                        APP="$candidate"
                        break
                    fi
                done
            fi

            if [ -n "$APP" ]; then
                detach_run sh -c "$APP"
            else
                detach_run xdg-open "calendar://"
            fi
            `,
            "--",
            (typeof Config !== "undefined" && Config.calendarApp) ? Config.calendarApp : ""
        ]
        running: false
    }

    function openCalendarApp(): void {
        if (!calendarAppLauncher.running)
            calendarAppLauncher.running = true;
    }

    // CalDAV date check helpers
    function isDateInRange(target: date, start: date, end: date): bool {
        const t = new Date(target.getFullYear(), target.getMonth(), target.getDate()).getTime();
        const s = new Date(start.getFullYear(), start.getMonth(), start.getDate()).getTime();
        const e = end ? new Date(end.getFullYear(), end.getMonth(), end.getDate()).getTime() : s;
        return t >= s && t <= e;
    }

    function getEventsForDate(targetDate: date): var {
        if (!targetDate)
            return [];

        if (root.calDavService && typeof root.calDavService.getEventsForDate === "function")
            return root.calDavService.getEventsForDate(targetDate);

        const events = root.calDavService?.events ?? [];
        return events.filter(ev => {
            const rawStart = ev.start ?? ev.startDate ?? ev.dtstart;
            if (!rawStart)
                return false;
            const startDate = new Date(rawStart);
            const rawEnd = ev.end ?? ev.endDate ?? ev.dtend;
            const endDate = rawEnd ? new Date(rawEnd) : null;
            return root.isDateInRange(targetDate, startDate, endDate);
        });
    }

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y > 0)
            screenState.dashboardDate = new Date(nonAnimCurrYear, nonAnimCurrMonth - 1, 1);
        else if (event.angleDelta.y < 0)
            screenState.dashboardDate = new Date(nonAnimCurrYear, nonAnimCurrMonth + 1, 1);
    }

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

    acceptedButtons: Qt.MiddleButton
    onClicked: root.screenState.dashboardDate = new Date()

    Anim {
        id: trOutAnim

        running: false
        target: root
        property: "animTranslate"
        to: root.Tokens.padding.extraLarge * root.animDirection
        type: Anim.FastSpatial
    }

    Behavior on currentDate {
        SequentialAnimation {
            ParallelAnimation {
                ScriptAction {
                    script: Qt.callLater(() => trOutAnim.start())
                }
                Anim {
                    target: root
                    property: "animOpacity"
                    to: 0
                    type: Anim.FastEffects
                }
            }
            ScriptAction {
                script: {
                    trOutAnim.complete();
                    root.animTranslate = root.Tokens.padding.extraLarge * -root.animDirection;
                }
            }
            PropertyAction {}
            ParallelAnimation {
                Anim {
                    target: root
                    property: "animTranslate"
                    to: 0
                    type: Anim.DefaultSpatial
                }
                Anim {
                    target: root
                    property: "animOpacity"
                    to: 1
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.extraSmall

        RowLayout {
            id: monthNavigationRow

            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            IconButton {
                isRound: true
                icon: "chevron_left"
                type: IconButton.Text
                font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                padding: Tokens.padding.small
                onClicked: root.screenState.dashboardDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth - 1, 1)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                implicitWidth: monthYearDisplay.implicitWidth + Tokens.padding.large * 2
                implicitHeight: monthYearDisplay.implicitHeight + Tokens.padding.extraSmall * 2

                StateLayer {
                    color: Colours.palette.m3primary
                    radius: pressed ? Tokens.rounding.small : height / 2
                    disabled: {
                        const now = new Date();
                        return root.nonAnimCurrMonth === now.getMonth() && root.nonAnimCurrYear === now.getFullYear();
                    }
                    onClicked: root.screenState.dashboardDate = new Date()

                    Behavior on radius {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                StyledText {
                    id: monthYearDisplay

                    opacity: root.animOpacity
                    transform: Translate {
                        x: root.animTranslate
                    }

                    anchors.centerIn: parent
                    text: grid.title
                    color: Colours.palette.m3primary
                    font: Tokens.font.title.builders.small.capitalisation(Font.Capitalize).build()
                }
            }

            IconButton {
                isRound: true
                icon: "chevron_right"
                type: IconButton.Text
                font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                padding: Tokens.padding.small
                onClicked: root.screenState.dashboardDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth + 1, 1)
            }
        }

        DayOfWeekRow {
            id: daysRow

            Layout.fillWidth: true
            locale: grid.locale

            delegate: StyledText {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: (model.day === 0 || model.day === 6) ? Colours.palette.m3tertiary : Colours.palette.m3onSurface
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight

            opacity: root.animOpacity
            transform: Translate {
                x: root.animTranslate
            }

            MonthGrid {
                id: grid

                month: root.currMonth
                year: root.currYear

                anchors.fill: parent

                spacing: 3
                locale: Qt.locale()

                delegate: Item {
                    id: dayItem

                    required property var model

                    readonly property var dayEvents: root.getEventsForDate(dayItem.model.date)
                    readonly property bool hasEvents: dayEvents.length > 0

                    implicitWidth: implicitHeight
                    implicitHeight: text.implicitHeight + Tokens.padding.small + 4

                    // Interactive click & ripple state layer to open the calendar app
                    StateLayer {
                        anchors.fill: parent
                        radius: width / 2
                        color: dayItem.model.today ? Colours.palette.m3onPrimary : Colours.palette.m3primary
                        onClicked: root.openCalendarApp()
                    }


                    StyledText {
                        id: text

                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: dayItem.hasEvents ? -2 : 0

                        horizontalAlignment: Text.AlignHCenter
                        text: grid.locale.toString(dayItem.model.day)
                        color: {
                            const dayOfWeek = dayItem.model.date.getDay();
                            if (dayOfWeek === 0 || dayOfWeek === 6)
                                return Colours.palette.m3tertiary;

                            return Colours.palette.m3onSurfaceVariant;
                        }
                        opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                        font: dayItem.hasEvents
                            ? Tokens.font.body.builders.small.weight(Font.Bold).build()
                            : Tokens.font.body.small
                    }

                    // Indicator dot below the day number
                    Rectangle {
                        id: eventDot

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2

                        visible: dayItem.hasEvents
                        width: 4
                        height: 4
                        radius: 2
                        color: {
                            if (dayItem.model.today)
                                return Colours.palette.m3onPrimary;
                            const dayOfWeek = dayItem.model.date.getDay();
                            return (dayOfWeek === 0 || dayOfWeek === 6)
                                ? Colours.palette.m3tertiary
                                : Colours.palette.m3primary;
                        }
                        opacity: dayItem.model.month === grid.month ? 1 : 0.4
                    }

                    // Tooltip preview for event titles
                    HoverHandler {
                        id: dayHover
                        enabled: dayItem.hasEvents
                    }

                    ToolTip {
                        visible: dayHover.hovered && dayItem.hasEvents
                        text: dayItem.dayEvents.map(ev => ev.summary ?? ev.title ?? "Event").join("\n")
                        delay: 350
                    }
                }
            }

            MaterialShape {
                id: todayIndicator

                readonly property Item todayItem: grid.contentItem.children.find(c => c.model.today) ?? null
                property Item today

                // Do not intercept clicks on today's cell so the StateLayer underneath receives the click
                enabled: false

                onTodayItemChanged: {
                    if (todayItem)
                        today = todayItem;
                }

                x: today ? today.x + (today.width - implicitWidth) / 2 : 0
                y: today ? today.y - Tokens.padding.extraSmall - 1 : 0

                implicitSize: today ? Math.max(today.implicitWidth, today.implicitHeight) + Tokens.padding.extraSmall * 2 : 0
                shape: MaterialShape.Sunny

                clip: true
                color: Colours.palette.m3primary

                opacity: todayItem ? 1 : 0

                Colouriser {
                    x: -todayIndicator.x
                    y: -todayIndicator.y

                    implicitWidth: grid.width
                    implicitHeight: grid.height

                    source: grid
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onPrimary
                }
            }
        }
    }
}