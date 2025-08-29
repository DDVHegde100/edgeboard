# Native Build Configuration
CC = clang
CFLAGS = -Wall -Wextra -O2 -std=c11
SWIFT_FLAGS = -O -Xswiftc -framework -Xswiftc Cocoa -Xswiftc -framework -Xswiftc WebKit

# Directories
C_SRC_DIR = c
SWIFT_SRC_DIR = swift
BUILD_DIR = ../../build/native
OBJ_DIR = $(BUILD_DIR)/obj

# Source files
C_SOURCES = $(wildcard $(C_SRC_DIR)/*.c)
SWIFT_SOURCES = $(wildcard $(SWIFT_SRC_DIR)/*.swift)

# Object files
C_OBJECTS = $(C_SOURCES:$(C_SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
SWIFT_OBJECTS = $(SWIFT_SOURCES:$(SWIFT_SRC_DIR)/%.swift=$(OBJ_DIR)/%.o)

# Targets
TARGET = $(BUILD_DIR)/EdgeBoard
DYLIB = $(BUILD_DIR)/libedgeboard.dylib

.PHONY: all clean install watch

all: $(TARGET) $(DYLIB)

# Create build directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

# Compile C sources
$(OBJ_DIR)/%.o: $(C_SRC_DIR)/%.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Compile Swift sources
$(OBJ_DIR)/%.o: $(SWIFT_SRC_DIR)/%.swift | $(OBJ_DIR)
	swiftc $(SWIFT_FLAGS) -c $< -o $@

# Link final executable
$(TARGET): $(C_OBJECTS) $(SWIFT_OBJECTS) | $(BUILD_DIR)
	swiftc $(SWIFT_FLAGS) $(C_OBJECTS) $(SWIFT_OBJECTS) -o $@

# Create dynamic library
$(DYLIB): $(C_OBJECTS) | $(BUILD_DIR)
	$(CC) -shared $(C_OBJECTS) -o $@

# Development watch mode
watch:
	@echo "Watching native sources for changes..."
	@while true; do \
		inotifywait -e modify,create,delete -r $(C_SRC_DIR) $(SWIFT_SRC_DIR) 2>/dev/null && \
		make all; \
	done

# Install to Applications
install: $(TARGET)
	@echo "Installing EdgeBoard to /Applications..."
	cp -r $(BUILD_DIR)/EdgeBoard.app /Applications/

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)

# Debug build
debug: CFLAGS += -g -DDEBUG
debug: SWIFT_FLAGS += -g
debug: all
