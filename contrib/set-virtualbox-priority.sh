VM_PID=$(pgrep -f 'VBoxHeadless.*sno')

# 1. リアルタイムスケジューリング
chrt -f -p 99 "$VM_PID"
chrt -p "$VM_PID"

# 2. I/O優先度
ionice -c1 -n0 -p "$VM_PID"

