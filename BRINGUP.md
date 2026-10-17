# GT-I8150 (ancora) — Android 8.0/8.1 Bring-up Checklist

Work in top-down order; each stage has a gate that must pass before moving on.
All "expect" blocks are things to verify on the device, not on the build box.

---

## Stage 0 — Build gates (build box)

- [ ] `make bootimage` compiles — kernel `drivers/staging/android/binder.c`
      multi-node patch, `BINDER_GET_NODE_DEBUG_INFO` addition, `binder.h`
      debug-info struct, ancora_defconfig edits
- [ ] Sepolicy compiles — device `sepolicy/` polyglot (non-treble, single
      policydb v30) has no `neverallow` clashes with core 15.1
- [ ] display-caf / audio-caf / media-caf build with `compat_headers/`
- [ ] `libsecril_shim`, `libbt-vendor` (hardware/broadcom/libbt
      lineage-15.1), libshims/libhealthd/libexifa build
- [ ] `libshim_media` (typed media trampolines + MemoryHeapPmem +
      JpegEncoder), `libstdc++`, `libjpeg` stub and `libstlport` build;
      `libstlport` must export the STLport freelist allocator under the
      blob-era mangles (`nm -D out/.../libstlport.so | grep node_alloc` →
      `_ZNSt12__node_alloc11_M_allocateERj` + `_ZNSt12__node_alloc13_M_deallocateEPvj`)
      — libsc-a2xx.so / libq3dtools_adreno.so DT_NEEDED both libstlport.so
      and libstdc++.so
- [ ] `libcamera_parameters_ancora` builds and wholesale-links into
      `libcamera_client` (TARGET_SPECIFIC_CAMERA_PARAMETER_LIBRARY soong
      wiring); requires
      `patches/frameworks-av-15.1-camera-params-extra.patch` applied to the
      frameworks/av tree first
