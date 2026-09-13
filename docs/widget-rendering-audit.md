# Auditoria da renderização — 13/09/2026

## Causa raiz

**CRÍTICO, confirmado:** `Text(timerInterval:countsDown:)` combinado com
`.fixedSize()` gerava largura `NaN` nas camadas arquivadas pelo WidgetKit neste
macOS. O problema ocorria em `Widget/Views/SmallWidgetView.swift` e
`Widget/Views/UsageColumnsRow.swift`. O host recebia arquivos, mas não conseguia
apresentar o conteúdo corretamente. Descoberta da extensão, metadados e sucesso
do provider não constituíam validação de renderização.

## Evidências e comparação controlada

- A imagem fornecida mostrava os nomes, descrições e quatro famílias/configurações,
  enquanto todas as regiões visuais estavam pretas.
- O processo da extensão concluía snapshots com `success`; não foi localizado
  relatório de crash da extensão na inspeção realizada.
- A leitura dos arquivos visuais revelou `size: [nan, 164]` nas prévias Small e
  Medium, tanto no widget legado quanto no configurável. O tamanho esperado
  informado pelo host era 164 × 164 ou 344 × 164.
- A alteração A/B removeu somente as duas chamadas a `.fixedSize()` dos contadores.
  Não alterou cores, espaçamentos, providers, App Group ou dados.
- Depois da instalação dessa alteração, os quatro previews foram inspecionados
  na galeria real: cabeçalhos, anéis, percentuais e contadores estavam visíveis.
- A verificação posterior dos seis arquivos de snapshot encontrou somente
  dimensões finitas: 164 × 164 e 344 × 164. Antes, a mesma ferramenta identificou
  quatro arquivos inválidos dentre seis.

A conclusão é específica à combinação de contador e sizing observada neste
ambiente. Não implica que todo uso de `.fixedSize()` seja incorreto. O ajuste
anterior de preservação do fundo não resolveu essa causa.

## Arquitetura e targets

| Componente | Responsabilidade e resultado da auditoria |
| --- | --- |
| `ClaudeUsage` | App macOS, `MenuBarExtra`, `LSUIElement`, um `@main` em `App/ClaudeUsageApp.swift`. Sem App Sandbox para acesso ao statusLine local. |
| `ClaudeUsageWidgetExtension` | Uma extensão WidgetKit, sandbox habilitado, um `@main`/`WidgetBundle` em `Widget/ClaudeUsageWidget.swift`. |
| `ClaudeUsageCore` | Pacote local usado por ambos: Domain, DTO/mappers, cliente da conta, credenciais e persistência. Não há cópias dos modelos nos targets. |
| Membership | Grupos sincronizados `App` e `Widget` associados aos respectivos targets; `Widget/Info.plist` excluído das fontes. O app incorpora uma única extensão. |
| Kinds | `ClaudeUsageWidget` usa `StaticConfiguration`; `ClaudeUsageConfigurableWidget` usa `AppIntentConfiguration`. Cada um registrado uma vez, com Small/Medium. |
| Signing | Team `3U9MRVV4FR`; bundle IDs `com.paula.ClaudeUsage` e `com.paula.ClaudeUsage.ClaudeUsageWidget`. |
| App Group | Ambos os entitlements usam `$(TeamIdentifierPrefix)claudeusage`, resolvido para `3U9MRVV4FR.claudeusage`, idêntico aos literais do app e provider. |
| Info.plist | App gerado pelo build; extensão declara `com.apple.widgetkit-extension`. Não há segundo bundle ou principal class concorrente. |

## Fluxo de dados e timeline

1. `ClaudeAccountClient` consulta o endpoint de uso usando o login existente.
   `ClaudeOAuthCredentials` lê o Chaves somente no fluxo do app. O statusLine
   opcional grava atomicamente; `StatusFileMonitor` observa o diretório.
2. DTOs/mappers validam os dados e produzem `UsageSnapshot`.
3. `MenuBarViewModel` salva pelo `SharedUsageStore`, baseado em
   `UserDefaults(suiteName:)`, e solicita reload dos dois kinds.
4. Os providers leem o mesmo store. A galeria/placeholder usa a entrada de
   demonstração; esse caminho não depende de rede, credenciais ou arquivo real.
5. `UsageEntry` alimenta as views compartilhadas. Sempre há entrada inicial;
   ausência de snapshot mostra uma mensagem. Resets futuros geram entradas
   ordenadas, e resets vencidos não apresentam o percentual antigo como atual.
6. WidgetKit arquiva as views e o host as apresenta. Foi nesta etapa visual que
   a largura inválida se manifestou.

Não foi encontrada chamada assíncrona de rede bloqueando o provider, view vazia
em caso de erro, família sem implementação ou acesso ao Chaves nas views. Falhas
de coleta preservam a leitura anterior. A política `.never` depende do app para
receber novos dados; as entradas futuras apenas atualizam a apresentação do reset.

## Achados secundários

