# h0 building Screen Sleep

Rendered from the session's recorded trace (`trace.jsonl`), not from a screen capture. Workspace paths are shown as `~`; tool output is cut to its first 40 lines.

Model `claude-opus-5-5` · fitting `omarchy-v4` · tools read, edit, write, grep, glob, bash, check

---

### › You

```text
Build me an Omarchy shell plugin that turns my screens off after 10 minutes of no input and turns them back on when I touch the mouse or keyboard. It must never suspend the machine, because I leave agents running overnight.
```

I'll start by reading the plugin guide, the current shell config, and any existing plugins.

**⏺ bash** `cat /usr/share/omarchy/default/agents/skills/omarchy/plugins.md; echo ----; cat .config/omarchy/shell.json; echo ----; ls -la .config/omarchy/plugins 2>&1; ls /usr/share/omarchy/shell/plugins/`

✓ 47 ms

```text
[exit 0, 43 ms]
# Omarchy Shell: Bar, Plugins, and Idle

Read this before changing the status bar, notifications, shell plugins,
widgets, or idle/lock behavior.

The bar, notification daemon, settings panel, and assorted overlays all run
inside a single long-running Quickshell process (`omarchy-shell`).

```
~/.config/omarchy/shell.json             # User overrides: bar, plugins, idle
~/.config/omarchy/plugins/<plugin-id>/   # User-owned shell plugins
$OMARCHY_PATH/config/omarchy/shell.json  # Canonical defaults
```

The shell hot-reloads `shell.json` on save — no restart needed for layout
changes. `idle.screensaver` and `idle.lock` are seconds since user idle began.

**Commands:** `omarchy restart shell`, `omarchy refresh shell`

## Bar Layout

Use the `omarchy bar` group to move and manage widgets:

```bash
omarchy bar move omarchy.clock --section right
```

For layout edits beyond what the commands cover, edit the bar configuration
in `~/.config/omarchy/shell.json`; it hot-reloads on save.

## Customizing Built-In Plugins and Widgets

To customize a built-in bar widget, never edit `$OMARCHY_PATH/shell/plugins/`.
Clone it into the user plugin directory instead:

```bash
omarchy plugin clone omarchy.workspaces
# Edit ~/.config/omarchy/plugins/<username>.workspaces/; saved changes reload automatically.
```
…
```

**⏺ bash** `cd /usr/share/omarchy/shell/plugins; cat README.md; ls -R lock services | head -50; cat /usr/share/omarchy/config/omarchy/shell.json | head -60`

✓ 50 ms

