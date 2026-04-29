# HeadsetControl Plugin for Noctalia Shell

Control your wireless gaming headset directly from Noctalia Shell using [HeadsetControl](https://github.com/Sapd/HeadsetControl).

![Preview](preview.png)

## Features

- **Battery monitoring** - Bar widget shows battery with NBattery widget (charging indicator)
- **Connection detection** - Reliable state via JSON battery status
- **Sidetone control** - Adjust mic feedback level (0-128) via panel or IPC
- **LED/Lights toggle** - Turn headset lights on/off
- **Inactive timer** - Set auto power-off timeout
- **Equalizer** - Choose from 4 preset EQ curves, or set a custom curve
- **Voice prompts** - Enable/disable audio cue prompts
- **Chatmix** - View game/chat audio balance dial level
- **Microphone LED brightness** - Adjust mute LED brightness
- **Volume limiter** - Toggle volume limiter on/off
- **Bluetooth controls** - Set power-on behavior and call volume
- **Notification sounds** - Trigger headset notification sounds
- **Capability-based UI** - Panel only shows controls supported by your headset
- **IPC access** - Control everything via `qs -c noctalia-shell ipc call plugin:headsetcontrol ...`

## Requirements

- [HeadsetControl](https://github.com/Sapd/HeadsetControl) installed and in PATH
- Supported headset (Logitech G533/G933/G935/Pro, SteelSeries Arctis series, Corsair Void, HyperX Cloud, etc.)

Install HeadsetControl on Arch Linux:
```bash
yay -S headsetcontrol
```

Or build from source:
```bash
git clone https://github.com/Sapd/HeadsetControl && cd HeadsetControl
mkdir build && cd build
cmake .. && make
sudo make install
sudo udevadm control --reload-rules && sudo udevadm trigger
```

## Installation

### Option 1: Add Repository (Recommended)

1. Open **Noctalia Settings** → **Plugins** → **Sources**
2. Click **Add custom repository**
3. Enter a repository name (e.g., "HeadsetControl Plugin")
4. Add the repository URL:
   ```
   https://github.com/hrzlgnm/noctalia-plugins
   ```
5. The HeadsetControl plugin will now appear in your **Available** tab
6. Click **Install** to enable it

### Option 2: Manual Symlink

Create a symlink to this plugin in your Noctalia plugins directory:

```bash
ln -s $(pwd) ~/.config/noctalia/plugins/headsetcontrol
```

Then enable it in Noctalia Settings > Plugins.

## IPC Commands

```bash
# Set sidetone level (0-128)
qs -c noctalia-shell ipc call plugin:headsetcontrol setSidetone 64

# Toggle lights (0=off, 1=on)
qs -c noctalia-shell ipc call plugin:headsetcontrol setLights 0

# Set inactive/auto-off timer (minutes, 0=disabled)
qs -c noctalia-shell ipc call plugin:headsetcontrol setInactiveTime 30

# Set voice prompt (0=off, 1=on)
qs -c noctalia-shell ipc call plugin:headsetcontrol setVoicePrompt 0

# Set equalizer preset (0-3)
qs -c noctalia-shell ipc call plugin:headsetcontrol setEqualizerPreset 0

# Set custom EQ curve (space-separated values)
qs -c noctalia-shell ipc call plugin:headsetcontrol setEqualizer "0 0 0 0 0 0 0 0 0 0"

# Set microphone mute LED brightness
qs -c noctalia-shell ipc call plugin:headsetcontrol setMicMuteLedBrightness 50

# Toggle volume limiter
qs -c noctalia-shell ipc call plugin:headsetcontrol setVolumeLimiter 1

# Set Bluetooth power-on behavior
qs -c noctalia-shell ipc call plugin:headsetcontrol setBtPowerOn 1

# Set Bluetooth call volume
qs -c noctalia-shell ipc call plugin:headsetcontrol setBtCallVolume 70

# Send notification sound (0 or 1)
qs -c noctalia-shell ipc call plugin:headsetcontrol sendNotification 0

# Check if headset is connected
qs -c noctalia-shell ipc call plugin:headsetcontrol checkConnected

# Toggle panel
qs -c noctalia-shell ipc call plugin:headsetcontrol togglePanel
```

## Supported Headsets

See the [HeadsetControl README](https://github.com/Sapd/HeadsetControl#supported-devices) for the full list. Supported features vary by model.

## Settings

- **Polling interval** - How often to refresh battery/chatmix (0 to disable)
- **Show battery % in bar** - Toggle percentage text visibility
- **Default sidetone** - Saved between sessions, applied via settings panel
- **Default EQ preset** - Saved between sessions

## License

GPL-3.0 (same as HeadsetControl)