| Gravidade | Achado | Evidência, impacto e encaminhamento |
| --- | --- | --- |
| ALTO | Instalações duplicadas | PlugInKit listou três cópias do mesmo bundle ID: DerivedData habitual e diretórios temporários `ClaudeUsage-layout-build`/`ClaudeUsage-review-build`. O processo inspecionado usava a cópia atual. É uma ambiguidade real de instalação, mas não a causa demonstrada do preto. Usar um caminho de instalação estável e conferir o executável ativo; não apagar DerivedData ou caches indiscriminadamente. |
| MÉDIO | Validação anterior insuficiente | Os 38 testes do Core não exercitam o arquivamento de views. Foram acrescentados diagnóstico dos arquivos e renderização local, mantendo inspeção real como critério separado. |
| MÉDIO | TestAction vazio | O scheme principal não declara Testables. Executar os testes do pacote com `swift test`; não apresentar `xcodebuild test` como aprovado. |
| MÉDIO | Vida do processo | Um app aberto via LaunchServices não é necessariamente encerrado ao parar outra execução no Xcode. Múltiplas cópias podem explicar ícones/executáveis persistentes; não foi observado mais de um processo principal simultâneo na inspeção. |
| BAIXO | Template multiplataforma | O target principal ainda declara plataformas iOS/visionOS. Não causou a falha macOS e não foi alterado nesta correção. |
| BAIXO | Constantes repetidas | App Group/kinds aparecem em mais de um ponto, mas os valores comparados coincidem. Sem refatoração não relacionada ao defeito. |

## Concorrência e limites da revisão

App/Widget usam Swift 5 language mode com isolamento padrão MainActor e
Approachable Concurrency; o pacote usa Swift 6. `MenuBarViewModel` é MainActor,
o cliente de conta é actor, e os modelos são Sendable. `SharedUsageStore` declara
`@unchecked Sendable` com a justificativa de thread safety de UserDefaults.
O monitor usa fila serial para I/O e entrega à MainActor. Não foram silenciados
warnings nem alteradas configurações de concorrência para obter o build.
Isso não equivale a uma prova formal de ausência de condições de corrida.

## Validação reproduzível

```sh
swift test --package-path Packages/ClaudeUsageCore
xcodebuild -project ClaudeUsage.xcodeproj -scheme ClaudeUsage -destination 'platform=macOS' build
xcodebuild -project ClaudeUsage.xcodeproj -scheme ClaudeUsageWidgetExtension -destination 'platform=macOS' build
zsh Tools/check-widget-rendering.sh /tmp/ClaudeUsage-render-check.png
swift Tools/check-widget-archives.swift "$HOME/Library/Containers/com.paula.ClaudeUsage.ClaudeUsageWidget/Data/SystemData/com.apple.chrono/snapshots"
```

Build completo e build separado pelo scheme da extensão aprovados; 38 testes
do Core aprovados. O teste local produziu oito views para prévia, ausência de
dados, zero sem reset e janelas vencidas. Os quatro previews reais foram
verificados visualmente. Nenhum warning novo nos builds aprovados.

A tentativa de build isolado por `-target`, sem destino, falhou ao resolver o
pacote e emitiu warnings de arquitetura; o comando pelo scheme acima resolveu
as dependências e passou. O diagnóstico de archives é somente leitura e usa
o formato interno observado no macOS 26.6: falha explicitamente se não reconhecer
o formato. Não faz parte do runtime do produto nem substitui inspeção visual.

## Entrega e pendências

A correção está registrada em `0089808`, incluindo o mesmo padrão no menu;
as ferramentas em `e08174a`. Esses commits posteriores à investigação foram
preservados. Não houve reescrita de histórico ou alterações em credenciais.

O defeito visual reproduzido foi corrigido. A organização das instalações foi
concluída separadamente, conforme o registro abaixo. Permanece como manutenção
separada a redução das plataformas do template.
Login OAuth vencido continua sendo um problema distinto de coleta, sinalizado
pelo app; não deve ser confundido com falha de renderização.

## Consolidação das instalações — 13/09/2026

- Instalação de uso diário: `~/Applications/ClaudeUsage.app`, com a build mais
  recente validada por `codesign --verify --deep --strict`.
- As três cópias registradas anteriormente foram arquivadas em
  `~/Library/Application Support/ClaudeUsage/InstallationBackups/2026-09-13/`.
  Os ZIPs `xcode-installed.zip`, `review-build.zip` e `layout-build.zip` passaram
  por `unzip -tq` antes da remoção dos bundles duplicados.
- Foram retirados os registros dessas três cópias do PlugInKit e LaunchServices;
  somente seus bundles `.app` foram removidos. Código-fonte, demais produtos de
  build, App Group, preferências, dados e credenciais foram preservados.
- PlugInKit passou de três registros para um, apontando para `~/Applications`.
  O app foi reaberto a partir desse caminho estável.

Para uso diário, abra a instalação em `~/Applications`. `Cmd+R` no Xcode executa
uma build de desenvolvimento separada e pode registrá-la novamente. Ao validar
uma versão nova, substitua a instalação estável com o app encerrado, confira a
assinatura e retire apenas o registro/bundle de desenvolvimento que não será
mais usado. Não limpe caches globais do WidgetKit nem restaure ZIPs de backup
como instalações paralelas.
