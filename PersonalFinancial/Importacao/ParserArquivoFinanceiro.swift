import Foundation

/// Contrato comum para parsers de arquivos financeiros.
protocol ParserArquivoFinanceiro {
    func extrair() throws -> [RegistroBruto]
    func extrairTransacoes() throws -> [DadosTransacaoExtraida]
}

/// Cria parsers financeiros a partir da origem informada.
final class ParserArquivoFactory {
    /// Criar parser para a origem financeira.
    func criar(origem: String, urlArquivo: URL) throws -> ParserArquivoFinanceiro {
        let codigo = origem.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch codigo {
        case "aib_csv":
            return AibCsvParser(urlArquivo: urlArquivo)
        case "revolut_pdf":
            throw ErroImportacao.origemNaoSuportada(
                "Importação Revolut PDF ainda não foi implementada no app."
            )
        default:
            throw ErroImportacao.origemNaoSuportada(
                "Origem de arquivo financeiro não suportada: \(origem)."
            )
        }
    }
}
