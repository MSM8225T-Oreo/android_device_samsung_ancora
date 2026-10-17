# Copyright (C) 2012 The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

# This device is hdpi
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := hdpi

# Boot animation
TARGET_BOOTANIMATION_HALF_RES := true
TARGET_SCREEN_HEIGHT := 800
TARGET_SCREEN_WIDTH := 480

# Bootsplash image
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/ARIESVE.rle:root/ARIESVE.rle

# Support files
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/handheld_core_hardware.xml:system/etc/permissions/handheld_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml

# Media configuration
PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:system/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_telephony.xml:system/etc/media_codecs_google_telephony.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video_le.xml:system/etc/media_codecs_google_video_le.xml \
    $(LOCAL_PATH)/media/media_codecs.xml:system/etc/media_codecs.xml \
    $(LOCAL_PATH)/media/media_codecs_performance.xml:system/etc/media_codecs_performance.xml \
    $(LOCAL_PATH)/media/media_profiles.xml:system/etc/media_profiles.xml

# Audio configuration (Oreo XML policy, replaces audio_policy.conf)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio_policy_configuration.xml:system/etc/audio_policy_configuration.xml \
    external/wpa_supplicant_8/wpa_supplicant/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf

# Ramdisk
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/init.qcom.rc:root/init.qcom.rc \
    $(LOCAL_PATH)/rootdir/init.qcom.usb.rc:root/init.qcom.usb.rc \
    $(LOCAL_PATH)/rootdir/ueventd.qcom.rc:root/ueventd.qcom.rc \
    $(LOCAL_PATH)/rootdir/fstab.qcom:root/fstab.qcom \
    $(LOCAL_PATH)/recovery/twrp.fstab:recovery/root/etc/twrp.fstab

# Wifi calibration
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/nvram_net.txt:system/vendor/firmware/nvram_net.txt

# MAC adress tool
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/system/bin/get_macaddrs:system/bin/get_macaddrs

# Input device calibration files
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/sec_touchscreen.idc:system/usr/idc/sec_touchscreen.idc

# Keylayouts
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keylayout/sec_jack.kl:system/usr/keylayout/sec_jack.kl \
    $(LOCAL_PATH)/keylayout/sec_key.kl:system/usr/keylayout/sec_key.kl \
    $(LOCAL_PATH)/keylayout/sec_power_key.kl:system/usr/keylayout/sec_power_key.kl \
    $(LOCAL_PATH)/keylayout/sec_touchscreen.kl:system/usr/keylayout/sec_touchscreen.kl

# GPS config
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/gps/etc/gps.conf:system/etc/gps.conf

# Oreo HIDL HAL stack:
# wrappers for the legacy msm7x30 hw modules (gralloc/hwc/audio/omx/gps/...)
PRODUCT_PACKAGES += \
    android.hardware.audio@2.0-impl \
    android.hardware.audio@2.0-service \
    android.hardware.audio.effect@2.0-impl \
    android.hardware.camera.provider@2.4-impl \
    android.hardware.camera.provider@2.4-service \
    camera.device@1.0-impl \
    android.hardware.gnss@1.0-impl \
    android.hardware.gnss@1.0-service \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.composer@2.1-impl \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.graphics.mapper@2.0-impl \
    android.hardware.light@2.0-impl \
    android.hardware.light@2.0-service \
    android.hardware.media.omx@1.0-service \
    android.hardware.memtrack@1.0-impl \
    android.hardware.memtrack@1.0-service \
    android.hardware.power@1.0-impl \
    android.hardware.power@1.0-service \
    android.hardware.sensors@1.0-impl \
    android.hardware.sensors@1.0-service \
    android.hardware.usb@1.0-service \
    android.hardware.vibrator@1.0-impl \
    android.hardware.wifi@1.0-service

# Legacy device HAL modules (rebuilt from cm-13.0 trees, loaded by the
# HIDL wrappers above through hw_get_module)
PRODUCT_PACKAGES += \
    camera.msm7x30 \
    copybit.msm7x30 \
    gralloc.msm7x30 \
    hwcomposer.msm7x30 \
    memtrack.msm7x30 \
    gps.msm7x30 \
    lights.msm7x30 \
    power.msm7x30 \
    audio.primary.msm7x30 \
    audio.a2dp.default \
    audio.usb.default \
    libaudio-resampler \
    libaudioparameter \
    libgenlock \
    libstlport

# Media / OMX
PRODUCT_PACKAGES += \
    libmm-omxcore \
    libOmxCore \
    libOmxVenc \
    libOmxVdec \
    libstagefrighthw \
    libc2dcolorconvert

# RIL: AOSP rild speaks HIDL (radio@1.0); the shim bridges Samsung blobs.
# libsec-ril.so additionally DT_NEEDEDs the listed legacy system libs; none
# of them is packaged by the base products, so name them explicitly here.
PRODUCT_PACKAGES += \
    rild \
    libril \
    librilutils \
    libsecril_shim \
    libhardware_legacy \
    libnetutils \
    libsqlite \
    libcrypto

# Filesystem tools
PRODUCT_PACKAGES += \
    badblocks \
    mke2fs.conf \
    resize2fs \
    make_ext4fs

PRODUCT_PACKAGES += \
    libexifa \
    libjpega

# Camera app (Snap/Gello are CM-13 era and do not exist in 15.1)
PRODUCT_PACKAGES += \
    Camera2

PRODUCT_PACKAGES_REMOVE += \
    Calculator \
    Calendar \
    DeskClock \
    Email \
    Gallery2 \
    Jelly \
    SoundRecorder \
    Terminal \
    WallpaperPicker

# AncoraParts
PRODUCT_PACKAGES += \
    AncoraParts

# libshims: libstdc++ (operator new/delete) and libstlport (std::__node_alloc)
# satisfy the DT_NEEDED of the Adreno GPU blobs (libsc-a2xx, libq3dtools);
# the Samsung camera chain blobs DT_NEEDED libstdc++ too.  libjpeg is a stub
# for a vestigial libseccameraadaptor DT_NEEDED.  libshim_media wraps Oreo
# media ABI drifts and re-adds MemoryHeapPmem/JpegEncoder for the camera
# blobs (DT_NEEDED of camera.msm7x30).
PRODUCT_PACKAGES += \
    libshim_media \
    libjpeg \
    libstdc++

# IPv6 tethering
PRODUCT_PACKAGES += \
    ebtables \
    ethertypes

# Charger images
PRODUCT_PACKAGES += \
    charger_res_images

# WPA supplicant
PRODUCT_PACKAGES += \
    dhcpcd.conf \
    hostapd \
    libwpa_client \
    wpa_supplicant \
    wpa_supplicant.conf

# Bluetooth: the AOSP Fluoride stack (bluetooth.default, auto-loaded by the
# Bluetooth app via hw_get_module) plus the Oreo HIDL HAL service whose
# vendor_interface dlopens libbt-vendor (BCM4329 UART + bluesleep LPM).
# Neither the AOSP full_base_telephony chain nor vendor_lineage packages the
# Bluetooth app, so it must be named explicitly here.
PRODUCT_PACKAGES += \
    Bluetooth \
    bluetooth.default \
    android.hardware.bluetooth@1.0-impl \
    android.hardware.bluetooth@1.0-service \
    libbt-vendor

# Shipping Android version for legacy-vold/FDE behaviours
PRODUCT_SHIPPING_API_LEVEL := 16

$(call inherit-product-if-exists, vendor/samsung/ancora/device-vendor.mk)
$(call inherit-product-if-exists, hardware/broadcom/wlan/bcmdhd/firmware/bcm4329/device-bcm.mk)
