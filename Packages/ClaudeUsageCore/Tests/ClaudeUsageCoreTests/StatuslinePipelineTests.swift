import Foundation
import Testing
import ClaudeUsageCore

@Suite("Statusline → arquivo → Mapper → Shared Store")
struct StatuslinePipelineTests {
    @Test("5h chega intacto ao store, inclusive com zero de uso", arguments: [0.0, 23.5])
    func fiveHourEndToEnd(usedPercentage: Double) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        var repository = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { repository.deleteLastPathComponent() }
        let script = repository.appendingPathComponent("Tools/claude-usage-statusline.sh")
        let statusDirectory = root.appendingPathComponent("status")
        let input = root.appendingPathComponent("input.json")
        let payload = Data("""
        {"model":{"display_name":"Sonnet 5"},"rate_limits":{
          "five_hour":{"used_percentage":\(usedPercentage),"resets_at":1800003600},
          "seven_day":{"used_percentage":20,"resets_at":1800345600}},"context_window":null}
        """.utf8)
        try payload.write(to: input)
        let inputHandle = try FileHandle(forReadingFrom: input)
        defer { try? inputHandle.close() }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [script.path]
        process.environment = ProcessInfo.processInfo.environment.merging([
            "CLAUDE_USAGE_STATUS_DIR": statusDirectory.path
        ]) { _, override in override }
        process.standardInput = inputHandle
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)

        let file = statusDirectory.appendingPathComponent("latest.json")
        let written = try Data(contentsOf: file)
        #expect(written == payload)
        let directoryMode = try FileManager.default.attributesOfItem(atPath: statusDirectory.path)[.posixPermissions] as? NSNumber
        let fileMode = try FileManager.default.attributesOfItem(atPath: file.path)[.posixPermissions] as? NSNumber
        #expect(directoryMode?.intValue == 0o700)
        #expect(fileMode?.intValue == 0o600)
        #expect(try FileManager.default.contentsOfDirectory(atPath: statusDirectory.path) == ["latest.json"])

        let snapshot = try ClaudeStatusMapper.map(
            jsonData: written, capturedAt: Date(timeIntervalSince1970: 1_800_000_000)
        ).get()
        let suite = "com.claudeusage.pipeline.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let store = try #require(SharedUsageStore(appGroupIdentifier: suite))
        try store.save(snapshot)
        let restored = try #require(store.loadLatestSnapshot(for: .sonnet))
        #expect(restored.fiveHour?.usedPercentage == usedPercentage)
        #expect(restored.fiveHour?.remainingPercentage == 100 - usedPercentage)
        #expect(restored.fiveHour?.resetsAt == Date(timeIntervalSince1970: 1_800_003_600))
        #expect(restored.sevenDay?.usedPercentage == 20)
        #expect(store.loadLatestSnapshot() == restored)

        let diagnostic = Process()
        diagnostic.executableURL = URL(fileURLWithPath: "/bin/zsh")
        diagnostic.arguments = [repository.appendingPathComponent("Tools/diagnose-statusline.sh").path]
        diagnostic.environment = process.environment
        let output = Pipe()
        diagnostic.standardOutput = output
        diagnostic.standardError = FileHandle.nullDevice
        try diagnostic.run()
        let report = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        diagnostic.waitUntilExit()
        #expect(diagnostic.terminationStatus == 0)
        #expect(report.contains("five_hour: percentual e reset numéricos presentes"))
        #expect(report.contains("seven_day: percentual e reset numéricos presentes"))
        #expect(!report.contains("JSON inválido"))
    }
}
