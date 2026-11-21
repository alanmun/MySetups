#!/bin/bash
# The Xbox Wireless Adapter on front port usb1-2 can wedge chipset xHCI 0000:0b:00.0
# at boot. The MT7925 Bluetooth sits on the same controller and dies with it.
# Rebind the controller until Bluetooth is up and the front port isn't stuck.
CTRL=0000:0b:00.0
DRV=/sys/bus/pci/drivers/xhci_hcd
PORT=/sys/bus/usb/devices/1-0:1.0/usb1-port2/state

healthy() {
  # Bluetooth only. A stuck front port with BT still up is left alone:
  # a rebind doesn't unstick the dongle and it would drop BT devices.
  timeout 5 bluetoothctl list 2>/dev/null | grep -q '^Controller' 
}

# BT setup alone takes ~15s after a rebind, so poll up to 45s before giving up.
wait_healthy() {
  for _ in $(seq 1 15); do healthy && return 0; sleep 3; done
  return 1
}

if healthy; then echo "healthy, nothing to do"; exit 0; fi
for attempt in 1 2 3; do
  echo "unhealthy (bt: $(timeout 5 bluetoothctl list 2>/dev/null | wc -l) controllers, port2: $(cat "$PORT" 2>/dev/null)); rebind #$attempt of $CTRL"
  echo "$CTRL" > "$DRV/unbind"
  sleep 3
  echo "$CTRL" > "$DRV/bind"
  if wait_healthy; then echo "healthy after rebind #$attempt"; exit 0; fi
done
echo "still unhealthy after 3 rebinds"
exit 1
