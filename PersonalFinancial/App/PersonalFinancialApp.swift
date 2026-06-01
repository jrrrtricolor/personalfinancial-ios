import SwiftUI

/// Ponto de entrada do app PersonalFinancial.
@main
struct PersonalFinancialApp: App {
    var body: some Scene {
        WindowGroup {
            TelaImportacaoArquivos()
                .frame(minWidth: 720, minHeight: 520)
        }
    }
}
