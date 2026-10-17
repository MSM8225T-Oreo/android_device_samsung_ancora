# Copyright (C) 2015 The CyanogenMod Project
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

#
# Device shims for LineageOS 15.1 (Oreo) on GT-I8150 (ancora).
#
#  libshim_media : typed trampolines for Oreo media ABI drift
#                  (MediaPlayer::seekTo gained a MediaPlayerSeekMode
#                  parameter, setAudioStreamType takes audio_stream_type_t,
#                  setDataSource requires an IMediaHTTPService) plus the
#                  Samsung-era MemoryHeapPmem and JpegEncoder classes, which
#                  are gone from the platform.  Linked as a DT_NEEDED of
#                  camera.msm7x30 so the Samsung blob chain binds all of it
#                  from the HAL's local lookup group.  Plain content-free
#                  DT_NEEDED links only — no RTLD_GLOBAL, no LD_SHIM_LIBS.
#  libstdc++     : operator new/delete for the Samsung blobs that DT_NEEDED
#                  libstdc++.so; Oreo ships no libstdc++.so of its own.  (The
#                  std::__node_alloc symbols the Adreno blobs import live in
#                  libstlport.so, built from libstlport/ in this tree.)
#  libjpeg       : empty stub - libseccameraadaptor.so DT_NEEDEDs it but no
#                  blob imports any jpeg_* symbol (vestigial Samsung glue).

LOCAL_PATH := $(call my-dir)

# Camera blob chain shim
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
	media_shim.cpp \
	MemoryHeapPmem.cpp \
	JpegEncoder.cpp

LOCAL_SHARED_LIBRARIES := liblog libcutils libmedia libbinder libutils

LOCAL_C_INCLUDES += \
	$(LOCAL_PATH) \
	system/core/include \
	system/core/libutils/include \
	frameworks/native/include \
	frameworks/native/libs/binder/include \
	frameworks/av/include \
	frameworks/av/media/libmedia/include \
	$(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ/usr/include
LOCAL_ADDITIONAL_DEPENDENCIES := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ/usr

LOCAL_MODULE := libshim_media
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)

include $(BUILD_SHARED_LIBRARY)

# Minimal C++ runtime for the Samsung blobs (32-bit GNU operator new/delete)
include $(CLEAR_VARS)

LOCAL_SRC_FILES := stdcpp/libstdc++.cpp

LOCAL_MODULE := libstdc++
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)
# NOTE: default visibility on purpose - the extern "C" operator names ARE the
# ABI the blobs bind against.

include $(BUILD_SHARED_LIBRARY)

# Empty stub for the vestigial libjpeg.so DT_NEEDED of libseccameraadaptor.so
include $(CLEAR_VARS)

LOCAL_SRC_FILES := libjpeg_stub.c

LOCAL_MODULE := libjpeg
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)

include $(BUILD_SHARED_LIBRARY)
