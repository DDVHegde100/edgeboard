#ifndef CLIPBOARD_H
#define CLIPBOARD_H

#include <stdint.h>
#include <stdbool.h>
#include <time.h>

// Maximum clipboard history entries
#define MAX_CLIPBOARD_HISTORY 100
#define MAX_CONTENT_SIZE 1048576  // 1MB max per clipboard item

// Clipboard item types
typedef enum {
    CLIPBOARD_TYPE_TEXT = 0,
    CLIPBOARD_TYPE_IMAGE = 1,
    CLIPBOARD_TYPE_FILE = 2,
    CLIPBOARD_TYPE_RICH_TEXT = 3,
    CLIPBOARD_TYPE_URL = 4,
    CLIPBOARD_TYPE_UNKNOWN = 99
} clipboard_type_t;

// Clipboard item structure
typedef struct {
    char id[37];                    // UUID string
    clipboard_type_t type;          // Content type
    char *content;                  // Main content
    size_t content_size;            // Content size in bytes
    char *metadata;                 // Additional metadata (JSON)
    time_t timestamp;               // When it was copied
    char source_app[256];           // Source application name
    bool is_sensitive;              // Contains sensitive data
} clipboard_item_t;

// Clipboard history structure
typedef struct {
    clipboard_item_t items[MAX_CLIPBOARD_HISTORY];
    int count;                      // Current number of items
    int current_index;              // Index of current clipboard item
    bool is_monitoring;             // Whether monitoring is active
} clipboard_history_t;

// Core clipboard functions
int clipboard_init(void);
void clipboard_cleanup(void);

// Clipboard content operations
char* clipboard_get_text(void);
bool clipboard_set_text(const char *text);
clipboard_type_t clipboard_detect_type(const char *content);

// Clipboard history management
clipboard_history_t* clipboard_get_history(void);
bool clipboard_add_to_history(const char *content, clipboard_type_t type, const char *source_app);
clipboard_item_t* clipboard_get_item(int index);
bool clipboard_restore_item(int index);
void clipboard_clear_history(void);

// Clipboard monitoring
bool clipboard_start_monitoring(void);
bool clipboard_stop_monitoring(void);
bool clipboard_is_monitoring(void);

// Utility functions
char* clipboard_generate_uuid(void);
bool clipboard_is_sensitive_content(const char *content);
char* clipboard_format_content_preview(const char *content, int max_length);
size_t clipboard_get_content_size(void);

// Search and filter
clipboard_item_t** clipboard_search(const char *query, int *result_count);
clipboard_item_t** clipboard_filter_by_type(clipboard_type_t type, int *result_count);
clipboard_item_t** clipboard_get_recent(int count);

// Export/Import
bool clipboard_export_history(const char *filepath);
bool clipboard_import_history(const char *filepath);

// Statistics
typedef struct {
    int total_items;
    int text_items;
    int image_items;
    int file_items;
    size_t total_size;
    time_t oldest_item;
    time_t newest_item;
} clipboard_stats_t;

clipboard_stats_t clipboard_get_stats(void);

#endif // CLIPBOARD_H
