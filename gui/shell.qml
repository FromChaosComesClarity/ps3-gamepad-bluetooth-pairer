// PS3 Gamepad Bluetooth Pairer - Quickshell front-end for ps3pair.
// Run with: qs -p gui/shell.qml   (or the ps3pair-gui launcher)
// It shows as a centered overlay, like Omarchy's own menus; Esc closes it.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    readonly property string bin: Quickshell.env("PS3PAIR_BIN") || "ps3pair"
    readonly property string home: Quickshell.env("HOME")

    // Omarchy theme (falls back to a neutral dark palette)
    property color bg: "#1a1b26"
    property color fg: "#c0caf5"
    property color accent: "#7aa2f7"
    property color dim: "#565f89"
    property color red: "#f7768e"
    property color green: "#9ece6a"
    property color yellow: "#e0af68"

    property var status: null
    property bool busy: false
    property string task: ""
    property string action: ""
    property string fixHint: ""

    readonly property var controller: status && status.controllers.length ? status.controllers[0] : null
    readonly property bool btOn: !!(status && status.adapter && status.adapter.powered && status.rfkill === "")
    readonly property bool needsCloneFix: !!(status && status.classic_bonded_only
                                            && ((controller && controller.clone) || fixHint !== ""))
    readonly property var forgettable: {
        if (!status) return null;
        if (controller && controller.bluez) return controller;
        return status.known.length ? status.known[0] : null;
    }

    function parseTheme(text) {
        const pick = key => {
            const m = text.match(new RegExp("^\\s*" + key + "\\s*=\\s*\"(#[0-9A-Fa-f]{6})\"", "m"));
            return m ? m[1] : null;
        };
        bg = pick("background") || bg;
        fg = pick("foreground") || fg;
        accent = pick("accent") || pick("color4") || accent;
        dim = pick("color8") || dim;
        red = pick("color1") || red;
        green = pick("color2") || green;
        yellow = pick("color3") || yellow;
    }

    function log(kind, message) {
        logModel.append({ kind: kind, message: message });
        logView.positionViewAtEnd();
    }

    function run(name, args) {
        if (busy) return;
        busy = true;
        task = name;
        action = "";
        fixHint = "";
        logModel.clear();
        worker.command = [bin, "--events"].concat(args);
        worker.running = true;
    }

    function refresh() {
        if (!statusProc.running) statusProc.running = true;
    }

    Process {
        command: ["sh", "-c", "cat \"$HOME/.config/omarchy/current/theme/colors.toml\" 2>/dev/null"
                              + " || cat \"$HOME/.local/state/omarchy/current/theme/colors.toml\" 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseTheme(text) }
    }

    Process {
        id: statusProc
        command: [root.bin, "status", "--json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.status = JSON.parse(text); } catch (e) { }
            }
        }
    }

    Timer {
        interval: 2000
        running: !root.busy
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: worker
        stdout: SplitParser {
            onRead: data => {
                let ev;
                try { ev = JSON.parse(data); } catch (e) { root.log("info", data); return; }
                if (ev.event === "action") root.action = ev.message;
                if (ev.event === "done") root.action = "";
                if (ev.hint === "fix-clone") root.fixHint = ev.message;
                root.log(ev.event, ev.message);
            }
        }
        stderr: SplitParser { onRead: data => root.log("error", data) }
        onExited: (code, exitStatus) => {
            root.busy = false;
            root.action = "";
            if (code !== 0 && root.task !== "") root.log("error", root.task + " ended (exit " + code + ")");
            root.task = "";
            root.refresh();
        }
    }

    component Btn: Rectangle {
        id: btn
        property string label
        property bool primary: false
        signal clicked
        implicitWidth: btnText.implicitWidth + 28
        implicitHeight: 34
        radius: 6
        opacity: enabled ? 1 : 0.4
        color: primary ? root.accent : (mouse.containsMouse ? Qt.alpha(root.accent, 0.18) : "transparent")
        border.width: 1
        border.color: root.accent
        Text {
            id: btnText
            anchors.centerIn: parent
            text: btn.label
            color: btn.primary ? root.bg : root.fg
            font.family: "monospace"
            font.pixelSize: 13
            font.bold: btn.primary
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (btn.enabled) btn.clicked()
        }
    }

    component Row2: RowLayout {
        property string key
        property string value
        property color valueColor: root.fg
        Layout.fillWidth: true
        spacing: 12
        Text {
            text: parent.key
            color: root.dim
            font.family: "monospace"
            font.pixelSize: 13
            Layout.preferredWidth: 110
        }
        Text {
            text: parent.value
            color: parent.valueColor
            font.family: "monospace"
            font.pixelSize: 13
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    PanelWindow {
        id: win
        color: "transparent"
        implicitWidth: 600
        implicitHeight: 560
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "ps3pair"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: root.bg
            radius: 10
            border.width: 2
            border.color: root.accent

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: Qt.quit()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Q) Qt.quit();
                    if (event.key === Qt.Key_P && !root.busy && root.controller) root.run("Pairing", ["pair"]);
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "🎮  PS3 Gamepad Bluetooth Pairer"
                        color: root.accent
                        font.family: "monospace"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "✕"
                        color: root.dim
                        font.pixelSize: 16
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.quit()
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Row2 {
                        key: "Bluetooth"
                        value: !root.status ? "…"
                             : !root.status.adapter ? "no adapter found"
                             : (root.btOn ? "on" : "off") + "  ·  " + root.status.adapter.name + "  " + root.status.adapter.address
                        valueColor: root.btOn ? root.green : root.red
                    }
                    Row2 {
                        key: "Controller"
                        value: root.controller
                               ? root.controller.name + (root.controller.clone ? "  (clone)" : "") + "  " + (root.controller.address || "")
                               : (root.forgettable && root.forgettable.connected
                                  ? root.forgettable.name + "  (connected over Bluetooth)"
                                  : "not on USB — plug it in with a cable")
                        valueColor: root.controller || (root.forgettable && root.forgettable.connected) ? root.fg : root.yellow
                    }
                    Row2 {
                        visible: !!root.controller
                        key: "Paired to"
                        value: !root.controller ? "" : root.controller.error ? root.controller.error
                             : root.controller.master + (root.controller.paired_here ? "  (this machine)" : "  (another device)")
                        valueColor: root.controller && root.controller.paired_here ? root.green : root.yellow
                    }
                    Row2 {
                        key: "BlueZ"
                        property var d: root.controller ? root.controller.bluez : root.forgettable
                        value: !d ? "not registered yet"
                             : (d.trusted ? "trusted" : "not trusted") + "  ·  " + (d.connected ? "connected" : "not connected")
                        valueColor: d && d.connected ? root.green : root.fg
                    }
                    Row2 {
                        key: "Clone fix"
                        value: root.status ? (root.status.classic_bonded_only ? "not applied (ClassicBondedOnly=true)"
                                                                              : "applied (ClassicBondedOnly=false)") : "…"
                        valueColor: root.needsCloneFix ? root.yellow : root.dim
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: root.action !== ""
                    implicitHeight: actionText.implicitHeight + 24
                    radius: 8
                    color: Qt.alpha(root.accent, 0.15)
                    border.color: root.accent
                    Text {
                        id: actionText
                        anchors.fill: parent
                        anchors.margins: 12
                        text: "▶  " + root.action
                        color: root.fg
                        wrapMode: Text.WordWrap
                        font.family: "monospace"
                        font.pixelSize: 15
                        font.bold: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: Qt.darker(root.bg, 1.25)
                    clip: true

                    Text {
                        anchors.centerIn: parent
                        visible: logModel.count === 0
                        width: parent.width - 40
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: root.dim
                        font.family: "monospace"
                        font.pixelSize: 12
                        text: "Plug the controller in over USB and press Pair.\n"
                            + "You'll be asked to re-plug it, then unplug it and press the PS button."
                    }

                    ListView {
                        id: logView
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 3
                        model: ListModel { id: logModel }
                        delegate: Text {
                            width: logView.width
                            wrapMode: Text.WordWrap
                            font.family: "monospace"
                            font.pixelSize: 12
                            readonly property var marks: ({ step: "==>", ok: "✓", done: "✓", warn: "!", error: "✗", action: "▶" })
                            text: (marks[model.kind] || "·") + " " + model.message
                            color: model.kind === "error" ? root.red
                                 : model.kind === "warn" ? root.yellow
                                 : (model.kind === "ok" || model.kind === "done") ? root.green
                                 : (model.kind === "step" || model.kind === "action") ? root.accent
                                 : root.fg
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Btn {
                        label: root.task === "Pairing" ? "Pairing…" : "Pair"
                        primary: true
                        enabled: !root.busy && !!root.controller
                        onClicked: root.run("Pairing", ["pair"])
                    }
                    Btn {
                        visible: root.needsCloneFix
                        label: "Apply clone fix"
                        enabled: !root.busy
                        onClicked: root.run("Clone fix", ["fix-clone", "--pkexec"])
                    }
                    Btn {
                        visible: !!root.status && !root.btOn
                        label: "Turn Bluetooth on"
                        enabled: !root.busy
                        onClicked: root.run("Bluetooth", ["prepare"])
                    }
                    Btn {
                        visible: !!root.forgettable && !root.busy
                        label: "Forget"
                        onClicked: root.run("Forget", ["forget", root.forgettable.address])
                    }
                    Item { Layout.fillWidth: true }
                    Btn {
                        visible: root.busy
                        label: "Cancel"
                        onClicked: worker.signal(2)
                    }
                    Btn {
                        label: "Close"
                        onClicked: Qt.quit()
                    }
                }
            }
        }
    }
}
