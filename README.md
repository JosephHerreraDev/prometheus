# Prometheus

A modern, fast, customizable and minimal arch rice.

<img width="1080" height="607" alt="hyprland-beatiful-minimalist-rice-for-productivity-v0-7p2dbxa4euvg1" src="https://github.com/user-attachments/assets/22cf90f4-6319-40ab-83d3-d0473d70f90d" />

<img width="1080" height="607" alt="hyprland-beatiful-minimalist-rice-for-productivity-v0-j3xy8ja4euvg1" src="https://github.com/user-attachments/assets/73b1f43e-f788-4a47-a290-db0de7f88c3a" />

<img width="1080" height="607" alt="hyprland-beatiful-minimalist-rice-for-productivity-v0-3jyreja4euvg1" src="https://github.com/user-attachments/assets/63f964c1-903d-4eb9-ac55-72883574e912" />


## Installation
    
```bash
curl -fsSL https://raw.githubusercontent.com/JosephHerreraDev/prometheus/main/boot.sh | bash
```

> [!WARNING]
> Run on Arch Linux as a regular user with sudo access, not as root.

To install from a local checkout, run from the project directory:

```bash
bash ./install.sh
```

The installer installs the official and AUR package lists, downloads wallpapers,
then links the supplied configurations into `~/.config` with GNU Stow and sets the Nord theme.
Unrelated configuration files are kept. Replaced files are backed up under
`~/.local/state/prometheus/config-backup.*`. Edits in the checkout immediately
appear through the links in `~/.config`; editing a linked file also updates the
checkout. Applications may need a reload to pick up changes.

To migrate existing copies or link newly added files without reinstalling packages:

```bash
bash install/config/config.sh
```

Stow keeps directories unfolded so generated theme files stay outside the checkout.

Keep the checkout in place: theme assets and helper commands use it. The installer
adds its environment to Bash startup files; log out and select Hyprland after
installation. Installation stops if a stage fails; fix the reported error and
rerun `bash ./install.sh`. The bootstrap reuses an existing checkout without
removing local changes; update it yourself before rerunning if needed.

## Features

- Hyprland window manager with custom settings
- Theme switching from predefined selections, with the ability to add custom ones
- Wallpapers, from the current theme or in general
- Quickshell based: all menus, bar, notification manager.

### Login and lock screens

Prometheus includes its own QML SDDM greeter, inspired by
[SilentSDDM](https://github.com/uiriansan/SilentSDDM)'s default presentation:
a large clock and date, a key/click transition into login, and translucent rounded
controls. It does not install or load SilentSDDM. Hyprlock uses matching typography,
colors, input dimensions, and the same wallpaper. It keeps a persistent native
password field; it does not run the greeter's QML or login transition.

The full installer sets up both screens. For an existing installation:

```bash
bash install/config/lockscreen.sh
bash install/config/config.sh
```

Setup requires sudo. It copies the current wallpaper to a system-readable location
for both screens; pass an image path to `lockscreen.sh` to choose another image.
Without a wallpaper both screens use the same dark solid background. Desktop theme
switches do not change this snapshot. Edit `default/lockscreen/style.json` and rerun
setup to update both styles together. No third-party theme or fonts are required.

An existing `/etc/sddm.conf` is backed up before its theme settings are updated.
Setup does not restart SDDM or log you out. Preview before your next login:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/prometheus
```

Use the power menu's Lock action to check hyprlock (this locks the session).

