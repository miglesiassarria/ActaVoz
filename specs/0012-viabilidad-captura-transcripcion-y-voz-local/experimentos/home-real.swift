import Foundation
import Darwin

// Ejecutar solo de forma explícita: crea una carpeta de prueba en el home real.
// No modifica contenido preexistente ni elimina recursivamente la raíz .ActaVoz.
@main struct Probe {
    static func main() throws {
        let fm = FileManager.default
        let base = fm.homeDirectoryForCurrentUser.appendingPathComponent(".ActaVoz")
        let existia = fm.fileExists(atPath: base.path)
        let prueba = base.appendingPathComponent(".discovery-" + UUID().uuidString)
        if !existia { try fm.createDirectory(at: base, withIntermediateDirectories: false) }
        defer {
            try? fm.removeItem(at: prueba)
            // rmdir solo puede eliminar una carpeta vacía que este experimento creó.
            if !existia { _ = base.path.withCString { rmdir($0) } }
        }
        try fm.createDirectory(at: prueba, withIntermediateDirectories: false)
        let centinela = prueba.appendingPathComponent("centinela.txt")
        let contenido = Data("conservar".utf8)
        try contenido.write(to: centinela, options: .withoutOverwriting)
        for _ in 0..<2 {
            for name in ["Notas", "Directorios"] {
                try fm.createDirectory(at: prueba.appendingPathComponent(name), withIntermediateDirectories: true)
            }
        }
        guard try Data(contentsOf: centinela) == contenido else {
            throw NSError(domain: "ActaVozDiscovery", code: 1)
        }
        print("OK: escritura en .ActaVoz del home real, dos pasadas y centinela intacto")
        print("raiz_preexistente=\(existia)")
    }
}
