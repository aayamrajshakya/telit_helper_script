#!/bin/bash

device=$(ls /dev/cdc-wdm* 2>/dev/null | head -n 1)

[ -z "$device" ] && { echo "No device found"; exit 1; }

# Set the device to low-power mode
sudo qmicli -d "$device" --dms-set-operating-mode="low-power"

sleep 2

# Stop the network connection
sudo qmi-network "$device" stop