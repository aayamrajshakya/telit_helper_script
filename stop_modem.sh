#!/bin/bash

device=$(ls /dev/cdc-wdm* 2>/dev/null | head -n 1)

[ -z "$device" ] && { echo "No device found"; exit 1; }

# Set the device to low-power mode and stop the network connection
if sudo qmicli -d "$device" --dms-set-operating-mode="low-power" && sudo qmi-network "$device" stop; then
    echo "Device $device is now in low-power mode and the network is stopped."
else
    echo "Error: Failed to set low-power mode or stop the network."
    exit 1
fi