#!/bin/zsh
# Recebe o JSON do statusLine via stdin, grava atomicamente em
# ~/Library/Application Support/ClaudeUsage/status/latest.json e imprime
# uma linha curta. Nunca imprime nem loga o conteúdo do payload (pode
# conter cwd, transcript_path e outros dados privados).
set -eu

STATUS_DIR="$HOME/Library/Application Support/ClaudeUsage/status"
STATUS_FILE="$STATUS_DIR/latest.json"

mkdir -p "$STATUS_DIR"
chmod 700 "$STATUS_DIR"

TMP_FILE=""
cleanup() {
    if [[ -n "$TMP_FILE" && -e "$TMP_FILE" ]]; then
        rm -f "$TMP_FILE"
    fi
}
trap cleanup EXIT

TMP_FILE=$(mktemp "$STATUS_DIR/latest.json.XXXXXX")
cat > "$TMP_FILE"
chmod 600 "$TMP_FILE"
mv -f "$TMP_FILE" "$STATUS_FILE"
TMP_FILE=""

MODEL=$(plutil -extract model.display_name raw -o - "$STATUS_FILE" 2>/dev/null) || MODEL="Claude"

CONTEXT_PCT=$(plutil -extract context_window.used_percentage raw -o - "$STATUS_FILE" 2>/dev/null) || CONTEXT_PCT=""

if [[ -n "$CONTEXT_PCT" ]]; then
    echo "[$MODEL] ${CONTEXT_PCT%%.*}% contexto"
else
    echo "[$MODEL] ClaudeUsage"
fi
