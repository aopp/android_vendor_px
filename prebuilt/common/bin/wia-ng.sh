#!/system/bin/sh
# Set internal wlan to wlan0 and external wlan to wlan1
# Author: Zero_Chaos
#una salus victis nullam sperare salutem

#first, find the internal interface, if it's wlan0 we exit
if [ -r "/sys/class/net/wlan0/device/modalias" ]; then
  WLAN0_BUS=$(/system/xbin/busybox awk -F: '{print $1}' /sys/class/net/wlan0/device/modalias)
  if [ "${WLAN0_BUS}" = "usb" ]; then
    #All other legs exit, only this continues
    /system/xbin/busybox printf "Interface wlan0 is usb.\n"
  elif [ "${WLAN0_BUS}" = "sdio" ] || [ "${WLAN0_BUS}" = "platform" ]; then
    /system/xbin/busybox printf "Interface wlan0 is already the internal.\n"
    exit 0
  else
    /system/xbin/busybox printf "Interface wlan0 is unknown bus ${WLAN0_BUS}, quitting.\n"
    exit 1
else
  /system/xbin/busybox printf "Unable to read wlan0 bus, nothing we can do.\n"
  exit 1
fi

#if we got this far, we know that wlan0 is not the internal, so find the internal
INTERNAL=""
if [ -d /sys/class/net ]; then
  #check all network cards
  for iface in /sys/class/net/*; do
    if [ -r "/sys/class/net/${iface}/uevent" ]; then
      #check wlan cards
      if $(grep -q "DEVTYPE=wlan" "/sys/class/net/${iface}/uevent"); then
        if [ -r "/sys/class/net/${iface}/device/modalias" ]; then
          BUS=$(/system/xbin/busybox awk -F: '{print $1}' "/sys/class/net/${iface}/device/modalias")
          if [ "${BUS}" = "sdio" ] || [ "${BUS}" = "platform" ]; then
            INTERNAL="${iface}"
            break
          fi
        fi
      fi
    fi
  done
fi

#if we found internal switch it with wlan0, if not, just clear a path
if [ -n "${INTERNAL}" ]; then
  #switch wlan0 and internal
  /system/xbin/busybox printf "Switching wlan0 and ${INTERNAL}...\n"
  internal_wlan_mac=$(/system/xbin/busybox ifconfig -a | /system/xbin/busybox grep "^${INTERNAL}" | /system/xbin/busybox awk '{print $5}')
  external_wlan_mac=$(/system/xbin/busybox ifconfig -a | /system/xbin/busybox grep "^wlan0" | /system/xbin/busybox awk '{print $5}')

  if [ "$(/system/bin/getprop wlan.driver.status)" != "unloaded" ]; then
    # Disable Android wifi manager
    /system/bin/svc wifi disable
    sleep 2
    REENABLE_WIFI=1
  fi

  #down interfaces
  /system/xbin/busybox ifconfig wlan0 down
  /system/xbin/busybox ifconfig "${INTERNAL}" down

  # Set temporary interface name for internal wlan
  /system/xbin/busybox nameif temp_internal "${internal_wlan_mac}"
  # Set temporary interface name for external wlan
  /system/xbin/busybox nameif temp_external "${external_wlan_mac}"

  # Set internal wlan to wlan0
  /system/xbin/busybox nameif wlan0 "${internal_wlan_mac}"
  # Set external wlan to ${INTERNAL}
  /system/xbin/busybox nameif "${INTERNAL}" "${external_wlan_mac}"

  if [ "$REENABLE_WIFI" = "1" ]; then
    # Re-enable Android wifi manager
    /system/bin/svc wifi enable
  fi
  /system/xbin/busybox printf "Complete.\n"
else
  #just move wlan0 to the first available wlanX
  for i in $(/system/xbin/busybox seq 1 99); do
    if [ ! -e "/sys/class/net/wlan${i}" ]; then
      break
    fi
    if [ "${i}" = "99" ]; then
      /system/xbin/busybox printf "Unable to find a free name between wlan1 and wlan99, giving up.\n"
      exit 1
    fi
  done

  /system/xbin/busybox printf "Moving wlan0 to wlan${i}...\n"
  external_wlan_mac=$(/system/xbin/busybox ifconfig -a | /system/xbin/busybox grep "^wlan0" | /system/xbin/busybox awk '{print $5}')
  /system/xbin/busybox ifconfig wlan0 down
  # Set external wlan to wlan1
  /system/xbin/busybox nameif "wlan${i}" "${external_wlan_mac}"
fi
