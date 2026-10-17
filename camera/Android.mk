LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_MODULE := camera.$(TARGET_BOARD_PLATFORM)

LOCAL_SRC_FILES := \
    cameraHAL.cpp \
    Overlay.cpp


LOCAL_C_INCLUDES := $(TOP)/frameworks/native/include

LOCAL_C_INCLUDES += $(call project-path-for,qcom-display)/libgralloc \
                    system/media/camera/include

LOCAL_MODULE_TAGS := optional

LOCAL_SHARED_LIBRARIES := liblog libutils libhardware libcamera_client
# libshim_media: typed trampolines for Oreo media ABI drift for the Samsung
# blob chain (MediaPlayer::seekTo grew a MediaPlayerSeekMode parameter,
# setAudioStreamType takes audio_stream_type_t, setDataSource requires an
# IMediaHTTPService), plus the Samsung-era MemoryHeapPmem and JpegEncoder
# classes that no longer exist on the platform.  DT_NEEDED of the HAL, so the
# blobs bind them from the HAL's local lookup group.
LOCAL_SHARED_LIBRARIES += libshim_media
LOCAL_SHARED_LIBRARIES += libseccameraadaptor

include $(BUILD_SHARED_LIBRARY)
