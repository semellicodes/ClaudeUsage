import Foundation

// Diagnóstico somente leitura do formato observado no macOS 26.6.
// Formato interno: se mudar, falhar explicitamente em vez de declarar sucesso.
// Uso: swift Tools/check-widget-archives.swift <diretório de snapshots/timelines>
guard CommandLine.arguments.count == 2 else {
    fatalError("Informe o diretório de arquivos visuais do WidgetKit")
}
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let signature = Data("bplist00".utf8)
guard let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
    fatalError("Diretório indisponível")
}
var checked = 0
var failures = 0
for case let file as URL in files where file.pathExtension == "chrono-timeline" {
    guard file.lastPathComponent.hasPrefix("systemSmall") || file.lastPathComponent.hasPrefix("systemMedium") else { continue }
    let data = try Data(contentsOf: file)
    var dimensions: [NSNumber]?
    if let start = data.range(of: signature)?.lowerBound, data.count > start + 40 {
        for end in (start + 40)...min(data.count, start + 2048) {
            if let plist = try? PropertyListSerialization.propertyList(from: data.subdata(in: start..<end), format: nil),
               let objects = plist as? [[String: Any]],
               let size = objects.first?["size"] as? [NSNumber] {
                dimensions = size
                break
            }
        }
    }
    checked += 1
    let valid = dimensions?.count == 2 && dimensions?.allSatisfy { $0.doubleValue.isFinite && $0.doubleValue > 0 } == true
    if !valid { failures += 1 }
    print("\(valid ? "OK" : "FALHA") \(file.deletingLastPathComponent().lastPathComponent)/\(file.lastPathComponent.components(separatedBy: "----")[0]): \(dimensions?.description ?? "formato não reconhecido")")
}
guard checked > 0, failures == 0 else {
    fputs("Verificação reprovada: \(failures) inválidos em \(checked) arquivos.\n", stderr)
    exit(1)
}
print("\(checked) arquivos com dimensões finitas. Isso não substitui a inspeção visual no desktop.")