```text
[exit 0, 44 ms]
# First-party plugins

These plugins ship with Omarchy and are discovered by the shell at startup.
They use the same `manifest.json` contract as third-party plugins; the
only difference is that the shell flags them with `__isFirstParty: true`.
First-party non-bar plugins are enabled unless listed in `disabledPlugins[]`;
`omarchy.bar` is the default bar option and becomes inactive only while another
`kind: "bar"` plugin is selected. Services and keep-loaded panels are mounted
at startup; other panels, overlays, and menus are loaded on demand.

User-installed plugins live alongside these conceptually but on disk under
`~/.config/omarchy/plugins/<plugin-id>/` rather than in this directory.

| Plugin        | id                        | kinds                   | entry point                           |
|---------------|---------------------------|-------------------------|---------------------------------------|
| Bar           | `omarchy.bar`             | `bar`                   | `bar/Bar.qml`                         |
| Image picker  | `omarchy.image-picker`    | `overlay`               | `image-picker/ImagePicker.qml`        |
| Emojis        | `omarchy.emojis`          | `overlay`               | `emojis/Emojis.qml`                   |
| Clipboard mgr | `omarchy.clipboard`       | `overlay`               | `clipboard/Clipboard.qml`             |
| Reminders     | `omarchy.reminders`       | `overlay`               | `reminders/ReminderFlow.qml`          |
| Omarchy menu  | `omarchy.menu`            | `menu`, `bar-widget`    | `menu/Menu.qml`, `menu/BarWidget.qml` |
| Notifications | `omarchy.notifications`   | `service`               | `notifications/Service.qml`           |
| Audio         | `omarchy.audio`           | `bar-widget`            | `panels/audio/Panel.qml`              |
| Bluetooth     | `omarchy.bluetooth`       | `bar-widget`            | `panels/bluetooth/Panel.qml`          |
| Clock         | `omarchy.clock`           | `bar-widget`            | `panels/clock/BarWidget.qml`          |
| Monitor       | `omarchy.monitor`         | `bar-widget`            | `panels/monitor/Panel.qml`            |
| Network       | `omarchy.network`         | `bar-widget`            | `panels/network/Panel.qml`            |
| Power         | `omarchy.power`           | `bar-widget`            | `panels/power/Panel.qml`              |
| Tailscale     | `omarchy.tailscale`       | `bar-widget`            | `panels/tailscale/Panel.qml`          |
| Agents   | `omarchy.agents`     | `bar-widget`            | `agents/Panel.qml`               |
| Weather       | `omarchy.weather`         | `bar-widget`            | `panels/weather/BarWidget.qml`        |
| Media         | `omarchy.media`           | `service`, `bar-widget` | `services/media/Service.qml`, `services/media/BarWidget.qml` |
| Battery       | `omarchy.battery`         | `service`               | `services/battery/Service.qml`        |
| Idle          | `omarchy.idle`            | `service`               | `services/idle/Service.qml`           |
| Night light   | `omarchy.nightlight`      | `service`               | `services/nightlight/Service.qml`     |
| Lock screen   | `omarchy.lock`            | `service`               | `lock/Service.qml`                    |
| OSD           | `omarchy.osd`             | `panel`                 | `osd/Osd.qml`                         |
| Polkit agent  | `omarchy.polkit`          | `service`               | `polkit/PolkitAgent.qml`              |

…
```

**⏺ bash** `cd /usr/share/omarchy/shell/plugins/services/idle; cat manifest.json Service.qml IdleModel.js`

✓ 52 ms

```text
[exit 0, 46 ms]
{
  "schemaVersion": 1,
  "id": "omarchy.idle",
  "name": "Idle",
  "version": "1.0.0",
  "author": "Omarchy",
  "description": "Quickshell-based idle detection for screensaver, lock, and display wake.",
  "kinds": [
    "service"
  ],
  "keepLoaded": true,
  "entryPoints": {
    "service": "Service.qml"
  }
}
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "IdleModel.js" as IdleModel

Item {
  id: root

  // Injected by omarchy-shell (the first-party service loader).
  property var shell: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string stayAwakeStateDir: home + "/.local/state/omarchy/indicators"
  readonly property string stayAwakeStatePath: stayAwakeStateDir + "/stay-awake"
  readonly property int defaultScreensaverSeconds: 150
  readonly property int defaultLockSeconds: 300
  readonly property var idleConfig: shell && shell.shellConfig && shell.shellConfig.idle
    ? shell.shellConfig.idle : (shell && shell.idleConfig ? shell.idleConfig : ({}))
  readonly property int screensaverTimeoutSeconds: secondsFromConfig(idleConfig.screensaver, defaultScreensaverSeconds)
  readonly property int lockTimeoutSeconds: secondsFromConfig(idleConfig.lock, defaultLockSeconds)
  readonly property int firstIdleTimeoutSeconds: Math.min(screensaverTimeoutSeconds, lockTimeoutSeconds)
  readonly property int screensaverDelaySeconds: Math.max(0, screensaverTimeoutSeconds - firstIdleTimeoutSeconds)
…
```

Now let me check the helper commands, the plugin validator's schema, and whether anything in the stock stack suspends.

**⏺ bash** `for c in omarchy-system-lock omarchy-system-wake omarchy-plugin-validate; do echo "=== $c"; cat $(which $c) 2>&1 | head -120; done; echo ===; grep -rl -i "suspend" /usr/share/omarchy/shell /usr/share/omarchy/bin 2>/dev/null | head -30; ls /usr/share/omarchy/default/omarchy/ 2>/dev/null`

