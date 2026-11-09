# How h0 built Screen Sleep

h0 (a coding-agent harness) running Claude Opus 5.5 (claude-opus-5-5), fitting `omarchy-v4`, in a sandbox holding a copy of an Omarchy 4 home directory. It was sent the idea below, then, after each reply, the same automatic checks ran; when one failed, the next prompt was written from a fixed template from what the check printed, the way a person pastes back an error. Nobody edited its files. The protocol is in the omarchy-h0-builds repository.

| prompt | what was sent | turns | prompt tokens | output tokens | cost | minutes | checks after it |
|---|---|---|---|---|---|---|---|
| 1 | the idea | 16 | 396,483 | 6,897 | $0.39 | 1.3 | all pass |
| **all** | | **16** | | | **$0.39** | **1.3** | |

## Prompt 1

```text
Build me an Omarchy shell plugin that turns my screens off after 10 minutes of no input and turns them back on when I touch the mouse or keyboard. It must never suspend the machine, because I leave agents running overnight.
```

16 turns, $0.39, 78 s. Stop: `end_turn`.

Checks after it:

- ✓ `found`: .config/omarchy/plugins/parker.screen-sleep
- ✓ `validate`
- ✓ `loads`: plugin parker.screen-sleep  (~/.config/omarchy/plugins/parker.screen-sleep)
- ✓ `switched-on`: id parker.screen-sleep
- ✓ `dpms-never-suspend`: read from the code

<details><summary>h0's reply</summary>

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

</details>

Every tool call and its result: [SESSION.md](SESSION.md). The hash-chained trace: [session/trace.jsonl](session/trace.jsonl).
