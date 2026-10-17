LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_MODULE := camera.$(TARGET_BOARD_PLATFORM)

LOCAL_SRC_FILES := \
    cameraHAL.cpp \
    Overlay.cpp


# Header homes on lineage-15.1: frameworks/native/include was pruned in Oreo
# (binder -> libs/binder/include, ui -> libs/ui/include) and system/media no
# longer carries camera HAL headers; CameraParameters lives in frameworks/av.
# camera_parameters/ supplies CameraParametersExtra.h for the Samsung extras.
LOCAL_C_INCLUDES := $(TOP)/frameworks/av/camera/include \
    $(TOP)/frameworks/native/libs/binder/include \
    $(TOP)/frameworks/native/libs/ui/include \
    system/core/libutils/include \
    system/core/libcutils/include \
    hardware/libhardware/include \
    $(call project-path-for,qcom-display)/libgralloc \
    $(LOCAL_PATH)/camera_parameters

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
