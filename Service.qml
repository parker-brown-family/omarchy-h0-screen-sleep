import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Screen Sleep: DPMS-off after N seconds of no input, DPMS-on at the next input.
//
// Deliberately display-only. Nothing here suspends, hibernates, or locks the
// machine: the only commands run are `omarchy-brightness-display off|on`,
// which dispatch Hyprland DPMS. Long-running agents keep running overnight.
Item {
  id: root

  // Injected by omarchy-shell (capability-scoped facade for user plugins).
  property var shell: null

  // Change this to adjust the delay (seconds of no keyboard/mouse input).
  readonly property int timeoutSeconds: 600

  // Respect Omarchy's "stay awake" indicator: when it's on, screens stay lit.
  readonly property string stayAwakeFile: "$HOME/.local/state/omarchy/indicators/stay-awake"

  property bool screensOff: false

  function log(msg) {
    console.log("screen-sleep " + new Date().toISOString() + " " + msg)
  }

  function screensOffNow() {
    if (offProcess.running) return
    log("idle " + root.timeoutSeconds + "s: turning displays off")
    root.screensOff = true
    offProcess.running = true
  }

  function screensOnNow() {
    if (!root.screensOff) return
    root.screensOff = false
    log("activity: turning displays on")
    // Hyprland's mouse_move/key_press_enables_dpms usually already did this;
    // the script is a no-op when every display is lit.
    if (!onProcess.running) onProcess.running = true
  }

  IdleMonitor {
    id: idleMonitor
    enabled: true
    timeout: root.timeoutSeconds
    // Apps holding an idle inhibitor (video players, etc.) keep screens on.
    respectInhibitors: true
    onIsIdleChanged: {
      if (isIdle) root.screensOffNow()
      else root.screensOnNow()
    }
  }

  Process {
    id: offProcess
    command: ["bash", "-c", "[[ -f \"" + root.stayAwakeFile + "\" ]] && exit 0; omarchy-brightness-display off"]
  }

  Process {
    id: onProcess
    command: ["bash", "-c", "omarchy-brightness-display on"]
  }

  IpcHandler {
    target: "screen-sleep"

    function status(): string {
      return JSON.stringify({
        timeoutSeconds: root.timeoutSeconds,
        idle: idleMonitor.isIdle,
        screensOff: root.screensOff
      })
    }
  }

  Component.onCompleted: log("ready, timeout=" + root.timeoutSeconds + "s")
}