✓ 68 ms

```text
[exit 0, 63 ms]
=== omarchy-system-lock
#!/bin/bash

# omarchy:summary=Lock the computer and turn off the display
# omarchy:group=system
# omarchy:name=lock
# omarchy:examples=omarchy system lock

omarchy-shell lock lock >/dev/null

# Set keyboard layout to default (first layout)
hyprctl switchxkblayout all 0 > /dev/null 2>&1

# Ensure 1password is locked. Use timeout because `1password --lock` can
# otherwise leave a full Electron helper tree running after each lock.
if pgrep -x "1password" >/dev/null && omarchy-cmd-present 1password; then
  (
    flock -n 9 || exit 0
    timeout --kill-after=1s 3s 1password --lock >/dev/null 2>&1 || true
  ) 9>"${XDG_RUNTIME_DIR:-/tmp}/omarchy-1password-lock.lock" &
fi

# Avoid running screensaver when locked
pkill -x ttfx 2>/dev/null || true
# ttfx handles SIGTERM asynchronously, so keep its terminal alive until it exits.
timeout 1s pidwait -x ttfx 2>/dev/null || true
pkill -f '[o]rg.omarchy.screensaver' 2>/dev/null || true
=== omarchy-system-wake
#!/bin/bash

# omarchy:summary=Wake displays and restore brightness after idle
# omarchy:group=system
# omarchy:name=wake
# omarchy:examples=omarchy system wake

omarchy-brightness-display on
omarchy-brightness-keyboard restore
omarchy-hyprland-monitor-clamshell >/dev/null 2>&1 || true
=== omarchy-plugin-validate
…
```

Let me check where suspend appears, how display on/off is done, and how user plugins get enabled in `shell.json`.

**⏺ bash** `grep -n -i suspend /usr/share/omarchy/shell/plugins/lock/Service.qml; echo ===; cat $(which omarchy-brightness-display); echo ===; ls /usr/share/omarchy/shell/services/; grep -n -i -E '"plugins"|shellConfig\.plugins|enabled|disabledPlugins|injected|property var shell' /usr/share/omarchy/shell/servic`

✓ 48 ms

```text
[exit 0, 43 ms]
420:      // A countdown frozen by suspend fires right after resume, which would
===
#!/bin/bash

# omarchy:summary=Show or adjust brightness on the focused display.
# omarchy:args=[--no-osd] [--monitor name] [+N%|N%-|N%|off|on]
# omarchy:examples=omarchy brightness display | omarchy brightness display +5% | omarchy brightness display --monitor DP-1 50% | omarchy brightness display off | omarchy brightness display on

no_osd=0
monitor=""

while (( $# > 0 )); do
  case "$1" in
  --no-osd)
    no_osd=1
    shift
    ;;
  --monitor)
    (( $# >= 2 )) || exit 1
    monitor="$2"
    shift 2
    ;;
  *)
    break
    ;;
  esac
done

# Get the brightness of the passed display
backlight_brightness() {
  brightnessctl -d "$1" -m 2>/dev/null | awk -F, '{ gsub("%", "", $4); print $4; found=1 } END{ exit !found }'
}

[[ -n $monitor ]] || monitor="$(omarchy-hyprland-monitor-focused 2>/dev/null || true)"

monitor_is_internal() {
  [[ $monitor =~ ^(eDP|LVDS|DSI)- ]]
}

…
```

**⏺ bash** `sed -n 120,170p /usr/share/omarchy/shell/services/PluginRegistry.qml; sed -n 470,540p /usr/share/omarchy/shell/services/PluginRegistry.qml; grep -rn "service" /usr/share/omarchy/shell/services/PluginRegistry.qml | head -30`

✓ 48 ms

