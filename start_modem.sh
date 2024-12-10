#!/bin/bash

device=$(ls /dev/cdc-wdm* 2>/dev/null | head -n 1)
if [ -z "$device" ]; then
    echo "No device found"
    exit 1
fi

wwan_interface=$(sudo qmicli -d "$device" --get-wwan-iface 2>/dev/null)
if [ -z "$wwan_interface" ]; then
    echo "Failed to get WWAN interface"
    exit 1
fi

echo "Device: $device, WWAN interface: $wwan_interface"

# New addition
# Set system selection preference to 5GNR right after detecting the module
sudo qmicli -d "$device" --nas-set-system-selection-preference=5gnr

check_connection() {
    sudo qmicli -p -d "$device" --wds-get-packet-service-status | grep -q "Connection status: 'connected'"
}

setup_connection() {
    sudo qmicli -d "$device" --dms-set-operating-mode='low-power'
    sleep 1
    sudo qmicli -d "$device" --dms-set-operating-mode='online'
    sleep 1
    sudo ip link set "$wwan_interface" down
    echo 'Y' | sudo tee /sys/class/net/"$wwan_interface"/qmi/raw_ip > /dev/null
    sudo ip link set "$wwan_interface" up
    sudo qmicli -p -d "$device" --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='internet',ip-type=4" --client-no-release-cid
}

while true; do
    setup_connection
    
    if check_connection; then
        echo "Device is connected."
        sudo qmicli -p -d "$device" --wds-get-current-settings
        sudo udhcpc -q -f -i "$wwan_interface"
        break
    else
        echo "Device not connected. Resetting..."
        sudo qmicli -d "$device" --dms-set-operating-mode=reset
        echo "Wait 22 seconds to let the module restart"
        sleep 22
    fi
done