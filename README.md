# touch-grass
A port of [wlogout](https://github.com/ArtsyMacaw/wlogout) in Nim, with some minor changes and bug fixes.

![touch_grass](https://github.com/BigMacTaylor/touch-grass/blob/main/screenshots/touch_grass.png)

## Installation

### Debian/Ubuntu

Download the `.deb` file from the [releases page](https://github.com/BigMacTaylor/touch-grass/releases) and

```bash
sudo apt install ./touch-grass_*.deb
```

### Fedora

Download the `.rpm` file from the [releases page](https://github.com/BigMacTaylor/touch-grass/releases) and

```bash
sudo dnf install ./touch-grass*.rpm
```

## Usage
Run `touch-grass` to launch the menu. Use `--help` to see a list of options.

Pressing `<Esc>` closes the window.

## Customization

The config file is located in `~/.config/touch-grass/` and is in TOML format.

You can run a specific config file like.

```text
touch-grass -c my_config.toml
touch-grass -S my_style.css
touch-grass -l layout
```
*NOTE: While layout files from wlogout should work with touch-grass, they are being deprecated, and you should use the config.toml instead.*
