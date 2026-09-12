# ClaudeUsage

Utilitário macOS com menu e widgets para exibir os percentuais de uso recebidos pelo `statusLine` do **Claude Code no terminal**. Sem rede, credenciais ou dependências externas.

## Compatibilidade da fonte

O aplicativo Claude Desktop não atualiza este coletor nas sessões observadas em `stream-json`. Compartilhar as configurações com o terminal não garante que o Desktop execute `statusLine`. Esse comportamento também foi [relatado no repositório da Anthropic](https://github.com/anthropics/claude-code/issues/58071); o [pedido de suporte ao Desktop](https://github.com/anthropics/claude-code/issues/41456) é separado.

Assim, recompilar o widget não disponibiliza um limite que não chegou à origem. A coleta automática do Desktop não está implementada. Não usamos transcrições, scraping ou endpoints autenticados como substitutos.

Segundo a [documentação de statusLine](https://code.claude.com/docs/en/statusline), `five_hour` e `seven_day` são opcionais e independentes. Ausência não significa 0% usado nem bloqueio. A janela curta é de **5 horas**, não de 24 horas. Depois do reset, o percentual anterior deixa de ser apresentado como atual; é necessária uma nova leitura para conhecer o uso.

## Uso e diagnóstico

Configure `statusLine` para executar `Tools/claude-usage-statusline.sh` por caminho absoluto, preservando as outras configurações do Claude Code. Abra o Claude Code no terminal e envie uma mensagem. O script escreve o JSON atomicamente; o app converte e compartilha apenas o snapshot sanitizado com o widget.

Para verificar a data de escrita e a presença dos campos, sem imprimir o payload:

```sh
zsh Tools/diagnose-statusline.sh
```

O diagnóstico não substitui a validação do mapper: presença de campos numéricos não garante que os valores sejam válidos. `CLAUDE_USAGE_STATUS_DIR` permite executar os scripts com uma pasta isolada nos testes.

Em “Editar Widget”, escolha automático, Sonnet ou Opus. A seleção mostra a última leitura recebida daquele modelo; não troca o modelo do Claude. Os limites do plano são compartilhados, não cotas independentes por modelo. O widget pequeno também permite escolher 5h ou 7d. Confira a data da leitura; WidgetKit controla quando a atualização fica visível.

## Validação

```sh
swift test --package-path Packages/ClaudeUsageCore
xcodebuild -project ClaudeUsage.xcodeproj -scheme ClaudeUsage -destination 'platform=macOS' build
```

Os testes incluem o fluxo shell → arquivo → mapper → store com 0% e uso parcial, permissões do arquivo, dados ausentes, resets e persistência por modelo. O scheme do aplicativo não possui um target de testes; os testes automatizados ficam no pacote Swift.
