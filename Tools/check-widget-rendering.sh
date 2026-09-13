#!/bin/zsh
# Compila as views e providers reais, sem consultar a conta nem o Chaves.
set -eu
cd "${0:A:h:h}"
CHECK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ClaudeUsage-render-check.XXXXXX")
trap 'rm -rf "$CHECK_DIR"' EXIT
swiftc -parse-as-library -emit-library -emit-module -module-name ClaudeUsageCore \
    Packages/ClaudeUsageCore/Sources/ClaudeUsageCore/**/*.swift \
    -emit-module-path "$CHECK_DIR/ClaudeUsageCore.swiftmodule" \
    -o "$CHECK_DIR/libClaudeUsageCore.dylib"
swiftc -parse-as-library -I "$CHECK_DIR" -L "$CHECK_DIR" -lClaudeUsageCore \
    -Xlinker -rpath -Xlinker "$CHECK_DIR" \
    Widget/Views/*.swift Widget/UsageTimelineProvider.swift Widget/WidgetSelectionIntent.swift \
    Tools/WidgetRenderCheck.swift -o "$CHECK_DIR/check"
"$CHECK_DIR/check" "${1:-/tmp/ClaudeUsage-render-check.png}"
