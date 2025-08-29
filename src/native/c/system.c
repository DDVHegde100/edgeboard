// system.c - Core system interaction functions for EdgeBoard
// Implements clipboard access, memory management, and basic utilities

#include "system.h"
#include <stdlib.h>
#include <string.h>
#include <time.h>
#ifdef __APPLE__
#include <ApplicationServices/ApplicationServices.h>
#endif

// Clipboard access (macOS implementation)
char *eb_get_clipboard_content(size_t *out_len) {
#ifdef __APPLE__
    PasteboardRef pb;
    if (PasteboardCreate(kPasteboardClipboard, &pb) != noErr) return NULL;
    PasteboardSynchronize(pb);
    ItemCount itemCount;
    if (PasteboardGetItemCount(pb, &itemCount) != noErr || itemCount == 0) return NULL;
    for (ItemCount i = 1; i <= itemCount; ++i) {
        PasteboardItemID itemID;
        if (PasteboardGetItemIdentifier(pb, i, &itemID) != noErr) continue;
        CFArrayRef types;
        if (PasteboardCopyItemFlavors(pb, itemID, &types) != noErr) continue;
        for (CFIndex j = 0; j < CFArrayGetCount(types); ++j) {
            CFStringRef type = (CFStringRef)CFArrayGetValueAtIndex(types, j);
            if (UTTypeConformsTo(type, CFSTR("public.utf8-plain-text"))) {
                CFDataRef data;
                if (PasteboardCopyItemFlavorData(pb, itemID, type, &data) == noErr) {
                    CFIndex len = CFDataGetLength(data);
                    char *buf = (char *)eb_malloc(len + 1);
                    memcpy(buf, CFDataGetBytePtr(data), len);
                    buf[len] = '\0';
                    if (out_len) *out_len = len;
                    CFRelease(data);
                    CFRelease(types);
                    return buf;
                }
            }
        }
        CFRelease(types);
    }
#endif
    return NULL;
}

bool eb_set_clipboard_content(const char *data, size_t len) {
#ifdef __APPLE__
    PasteboardRef pb;
    if (PasteboardCreate(kPasteboardClipboard, &pb) != noErr) return false;
    if (PasteboardClear(pb) != noErr) return false;
    CFDataRef cfdata = CFDataCreate(NULL, (const UInt8 *)data, (CFIndex)len);
    if (!cfdata) return false;
    OSStatus err = PasteboardPutItemFlavor(pb, (PasteboardItemID)1, CFSTR("public.utf8-plain-text"), cfdata, 0);
    CFRelease(cfdata);
    return err == noErr;
#else
    return false;
#endif
}

// Memory management
void *eb_malloc(size_t size) {
    return malloc(size);
}

void eb_free(void *ptr) {
    free(ptr);
}

// System utilities
void eb_sleep_ms(int ms) {
    struct timespec ts;
    ts.tv_sec = ms / 1000;
    ts.tv_nsec = (ms % 1000) * 1000000;
    nanosleep(&ts, NULL);
}