```text
[exit 0, 43 ms]
    var ep = manifest.entryPoints ? manifest.entryPoints[kind] : null
    if (!ep) return ""
    var dir = manifest.__sourceDir || ""
    if (!dir) return ""
    // Defense in depth: even after validateManifest, confirm the resolved
    // path stays inside the plugin's sourceDir.
    var resolved = dir.replace(/\/$/, "") + "/" + String(ep)
    var expectedPrefix = dir.replace(/\/$/, "") + "/"
    if (resolved.indexOf(expectedPrefix) !== 0) {
      console.warn("PluginRegistry: entry point escapes sourceDir: " + resolved)
      return ""
    }
    return Util.fileUrl(resolved)
  }

  // Enabled = the plugin id is referenced somewhere in shell.json. That can
  // be either the active bar option in `bar.id`, a layout entry inside
  // `bar.layout.*` (bar widgets), or a top-level entry in `plugins[]` (panels,
  // overlays, services).
  //
  // Special cases (implicitly always enabled, no shell.json entry needed):
  //   - the built-in bar option (`omarchy.bar`) is active when `bar.id` is
  //     missing or set to `omarchy.bar`.
  //   - first-party non-bar plugins are shell infrastructure (settings,
  //     image-picker, ...). Requiring users to add them to plugins[] just to
  //     summon them was a footgun: a stock shell.json with `plugins: []` would
  //     silently make `omarchy launch bar-settings` a no-op. Turning one off
  //     is therefore recorded the other way round, in `disabledPlugins[]`.
  function isEnabled(id) {
    var key = String(id)
    var manifest = installedPlugins[key]
    var config = shellConfigProvider ? shellConfigProvider() : null
    if (manifest) {
      if (Array.isArray(manifest.kinds) && manifest.kinds.indexOf("bar") !== -1) {
        var selectedBar = ""
        if (Util.isPlainObject(config) && Util.isPlainObject(config.bar))
          selectedBar = Util.canonicalWidgetId(String(config.bar.id || ""))
        if (!selectedBar) selectedBar = "omarchy.bar"
        return selectedBar === key
…
```

Now how user services are mounted and what properties they receive:

**⏺ bash** `cd /usr/share/omarchy/shell; grep -rn -E '"service"' --include=*.qml . | grep -v plugins/ | head -20; grep -rn -i "pluginConfig\|pluginSettings\|entryConfig" --include=*.qml . | grep -v "^./plugins" | head -20; ls /usr/share/omarchy/default/omarchy 2>/dev/null; ls ~/.local/bin 2>/dev/null; ls /usr/s`

✓ 67 ms

```text
[exit 0, 63 ms]
./shell.qml:268:  // Generic loader for any enabled plugin that declares kind "service".
./shell.qml:907:    if (!Array.isArray(manifest.kinds) || manifest.kinds.indexOf("service") === -1) return null
./shell.qml:909:    var url = pluginRegistry.entryPointUrl(manifest, "service")
./shell.qml:959:      if (!Array.isArray(m.kinds) || m.kinds.indexOf("service") === -1) continue
./shell.qml:997:        && stillThere.kinds.indexOf("service") !== -1
./shell.qml:1015:        && authenticationManifest.kinds.indexOf("service") !== -1
./shell.qml:1349:          if ("service" in item) item.service = shell.serviceFor(panelEntry.pluginId)
./shell.qml:396:  function barEntryConfigured(pluginId) {
./shell.qml:406:    if (shell.barEntryConfigured(id)) return true
./shell.qml:619:          && shell.pluginRegistry.isEnabled(key) && shell.barEntryConfigured(key)
./shell.qml:650:        if (hasCurrentBarCapabilities() && shell.barEntryConfigured(requestedId))
./shell.qml:692:    if (!shell.barEntryConfigured(target)) return null
./shell.qml:855:      if (entryApi && shell.barEntryConfigured(entryApi.pluginId)) entryNext[entryKey] = entryApi
launcher.hides
omarchy-menu.jsonc
Commons
README.md
Ui
plugins
services
shell.qml
```

**⏺ bash** `cd /usr/share/omarchy/shell; sed -n 260,300p shell.qml; sed -n 895,1000p shell.qml; grep -n -i "service\|plugins\[\]" README.md | head -40`

