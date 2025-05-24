#!/bin/bash

# Set CPU governor to performance
for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
  echo performance | sudo tee $CPU/cpufreq/scaling_governor
done

# Fix the minimum frequency to the maximum frequency
MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
  echo $MAX_FREQ | sudo tee $CPU/cpufreq/scaling_min_freq
done

# Enable Turbo Boost (for intel_pstate driver)
echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Disable irqbalance (requires reboot or manual stop)
sudo systemctl disable --now irqbalance

