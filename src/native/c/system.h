// system.h - System-level function declarations for EdgeBoard
// Provides low-level system interaction utilities for clipboard and memory management

#ifndef EDGEBOARD_SYSTEM_H
#define EDGEBOARD_SYSTEM_H

#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Clipboard access
char *eb_get_clipboard_content(size_t *out_len);
bool eb_set_clipboard_content(const char *data, size_t len);

// Memory management
void *eb_malloc(size_t size);
void eb_free(void *ptr);

// System utilities (extend as needed)
void eb_sleep_ms(int ms);

#ifdef __cplusplus
}
#endif

#endif // EDGEBOARD_SYSTEM_H
