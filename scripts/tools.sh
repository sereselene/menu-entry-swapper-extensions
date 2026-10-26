#!/usr/bin/env bash

STYLUA_VERSION="2.6.0"
STYLUA_LINUX_SHA256="a485f72bbfa22e4642e77a84b5edc2611a5cab7477b34e2e709dd8f78e919895"
STYLUA_WINDOWS_SHA256="fd13b4014e3b779c244bbc03f2c282e357f15bc526de6a6fa5ecbc447538313c"

LUACHECK_VERSION="1.2.0"
LUACHECK_LINUX_SHA256="d68da17fca0697d9e2fb04201f3884abd259fa558b3a449bccaed47f1390defc"
LUACHECK_WINDOWS_SHA256="0f1c69c4d09f1ebb4d8df14c215e4553e2e639bd4cb7bf3c639b0daa6198317b"

TOOLS_FOLDER=".tools"
TOOLS_BIN="$TOOLS_FOLDER/bin"
TOOLS_DOWNLOADS="$TOOLS_FOLDER/downloads"

running_on_windows() {
    case "$(uname -s)" in
        MINGW* | MSYS* | CYGWIN*) return 0 ;;
        *) return 1 ;;
    esac
}

tool_path() {
    local name="$1"
    local file_name="$name"
    if running_on_windows; then
        file_name="$name.exe"
    fi
    if [ -x "$TOOLS_BIN/$file_name" ]; then
        printf '%s\n' "$TOOLS_BIN/$file_name"
        return 0
    fi
    command -v "$name" 2>/dev/null || true
}
