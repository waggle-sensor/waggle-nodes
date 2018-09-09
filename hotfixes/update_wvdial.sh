#!/bin/bash

detect_system_info() {
  #
  # Detect Odroid model
  #
  . /usr/lib/waggle/core/scripts/detect_odroid_model.sh
  # returns ODROID_MODEL
  # detect MAC address
  #
  . /usr/lib/waggle/core/scripts/detect_mac_address.sh
  # returns MAC_ADDRESS and MAC_STRING

  #
  # detect disk device and type
  . /usr/lib/waggle/core/scripts/detect_disk_devices.sh
  # returns CURRENT_DISK_DEVICE, CURRENT_DISK_DEVICE_NAME, CURRENT_DISK_DEVICE_TYPE,
  #         OTHER_DISK_DEVICE, OTHER_DISK_DEVICE_NAME, OTHER_DISK_DEVICE_TYPE

}

unmount_otherdisk() {

 #
  # umount the other disk partitions by their /dev block devices just in case
  #
  for device in $(mount | grep "^${CURRENT_DISK_DEVICE}/p1" | cut -f1 -d ' ') ; do
    echo "Warning, device ${device} is currently mounted"
    umount ${device}
    sleep 5
  done

  for device in $(mount | grep "^${OTHER_DISK_DEVICE}" | cut -f1 -d ' ') ; do
    echo "Warning, device ${device} is currently mounted"
    umount ${device}
    sleep 5
  done

  for device in $(mount | grep "^${OTHER_DISK_DEVICE}" | cut -f1 -d ' ') ; do
    echo "Error, device ${device} is still mounted"
    rm -f ${pidfile}
    exit 1
  done

}

prepare_mountpoints() {
  #
  # make sure /tmp/boot and /tmp/other* are available
  #
  echo 'making sure the /tmp/other* mount points are available to use...'
  local boot_partition=/tmp/boot
  mkdir -p ${boot_partition}
  while [ $(mount | grep "${boot_partition}" | wc -l) -ne 0 ] ; do
    umount ${boot_partition}
    sleep 5
  done

  mkdir -p ${OTHER_DISK_P1}
  while [ $(mount | grep "${OTHER_DISK_P1}" | wc -l) -ne 0 ] ; do
    umount ${OTHER_DISK_P1}
    sleep 5
  done

  mkdir -p ${OTHER_DISK_P2}
  while [ $(mount | grep "${OTHER_DISK_P2}" | wc -l) -ne 0 ] ; do
    umount ${OTHER_DISK_P2}
    sleep 5
  done

  mkdir -p ${OTHER_DISK_P3}
  while [ $(mount | grep "${OTHER_DISK_P3}" | wc -l) -ne 0 ] ; do
    umount ${OTHER_DISK_P3}
    sleep 5
  done

}

#====================
#===     MAIN     ===
#====================

declare -r OTHER_DISK_P1=/tmp/otherp1
declare -r OTHER_DISK_P2=/tmp/otherp2
declare -r OTHER_DISK_P3=/tmp/otherp3

wget --quiet "https://raw.githubusercontent.com/waggle-sensor/nodecontroller/master/scripts/wvwaggle.sh" -O /tmp/wvwaggle.sh
echo "35846769b735cb18aa9f6ebd811f6b4c8c1dc9586dfcbe12aeca18708fbec316  /tmp/wvwaggle.sh" | sha256sum -c
if [ $? == 0 ]; then
    echo "Checked SHA256SUM of downloaded file, checks out fine..."
    waggle-switch-to-safe-mode
    cp /tmp/wvwaggle.sh /usr/bin/wvwaggle.sh
    waggle-switch-to-operation-mode
    echo "35846769b735cb18aa9f6ebd811f6b4c8c1dc9586dfcbe12aeca18708fbec316  /usr/bin/wvwaggle.sh" | sha256sum -c
    if [ $? == 0 ]; then
        echo ""
        echo "Successfully updated primary disk."
        echo ""
    fi
fi

echo "Updating the other media..."

detect_system_info
prepare_mountpoints
echo "mounting ${OTHER_DISK_DEVICE_TYPE} data partition..."
mount ${OTHER_DISK_DEVICE}p2 ${OTHER_DISK_P2}/
echo "35846769b735cb18aa9f6ebd811f6b4c8c1dc9586dfcbe12aeca18708fbec316  /tmp/wvwaggle.sh" | sha256sum -c
if [ $? == 0 ]; then
    echo "Checked SHA256SUM of downloaded file, checks out fine..."
    cp /tmp/wvwaggle.sh ${OTHER_DISK_P2}/usr/bin/wvwaggle.sh
    echo "35846769b735cb18aa9f6ebd811f6b4c8c1dc9586dfcbe12aeca18708fbec316  ${OTHER_DISK_P2}/usr/bin/wvwaggle.sh" | sha256sum -c
    if [ $? == 0 ]; then
        echo ""
        echo "Successfully updated secondary disk."
        echo ""
    fi
fi
umount ${OTHER_DISK_P2}/
echo "Done!"
