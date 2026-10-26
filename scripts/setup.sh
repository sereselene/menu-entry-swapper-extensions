#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"
source scripts/tools.sh

tools_only=false
for argument in "$@"; do
    case "$argument" in
        --tools-only) tools_only=true ;;
        *)
            echo "setup: unknown argument $argument. The only option is --tools-only." >&2
            exit 1
            ;;
    esac
done

for command_name in curl unzip; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "setup: $command_name isn't installed. Install it and run setup again." >&2
        exit 1
    fi
done

checksum_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d ' ' -f 1
    else
        shasum -a 256 "$1" | cut -d ' ' -f 1
    fi
}

fetch() {
    local url="$1"
    local expected_checksum="$2"
    local destination="$TOOLS_DOWNLOADS/$3"
    if [ -f "$destination" ] && [ "$(checksum_of "$destination")" = "$expected_checksum" ]; then
        return 0
    fi
    curl --fail --location --silent --show-error --output "$destination.partial" "$url"
    if [ "$(checksum_of "$destination.partial")" != "$expected_checksum" ]; then
        rm -f "$destination.partial"
        echo "setup: $url didn't match its pinned checksum, so it wasn't installed." >&2
        exit 1
    fi
    mv "$destination.partial" "$destination"
}

install_for() {
    local platform="$1"
    local stylua_checksum="$STYLUA_LINUX_SHA256"
    local luacheck_checksum="$LUACHECK_LINUX_SHA256"
    local stylua_asset="stylua-linux-x86_64.zip"
    local luacheck_asset="luacheck"
    if [ "$platform" = windows ]; then
        stylua_checksum="$STYLUA_WINDOWS_SHA256"
        luacheck_checksum="$LUACHECK_WINDOWS_SHA256"
        stylua_asset="stylua-windows-x86_64.zip"
        luacheck_asset="luacheck.exe"
    fi

    local stylua_download="stylua-$STYLUA_VERSION-$stylua_asset"
    local luacheck_download="luacheck-$LUACHECK_VERSION-$luacheck_asset"
    fetch "https://github.com/JohnnyMorganz/StyLua/releases/download/v$STYLUA_VERSION/$stylua_asset" "$stylua_checksum" "$stylua_download"
    fetch "https://github.com/lunarmodules/luacheck/releases/download/v$LUACHECK_VERSION/$luacheck_asset" "$luacheck_checksum" "$luacheck_download"

    unzip -o -q "$TOOLS_DOWNLOADS/$stylua_download" -d "$TOOLS_BIN"
    cp "$TOOLS_DOWNLOADS/$luacheck_download" "$TOOLS_BIN/$luacheck_asset"
    chmod +x "$TOOLS_BIN/$luacheck_asset" "$TOOLS_BIN"/stylua*
    echo "setup: installed StyLua $STYLUA_VERSION and Luacheck $LUACHECK_VERSION for $platform in $TOOLS_BIN"
}

platforms=()
case "$(uname -s)" in
    Linux)
        platforms=(linux)
        if grep -qi microsoft /proc/version 2>/dev/null; then
            platforms+=(windows)
        fi
        ;;
    MINGW* | MSYS* | CYGWIN*)
        platforms=(windows)
        ;;
    *)
        echo "setup: there are no pinned binaries for $(uname -s). Install StyLua $STYLUA_VERSION and Luacheck $LUACHECK_VERSION so they're on your PATH."
        ;;
esac

mkdir -p "$TOOLS_BIN" "$TOOLS_DOWNLOADS"
for platform in "${platforms[@]}"; do
    install_for "$platform"
done

if [ -x "$TOOLS_BIN/luacheck" ] && ! "$TOOLS_BIN/luacheck" --version >/dev/null 2>&1; then
    rm -f "$TOOLS_BIN/luacheck"
    echo "setup: the Luacheck binary won't run on this system (it needs glibc 2.38 or newer)."
    echo "setup: install it with LuaRocks instead and the hooks will use that: sudo luarocks --lua-version 5.4 install luacheck $LUACHECK_VERSION"
fi

if [ "$tools_only" = true ]; then
    exit 0
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    chmod +x .githooks/* scripts/*.sh
    git config core.hooksPath .githooks
    echo "setup: git hooks are on. Commits now check formatting, Luacheck and the type(scope): description title."
fi

if ! command -v busted >/dev/null 2>&1; then
    echo "setup: to run the specs you also need Lua 5.4 and Busted:"
    echo "setup:   sudo apt install lua5.4 liblua5.4-dev luarocks"
    echo "setup:   sudo luarocks --lua-version 5.4 install busted"
fi