✓ 49 ms

```text
[exit 0, 43 ms]
        console.warn("bar option " + shell.activeBarId + " failed to load, falling back to " + shell.defaultBarId)
        shell.failedBarId = shell.activeBarId
      }
    }
  }

  // ------------------------------------------------------------- services
  //
  // Generic loader for any enabled plugin that declares kind "service".
  // First-party infrastructure services are implicitly enabled by the registry;
  // third-party services are enabled by adding the plugin id to shell.json.
  Item {
    id: serviceHost
    visible: false
  }

  property var _services: ({})
  property var _pluginShellApis: ({})
  property var _pluginShellApiDescriptors: ({})
  property var _pluginBarEntryShellApis: ({})
  property var _pluginRegistryApis: ({})
  property var _pluginBarWidgetRegistryApis: ({})
  property var _pluginAppLibraryApis: ({})
  property var _pluginBarStateApis: ({})
  property var _pluginFirstPartyServiceApis: ({})

  Component {
    id: pluginShellApiComponent
    PluginShellApi { }
  }

  Component {
    id: pluginRegistryApiComponent
    PluginRegistryApi { }
  }

  Component {
    id: pluginBarWidgetRegistryApiComponent
    PluginBarWidgetRegistryApi { }
…
```

**⏺ bash** `cd /usr/share/omarchy/shell/plugins/lock; grep -n -i -E "dpms|brightness|display|suspend|sleep" Service.qml | head -30; echo ===; grep -rn -i -E "suspend|IdleAction" /etc/systemd/logind.conf /etc/systemd/logind.conf.d/ /usr/lib/systemd/logind.conf.d/ 2>/dev/null | grep -v '^\s*#' | head; grep -rn -i`

✗ 47 ms

```text
[exit 2, 43 ms]
411:    command: ["bash", "-c", "omarchy-brightness-keyboard off; omarchy-brightness-display off"]
420:      // A countdown frozen by suspend fires right after resume, which would
427:      // Only a password check in flight should hold the display up. The
===
/etc/systemd/logind.conf:27:#SleepOperation=suspend-then-hibernate suspend
/etc/systemd/logind.conf:32:#HandleSuspendKey=suspend
/etc/systemd/logind.conf:33:#HandleSuspendKeyLongPress=hibernate
/etc/systemd/logind.conf:36:#HandleLidSwitch=suspend
/etc/systemd/logind.conf:37:#HandleLidSwitchExternalPower=suspend
/etc/systemd/logind.conf:41:#SuspendKeyIgnoreInhibited=no
/etc/systemd/logind.conf:46:#IdleAction=ignore
/etc/systemd/logind.conf:47:#IdleActionSec=30min
/etc/systemd/logind.conf.d/20-inhibit-delay.conf:2:# before the machine suspends. A delay inhibitor is a timer, not a promise:
/etc/systemd/logind.conf.d/20-inhibit-delay.conf:3:# logind suspends anyway once the window expires, locked or not. Five seconds
/usr/share/omarchy/default/hypr/input.lua:72:    key_press_enables_dpms = true,
/usr/share/omarchy/default/hypr/input.lua:73:    mouse_move_enables_dpms = true,
/usr/share/omarchy/default/hypr/nvidia.lua:8:-- lspci reads PCI config space, which resumes a runtime-suspended GPU, and on a
parker
ls: cannot access '.config/hypr': No such file or directory
```

**⏺ bash** `cd /usr/share/omarchy/shell/plugins/lock; sed -n 395,450p Service.qml; cat /etc/systemd/logind.conf.d/*.conf; sed -n 60,80p /usr/share/omarchy/default/hypr/input.lua`

✓ 47 ms

