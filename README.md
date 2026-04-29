# Noctalia Plugins

A collection of plugins for [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell).

## Plugins

| Plugin | Description | Path |
|---|---|---|
| HeadsetControl | Control wireless headsets via HeadsetControl (sidetone, battery, LED, equalizer, chatmix, and more) | [headsetcontrol/](headsetcontrol/) |

## Installation

To use plugins from this repository:

1. Open **Noctalia Settings** → **Plugins** → **Sources**
2. Click **Add custom repository**
3. Enter a repository name (e.g., "hrzlgnm Plugins")
4. Add the repository URL:
   ```
   https://github.com/hrzlgnm/noctalia-plugins
   ```
5. Plugins will now appear in your **Available** tab
6. Click **Install** on any plugin to enable it

## Registry Automation

The plugin registry is automatically maintained using GitHub Actions:

- **Automatic Updates**: Registry updates when manifest.json files are modified
- **PR Validation**: Pull requests show if registry will be updated

See [.github/workflows/README.md](.github/workflows/README.md) for technical details.

## Plugin Development

See [AGENTS.md](AGENTS.md) for guidelines on contributing plugins.

## Reference

Original plugin repository: [noctalia-dev/noctalia-plugins](https://github.com/noctalia-dev/noctalia-plugins)
