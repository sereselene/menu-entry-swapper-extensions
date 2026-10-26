#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

RELEASE_FOLDER="release"

stop() {
    echo "package: $1" >&2
    exit 1
}

for command_name in zip unzip; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        stop "$command_name isn't installed. On Ubuntu or WSL run: sudo apt install zip unzip"
    fi
done

for required in main.lua plugin.json src; do
    if [ ! -e "$required" ]; then
        stop "$required is missing, and the client needs it to load the plugin."
    fi
done

manifest_value() {
    sed -n "s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" plugin.json | head -n 1
}

plugin_name="$(manifest_value name)"
version="$(manifest_value version)"
if [ -z "$plugin_name" ]; then
    stop "plugin.json has no name."
fi
if [[ ! "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    stop "plugin.json needs a version such as \"0.1.0\", not \"$version\"."
fi

files=(main.lua plugin.json)
while IFS= read -r -d '' file; do
    files+=("${file#./}")
done < <(find src -type f -name '*.lua' -print0 | LC_ALL=C sort -z)
if [ -d resources ]; then
    while IFS= read -r -d '' file; do
        files+=("${file#./}")
    done < <(find resources -type f ! -name '.*' -print0 | LC_ALL=C sort -z)
fi

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

for file in "${files[@]}"; do
    mkdir -p "$staging/$plugin_name/$(dirname "$file")"
    cp "$file" "$staging/$plugin_name/$file"
done
find "$staging/$plugin_name" -exec touch -h -d "1980-01-01 00:00:00" {} +

archive_name="$plugin_name-$version.zip"
mkdir -p "$RELEASE_FOLDER"
archive_path="$repository_root/$RELEASE_FOLDER/$archive_name"
rm -f "$archive_path"

entries=()
for file in "${files[@]}"; do
    entries+=("$plugin_name/$file")
done
(cd "$staging" && TZ=UTC zip -X -q -9 "$archive_path" "${entries[@]}")

if ! unzip -tqq "$archive_path"; then
    stop "$archive_name failed its integrity test."
fi
if [ "$(unzip -Z1 "$archive_path")" != "$(printf '%s\n' "${entries[@]}")" ]; then
    stop "$archive_name doesn't hold exactly the expected files."
fi

echo "package: $RELEASE_FOLDER/$archive_name, ${#entries[@]} files, $(wc -c <"$archive_path" | tr -d ' ') bytes"
for entry in "${entries[@]}"; do
    echo "package:   $entry"
done
