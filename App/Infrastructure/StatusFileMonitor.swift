import Foundation
import OSLog
import ClaudeUsageCore

/// Observa o DIRETÓRIO de status, não o arquivo: o shell script substitui
/// `latest.json` atomicamente via `mv` (rename), e um watch preso ao arquivo
/// antigo perderia esse evento assim que o inode trocasse.
///
/// I/O e decoding rodam numa fila serial dedicada, fora da MainActor.
/// `onSnapshotUpdate` é despachado explicitamente para a MainActor a cada
/// snapshot novo e válido. Falha transitória (arquivo ausente, JSON inválido)
/// nunca dispara `onSnapshotUpdate`: quem observa preserva o último snapshot.
final class StatusFileMonitor {
    private static let logger = Logger(subsystem: "com.paula.ClaudeUsage", category: "StatusFileMonitor")
    private static let debounceInterval: TimeInterval = 0.3

    var onSnapshotUpdate: (@MainActor (UsageSnapshot) -> Void)?

    private let statusDirectoryURL: URL
    private let statusFileURL: URL
    private let queue = DispatchQueue(label: "com.paula.ClaudeUsage.StatusFileMonitor")

    private var source: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?

    init(statusDirectoryURL: URL) {
        self.statusDirectoryURL = statusDirectoryURL
        self.statusFileURL = statusDirectoryURL.appendingPathComponent("latest.json")
    }

    deinit {
        source?.cancel()
    }

    /// Lê imediatamente (estado atual no launch) e passa a observar o diretório.
    func start() {
        queue.async { [weak self] in
            self?.readLatestSnapshot()
            self?.beginWatchingDirectory()
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.source?.cancel()
            self?.source = nil
            self?.debounceWorkItem?.cancel()
            self?.debounceWorkItem = nil
        }
    }

    private func beginWatchingDirectory() {
        guard source == nil else { return }

        // Diretório inexistente é normal (statusLine ainda não rodou); criamos
        // com 700 só para termos o que observar, mesma disciplina do script.
        try? FileManager.default.createDirectory(
            at: statusDirectoryURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )

        let fileDescriptor = open(statusDirectoryURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            Self.logger.error("Não foi possível observar o diretório de status.")
            return
        }

        let newSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: queue
        )
        newSource.setEventHandler { [weak self] in
            self?.scheduleDebouncedRead()
        }
        newSource.setCancelHandler {
            close(fileDescriptor)
        }
        newSource.resume()
        source = newSource
    }

    private func scheduleDebouncedRead() {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.readLatestSnapshot()
        }
        debounceWorkItem = workItem
        queue.asyncAfter(deadline: .now() + Self.debounceInterval, execute: workItem)
    }

    private func readLatestSnapshot() {
        guard let data = try? Data(contentsOf: statusFileURL) else {
            // Arquivo inexistente é o estado normal "aguardando dados"; falha
            // transitória de leitura preserva o último snapshot válido.
            return
        }

        switch ClaudeStatusMapper.map(jsonData: data, capturedAt: Date()) {
        case .success(let snapshot):
            let callback = onSnapshotUpdate
            Task { @MainActor in
                callback?(snapshot)
            }
        case .failure(let error):
            Self.logger.error("Falha ao decodificar status: \(String(describing: error), privacy: .public)")
        }
    }
}
