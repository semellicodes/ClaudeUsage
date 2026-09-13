import AppKit
import SwiftUI
import WidgetKit
import ClaudeUsageCore

/// Teste de integração visual local. Não substitui a validação dos arquivos do WidgetKit.
@main
struct WidgetRenderCheck {
    @MainActor static func main() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let size = CGSize(width: 344, height: 164)
        let preview = UsageEntry.preview(at: now, size: size)
        let empty = UsageEntry(date: now, snapshot: nil, displaySize: size)
        let zero = UsageEntry(date: now, snapshot: UsageSnapshot(
            schemaVersion: 1, capturedAt: now, claudeCodeVersion: nil,
            sessionID: nil, modelDisplayName: nil,
            fiveHour: RateLimit(usedPercentage: 0, resetsAt: nil),
            sevenDay: nil, context: nil, source: .account), displaySize: size)
        let timeline = UsageTimelineProvider.makeTimeline(for: preview)
        precondition(timeline.entries.count == 3)
        precondition(timeline.entries.map(\.date) == timeline.entries.map(\.date).sorted())
        precondition(UsageTimelineProvider.makeTimeline(for: empty).entries.count == 1)
        guard let expired = timeline.entries.last else { preconditionFailure("Timeline vazia") }
        let entries = [preview, empty, zero, expired]
        let rows = entries.map { entry in
            HStack(spacing: 12) {
                SmallWidgetView(entry: UsageEntry(date: entry.date, snapshot: entry.snapshot,
                    displaySize: CGSize(width: 164, height: 164)))
                    .frame(width: 164, height: 164)
                MediumWidgetView(entry: entry)
                    .frame(width: 344, height: 164)
            }
        }
        let view = VStack(spacing: 12) {
            ForEach(rows.indices, id: \.self) { rows[$0] }
        }
        .padding(12)
        .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.cgImage else { preconditionFailure("Renderização vazia") }
        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            preconditionFailure("Imagem inválida")
        }
        try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
        print("Providers: entries ordenadas, resets e ausência de dados OK. Oito views renderizadas para inspeção.")
    }
}
