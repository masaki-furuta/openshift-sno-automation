#!/bin/bash

# ❗ rootで実行されているか確認
if [[ $EUID -ne 0 ]]; then
  echo "❌ このスクリプトは root 権限で実行してください。"
  exit 1
fi

# 🔧 インストールしたいパッケージリスト
PACKAGES=(
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
  icdiff
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

