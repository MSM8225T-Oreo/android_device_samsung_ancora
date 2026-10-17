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

/*
 * Minimal libstdc++.so for LineageOS 15.1 on GT-I8150.
 *
 * Oreo no longer ships /system/lib/libstdc++.so, but the Samsung blobs for
 * this device DT_NEEDED it everywhere (camera chain, RIL, Adreno GPU blobs).
 * A blob-vs-blob dynsym audit across every installed blob shows the only
 * C++ runtime symbols the blobs import from it are the 32-bit GNU-mangled
 * operator new / operator delete, and the STLport freelist allocator entry
 * points (std::__node_alloc::_M_allocate/_M_deallocate), which come from
 * libstlport.so (built from libstlport/ in this tree and DT_NEEDED by the
 * Adreno blobs as well).
 */

#include <stdlib.h>
#include <stddef.h>

extern "C" void* _Znwj(unsigned int size)
{
    void* p = malloc(size ? size : 1);
    if (p == NULL)
        abort();
    return p;
}

extern "C" void* _Znaj(unsigned int size)
{
    return _Znwj(size);
}

extern "C" void _ZdlPv(void* p)
{
    free(p);
}

extern "C" void _ZdaPv(void* p)
{
    free(p);
}
