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

# Oreo compatibility notes:
#  - Pure C (libexif ancestry), no C++ STL dependency: builds unchanged on
#    the Oreo toolchain.
#  - Consumed by the Samsung jpeg camera blobs via DT_NEEDED at runtime,
#    so the SONAME must stay "libexifa.so" - do not rename.
#  - Keeps a legacy mangled-ABI surface for the blobs; no exports may be
#    pruned here (suppress visibility changes with default -fvisibility).

LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE_TAGS := optional

LOCAL_CFLAGS := \
    -Wno-unused-parameter \
    -Wno-sign-compare

LOCAL_C_INCLUDES += \
    $(LOCAL_PATH) \
    $(LOCAL_PATH)/libexif/ \
    $(LOCAL_PATH)/libexif/canon/ \
    $(LOCAL_PATH)/libexif/fuji/ \
    $(LOCAL_PATH)/libexif/olympus/ \
    $(LOCAL_PATH)/libexif/pentax/

LOCAL_SRC_FILES := \
    canon/exif-mnote-data-canon.c \
    canon/mnote-canon-tag.c \
    canon/mnote-canon-entry.c \
    pentax/mnote-pentax-tag.c \
    pentax/mnote-pentax-entry.c \
    pentax/exif-mnote-data-pentax.c \
    exif-loader.c \
    exif-byte-order.c \
    exif-content.c \
    exif-log.c \
    exif-mem.c \
    olympus/mnote-olympus-tag.c \
    olympus/mnote-olympus-entry.c \
    olympus/exif-mnote-data-olympus.c \
    exif-format.c \
    exif-utils.c \
    exif-entry.c \
    exif-ifd.c \
    exif-data.c \
    exif-tag.c \
    fuji/mnote-fuji-tag.c \
    fuji/mnote-fuji-entry.c \
    fuji/exif-mnote-data-fuji.c \
    exif-mnote-data.c

LOCAL_MODULE := libexifa

include $(BUILD_SHARED_LIBRARY)
