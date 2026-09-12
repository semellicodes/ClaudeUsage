#!/bin/zsh
# Diagnóstico somente leitura: não imprime payload, sessão, caminhos ou credenciais.
set -eu

STATUS_DIR="${CLAUDE_USAGE_STATUS_DIR:-$HOME/Library/Application Support/ClaudeUsage/status}"
STATUS_FILE="$STATUS_DIR/latest.json"

print -r -- "Diagnóstico somente da fonte local: statusLine do Claude Code no terminal."
print -r -- "A sincronização da conta para Desktop e terminal é verificada no menu do ClaudeUsage."

if [[ ! -f "$STATUS_FILE" ]]; then
    print -r -- "Arquivo de origem: ausente."
    exit 1
fi

print -r -- "Última escrita: $(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S %z' "$STATUS_FILE")"

for window in five_hour seven_day; do
    window_type=$(plutil -type "rate_limits.$window" "$STATUS_FILE" 2>/dev/null) || window_type="absent"
    if [[ "$window_type" != "dictionary" ]]; then
        print -r -- "$window: ausente, null ou ilegível na origem."
        continue
    fi
    used_type=$(plutil -type "rate_limits.$window.used_percentage" "$STATUS_FILE" 2>/dev/null) || used_type="absent"
    reset_type=$(plutil -type "rate_limits.$window.resets_at" "$STATUS_FILE" 2>/dev/null) || reset_type="absent"
    if [[ ( "$used_type" == "integer" || "$used_type" == "float" ) &&
          ( "$reset_type" == "integer" || "$reset_type" == "float" ) ]]; then
        print -r -- "$window: percentual e reset numéricos presentes na origem."
    else
        print -r -- "$window: bloco presente, mas percentual ou reset ausente/não numérico."
    fi
done

print -r -- "5h é uma janela de cinco horas; não é um limite diário de 24h."
