#!/bin/bash

set -euo pipefail

install_limine_packages() {
  if ! command -v yay >/dev/null 2>&1; then
    echo "Error: yay is required to install AUR packages limine-snapper-sync and limine-mkinitcpio-hook" >&2
    exit 1
  fi

  yay -S --noconfirm --needed limine-snapper-sync limine-mkinitcpio-hook
}

configure_snapper_config() {
  local config_path="$1"

  [[ -f "$config_path" ]] || return 0

  sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' "$config_path"
  sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' "$config_path"
  sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' "$config_path"
  sudo sed -i 's/^SPACE_LIMIT="0.5"/SPACE_LIMIT="0.3"/' "$config_path"
  sudo sed -i 's/^FREE_LIMIT="0.2"/FREE_LIMIT="0.3"/' "$config_path"
}

if ! command -v limine >/dev/null 2>&1; then
  echo "Limine is not installed; skipping Limine Snapper setup."
  exit 0
fi

if [[ -z "${PROMETHEUS_PATH:-}" ]]; then
  echo "Error: PROMETHEUS_PATH is not set" >&2
  exit 1
fi

if [[ ! -f "$PROMETHEUS_PATH/default/limine/default.conf" ]] || [[ ! -f "$PROMETHEUS_PATH/default/limine/limine.conf" ]]; then
  echo "Error: Prometheus Limine defaults are missing under $PROMETHEUS_PATH/default/limine" >&2
  exit 1
fi

install_limine_packages

sudo tee /etc/mkinitcpio.conf.d/prometheus_hooks.conf >/dev/null <<'EOF'
HOOKS=(base udev plymouth keyboard autodetect microcode modconf kms keymap consolefont block encrypt filesystems fsck btrfs-overlayfs)
EOF

sudo tee /etc/mkinitcpio.conf.d/thunderbolt_module.conf >/dev/null <<'EOF'
MODULES+=(thunderbolt)
EOF

EFI=""
[[ -d /sys/firmware/efi ]] && EFI=true

limine_config=""
if [[ -f /boot/EFI/arch-limine/limine.conf ]]; then
  limine_config="/boot/EFI/arch-limine/limine.conf"
elif [[ -f /boot/EFI/BOOT/limine.conf ]]; then
  limine_config="/boot/EFI/BOOT/limine.conf"
elif [[ -f /boot/EFI/limine/limine.conf ]]; then
  limine_config="/boot/EFI/limine/limine.conf"
elif [[ -f /boot/limine/limine.conf ]]; then
  limine_config="/boot/limine/limine.conf"
elif [[ -f /boot/limine.conf ]]; then
  limine_config="/boot/limine.conf"
else
  echo "Error: Limine config not found" >&2
  exit 1
fi

cmdline="$(sed -n 's/^[[:space:]]*cmdline:[[:space:]]*//p' "$limine_config" | head -n 1)"

sudo cp "$PROMETHEUS_PATH/default/limine/default.conf" /etc/default/limine
sudo sed -i "s|@@CMDLINE@@|$cmdline|g" /etc/default/limine

for dropin in /etc/limine-entry-tool.d/*.conf; do
  [[ -f "$dropin" ]] && sudo tee -a /etc/default/limine < "$dropin" >/dev/null
done

if [[ -z "$EFI" ]]; then
  sudo sed -i '/^ENABLE_UKI=/d; /^ENABLE_LIMINE_FALLBACK=/d' /etc/default/limine
fi

if [[ "$limine_config" != "/boot/limine.conf" ]] && [[ -f "$limine_config" ]]; then
  sudo rm "$limine_config"
fi

sudo cp "$PROMETHEUS_PATH/default/limine/limine.conf" /boot/limine.conf

if [[ -z "${PROMETHEUS_CHROOT_INSTALL:-}" ]] && command -v snapper >/dev/null 2>&1; then
  if ! sudo snapper list-configs 2>/dev/null | grep -q '^root[[:space:]]'; then
    sudo snapper -c root create-config /
  fi

  if [[ -d /home ]] && ! sudo snapper list-configs 2>/dev/null | grep -q '^home[[:space:]]'; then
    sudo snapper -c home create-config /home
  fi
fi

if command -v btrfs >/dev/null 2>&1; then
  sudo btrfs quota enable / || true
fi

configure_snapper_config /etc/snapper/configs/root
configure_snapper_config /etc/snapper/configs/home

if systemctl list-unit-files limine-snapper-sync.service >/dev/null 2>&1; then
  sudo systemctl enable --now limine-snapper-sync.service
fi

echo "Re-enabling mkinitcpio hooks..."

if [[ -f /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled ]]; then
  sudo mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled /usr/share/libalpm/hooks/90-mkinitcpio-install.hook
fi

if [[ -f /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled ]]; then
  sudo mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook
fi

echo "mkinitcpio hooks re-enabled"

sudo limine-update

if ! grep -q '^/+' /boot/limine.conf; then
  echo "Error: limine-update failed to add boot entries to /boot/limine.conf" >&2
  exit 1
fi

if [[ -n "$EFI" ]] && command -v efibootmgr >/dev/null 2>&1; then
  while IFS= read -r bootnum; do
    sudo efibootmgr -b "$bootnum" -B >/dev/null 2>&1
  done < <(efibootmgr | grep -E '^Boot[0-9]{4}\*? Arch Linux Limine' | sed 's/^Boot\([0-9]\{4\}\).*/\1/')
fi
