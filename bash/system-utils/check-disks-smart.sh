#!/bin/bash

# Check privileges
if sudo true
then
   true
else
   echo 'Root privileges required'

   exit 1
fi

# Check if smartctl is installed
if ! command -v smartctl &> /dev/null
then
    echo "smartctl is not installed. Please install it using: sudo apt install smartctl"
    exit 1
fi

# Check if nvme-cli is installed
if ! command -v nvme &> /dev/null
then
    echo "nvme-cli is not installed. Please install it using: sudo apt install nvme-cli"
    exit 1
fi

# Check the health status of the hard drives
echo "Checking health for hard drives..."
for drive in /dev/sd[a-z] /dev/sd[a-z][a-z]
do
   if [[ ! -e $drive ]]; then continue ; fi

   echo -n "$drive "

   smart=$(
      sudo smartctl -H $drive 2>/dev/null |
      grep '^SMART overall' |
      awk '{ print $6 }'
   )

   [[ "$smart" == "" ]] && smart='unavailable'

   echo "$smart"

done

# Insert a new line
printf '\n'

# Get a list of all NVMe devices
nvme_devices=$(ls /dev/nvme*n1)

if [ -z "$nvme_devices" ]; then
    echo "No NVMe devices found."
    exit 1
fi

# Check health for each NVMe device
for device in $nvme_devices; do
    echo "Checking health for $device..."
    sudo nvme smart-log "$device"
    echo
done
