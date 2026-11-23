import Foundation
import ActaVozCore

/// Genera una biblioteca de ejemplo para revisar la interfaz sin datos reales.
/// Uso: swift run ActaVozFixtures <ruta-raiz>
@main
struct Fixtures {
    static func main() throws {
        guard CommandLine.arguments.count > 1 else {
            FileHandle.standardError.write(Data("Uso: ActaVozFixtures <ruta-raiz>\n".utf8))
            exit(64)
        }
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let repository = SessionRepository(root: root)
        try DirectoryPreparer().prepare(
            StorageLocations(
                root: root,
                configurationDirectory: root.appendingPathComponent("Config", isDirectory: true),
                cachesDirectory: root.appendingPathComponent("Caches", isDirectory: true)
            )
        )
        // Marca el primer inicio como completado para que la app abra la biblioteca.
        try SettingsStore(fileURL: root.appendingPathComponent("Config/config.json"))
            .save(AppConfiguration(hasCompletedFirstRun: true))

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
}
