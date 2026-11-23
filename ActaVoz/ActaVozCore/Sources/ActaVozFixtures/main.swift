import Foundation
import ActaVozCore

/// Genera una biblioteca de ejemplo para revisar la interfaz sin datos reales.
/// Uso: swift run ActaVozFixtures <ruta-raiz> [--reset]
@main
struct Fixtures {
    static func main() {
        do {
            try run()
        } catch {
            FileHandle.standardError.write(Data("No se pudo crear la biblioteca: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    static func run() throws {
        var arguments = Array(CommandLine.arguments.dropFirst())
        let reset = arguments.contains("--reset")
        arguments.removeAll { $0 == "--reset" }

        guard let path = arguments.first else {
            FileHandle.standardError.write(Data("Uso: ActaVozFixtures <ruta-raiz> [--reset]\n".utf8))
            exit(64)
        }

        let root = URL(fileURLWithPath: path, isDirectory: true)
        try prepareRoot(root, reset: reset)

        let repository = SessionRepository(root: root)
        try repository.createDirectory(named: "Clientes")

        let calendar = Calendar(identifier: .gregorian)
        let today = Date()

        // Sesión sin organizar con transcripción, resumen y chat.
        let product = try repository.createSession(
            in: .inbox,
            startDate: calendar.date(byAdding: .hour, value: -3, to: today) ?? today,
            language: .spanish
        )
        let ana = Participant(id: "p1", name: "Ana")
        let luis = Participant(id: "p2", name: "Luis")
        try repository.updateParticipants([ana, luis], at: product.folderURL)
        try repository.updateTitle("Reunión de producto", at: product.folderURL)
        try repository.writeTranscript(
            Transcript(language: .spanish, segments: [
                TranscriptSegment(id: "s1", start: 0, end: 4.2, speakerId: "p1", text: "Revisemos el presupuesto del trimestre."),
                TranscriptSegment(id: "s2", start: 4.2, end: 9.5, speakerId: "p2", text: "Propongo cerrarlo antes del viernes."),
                TranscriptSegment(id: "s3", start: 9.5, end: 12.0, speakerId: "p1", text: "De acuerdo, lo confirmo con dirección.")
            ]),
            at: product.folderURL
        )
        try repository.writeSummary(
            "# Resumen general\n\n## Síntesis breve\nSe acordó cerrar el presupuesto antes del viernes.\n\n## Temas tratados\n- Presupuesto del trimestre.\n",
            at: product.folderURL
        )
        try repository.writeNotes("# Mis notas\n\nConfirmar con dirección antes del jueves.", at: product.folderURL)
        try repository.writeChat(
            ChatHistory(messages: [
                ChatMessage(id: "m1", role: .user, text: "¿Qué se decidió?", createdAt: today),
                ChatMessage(id: "m2", role: .assistant, text: "Cerrar el presupuesto antes del viernes.", createdAt: today)
            ]),
            at: product.folderURL
        )

        // Sesión de ayer, sin resumen todavía.
        let reflexion = try repository.createSession(
            in: .inbox,
            startDate: calendar.date(byAdding: .day, value: -1, to: today) ?? today
        )
        try repository.updateTitle("Reflexión sobre el trimestre", at: reflexion.folderURL)
        try repository.writeNotes("# Ideas\n\nSimplificar la propuesta comercial.", at: reflexion.folderURL)

        // Sesión organizada en un directorio.
        let clientes = try repository.createSession(
            in: .directory("Clientes"),
            startDate: calendar.date(byAdding: .day, value: -3, to: today) ?? today
        )
        try repository.updateTitle("Reunión con Clientes", at: clientes.folderURL)
        try repository.updateParticipants([Participant(id: "p1", name: "Marta")], at: clientes.folderURL)
        try repository.writeSummary("# Reunión de trabajo\n\n## Decisiones\n- Renovar el contrato anual.\n", at: clientes.folderURL)

        print("Biblioteca de ejemplo creada en \(root.path)")
        for summary in try repository.allSessions() {
            print("- \(summary.location): \(summary.title)")
        }
    }

    /// Solo escribe en una ruta vacía, nueva o marcada con --reset.
    private static func prepareRoot(_ root: URL, reset: Bool) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: root.path) {
            let contents = (try? fileManager.contentsOfDirectory(atPath: root.path)) ?? []
            if !contents.isEmpty {
                guard reset else {
                    FileHandle.standardError.write(Data("La ruta ya tiene contenido. Usa --reset o elige otra ruta.\n".utf8))
                    exit(73)
                }
                try fileManager.removeItem(at: root)
            }
        }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        try SettingsStore(fileURL: root.appendingPathComponent("Config/config.json"))
            .save(AppConfiguration(hasCompletedFirstRun: true))
        try DirectoryPreparer().prepare(
            StorageLocations(
                root: root,
                configurationDirectory: root.appendingPathComponent("Config", isDirectory: true),
                cachesDirectory: root.appendingPathComponent("Caches", isDirectory: true)
            )
        )
    }
}