```text
[exit 0, 43 ms]

      root.strandedLockResolved = true

      // A lock taken while this was in flight is this shell's own.
      root.strandedLock = exitCode === 0 && !root.locked && !root.lockRequested
      root.recoverStrandedLock()
    }
  }

  Process {
    id: wakeProcess
    command: ["bash", "-c", "omarchy-system-wake"]
  }

  Process {
    id: blankProcess
    command: ["bash", "-c", "omarchy-brightness-keyboard off; omarchy-brightness-display off"]
  }

  Timer {
    id: idleBlankTimer
    interval: 5000
    repeat: false
    property double armedAt: 0
    onTriggered: {
      // A countdown frozen by suspend fires right after resume, which would
      // blank the freshly woken unlock screen under the user. Wall-clock time
      // exposes the gap: take a fresh run-up instead of blanking.
      if (Date.now() - armedAt > interval + 2000) {
        root.armBlankTimer()
        return
      }
      // Only a password check in flight should hold the display up. The
      // fingerprint PAM stays armed for the whole lock, so gating on
      // `authenticating` here would keep the panel lit until unlock.
      if (root.lockRequested && !root.authenticatingPassword) root.runBlank()
    }
  }

…
```

**⏺ bash** `cd /usr/share/omarchy/shell/services; grep -n "function findEntryLocation" -A30 PluginRegistry.qml; ls ../plugins/services/battery; cat ../plugins/services/nightlight/manifest.json`

✓ 71 ms

```text
[exit 0, 66 ms]
231:  function findEntryLocation(config, id) {
232-    if (!Util.isPlainObject(config)) return { found: false }
233-    var key = Util.canonicalWidgetId(String(id))
234-    if (Util.isPlainObject(config.bar)) {
235-      var selectedBar = Util.canonicalWidgetId(String(config.bar.id || ""))
236-      if (selectedBar === key) return { found: true, kind: "bar-option" }
237-    }
238-    if (Util.isPlainObject(config.bar) && Util.isPlainObject(config.bar.layout)) {
239-      var barLocation = findBarLocation(config, key, "")
240-      if (barLocation.found) return barLocation
241-    }
242-    if (Array.isArray(config.plugins)) {
243-      for (var j = 0; j < config.plugins.length; j++) {
244-        if (config.plugins[j] && Util.canonicalWidgetId(config.plugins[j].id) === key) return { found: true, kind: "plugin", index: j }
245-      }
246-    }
247-    return { found: false }
248-  }
249-
250-  function barTarget(config, placement, fallbackSection) {
251-    var target = placement || {}
252-    var section = ["left", "center", "right"].indexOf(String(target.section || "")) !== -1
253-      ? String(target.section) : fallbackSection
254-    var relativeId = String(target.before || target.after || "")
255-    if (relativeId) {
256-      var relative = findRelativeBarLocation(config, relativeId, section && target.section ? section : "")
257-      if (!relative.found) return { error: "could not find target widget " + relativeId }
258-      return {
259-        section: relative.section,
260-        index: relative.index + (target.after ? 1 : 0)
261-      }
BatteryModel.js
Service.qml
manifest.json
{
  "schemaVersion": 1,
  "id": "omarchy.nightlight",
  "name": "Night Light",
  "version": "1.0.0",
…
```

Entries are `{ "id": ... }` objects. Next I'll write the plugin.

**⏺ write** `.config/omarchy/plugins/parker.screen-sleep/manifest.json`

```
{
  "schemaVersion": 1,
  "id": "parker.screen-sleep",
  "name": "Screen Sleep",
  "version": "1.0.0",
  "author": "parker",
  "description": "Turns all displays off (DPMS) after 10 minutes without input and back on at the next input. Never suspends.",
  "kinds": [
    "service"
  ],
  "entryPoints": {
    "service": "Service.qml"
  }
}
```

✓ 1 ms

```text
wrote 339 bytes to .config/omarchy/plugins/parker.screen-sleep/manifest.json
```

**⏺ write** `.config/omarchy/plugins/parker.screen-sleep/Service.qml`

```
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
… (20 more lines in the repository)
```

✓ 0 ms

```text
wrote 2320 bytes to .config/omarchy/plugins/parker.screen-sleep/Service.qml
```

Next I'll back up `shell.json` and add the plugin to `plugins[]`, which is how third-party services get enabled.

