import SwiftUI

/// Primer inicio sin proveedor: se explica qué falta y se permite continuar
/// con las funciones locales. La conexión real de proveedores pertenece a 0006.
struct FirstRunView: View {
    @ObservedObject var model: FirstRunModel
    let onConfigureProvider: () -> Void
    let onContinueWithoutProvider: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Bienvenido a ActaVoz")
                .font(.largeTitle.bold())

            Text("ActaVoz graba, transcribe y organiza tus reuniones en este Mac. Las preguntas y los resúmenes necesitan un proveedor de modelos de lenguaje: puedes configurarlo ahora o más tarde.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 520)

            HStack(spacing: 16) {
                Button("Configurar un proveedor…", action: onConfigureProvider)
                Button("Continuar sin proveedor", action: onContinueWithoutProvider)
                    .keyboardShortcut(.defaultAction)
            }

            if model.showsProviderNotice {
                Text("Abre Ajustes → Proveedores para añadir una conexión. Sin proveedor puedes seguir usando las funciones locales.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }
        }
        .padding(48)
    }
}
