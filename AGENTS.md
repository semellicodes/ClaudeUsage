# AGENTS.md — ClaudeUsage for macOS

## Objetivo
Construir `ClaudeUsage`, utilitário nativo macOS com `MenuBarExtra` + widgets WidgetKit Small/Medium para acompanhar uso do Codex. V1 deve ser local-first, leve, sem servidor, scraping, API key, telemetria ou dependências de terceiros.

## Fonte oficial de dados
A pedido explícito da usuária, a fonte principal pode consultar `GET https://api.anthropic.com/api/oauth/usage` com o OAuth existente do Claude Code. Leitura do Chaves e envio do token exclusivamente a esse endpoint foram autorizados na conversa. O statusLine permanece fonte local opcional. Esta decisão substitui a antiga restrição de exclusividade, rede e credenciais abaixo; as demais regras de privacidade permanecem.
Campos relevantes: `version`, `session_id`, `model.display_name`, `rate_limits.five_hour.{used_percentage,resets_at}`, `rate_limits.seven_day.{used_percentage,resets_at}`, `context_window.{total_input_tokens,total_output_tokens,context_window_size,used_percentage,remaining_percentage}`.

Regras de compatibilidade:
- `rate_limits` só aparece quando disponível e pode faltar antes da primeira API response; `five_hour` e `seven_day` podem faltar separadamente.
- campos de contexto podem ser `null` no início ou após `/compact`; campos JSON futuros/desconhecidos não podem quebrar decoding.
- `resets_at` é Unix epoch seconds.
- o statusline é orientado a eventos e também reexecuta quando uma janela conhecida chega ao reset; não criar polling agressivo.
- limites da assinatura são expostos como PERCENTUAL, não como total absoluto de tokens. Nunca inventar/estimar “tokens usados/restantes do plano”.
- tokens numéricos são apenas da JANELA DE CONTEXTO e devem aparecer visualmente separados do rate limit.

Docs oficiais:
- https://code.Codex.com/docs/en/statusline
- https://code.Codex.com/docs/en/memory
- https://developer.apple.com/documentation/swiftui/menubarextra
- https://developer.apple.com/documentation/widgetkit
- https://developer.apple.com/documentation/xcode/configuring-app-groups

## Arquitetura
Aplicar Clean Architecture pragmática, sem cerimônia desnecessária:
- UI não lê arquivos, não decodifica JSON e não contém regra de negócio.
- Domain não conhece SwiftUI, WidgetKit, shell ou paths.
- Infrastructure/Data não contém regras visuais.
- App e Widget reutilizam o MESMO Domain + Shared Store.
- usar protocols somente nas fronteiras úteis a teste/substituição; constructor injection; nenhum framework de DI.
- tipos pequenos/imutáveis, `Sendable` quando aplicável; evitar estado global mutável.
- proibido criar pastas genéricas `Utils`, `Helpers`, `Managers`, `Misc`.
- uma responsabilidade clara por tipo; nenhuma lógica de negócio duplicada nas Views.

Estrutura alvo:
```text
ClaudeUsage/
├── ClaudeUsage.xcodeproj
├── App/
│   ├── ClaudeUsageApp.swift
│   ├── Features/MenuBar/{MenuBarView.swift,MenuBarViewModel.swift}
│   └── Infrastructure/{StatusFileMonitor.swift,LaunchAtLoginService.swift}
├── Widget/
│   ├── ClaudeUsageWidget.swift
│   ├── UsageTimelineProvider.swift
│   └── Views/{SmallWidgetView.swift,MediumWidgetView.swift}
├── Packages/ClaudeUsageCore/
│   ├── Package.swift
│   ├── Sources/ClaudeUsageCore/
│   │   ├── Domain/{RateLimit.swift,ContextUsage.swift,UsageSnapshot.swift}
│   │   ├── Data/{ClaudeStatusPayload.swift,ClaudeStatusMapper.swift}
│   │   └── Persistence/{UsageRepository.swift,SharedUsageStore.swift}
│   └── Tests/ClaudeUsageCoreTests/Fixtures/
├── Tools/Codex-usage-statusline.sh
├── .gitignore
└── AGENTS.md
```
`ClaudeUsageCore` é a fonte única das regras/modelos compartilhados. Não criar cópias por target.

## Fluxo de dados
`Codex -> statusLine stdin -> shell -> ~/Library/Application Support/ClaudeUsage/status/latest.json -> StatusFileMonitor -> ClaudeStatusPayload DTO -> ClaudeStatusMapper -> UsageSnapshot -> SharedUsageStore/App Group -> MenuBarViewModel + Widget TimelineProvider`.

Após persistir snapshot válido, chamar `WidgetCenter.shared.reloadTimelines(ofKind:)`.

