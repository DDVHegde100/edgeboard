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


// --- API implementations and stubs for header completeness ---
char* clipboard_get_text(void) {
    if (clipboard_history.count == 0) return NULL;
    clipboard_item_t *item = &clipboard_history.items[clipboard_history.current_index];
    if (item->type == CLIPBOARD_TYPE_TEXT && item->content) {
        return strdup(item->content);
    }
    return NULL;
}

bool clipboard_set_text(const char *text) {
    if (!text) return false;
    return clipboard_add_to_history(text, CLIPBOARD_TYPE_TEXT, "api");
}

clipboard_item_t* clipboard_get_item(int index) {
    if (index < 0 || index >= clipboard_history.count) return NULL;
    return &clipboard_history.items[index];
}

bool clipboard_restore_item(int index) {
    if (index < 0 || index >= clipboard_history.count) return false;
    clipboard_history.current_index = index;
    return true;
}

bool clipboard_start_monitoring(void) { clipboard_history.is_monitoring = true; return true; }
bool clipboard_stop_monitoring(void) { clipboard_history.is_monitoring = false; return true; }
bool clipboard_is_monitoring(void) { return clipboard_history.is_monitoring; }

char* clipboard_generate_uuid(void) {
    uuid_t binuuid;
    char *uuid_str = (char*)malloc(37);
    uuid_generate_random(binuuid);
    uuid_unparse_lower(binuuid, uuid_str);
    return uuid_str;
}

bool clipboard_is_sensitive_content(const char *content) {
    if (!content) return false;
    // Simple heuristic: look for keywords
    if (strstr(content, "password") || strstr(content, "secret")) return true;
    return false;
}

char* clipboard_format_content_preview(const char *content, int max_length) {
    if (!content) return NULL;
    int len = strlen(content);
    int preview_len = (len < max_length) ? len : max_length;
    char *preview = (char*)malloc(preview_len + 4);
    strncpy(preview, content, preview_len);
    if (len > max_length) {
        strcpy(preview + preview_len, "...");
    } else {
        preview[preview_len] = '\0';
    }
    return preview;
}

size_t clipboard_get_content_size(void) {
    if (clipboard_history.count == 0) return 0;
    return clipboard_history.items[clipboard_history.current_index].content_size;
}

clipboard_item_t** clipboard_search(const char *query, int *result_count) {
    if (!query) { if (result_count) *result_count = 0; return NULL; }
    clipboard_item_t **results = malloc(sizeof(clipboard_item_t*) * clipboard_history.count);
    int found = 0;
    for (int i = 0; i < clipboard_history.count; ++i) {
        if (strstr(clipboard_history.items[i].content, query)) {
            results[found++] = &clipboard_history.items[i];
        }
    }
    if (result_count) *result_count = found;
    return results;
}

clipboard_item_t** clipboard_filter_by_type(clipboard_type_t type, int *result_count) {
    clipboard_item_t **results = malloc(sizeof(clipboard_item_t*) * clipboard_history.count);
    int found = 0;
    for (int i = 0; i < clipboard_history.count; ++i) {
        if (clipboard_history.items[i].type == type) {
            results[found++] = &clipboard_history.items[i];
        }
    }
    if (result_count) *result_count = found;
    return results;
}

clipboard_item_t** clipboard_get_recent(int count) {
    if (count > clipboard_history.count) count = clipboard_history.count;
    clipboard_item_t **results = malloc(sizeof(clipboard_item_t*) * count);
    for (int i = 0; i < count; ++i) {
        results[i] = &clipboard_history.items[clipboard_history.count - 1 - i];
    }
    return results;
}

bool clipboard_export_history(const char *filepath) {
    // Stub: implement file export if needed
    return false;
}

bool clipboard_import_history(const char *filepath) {
    // Stub: implement file import if needed
    return false;
}

clipboard_stats_t clipboard_get_stats(void) {
    clipboard_stats_t stats = {0};
    stats.total_items = clipboard_history.count;
    time_t oldest = 0, newest = 0;
    for (int i = 0; i < clipboard_history.count; ++i) {
        clipboard_item_t *item = &clipboard_history.items[i];
        stats.total_size += item->content_size;
        switch (item->type) {
            case CLIPBOARD_TYPE_TEXT: stats.text_items++; break;
            case CLIPBOARD_TYPE_IMAGE: stats.image_items++; break;
            case CLIPBOARD_TYPE_FILE: stats.file_items++; break;
            default: break;
        }
        if (i == 0 || item->timestamp < oldest) oldest = item->timestamp;
        if (i == 0 || item->timestamp > newest) newest = item->timestamp;
    }
    stats.oldest_item = oldest;
    stats.newest_item = newest;
    return stats;
}
