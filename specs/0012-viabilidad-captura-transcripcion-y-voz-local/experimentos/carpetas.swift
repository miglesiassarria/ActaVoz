import Foundation

// Experimento aislado: no usa el home real ni código de producción.
@main struct Probe {
    static func main() throws {
        let fm = FileManager.default
        let homeDePrueba = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: homeDePrueba, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: homeDePrueba) }
        let base = homeDePrueba.appendingPathComponent(".ActaVoz")
        func preparar() throws {
            for name in ["Notas", "Directorios"] {
                try fm.createDirectory(at: base.appendingPathComponent(name), withIntermediateDirectories: true)
            }
        }
        try preparar()
        let centinela = base.appendingPathComponent("Notas/centinela.txt")
        try Data("conservar".utf8).write(to: centinela)
        try preparar()
        guard try Data(contentsOf: centinela) == Data("conservar".utf8) else {
            throw NSError(domain: "ActaVozDiscovery", code: 1)
        }
        print("OK: carpetas creadas dos veces y centinela intacto en home simulado")
    }
}
