# Common config for all supported devices

# Required AOPP packages
PRODUCT_PACKAGES += \
    PxInstaller \
    TerminalEmulator

# Required PX legacy packages
PRODUCT_PACKAGES += \
    Airodump \
    BlueHydra \
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

# Required Pwnix env scripts
PRODUCT_COPY_FILES += \
    vendor/pwnieexpress/prebuilt/common/bin/bootpwn:system/bin/bootpwn \
    vendor/pwnieexpress/prebuilt/common/bin/chrootboot:system/bin/chrootboot \
    vendor/pwnieexpress/prebuilt/common/bin/chrootinit:system/bin/chrootinit \
    vendor/pwnieexpress/prebuilt/common/bin/envsetup:system/bin/envsetup \
    vendor/pwnieexpress/prebuilt/common/bin/wia-ng.sh:system/bin/wia-ng.sh
