#!/bin/bash

# CPU governorをperformanceに
for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
  echo performance | sudo tee $CPU/cpufreq/scaling_governor
done

# 最小周波数を最大に固定
MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
  echo $MAX_FREQ | sudo tee $CPU/cpufreq/scaling_min_freq
done

# Turbo Boost 有効化（intel_pstate）
echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# irqbalance 無効化（要再起動または手動で停止）
sudo systemctl disable --now irqbalance

