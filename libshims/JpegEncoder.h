/*
 * Copyright (C) 2018 The LineageOS Project
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

#ifndef ANDROID_LIBSHIMS_JPEG_ENCODER_H
#define ANDROID_LIBSHIMS_JPEG_ENCODER_H

namespace android {

// Opaque: the Samsung blob owns the real definition; we only need the class
// member name to reproduce its mangled symbol P16exif_attribute_t.
struct exif_attribute_t;

// Frozen MS-Samsung hack: the Gb-era Samsung libcamera.so's QualcommCamera
// hardware imports a JpegEncoder class that O's libmedia no longer exports.
// The blob's undefined symbols are:
//   _ZN7android11JpegEncoderC1Ev        (ctor)
//   _ZN7android11JpegEncoderD1Ev        (dtor)
//   _ZN7android11JpegEncoder8makeExifEPhS1_P16exif_attribute_tPjlb
// Only those three are needed; other JpegEncoder members resolve
// blob-to-blob from libs3cjpeg.so.
class JpegEncoder {
public:
    JpegEncoder();
    ~JpegEncoder();

    // Minimal EXIF writer: emits a zero-length EXIF payload (the blob skips
    // EXIF entirely when totalLen == 0, producing a valid, metadata-less
    // JPEG).  Structural layout mismatch with the blob's actual
    // exif_attribute_t is therefore survivable; re-implement properly if
    // photo metadata becomes important after bring-up.
    void makeExif(unsigned char* exifOut, unsigned char* jpegBuf,
                  exif_attribute_t* exifInfo, unsigned int* totalLen,
                  long thumbnailLength, bool useMainBuffer);
};

} // namespace android

#endif // ANDROID_LIBSHIMS_JPEG_ENCODER_H
