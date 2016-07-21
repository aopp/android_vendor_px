#!/system/bin/sh
# Set internal wlan to wlan0 and external wlan to wlan1
# Author: Zero_Chaos
#una salus victis nullam sperare salutem

WLAN_SWITCHAROO=0
REENABLE_WIFI=0

#Check if wlan0 is usb
if [ -f /sys/class/net/wlan0/device/modalias ];then
  WLAN0_BUS=$(/system/xbin/busybox awk -F: '{print $1}' /sys/class/net/wlan0/device/modalias)
  if [ "$WLAN0_BUS" = "usb" ]; then
    /system/xbin/busybox printf "Interface wlan0 is usb.\n"
    WLAN0_SWITCHAROO=1
    if [ -f /sys/class/net/wlan1/device/modalias ];then
      #check if wlan1 is usb
      WLAN1_BUS=$(/system/xbin/busybox awk -F: '{print $1}' /sys/class/net/wlan1/device/modalias)
      if [ "$WLAN1_BUS" = "sdio" ]; then
        /system/xbin/busybox printf "Interface wlan1 is sdio.\n"
        WLAN_SWITCHAROO=1
      elif [ "$WLAN1_BUS" = "usb" ]; then
        /system/xbin/busybox printf "Interface wlan1 is also usb, dazed and confused, failure.\n"
        exit 1
      elif [ "$WLAN1_BUS" = "platform" ]; then
        if [ "$(cat /sys/class/net/wlan1/device/modalias)" = "platform:wcnss_wlan" ]; then
          /system/xbin/busybox printf "Interface wlan1 is deb/flo internal.\n"
          WLAN_SWITCHAROO=1
        else
          /system/xbin/busybox printf "Interface wlan1 bus returns platform but deb/flo check fails, who are you?\n"
          exit 1
        fi
      else
        /system/xbin/busybox printf "Interface wlan1 exists but isn't usb or sdio, failure.\n"
        exit 1
      fi
    else
      if [ "$WLAN0_SWITCHAROO" = "1" ]; then
        /system/xbin/busybox printf "Interface wlan1 does not seem to exist, moving wlan0 to wlan1.\n"
      else
        /system/xbin/busybox printf "Interface wlan1 does not seem to exist, nothing to do.\n"
        exit 0
      fi
    fi
  elif [ "$WLAN0_BUS" = "sdio" ]; then
    /system/xbin/busybox printf "Interface wlan0 is already the internal sdio wifi nic.\n"
    exit 0
  else
    /system/xbin/busybox printf "Interface wlan0 exists but isn't usb or sdio, failure.\n"
    exit 1
  fi
else
  /system/xbin/busybox printf "Unable to use modalias to determine which device wlan0 is.\n"
  exit 1
fi

if [ "$WLAN_SWITCHAROO" = "1" ]; then
  /system/xbin/busybox printf "Switching wlan0 and wlan1...\n"
  onboard_wlan_mac=$(/system/xbin/busybox ifconfig -a | /system/xbin/busybox grep "^wlan1" | /system/xbin/busybox awk '{print $5}')
  external_wlan_mac=$(/system/xbin/busybox ifconfig -a | /system/xbin/busybox grep "^wlan0" | /system/xbin/busybox awk '{print $5}')

  if [ "$(/system/bin/getprop wlan.driver.status)" != "unloaded" ]; then
    # Disable Android wifi manager
    /system/bin/svc wifi disable
    sleep 2
    REENABLE_WIFI=1
  fi

  #down interfaces
  /system/xbin/busybox ifconfig wlan0 down
  /system/xbin/busybox ifconfig wlan1 down

  # Set temporary interface name for internal wlan
  /system/xbin/busybox nameif temp_onboard "${onboard_wlan_mac}"

  # Set temporary interface name for external wlan
  /system/xbin/busybox nameif temp_external "${external_wlan_mac}"

  # Set internal wlan to wlan0
  /system/xbin/busybox nameif wlan0 "${onboard_wlan_mac}"

  # Set external wlan to wlan1
  /system/xbin/busybox nameif wlan1 "${external_wlan_mac}"

  if [ "$REENABLE_WIFI" = "1" ]; then
    # Re-enable Android wifi manager
    /system/bin/svc wifi enable
  fi
  /system/xbin/busybox printf "Complete.\n"
elif [ "${WLAN0_SWITCHAROO}" = "1" ]; then
  #quick hack for deb/flo that pulls the wifi completely off the bus when off
  /system/xbin/busybox printf "Moving wlan0 to wlan1...\n"
  external_wlan_mac=$(/system/xbin/busybox ifconfig -a | /system/xbin/busybox grep "^wlan0" | /system/xbin/busybox awk '{print $5}')
  /system/xbin/busybox ifconfig wlan0 down
  # Set external wlan to wlan1
  /system/xbin/busybox nameif wlan1 "${external_wlan_mac}"
fi
