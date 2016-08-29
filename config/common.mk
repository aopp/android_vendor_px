# Common config for all supported devices

# Required AOPP packages
PRODUCT_PACKAGES += \
    PxInstaller \
    TerminalEmulator

# Required PX legacy packages
PRODUCT_PACKAGES += \
    Airodump \
    Bluelog \
    BluetoothScan \
    CapturesDump \
    DnsSpoof \
    Dsniff \
    Ettercap \
    EvilAp \
    HostMacChanger \
    Kismet \
    LogWiper \
    Metasploit \
    Nmap \
    PwnieUIOnOff \
    RootShell \
    Set \
    SshOnOff \
    SslStrip \
    StringsWatch \
    TcpDump \
    TShark \
    Ubertooth \
    Wifite

# Optional AOPP packages
ifeq (,$(findstring $(TARGET_PRODUCT),aopp_deb aopp_hammerhead))
    PRODUCT_PACKAGES += BlueHydra
endif

# Enable root usb debugging on experimental builds
ifeq ($(RELEASE_TYPE),EXPERIMENTAL)
    PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
        persist.sys.usb.config=mtp,adb \
        ro.adb.secure=0 \
        ro.secure=0 \
        ro.debuggable=1
endif

# Required Pwnix env scripts
PRODUCT_COPY_FILES += \
    vendor/pwnieexpress/prebuilt/common/bin/bootpwn:system/bin/bootpwn \
    vendor/pwnieexpress/prebuilt/common/bin/chrootboot:system/bin/chrootboot \
    vendor/pwnieexpress/prebuilt/common/bin/chrootinit:system/bin/chrootinit \
    vendor/pwnieexpress/prebuilt/common/bin/envsetup:system/bin/envsetup \
    vendor/pwnieexpress/prebuilt/common/bin/wia-ng.sh:system/bin/wia-ng.sh

# Backup tool
ifneq ($(WITH_GMS),true)
PRODUCT_COPY_FILES += \
    vendor/pwnieexpress/prebuilt/common/bin/99-supersu.sh:system/addon.d/99-supersu.sh
endif
