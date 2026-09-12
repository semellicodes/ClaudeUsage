# ClaudeUsage

Utilitário macOS com menu e widgets para acompanhar os limites de 5h e 7d da conta Claude, usada no Desktop e no terminal. Sem servidor próprio, telemetria ou dependências externas.

## Sincronização da conta

No menu do ClaudeUsage, ative **Sincronizar Desktop e terminal**. A opção começa desativada e explica o acesso: o app lê o login do Claude Code no Chaves (ou o arquivo de credenciais quando o item não existe) e envia o token somente para `GET https://api.anthropic.com/api/oauth/usage`. O macOS pode pedir permissão ao Chaves ao conectar ou atualizar manualmente. Consultas em segundo plano não abrem pedidos de acesso.

Use a mesma conta no Desktop e no Claude Code. Com o login válido e a sincronização ativada, o app consulta a conta a cada cinco minutos enquanto estiver aberto, sem precisar enviar mensagens no terminal. A consulta não envia prompts. WidgetKit controla quando a nova leitura aparece no desktop.

O endpoint pertence à Anthropic, mas não possui contrato público estável para aplicativos de terceiros. A integração segue o protocolo descrito pelo [CodexBar](https://github.com/steipete/CodexBar/blob/main/docs/claude.md), sem incorporar seu código ou dependências. Alterações no serviço podem exigir manutenção.

Se o login expirar ou não tiver o escopo `user:profile`, execute `claude auth login` no Terminal e depois clique em **Atualizar agora**. O app relê o login a cada consulta; não renova tokens nem altera credenciais do Claude Code. A leitura real depende do login válido e da aceitação pelo servidor. Uma chave da Claude API não substitui esse login.

Falhas preservam a última leitura com sua data original. Há espera progressiva de cinco minutos até uma hora, respeitando `Retry-After`. O horário permitido para uma nova tentativa persiste entre reinícios e reconexões. Atualizações manuais têm intervalo mínimo de um minuto; erros de login permitem tentar novamente após 30 segundos.

Segundo a [documentação de statusLine](https://code.claude.com/docs/en/statusline), `five_hour` e `seven_day` são opcionais e independentes. Ausência não significa 0% usado nem bloqueio. A janela curta é de **5 horas**, não de 24 horas. Depois do reset, o percentual anterior deixa de ser apresentado como atual; é necessária uma nova leitura para conhecer o uso.

## Modelo e contexto

A API pode retornar `utilization: 0` com `resets_at: null` após liberar uma janela. O app preserva os 0% informados e apresenta “Reinício não informado” até receber uma data; não inventa uma contagem regressiva nem descarta o limite semanal.

Em **Editar Widget**, escolha automático, Sonnet ou Opus. A janela de 5h é compartilhada. O semanal usa `seven_day_sonnet` ou `seven_day_opus` quando informado; caso contrário, usa o geral `seven_day`. A seleção não troca o modelo no Claude. O widget pequeno permite escolher 5h ou 7d.

A API da conta não fornece o contexto de uma conversa. Na sincronização da conta, o contexto fica ausente para evitar apresentar uma leitura antiga do terminal como se fosse da conversa no Desktop. Desativando a sincronização, o coletor `statusLine` continua disponível para limites e contexto do terminal.

## Fonte local opcional

Configure `statusLine` para executar `Tools/claude-usage-statusline.sh` por caminho absoluto, preservando as outras configurações do Claude Code. Abra o Claude Code no terminal e envie uma mensagem. O script escreve o JSON atomicamente; o app converte e compartilha apenas o snapshot sanitizado com o widget.

Para verificar a data de escrita e a presença dos campos, sem imprimir o payload:

```sh
zsh Tools/diagnose-statusline.sh
```

O diagnóstico não substitui a validação do mapper: presença de campos numéricos não garante que os valores sejam válidos. `CLAUDE_USAGE_STATUS_DIR` permite executar os scripts com uma pasta isolada nos testes.

Esse diagnóstico verifica somente o arquivo local. O status da conexão da conta aparece no menu do app. O Desktop não executou o coletor local nas sessões observadas; por isso ele deixou de ser a única fonte.

## Privacidade

O token nunca é gravado pelo ClaudeUsage nem compartilhado com widgets. Requisições usam sessão efêmera, sem cookies/cache e sem seguir redirecionamentos. Não há scraping, leitura de conversas, API key ou telemetria. Só o snapshot sanitizado é persistido no App Group.

## Validação

```sh
swift test --package-path Packages/ClaudeUsageCore
xcodebuild -project ClaudeUsage.xcodeproj -scheme ClaudeUsage -destination 'platform=macOS' build
```

Os testes usam transporte simulado e credenciais fictícias; não acessam o Chaves nem a rede. Cobrem o contrato da conta, zero/ausência de uso, datas, limites por modelo, persistência, erros de autenticação/HTTP e espera do servidor, além do fluxo shell → arquivo → mapper → store. O scheme do aplicativo não possui target de testes; os testes ficam no pacote Swift. Testes simulados não comprovam acesso de uma conta real ao endpoint.
