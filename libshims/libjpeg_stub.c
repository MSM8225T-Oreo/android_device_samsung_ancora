/*
 * Empty libjpeg.so stub.
 *
 * libseccameraadaptor.so carries a DT_NEEDED entry for libjpeg.so, but a
 * blob-wide dynsym audit shows no blob imports any jpeg_* symbol - the
 * dependency is vestigial (left over from the old Samsung build glue that
 * linked a real libjpeg into the enclave).  Ship an empty shared object that
 * exports nothing so the DT_NEEDED resolves and the blob chain loads.
 */

/* exported nothing */
char libjpeg_stub_notice = 0;
