#!/usr/bin/env bash
# Manages the git repository version through tags.

set -e

ACTION="ECHO"
MODE="RUN"

fetch_latest_version() {
    local LATEST_TAG=`git tag 2> /dev/null | sort -r | grep "^v[0-9]*\.[0-9]*\.[0-9]$" | head -1`
    if [[ -z "$LATEST_TAG" ]]; then
        echo '0.0.0'
    else
        echo "${LATEST_TAG:1}"
    fi
}

parse_version() {
    local VERSION=$1
    IFS='.' read -a version_parts <<< "$VERSION"
    version_major=${version_parts[0]}
    version_minor=${version_parts[1]}
    version_patch=${version_parts[2]}
}

print_version() {
    echo "$version_major.$version_minor.$version_patch"
}

print_tag() {
    echo "v$(print_version)"
}

exec_mut() {
    local CMD=("$@")
    case $MODE in
        "DRY_RUN") echo "-- Dry run: ${CMD[@]}" ;;
        "RUN") "${CMD[@]}" ;;
    esac
}

usage() {
    echo "Manages the git repository version."
    echo
    echo "Usage: $0 [-h|-?] [-d] [-u <update action>]"
    echo "  -h | -?       Prints this help message"
    echo "  -d            Dry run"
    echo "  -u <update action>"
    echo "                Updates and tags the current version depending on <update action>:"
    echo "                  major: updates the major version"
    echo "                  minor: updates the minor version"
    echo "                  patch: updates the patch version"
    echo
}

echo_version() {
    echo "Current version: $(fetch_latest_version)"
}

update_version() {
    local update_action=$1

    local latest_version=$(fetch_latest_version)
    parse_version $latest_version

    echo "Previous version: $(print_version)"

    case $update_action in
        "major") version_major=$((version_major + 1)) ; version_minor=0 ; version_patch=0 ;; 
        "minor") version_minor=$((version_minor + 1)) ; version_patch=0 ;;
        "patch") version_patch=$((version_patch + 1)) ;;
    esac

    local next_version=$(print_version)
    echo "Next version: $next_version"

    local updated_tag=$(print_tag)
    exec_mut git tag "$updated_tag"
    exec_mut git push origin "$updated_tag"
}

while getopts "du:h?" option
do
    case "$option" in
        d) MODE="DRY_RUN" ;;
        u) ACTION="UPDATE" ; UPDATE_ACTION="$OPTARG" ;;
        h|?) ACTION="USAGE" ;;
    esac
done

case "$ACTION" in
    "USAGE") usage ;;
    "ECHO") echo_version ;;
    "UPDATE") update_version $UPDATE_ACTION ;;
esac
