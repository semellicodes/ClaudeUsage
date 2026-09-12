import AppIntents
import ClaudeUsageCore

enum WidgetModelSelection: String, AppEnum {
    case automatic, sonnet, opus

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Modelo"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .automatic: "Automático (última leitura)", .sonnet: "Sonnet", .opus: "Opus"
    ]

    var usageModel: UsageModel? {
        switch self {
        case .automatic: nil
        case .sonnet: .sonnet
        case .opus: .opus
        }
    }

    var name: String? {
        switch self {
        case .automatic: nil
        case .sonnet: "Sonnet"
        case .opus: "Opus"
        }
    }
}

enum WidgetWindowSelection: String, AppEnum {
    case fiveHour, sevenDay

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Janela"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .fiveHour: "5 horas", .sevenDay: "7 dias"
    ]
}

struct WidgetSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Uso do Claude"
    static var description = IntentDescription(
        "Na sincronização da conta, 5h é compartilhado. O semanal usa o limite do modelo quando disponível; caso contrário, usa o geral da conta."
    )

    @Parameter(title: "Modelo", default: .automatic)
    var model: WidgetModelSelection

    @Parameter(title: "Limite no widget pequeno", default: .fiveHour)
    var window: WidgetWindowSelection
}
