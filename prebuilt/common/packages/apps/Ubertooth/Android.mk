LOCAL_PATH:= $(call my-dir)
include $(CLEAR_VARS)

$(info $(shell ($(LOCAL_PATH)/gradlew build -p $(LOCAL_PATH))))
$(info $(shell ($(LOCAL_PATH)/prepare.sh)))

LOCAL_MODULE := Ubertooth
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := APPS
LOCAL_SRC_FILES := $(LOCAL_MODULE).apk
LOCAL_CERTIFICATE := platform
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)

include $(BUILD_PREBUILT)
