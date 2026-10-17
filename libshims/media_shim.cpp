/*
 * Copyright (C) 2015-2018 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Typed trampolines for the Samsung camera blob chain (libcamera.so /
 * libseccameraadaptor.so) against Oreo's libmedia ABI drift:
 *
 *   blob mangle                                     O libmedia
 *   setDataSource(const char*, KeyedVector*)         setDataSource(sp<IMediaHTTPService>&, const char*, KeyedVector*)
 *   setAudioStreamType(int)                          setAudioStreamType(audio_stream_type_t)
 *   seekTo(int)                                      seekTo(int, MediaPlayerSeekMode = default)
 *
 * These are defined as extern "C" functions carrying the blob-side mangled
 * names so that the blobs' undefined symbols bind directly to them inside the
 * camera HAL's local lookup group (camera.msm7x30 DT_NEEDEDs this shim).
 * Full typed definitions (compiler-generated O-side mangles) resolve against
 * libmedia via this library's own DT_NEEDED on libmedia, so there is no
 * global-group hijack risk: O vtable/Jpeg-style symbols are untouched.
 */

#include <media/mediaplayer.h>
#include <system/audio.h>

namespace android {
extern "C" {

// blob: legacy 3-arg setDataSource; O requires the IMediaHTTPService
// first parameter.  A null service is fine for local-file playback (the
// Samsung blob only plays shutter/jpeg sounds from local files).
status_t _ZN7android11MediaPlayer13setDataSourceEPKcPKNS_11KeyedVectorINS_7String8ES4_EE(
        MediaPlayer* self, const char* url,
        const KeyedVector<String8, String8>* headers)
{
    return self->setDataSource(sp<IMediaHTTPService>(), url, headers);
}

// blob:  int stream → O: audio_stream_type_t (values have been stable since
// ICS: 0=VOICE_CALL 1=SYSTEM 2=RING 3=MUSIC ...).
status_t _ZN7android11MediaPlayer18setAudioStreamTypeEi(
        MediaPlayer* self, int stream)
{
    return self->setAudioStreamType((audio_stream_type_t) stream);
}

// blob:  seekTo(int) → O: seekTo(int, MediaPlayerSeekMode); the default
// argument preserves the legacy SEEK_PREVIOUS_SYNC behaviour.
status_t _ZN7android11MediaPlayer6seekToEi(MediaPlayer* self, int msec)
{
    return self->seekTo(msec);
}

} // extern "C"
} // namespace android
