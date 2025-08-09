Collecting logs about failed boots

Errors and warnings (prev boot): sudo journalctl --boot -1 -p 0..4 --no-pager -o short-iso -n 400

Display manager (SDDM) logs: sudo journalctl --boot -1 -u display-manager --no-pager -o short-iso

SDDM greeter logs: sudo journalctl --boot -1 -t sddm-greeter-qt6 --no-pager -o short-precise

SDDM Wayland launcher logs: sudo journalctl --boot -1 -t sddm-helper-start-wayland --no-pager -o short-precise

Kernel DRM/AMDGPU messages: sudo journalctl --boot -1 -k --no-pager | grep -i -E 'amdgpu|drm|gpu|timeout|reset|hang|xid'

Any coredumps for greeter/kwin: coredumpctl --boot -1 list | grep -Ei 'sddm|greeter|kwin' coredumpctl --boot -1 info sddm-greeter-qt6 # if listed
