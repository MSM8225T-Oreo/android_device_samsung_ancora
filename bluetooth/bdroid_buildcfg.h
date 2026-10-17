/*
 * Copyright (C) 2012 The Android Open Source Project
 * Copyright (C) 2012 The CyanogenMod Project <http://www.cyanogenmod.org>
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
 * Bytecode buildcfg for the Oreo Fluoride stack (system/bt).
 *
 * The pre-O macros (BTM_DEF_LOCAL_NAME, BTA_BLE_SKIP_CONN_UPD,
 * BTA_SKIP_BLE_READ_REMOTE_FEAT, REMOVE_EAGER_THREADS and the
 * BLE_INCLUDED/BTA_GATT_INCLUDED/SMP_INCLUDED disable set) no longer exist in
 * 15.1 system/bt: the BLE compile-time guards were removed entirely, so the
 * stack always builds BLE/GATT/SMP code. The BCM4329 simply lacks the BLE
 * feature set and the stack degrades gracefully at the HCI level; do NOT try
 * to re-add the old disable defines.
 *
 * Chip-specific knobs live in vnd_ancora.txt (compiled into libbt-vendor's
 * generated vnd_buildcfg.h) instead.
 */

#ifndef _BDROID_BUILDCFG_H
#define _BDROID_BUILDCFG_H

/* Intentionally empty — kept so BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR
 * (and thus -DHAS_BDROID_BUILDCFG) has a stable target for future tweaks. */

#endif
