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
then copies the supplied configurations into `~/.config` and sets the Nord theme.
Unrelated configuration files are kept. Replaced files are backed up under
`~/.local/state/prometheus/config-backup.*`. Configurations are copies: edits
in `~/.config` do not update this Git checkout.

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