## Script statusline
`Tools/Codex-usage-statusline.sh` deve:
- usar `#!/bin/zsh` + `set -eu`; zero dependência de jq/Python/Node/Homebrew.
- receber JSON inteiro via stdin; nunca imprimir/logar payload.
- criar diretório com modo `700` e arquivo `600`.
- escrever atomicamente: `mktemp -> cat -> chmod -> mv`, com `trap` para cleanup e todos os paths entre aspas.
- imprimir no máximo uma linha curta no statusline.
- preservar `~/.Codex/settings.json`: alterar somente `statusLine`, nunca substituir o arquivo inteiro.
- não configurar `refreshInterval` sem necessidade real.

## Domain
`RateLimit`: `usedPercentage: Double`, `resetsAt: Date?`, `remainingPercentage` derivado e limitado a `0...100`. A API de conta pode informar uso zero com reset null; preservar esse percentual sem inventar uma data.
`ContextUsage`: `inputTokens?`, `outputTokens?`, `windowSize?`, `usedPercentage?`, `remainingPercentage?` — todos opcionais porque ausência precisa continuar sendo ausência, nunca virar zero.
`UsageSnapshot`: `schemaVersion`, `capturedAt`, `claudeCodeVersion?`, `sessionID?`, `modelDisplayName?`, `fiveHour?`, `sevenDay?`, `context?`.

O percentual oficial de contexto usa tokens de entrada/contexto. Não calcular `(input + output) / windowSize` para substituí-lo. Preferir `context_window.used_percentage`.

## DTO e Mapper
DTO deve espelhar apenas campos necessários do JSON externo, usando `Codable` e CodingKeys snake_case. Campos condicionais precisam ser opcionais.
Mapper é a única fronteira DTO -> Domain: converte epoch para `Date`, valida números finitos, normaliza percentuais defensivamente e não deixa payload inválido contaminar o snapshot anterior. Sua API pública retorna `Result<UsageSnapshot, MappingError>`, não opcional — falha carrega o motivo técnico (nunca o conteúdo do payload) para quem chama decidir manter o snapshot anterior e logar com segurança.

## Persistência e privacidade
O payload bruto pode conter `cwd`, `transcript_path` e outros dados privados. Compartilhar com Widget APENAS `UsageSnapshot`; nunca payload bruto, paths completos ou transcript.
Sem analytics, API key ou logging de conteúdo. Rede restrita à consulta de uso autorizada; nunca persistir tokens no ClaudeUsage ou no App Group. Não seguir redirecionamentos. Usar `OSLog.Logger` apenas com mensagens técnicas seguras.

Usar App Group nos dois targets. Snapshot é pequeno: preferir `UserDefaults(suiteName:)` com `Data` de `JSONEncoder/JSONDecoder` e `schemaVersion`.
Não inventar App Group: verificar signing/Team ID. Preferir `group.` provisionado quando funcionar; macOS também aceita `<TeamID>.<group-name>` conforme Apple. Mesmo ID nos dois targets.
O app principal precisa ler o arquivo criado pelo shell fora do container. Na V1 local, não habilitar App Sandbox no target principal sem resolver explicitamente esse acesso. Widget Extension usa seu sandbox + App Group. Não adicionar exceções amplas de filesystem.

## StatusFileMonitor
- ler `latest.json` imediatamente no launch.
- observar o DIRETÓRIO, pois o arquivo é substituído atomicamente por rename.
- debounce de eventos rápidos; I/O/decoding fora da MainActor; atualização de UI na MainActor.
- se houver falha transitória, preservar último snapshot válido.
- arquivo inexistente é estado normal “aguardando dados”; sem polling frequente.

## Menu Bar
Usar SwiftUI `MenuBarExtra` como cena principal com `.menuBarExtraStyle(.window)` e `LSUIElement = true`.
Mostrar 5h e 7d com `% usado`, `% restante` e reset; contexto separado; modelo e última atualização quando disponíveis.
Label da barra deve ser curta e nunca chamar rate-limit de “tokens”.
Adicionar “Abrir ao iniciar sessão” via `SMAppService.mainApp`; não criar LaunchAgent manual.

## WidgetKit
Criar `.systemSmall` e `.systemMedium`.
TimelineProvider lê somente `SharedUsageStore`. App solicita reload após snapshot novo.
A timeline considera `resetsAt` para não manter percentual vencido como atual. WidgetKit não é tempo real; não prometer refresh imediato.
Adaptar light/dark e rendering modes; cores semânticas; SF Symbols; sem logo não autorizado; accessibility labels adequados.

