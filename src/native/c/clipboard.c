#include "clipboard.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <uuid/uuid.h>

static clipboard_history_t clipboard_history = {0};

int clipboard_init(void) {
    clipboard_history.count = 0;
    clipboard_history.current_index = 0;
    clipboard_history.is_monitoring = false;
    return 1;
}

void clipboard_cleanup() {
    clipboard_clear_history();
}

clipboard_history_t *clipboard_get_history() {
    return &clipboard_history;
}

bool clipboard_add_to_history(const char *content, clipboard_type_t type, const char *source_app) {
    if (!content || clipboard_history.count >= MAX_CLIPBOARD_HISTORY) return false;
    clipboard_item_t *item = &clipboard_history.items[clipboard_history.count];
    uuid_t binuuid;
    uuid_generate_random(binuuid);
    uuid_unparse_lower(binuuid, item->id);
    item->type = type;
    item->content_size = strlen(content);
    item->content = strdup(content);
    item->metadata = NULL;
    item->timestamp = time(NULL);
    strncpy(item->source_app, source_app ? source_app : "unknown", sizeof(item->source_app)-1);
    item->is_sensitive = false;
    clipboard_history.count++;
    clipboard_history.current_index = clipboard_history.count - 1;
    return true;
}

clipboard_type_t clipboard_detect_type(const char *content) {
    if (!content) return CLIPBOARD_TYPE_UNKNOWN;
    if (strstr(content, "\x89PNG") || strstr(content, "JFIF")) return CLIPBOARD_TYPE_IMAGE;
    if (strstr(content, ".png") || strstr(content, ".jpg") || strstr(content, ".jpeg")) return CLIPBOARD_TYPE_IMAGE;
    if (strstr(content, ".pdf") || strstr(content, ".doc") || strstr(content, ".txt")) return CLIPBOARD_TYPE_FILE;
    if (strlen(content) > 0 && strlen(content) < 4096) return CLIPBOARD_TYPE_TEXT;
    return CLIPBOARD_TYPE_UNKNOWN;
}

void clipboard_clear_history() {
    for (int i = 0; i < clipboard_history.count; ++i) {
        free(clipboard_history.items[i].content);
        clipboard_history.items[i].content = NULL;
        if (clipboard_history.items[i].metadata) {
            free(clipboard_history.items[i].metadata);
            clipboard_history.items[i].metadata = NULL;
        }
    }
    clipboard_history.count = 0;
    clipboard_history.current_index = 0;
}

// --- API stubs for header completeness ---
char* clipboard_get_text(void) { return NULL; }
bool clipboard_set_text(const char *text) { return false; }
clipboard_item_t* clipboard_get_item(int index) {
    if (index < 0 || index >= clipboard_history.count) return NULL;
    return &clipboard_history.items[index];
}
bool clipboard_restore_item(int index) { return false; }
bool clipboard_start_monitoring(void) { return false; }
bool clipboard_stop_monitoring(void) { return false; }