**⏺ bash** `cp .config/omarchy/shell.json .config/omarchy/shell.json.bak.$(date +%s) && ls .config/omarchy/`

✓ 92 ms

```text
[exit 0, 86 ms]
extensions
hooks
plugins
shell.json
shell.json.bak.1794262861
themed
themes
```

**⏺ edit** `.config/omarchy/shell.json`

```
  "plugins": [
    {
      "id": "parker.screen-sleep"
    }
  ]
```

✓ 333 ms

```text
edited .config/omarchy/shell.json at line 65

[harness note] Read /usr/share/omarchy/default/agents/skills/omarchy/plugins.md first. Bar is omarchy-shell, not Waybar; idle values are seconds. A new plugin goes in .config/omarchy/plugins/<id>/ with a manifest.json; read a built-in plugin's source under /usr/share/omarchy/shell/plugins/ for the patterns, and switch a plugin on by adding its id to shell.json (bar.layout for widgets, plugins for others). Run the validate and preview checks before finishing. Never edit packaged plugins.
```

**⏺ check** `build`

✓ 3295 ms

```text
[exit 0, 3290 ms]
plugin parker.screen-sleep  (~/.config/omarchy/plugins/parker.screen-sleep)
  service: Service.qml: loaded; drew no text
PREVIEW: ok
```

**⏺ bash** `bash -n -c '[[ -f "$HOME/.local/state/omarchy/indicators/stay-awake" ]] && exit 0; omarchy-brightness-display off' && echo ok`

✓ 89 ms

```text
[exit 0, 85 ms]
ok
```

I built the plugin `parker.screen-sleep` and turned it on. It turns all screens off after 10 minutes with no input and back on when you touch the mouse or keyboard. It never suspends the machine. One problem: **your current lock setting will turn the screens off at about 5 minutes, before this plugin's 10.** Details below.

**What I added**
- `.config/omarchy/plugins/parker.screen-sleep/manifest.json` and `Service.qml`: a background plugin that watches for input. After 600 seconds with none, it runs `omarchy-brightness-display off`. When input comes back, it runs `omarchy-brightness-display on`. Those two commands only switch the displays off and on; the plugin can't suspend, hibernate or lock anything.
  - If you have Omarchy's "stay awake" toggle on, it leaves the screens alone.
  - If an app is blocking idle (a video player, for example), it waits.
  - Hyprland is already set to turn screens back on at any key press or mouse move. The plugin's "on" command is a backup.
  - To change the delay, edit `timeoutSeconds` near the top of `Service.qml`. It reloads when you save.
- `.config/omarchy/shell.json`: I added `{ "id": "parker.screen-sleep" }` to `plugins`, which is what turns it on. A backup of the original is at `shell.json.bak.1794262861`.

**Nothing suspends on idle today.** I checked: Omarchy's own idle handling only starts the screensaver and then locks, and the system's idle action is the default, "ignore". So adding this plugin doesn't add any suspend path.

**Things you should know**
1. **The lock turns the screens off first.** Your `shell.json` has `idle.lock: 300`, and Omarchy's lock screen switches the displays off a few seconds after it locks. That means your screens currently go dark at about 5 minutes. If you want the 10-minute timing to be what actually happens, either:
   - set `idle.lock` to `600` or higher, or
   - tell me if you want to keep locking at 5 minutes, or you'd rather have screens off without any lock.

   I didn't change your lock time, since it's a security setting you didn't ask about.
2. **Closing a laptop lid still suspends.** That's the system default, separate from idle. If this is a laptop and you close it overnight, say so and I can look at changing that. It's a system file outside your config folder, so it would need admin rights.

**How I checked it**
- The `build` check passed: valid JSON, Omarchy's plugin validator accepted it, and the shell loaded the plugin with no errors.
- I couldn't test it on your running desktop, so the actual screen-off and wake-up are untested. To confirm it's running, use `omarchy-shell screen-sleep status`. To test it quickly, set `timeoutSeconds` to `15`, wait, move the mouse, then set it back to `600`.

*harness: verify check `build` passed*