## Estados obrigatórios
1. Sem arquivo: “Abra o Codex e envie uma mensagem para carregar o uso”.
2. Payload sem rate limits: “Limites ainda não disponíveis”.
3. Só uma janela disponível: renderizar a existente sem quebrar layout.
4. Dados normais: 5h/7d + contexto.
5. `resetsAt <= now`: não mostrar percentual antigo como atual; indicar reset/aguardar nova atualização.
6. Erro de decoding: manter último snapshot e logar somente erro técnico seguro.

## Convenções Swift
SwiftUI + Foundation/Observation; ViewModels de UI em `@MainActor`; async/await quando útil.
Nomes de código em inglês; UI em pt-BR preparada para String Catalog.
Sem `try!`; sem force unwrap salvo invariante comprovada/documentada.
Erros tipados em I/O. Constantes centralizadas; sem números mágicos.
Formatação de datas/tokens/percentuais pertence à apresentação, não ao Domain.
Views pequenas/declarativas; extrair subview só quando houver responsabilidade visual própria.
Nenhuma dependência externa na V1.

## Testes obrigatórios
Criar fixtures/testes para: payload completo; `rate_limits` ausente; cada janela ausente isoladamente; contexto null; campos desconhecidos; JSON inválido; epoch->Date; remaining%; percentuais anormais; reset passado; encode/decode do snapshot; Shared Store vazio.
Testes não dependem de Codex ativo, rede ou relógio real. Injetar `Date`/clock onde “agora” influenciar regra.

## Git
`.gitignore` deve incluir `.DS_Store`, `DerivedData/`, `xcuserdata/`, `.build/`, temporários/logs. Versionar schemes compartilhados necessários.
Nunca versionar credenciais, payload real ou configuração privada.
Commits pequenos por etapa. Nunca `git reset --hard`, apagar mudanças da usuária ou reescrever histórico sem pedido explícito.

## Build/validação
Antes de declarar etapa concluída: compilar App + Widget, rodar unit tests, corrigir warnings novos e confirmar que ambos usam o mesmo `UsageSnapshot`.
Comandos preferidos:
```bash
swift test --package-path Packages/ClaudeUsageCore
xcodebuild -project ClaudeUsage.xcodeproj -scheme ClaudeUsage -destination 'platform=macOS' build
xcodebuild -project ClaudeUsage.xcodeproj -scheme ClaudeUsage -destination 'platform=macOS' test
```
Não editar `project.pbxproj` às cegas. Se inevitável, mudança mínima e validação imediata com `xcodebuild -list` + build.

## Ordem de implementação
1. Validar `xcodebuild -version`, `swift --version`, `Codex --version` e estado do projeto/Git.
2. Configurar App target + Widget Extension + signing + App Group.
3. Criar `ClaudeUsageCore`, Domain, DTO, Mapper e testes.
4. Implementar SharedUsageStore + testes.
5. Implementar script com escrita atômica e configuração segura do statusline.
6. Implementar StatusFileMonitor e integração do MenuBarExtra.
7. Implementar Small/Medium Widget e reload da timeline.
8. Implementar Launch at Login.
9. Testar estados ausentes/parciais/reset e fazer revisão final de privacidade, arquitetura e warnings.
Não mascarar erro para avançar: corrigir a causa antes da próxima etapa.

## Critérios de aceite V1
- nova resposta do Codex atualiza a fonte local e o app a processa sem scraping.
- 5h/7d mostram usado/restante/reset quando disponíveis, sem inventar tokens de assinatura.
- contexto é claramente separado do rate limit.
- MenuBarExtra funciona como utilitário sem Dock; widgets Small/Medium leem o snapshot compartilhado.
- ausência/null/corrupção transitória não causa crash nem apaga último snapshot válido.
- shell nunca precisa acessar App Group; widget nunca lê payload bruto.
- rede somente para a consulta autorizada da conta; zero API key/telemetria/dependência externa.
- testes do Core passam e App/Widget compilam sem warnings novos.
- estrutura continua coerente com este documento.

## Regra de trabalho para Codex
Antes de criar arquivo/tipo/abstração, verificar se a responsabilidade já existe e justificar o problema concreto resolvido. Não overengineer.
Se esta especificação conflitar com API atual Apple/Anthropic, consultar documentação OFICIAL atual, explicar a divergência e seguir a API atual; nunca usar hack silencioso de signing/sandbox.
Após cada etapa significativa, informar objetivamente: arquivos alterados, o que mudou, como foi validado e pendências reais.
Prioridade: correção > simplicidade > manutenção > estética > micro-otimização.

## Compatibilidade verificada e entrega
- O produto acompanha Claude. A sincronização da conta permite consultar uso do Desktop e terminal sem statusLine; exige login OAuth válido da mesma conta. A coleta statusLine continua dependendo do terminal. Ver README.md.
- Ao concluir alterações solicitadas, executar as validações e fazer commit, informando o hash. Não enviar push sem pedido.
