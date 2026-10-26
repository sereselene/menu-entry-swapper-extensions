#!/usr/bin/env bash
set -euo pipefail

ALLOWED_TYPES="feat fix refactor perf test docs style build ci chore revert"
ALLOWED_SCOPES="app windows packs swapper core spec repo ci docs"
MAXIMUM_LENGTH=100
MINIMUM_DESCRIPTION_LENGTH=10

title="${1:-}"
problems=()

if [ "${#title}" -gt "$MAXIMUM_LENGTH" ]; then
    problems+=("The title is ${#title} characters long. Keep it to $MAXIMUM_LENGTH or fewer.")
fi

if printf '%s' "$title" | LC_ALL=C grep -q '[^ -~]'; then
    problems+=("The title has a character that isn't plain ASCII, such as an emoji or a smart quote. Remove it.")
fi

if [[ "$title" =~ ^([a-z]+)\(([a-z]+)\):\ (.+)$ ]]; then
    type="${BASH_REMATCH[1]}"
    scope="${BASH_REMATCH[2]}"
    description="${BASH_REMATCH[3]}"

    if [[ " $ALLOWED_TYPES " != *" $type "* ]]; then
        problems+=("\"$type\" isn't an allowed type. Use one of: $ALLOWED_TYPES.")
    fi
    if [[ " $ALLOWED_SCOPES " != *" $scope "* ]]; then
        problems+=("\"$scope\" isn't an allowed scope. Use one of: $ALLOWED_SCOPES.")
    fi
    if [ "${#description}" -lt "$MINIMUM_DESCRIPTION_LENGTH" ]; then
        problems+=("The description is too short. Say what changed in at least $MINIMUM_DESCRIPTION_LENGTH characters.")
    fi
    if [[ ! "$description" =~ ^[a-z] ]]; then
        problems+=("Start the description with a lowercase letter.")
    fi
    if [[ "$description" == *. ]]; then
        problems+=("Drop the full stop at the end of the description.")
    fi
else
    problems+=("The title doesn't follow type(scope): description, for example feat(packs): add the clue scroll pack.")
fi

if [ "${#problems[@]}" -eq 0 ]; then
    exit 0
fi

printf '%s\n' "${problems[@]}"
exit 1