- [ ] The mandatory frameworks/av + system/core patches are applied to the
      Lineage 15.1 tree (from the build root run
      `device/samsung/ancora/apply-patches.sh` — it skips already-applied
      hunks); then verify the restored ABI slots are exported:
      `nm -D out/target/product/ancora/system/lib/libutils.so | grep reservedVectorImpl`
      (needs `reservedVectorImpl1..8` + the SortedVectorImpl eight — without
      them libcamera.so's fused blob chain cannot even dlopen)
- [ ] Blob copy stage: `device-vendor-blobs.mk` paths all resolve
      (incl. `sensors.default.so` alias; `rild`/`libril.so` excluded)

## Stage 1 — Kernel only (flash boot.img, boot into recovery)

```
ls -lZ /dev/binder /dev/hwbinder      # both nodes, both exist
dmesg | grep -i binder                # misc "binder" + misc "hwbinder" registered
cat /proc/cmdline                     # ... androidboot.selinux=permissive (bring-up only)
dmesg | grep -Ei "selinux"            # policy.30 loaded (xperm capable kernel)
```

- [ ] `/dev/binder` **and** `/dev/hwbinder` created by ueventd
- [ ] SELinux policy v30 loads (no "policy version mismatch" error)

Fail modes:
- `/dev/hwbinder` missing → second `misc_register` failed (name/minor
  collision) — check dmesg for the misc driver error
- policy load fails → kernel security/selinux missing the v30 backport
  (should not happen: `POLICYDB_VERSION_XPERMS_IOCTL` is in this tree)

## Stage 2 — Full ROM first boot (permissive)

Watch in this order. Collect everything: `logcat -b all` + `dmesg` + AVCs.

```
adb shell 'logcat -d | grep -E "( servicemanager|hwservicemanager)"'
adb shell getprop | grep -E "ro.controller|ctl.start|init.svc"
```

1. **servicemanager + hwservicemanager**
   - [ ] Both run (`init.svc.servicemanager`, `init.svc.hwservicemanager`)
   - [ ] Each owns its own context: `service list` (framework) works, and
         `lshal 2>/dev/null || /system/bin/hwservicemanager -d`-equivalent
         HW service queries respond
   - Unit test of the two-context-manager binder patch — if only
     servicemanager gets ctx 0 and hwservicemanager fails to claim, check
     the `binder_open` minor→ctx classification (`hwbinder_registered`)

2. **ueventd**
   - [ ] No `init.rc` failure from missing `net_bt` group (net_bt fixes are
         in init*.rc / ueventd.qcom.rc)

3. **SurfaceFlinger / EGL / gralloc**
   - [ ] `android.hardware.graphics.allocator@2.0-service` up
   - [ ] `hwcomposer.msm7x30` loaded through hwc2on1adapter (no "failed to
         dlopen hwcomposer")
   - [ ] Adreno EGL blobs picked via `ro.hardware.egl=adreno`
   - [ ] Boot animation renders (tests gralloc buffers + HWC1 composition
         and the fence-less path)
   Highest-risk seam. Bootanim black but ioctl errors absent → check
   fence-less composition in hwc2on1adapter logs.

4. **audio**
   - [ ] `audio_policy_configuration.xml` parsed (no policy load error)
   - [ ] Legacy ALSA HAL wrapped by `audio@2.0` (`init.svc.audiopolicy?`
         / audiopolicy services up)
   - [ ] Notification/boot chime audible; later: A2DP, SCO

5. **legacy sensor/light/power/memtrack HALs**
   - [ ] `sensors@1.0-impl` dlopens `sensors.default.so` (→ legacy
         `sensors.ancora.so`; the sensor blobs import nothing outside the
         platform — verified dynsym-clean, no shims)
   - [ ] GPU blob package resolves at load: `libsc-a2xx.so`/`libq3dtools`
         `DT_NEEDED` `libstlport.so`+`libstdc++.so` are both device-built
         (if SurfaceFlinger/EGL fails to load, `nm -D` the built
         `libstlport.so` per Stage 0)
   - [ ] `lights.msm7x30` (TARGET_PROVIDES_LIBLIGHT, no duplicate)
   - [ ] memtrack loads (`dumpsys meminfo` runs clean)

6. **camera (msm7x30 blob HAL chain)**
   - [ ] cameraserver up; `camera.msm7x30.so` loads with no "cannot locate
         symbol" — every blob UND binds: CameraParameters Samsung extras
         from `libcamera_client` (global group), media trampolines +
         MemoryHeapPmem/JpegEncoder from `libshim_media` (HAL local group)
   - [ ] Camera2 opens, preview frames arrive
   - [ ] Still capture produces a valid JPEG — placeholder EXIF-free output
         is expected (zero-length EXIF by design, see Phase-5 note below)
   - Fail modes: HAL dlopen failure → frameworks/av patch applied? Board
         `TARGET_SPECIFIC_CAMERA_PARAMETER_LIBRARY` set? symbol failures
         mentioning `reservedVectorImpl` → system/core VectorImpl patch
         missing; linker kill/SIGSEGV *while mapping* `libcamera.so` →
         apply the OPTIONAL `patches/bionic-15.1-prelink-optional.patch`
         (blobs carry PRE trailers but normalized headers, so this is the
         last-resort path); failures in Samsung parameter strings check the
         Extra header copy

7. **ril**
   - [ ] `rild.libpath=/system/lib/libsecril_shim.so` loads; blob
         `rild`/`libril.so` bundle is NOT in APK — confirmed at blob stage
   - [ ] SIM read works, radio state transitions to reliable
   - Riskiest: Samsung SETUP_DATA_CALL legacy format at the shim seam —
     watch during data attach

8. **bluetooth** (traceable end-to-end)
   - [ ] `bluetooth-1-0` service up (`/vendor/bin/hw/android.hardware.bluetooth@1.0-service`)
   - [ ] `vendor_interface` dlopens `libbt-vendor.so`
   - [ ] HCI goes out on `/dev/ttyHS0`
   - [ ] Patchram succeeds: firmware `/system/vendor/firmware/bcm4329.hcd`
         loads (missing `/etc/bluetooth/bt_vendor.conf` warning is harmless)
   - [ ] Bluesleep LPM works (`/proc/bluetooth/sleep/lpm`)
   - [ ] `Bluetooth` app starts in-process fluoride (`bluetooth.default.so`)

9. **wifi (bcmdhd)**
   - [ ] `wificond` talks to the 3.4 nl80211 — classic risk: missing
         ioctl coverage in bcmdhd — surface as missing `scan` support;
         client connect via the old `wifi` HAL side
   - [ ] `libwifi-hal-bcm` loaded (BOARD_WLAN_DEVICE=bcmdhd picked it)

10. **framework / storage**
   - [ ] vold mounts userdata via the new `/dev/block/vold` policy types
   - [ ] lmkd up with MALLOC_SVELTE + kernels' LMK knobs
   - [ ] DexPreOpt boot-class only (`WITH_DEXPREOPT_BOOT_IMG_ONLY`) boots
         without (huge) first-boot compile stall

## Stage 3 — Denials → enforcing

- [ ] `logcat -b all` + `dmesg` avc's during Stage 2 are recorded
- [ ] Fix all denials (device `sepolicy/` only; don't touch core)
- [ ] Then edit `arch/arm/configs/ancora_defconfig` and REMOVE
      `CONFIG_CMDLINE="androidboot.selinux=permissive"` (big inline comment
      marks the line; CMDLINE_EXTEND appends it every boot)
- [ ] Rebuild kernel, reflash, confirm `getenforce` = Enforcing (and still
      do `setenforce` toggles via `CONFIG_SECURITY_SELINUX_DEVELOP=y`)

------

## Companion facts (verified statically — no need to recheck)

- **binder ABI**: protocol v7 (`BINDER_IPC_32BIT`), two context-manager
  nodes, per-node uid arrays; `BINDER_GET_NODE_DEBUG_INFO` ('b', 11)
  implemented (the struct in userspace matches 4×__u32 = 16 bytes on ARM32)
- **ueventd default perms** for both binder nodes + ashmem come from core
  15.1 `rootdir/ueventd.rc`; core `file_contexts` labels
  `binder_device`/`hwbinder_device` — no device-side additions needed
- **sepolicy runtime**: kernel avtab has full extended-perm (xperm) support
  (`avtab_xperms`, ioctl checks in hooks.c) — `allowxperm` rules load
- **defconfig**: `SYSVIPC`, `ASHMEM`, `ANDROID_PMEM`(+CMA), `ION_MSM`,
  `DEFAULT/LSM_MMAP_MIN_ADDR=4096` set; `CONFIG_ANDROID_PARANOID_NETWORK`
  must stay DISABLED (Oreo apps get no `inet` gid — documented in
  ancora_defconfig)
- **Optional post-bring-up hardening**: a handful of post-3.10 binder CVE
  fixes (2016-2503 / 2017-0623 class) — cherry-pick on the build box once
  the tree compiles cleanly
- **camera blob ABI (Phase 5, verified statically — no need to recheck)**:
  - Samsung/Qualcomm CameraParameters extensions are compiled into
    `libcamera_client` via `TARGET_SPECIFIC_CAMERA_PARAMETER_LIBRARY` →
    `libcamera_parameters_ancora` (device `camera/camera_parameters/`: frozen
    copy of 15.1 `CameraParameters.cpp` force-including
    `CameraParametersExtra.h` + EXTRA_C hook). The frameworks/av patch adds
    the guarded `CAMERA_PARAMETERS_EXTRA_H` hook inside the class header
    (this is the only frameworks/av edit). Zero member-name collisions
    against the 15.1 class were verified decl-by-decl; blob
    `CameraParameters::` imports (e.g. `dump(int, const Vector<String16>&)`,
    Samsung keys) resolve from the cameraserver global lookup group even for
    runtime-dlopen'ed blobs (`liboemcamera.so`), which never see the HAL's
    local group.
  - Oreo's libutils (`system/core/libutils`) still exports the classic
    Vector/SortedVector/VectorImpl + SharedBuffer ABI — `libcamera.so`'s
    VectorImpl imports bind natively; **no frozen-container shim needed**.
  - `libshim_media` (DT_NEEDED of `camera.msm7x30`) provides typed
    trampolines mapping blob-side mangles
    `setDataSource(const char*, KeyedVector*)` → O's
    `(sp<IMediaHTTPService>, const char*, KeyedVector*)`,
    `setAudioStreamType(int)` → `(audio_stream_type_t)`,
    `seekTo(int)` → `seekTo(int, MediaPlayerSeekMode)` (O added the mode
    parameter with a default arg — mangle changed), plus a minimal
    `JpegEncoder` (ctor/dtor/makeExif — emits zero-length EXIF, producing
    valid metadata-less stills) and the classic `MemoryHeapPmem`
    (trimmed: blob imports only the ctor). Other members (e.g.
    `scaleDownYuv422`) resolve blob-to-blob from `libs3cjpeg.so`.
  - `libstdc++.so` is a device module exporting only the 4 GNU-32-bit
    operator new/delete (`_Znwj/_Znaj/_ZdlPv/_ZdaPv`) — the entire
    non-android UND sweep across all blobs. `libstlport` (device tree)
    provides `std::__node_alloc::_M_allocate/_M_deallocate` for the Adreno
    blobs (`libsc-a2xx.so`, `libq3dtools_adreno.so` DT_NEEDED both
    libstlport.so and libstdc++.so).
  - `libsec-ril.so` needs no shim: its dynsym imports only stable Parcel
    accessors plus `elapsedRealtime()`; the GB-era `RIL_Env` handoff is
    implemented inside `libsecril_shim` (the blob never links `RIL_*`
    directly — hence the blob `libril.so` was safely dropped).
  - `libhardware_legacy`, `libnetutils`, `libsqlite` (module names verified
    against lineage-15.1 trees) are packaged for `libsec-ril.so`'s
    DT_NEEDED on them; `libcrypto` ships anyway but is named explicitly.
  - `libjpeg` stub ships empty for the vestigial `libseccameraadaptor.so`
    DT_NEEDED (no blob imports any `jpeg_*` symbol).
  - Samsung `exif_attribute_t` layout is unsourcable → photos carry no EXIF
    metadata at bring-up by design; makeExif writes `*totalLen = 0` and the
    blob skips the APP1 block (cannot corrupt the still).
- **legacy-commit equivalents audited (7 supplied refs — decision table)**:
  - `NEEDS_VECTORIMPL_SYMBOLS` (cm system_core 04e5e3b6 + 1ff7854): REQUIRED,
    rewritten for the Oreo tree as
    `patches/system-core-15.1-vectorimpl-reserved.patch` — unconditionally
    (no board gate): `libcamera.so` imports all 16 reserved slots but no
    VectorImpl vtable/typeinfo symbols, and the classes' remaining virtual
    declaration order matches the blob-era header, so appended slots at the
    same positions reproduce the old vtables exactly.
  - `bionic: Add prelink support` (sirmordred b1e089a): OPTIONAL, rewritten
    as `patches/bionic-15.1-prelink-optional.patch` — libcamera.so /
    liboemcamera.so carry `PRE ` trailers but both have normalized program
    headers (first PT_LOAD at p_vaddr 0x0), so apply only if the blob chain
    fails to map at Stage 2. (The prelinked `libril.so` blob is NOT shipped.)
  - telephony `getDataTechnology` (CM 8dd84c2): NOT applicable — the fix is
    about pre-v5 `getRilVersion()` framework plumbing; in the Oreo port the
    legacy seam lives entirely in the AOSP libril/rild structure translation
    before the blob's function table (libsecril_shim).
  - `BINDER_COMPAT` MemoryHeapBase getOffset removal (AriesVE 10c3798): NOT
    needed — consistent O libbinder on both binder ends in our port; the
    blobs import only the MemoryHeapBase ctors + getDevice (no getOffset),
    and a GB-era reader of a 3-int reply against O's 4-int (fd,size,flags,
    offset) writer stays compatible (extra tail field is simply unread).
  - linker "fix pie" (-Werror removal, sooti 0ac7b51): NOT needed — modern
    tree builds the linker fine.
  - linker "load shim libs first" (crpalmer 02b1d48): NOT needed — it
    orders LD_SHIM_LIBS entries inside walk_dependencies_tree, and this
    port removed LD_SHIM_LIBS entirely (no blob-local shims are attached).
