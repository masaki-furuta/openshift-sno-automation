cat <<EOF | sudo tee /etc/modprobe.d/iwlwifi_power.conf
options iwlmvm power_scheme=1
options iwlwifi power_save=0
EOF

