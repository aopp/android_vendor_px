#!/system/bin/sh
# Set internal wlan to wlan0 and external wlan to wlan1
# Author: Zero_Chaos
# una salus victis nullam sperare salutem

# First find the internal interface; if it's wlan0, exit
if [ -r "/sys/class/net/wlan0/device/modalias" ]; then
  WLAN0_BUS=$(/system/bin/toybox cut -d: -f1 /sys/class/net/wlan0/device/modalias)
  if [ "${WLAN0_BUS}" = "usb" ]; then
    # All other conditions exit, only this continues
    /system/bin/toybox printf "Interface wlan0 is usb.\n"
  elif [ "${WLAN0_BUS}" = "sdio" ] || [ "${WLAN0_BUS}" = "platform" ]; then
    /system/bin/toybox printf "Interface wlan0 is already the internal.\n"
    exit 0
  else
    /system/bin/toybox printf "Interface wlan0 is unknown bus ${WLAN0_BUS}, quitting.\n"
    exit 1
  fi
else
  /system/bin/toybox printf "Unable to read wlan0 bus, nothing we can do.\n"
  exit 1
fi

# If we got this far, we know wlan0 is not the internal, so find the internal
INTERNAL=""
if [ -d /sys/class/net ]; then
  # Check all network cards
  for i in /sys/class/net/*; do
    if [ -r "${i}/uevent" ]; then
      # Check wlan cards
      if /system/bin/toybox grep -q "DEVTYPE=wlan" "${i}/uevent"; then
        # TODO: better check here, is there a way to check for wifi direct mode?
        if [ "${i}" = "/sys/class/net/p2p0" ]; then
          continue
        fi
        if [ -r "${i}/device/modalias" ]; then
          BUS=$(/system/bin/toybox cut -d: -f1 "${i}/device/modalias")
          if [ "${BUS}" = "sdio" ] || [ "${BUS}" = "platform" ]; then
            INTERNAL="${i#/sys/class/net/}"
            break
          else
            continue
          fi
        fi
      fi
    fi
  done
fi

# If we found the internal, switch it with wlan0. If not, clear a path
if [ -n "${INTERNAL}" ]; then
  # Switch wlan0 and the internal
  /system/bin/toybox printf "Switching wlan0 and ${INTERNAL}...\n"
  internal_wlan_mac=$(/system/bin/toybox ifconfig -a | /system/bin/toybox grep "^${INTERNAL}" | /system/bin/toybox tr -s [:blank:] | /system/bin/toybox cut -d' ' -f5)
  external_wlan_mac=$(/system/bin/toybox ifconfig -a | /system/bin/toybox grep "^wlan0" | /system/bin/toybox tr -s [:blank:] | /system/bin/toybox cut -d' ' -f5)

  if [ "$(/system/bin/getprop wlan.driver.status)" != "unloaded" ]; then
    # Disable Android wifi manager
    /system/bin/svc wifi disable
    /system/bin/toybox sleep 2
    REENABLE_WIFI=1
  fi

  # Down interfaces
  /system/bin/toybox ip link set dev wlan0 down
  /system/bin/toybox ip link set dev "${INTERNAL}" down

  # Set temporary interface name for internal wlan
  /system/bin/toybox ip link set dev temp_internal address "${internal_wlan_mac}"
  # Set temporary interface name for external wlan
  /system/bin/toybox ip link set dev temp_external address "${external_wlan_mac}"

  # Set internal wlan to wlan0
  /system/bin/toybox ip link set dev wlan0 address "${internal_wlan_mac}"
  # Set external wlan to ${INTERNAL}
  /system/bin/toybox ip link set dev "${INTERNAL}" address "${external_wlan_mac}"

  if [ "$REENABLE_WIFI" = "1" ]; then
    # Re-enable Android wifi manager
    /system/bin/svc wifi enable
  fi
  /system/bin/toybox printf "Complete.\n"
else
  # Just move wlan0 to the first available wlanX
  for i in $(/system/bin/toybox seq 1 99); do
    if [ ! -e "/sys/class/net/wlan${i}" ]; then
      break
    fi
    if [ "${i}" = "99" ]; then
      /system/bin/toybox printf "Unable to find a free name between wlan1 and wlan99, giving up.\n"
      exit 1
    fi
  done

  /system/bin/toybox printf "Moving wlan0 to wlan${i}...\n"
  external_wlan_mac=$(/system/bin/toybox ifconfig -a | /system/bin/toybox grep "^wlan0" | /system/bin/toybox tr -s [:blank:] | /system/bin/toybox cut -d' ' -f5)
  /system/bin/toybox ifconfig wlan0 down
  # Set external wlan to wlan1
  /system/bin/toybox ip link set dev "wlan${i}" address "${external_wlan_mac}"
fi
