#!/bin/bash

devices=$(ls /dev/cdc-wdm* 2>/dev/null)

if [ -z "$devices" ]; then
    echo "No device found"
    exit 1
fi

device=$(echo "$devices" | head -n 1)
wwan_interface=$(sudo qmicli -d "$device" --get-wwan-iface)

if [ -z "$wwan_interface" ]; then
    echo "Failed to get WWAN interface"
    exit 1
fi

echo "Device : $device and WWAN interface: $wwan_interface"

check_connection_status() {
    status=$(sudo qmicli -p -d "$device" --wds-get-packet-service-status)
    if [[ $status == *"Connection status: 'connected'"* ]]; then
        return 0
    else
        return 1
    fi
}

setup_connection() {
    sudo qmicli -d "$device" --dms-set-operating-mode='low-power'
    sleep 1
    sudo qmicli -d "$device" --dms-set-operating-mode='online'
    sleep 1
    sudo ip link set "$wwan_interface" down
    sleep 1
    echo 'Y' | sudo tee /sys/class/net/"$wwan_interface"/qmi/raw_ip
    sleep 2
    sudo ip link set "$wwan_interface" up
    sleep 1
    sudo qmicli -p -d "$device" --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='internet',ip-type=4" --client-no-release-cid
    sleep 2
}

while true; do
    setup_connection
    
    if check_connection_status; then
        echo "Device is connected. Continuing with current settings."
        sudo qmicli -p -d "$device" --wds-get-current-settings
        sudo udhcpc -q -f -i "$wwan_interface"
        break
    else
        echo "Device is not connected. Resetting and attempting to connect again."
        sudo qmicli -d "$device" --dms-set-operating-mode=reset
        echo "Wait 22 seconds to let the module restart."
        sleep 22
    fi
done
