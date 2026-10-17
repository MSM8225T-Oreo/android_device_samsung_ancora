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

#include <string.h>

#include "JpegEncoder.h"

namespace android {

JpegEncoder::JpegEncoder()
{
}

JpegEncoder::~JpegEncoder()
{
}

// Signature recovered from the blob's dynsym:
//   _ZN7android11JpegEncoder8makeExifEPhS1_P16exif_attribute_tPjlb
//   → makeExif(unsigned char*, unsigned char*, exif_attribute_t*,
//              unsigned int*, long, bool)
//
// Writing zero EXIF bytes makes the blob's append path a no-op: the still
// capture stays a valid (EXIF-less) JPEG and cannot be corrupted by a
// mis-typed exif_attribute_t layout.  Revisit after bring-up if photo
// metadata (GPS / orientation) is worth reverse engineering.
void JpegEncoder::makeExif(unsigned char* exifOut, unsigned char* jpegBuf,
        exif_attribute_t* exifInfo, unsigned int* totalLen,
        long thumbnailLength, bool useMainBuffer)
{
    if (totalLen)
        *totalLen = 0;
}

} // namespace android
