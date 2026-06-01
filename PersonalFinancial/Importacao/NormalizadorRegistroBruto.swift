import Foundation

/// Normaliza dados brutos extraídos por parsers financeiros.
final class NormalizadorRegistroBruto {
    private let formatadorAIB: DateFormatter

    init() {
        formatadorAIB = DateFormatter()
        formatadorAIB.calendar = Calendar(identifier: .gregorian)
        formatadorAIB.locale = Locale(identifier: "en_US_POSIX")
        formatadorAIB.dateFormat = "dd/MM/yyyy"
    }

    /// Normalizar chaves sem alterar valores.
    func normalizarDados(_ dados: [String: String]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: dados.map { chave, valor in
            (chave.trimmingCharacters(in: .whitespacesAndNewlines), valor)
        })
    }

    /// Converter data textual do AIB.
    func parseDataAIB(numeroLinha: Int, valor: String) throws -> Date {
        let valorLimpo = valor.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = formatadorAIB.date(from: valorLimpo) else {
            throw ErroImportacao.csvInvalido(
                "Data inválida na linha \(numeroLinha): \(valor)."
            )
        }

        return data
    }

    /// Converter valor monetário textual para `Decimal`.
    func parseDecimal(numeroLinha: Int, nomeCampo: String, valor: String) throws -> Decimal {
        let valorLimpo = valor
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: ",", with: "")

        guard !valorLimpo.isEmpty, let decimal = Decimal(string: valorLimpo) else {
            throw ErroImportacao.csvInvalido(
                "Valor inválido no campo \(nomeCampo), linha \(numeroLinha): \(valor)."
            )
        }

        return decimal
    }

    /// Calcular valor assinado a partir de débito ou crédito.
    func calcularValorDebitoCredito(
        numeroLinha: Int,
        debito: String,
        credito: String
    ) throws -> Decimal {
        let debitoLimpo = debito.trimmingCharacters(in: .whitespacesAndNewlines)
        let creditoLimpo = credito.trimmingCharacters(in: .whitespacesAndNewlines)

        guard debitoLimpo.isEmpty != creditoLimpo.isEmpty else {
            throw ErroImportacao.csvInvalido(
                "A linha \(numeroLinha) deve possuir débito ou crédito, nunca ambos ou nenhum."
            )
        }

        if !debitoLimpo.isEmpty {
            return try -parseDecimal(numeroLinha: numeroLinha, nomeCampo: "débito", valor: debitoLimpo)
        }

        return try parseDecimal(numeroLinha: numeroLinha, nomeCampo: "crédito", valor: creditoLimpo)
    }

    /// Montar descrição original com partes não vazias.
    func montarDescricaoOriginal(_ partes: [String]) -> String {
        partes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
    }

    /// Normalizar descrição para comparação determinística.
    func normalizarDescricao(_ descricao: String) -> String {
        descricao
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }
}
