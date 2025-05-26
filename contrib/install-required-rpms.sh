#!/bin/bash

# ❗ rootで実行されているか確認
if [[ $EUID -ne 0 ]]; then
  echo "❌ このスクリプトは root 権限で実行してください。"
  exit 1
fi

# 🔧 インストールしたいパッケージリスト
PACKAGES=(
  ansible-collection-ansible-posix
  ansible-playbook
  atop
  avahi
  avahi-tools
  bsdtar
  ccze
  curl
  dnsmasq
  duff
  fdupes
  gdb
  git
  glow
  golang
  hexedit
  htop
  https://raw.githubusercontent.com/rpmsphere/noarch/master/i/icdiff-2.0.7-1.noarch.rpm
  intel-undervolt
  inxi
  jq
  kernel-tools
  light
  lv
  mkpasswd
  msr-tools
  nmap
  nmon
  nmstate
  nss-mdns
  pcre-tools
  ripgrep
  screen
  smartmontools
  socat
  strace
  stress-ng
  s-tui
  syslinux
  tmux
  w3m
  wget2
  yamllint
  yq
)

echo "📦 Installing packages: ${PACKAGES[*]}"
dnf install -y "${PACKAGES[@]}"
echo ""

echo "📦 Stop firewalld"
systemctl disable firewalld --now

echo "📦 Extend LVM"
lvextend -l +100%FREE /dev/fedora/root
xfs_growfs /
df -h

