/*
 * Copyright (C) 2016-2018 The LineageOS Project
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
 * libsecril_shim: Qualcomm RIL bridge for Android Oreo (LineageOS 15.1).
 *
 * Rationale:
 *   Android 8.0 framework telephony speaks only HIDL (android.hardware.radio
 *   @1.0). The cm-13.0 SamsungRIL.java subclass mirrored RIL socket parsing
 *   (processSolicited/processUnsolicited), which was removed from the
 *   framework in Oreo - so the Samsung blobs' non-standard behaviour now has
 *   to be handled below the framework, between AOSP libril and
 *   vendor's libsec-ril.so.
 *
 * what this shim does:
 *   - Loads the vendor libsec-ril.so through dlopen().
 *   - Clamps the vendor function table version up to RIL_VERSION_MIN.
 *
 *   (No Parcel shim preload is needed: the blob's dynsym was verified to
 *   import only stable Parcel accessors plus elapsedRealtime(), all still
 *   exported by Oreo's libbinder/libutils.)
 *
 * Follow-up work (bring-up iterations, tracked per-quirk):
 *   - Samsung SETUP_DATA_CALL legacy response format handling.
 *   - Optional request code mapping (Samsung 10016 DIAL_EMERGENCY etc).
 */

#define LOG_TAG "libsecril_shim"

#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <cutils/log.h>
#include <telephony/ril.h>

#define VENDOR_RIL_LIB_PATH "/system/lib/libsec-ril.so"

typedef const RIL_RadioFunctions* (*RIL_InitFunc)(const RIL_Env*, int, char**);

static RIL_RadioFunctions sSecRilFunctions;
static bool sSecRilInitialized = false;

extern "C"
const RIL_RadioFunctions* RIL_Init(const RIL_Env *env, int argc, char **argv)
{
    RIL_RadioFunctions *vendor = NULL;
    RIL_InitFunc vendorInit = NULL;
    void *vendorLib = NULL;
    char *errMsg = NULL;
    int i;

    if (sSecRilInitialized) {
        return &sSecRilFunctions;
    }

    vendorLib = dlopen(VENDOR_RIL_LIB_PATH, RTLD_NOW | RTLD_LOCAL);
    if (!vendorLib) {
        errMsg = (char *)dlerror();
        RLOGE("Failed to load %s: %s", VENDOR_RIL_LIB_PATH,
                errMsg ? errMsg : "unknown");
        return NULL;
    }

    vendorInit = (RIL_InitFunc)dlsym(vendorLib, "RIL_Init");
    if (vendorInit == NULL) {
        RLOGE("dlsym(RIL_Init) failed: %s", dlerror());
        return NULL;
    }

    vendor = (RIL_RadioFunctions *)vendorInit(env, argc, argv);
    if (vendor == NULL) {
        RLOGE("vendor RIL_Init() failed");
        return NULL;
    }

    RLOGI("RIL Init: vendor version %d (versionMin %d)",
            vendor->version, RIL_VERSION_MIN);

    memcpy(&sSecRilFunctions, vendor, sizeof(RIL_RadioFunctions));

    if (sSecRilFunctions.version < RIL_VERSION_MIN) {
        RLOGW("Clamping vendor RIL version %d -> %d",
                sSecRilFunctions.version, RIL_VERSION_MIN);
        sSecRilFunctions.version = RIL_VERSION_MIN;
    }

    if (sSecRilFunctions.version > RIL_VERSION) {
        RLOGW("Sanity clamping vendor RIL version %d -> %d",
                sSecRilFunctions.version, RIL_VERSION);
        sSecRilFunctions.version = RIL_VERSION;
    }

    for (i = 0; i <= RIL_LAST_RADIO_REQUEST; i++) {
        if (sSecRilFunctions.onRequest[i] == NULL && i <= RIL_LAST_REQUEST) {
            RLOGW("RIL vendor provided NULL callback for request %d", i);
        }
    }

    sSecRilInitialized = true;
    return &sSecRilFunctions;
}
