import Foundation

/// Valida o contrato comum das transações extraídas.
final class ValidadorTransacaoExtraida {
    /// Validar uma transação extraída de qualquer fonte financeira.
    func validar(_ transacao: DadosTransacaoExtraida) throws {
        try validarNumeroLinha(transacao.numeroLinha)
        try validarTexto("conta", transacao.conta)
        try validarTexto("descricao_original", transacao.descricaoOriginal)
        try validarMoeda("moeda", transacao.moeda)
        try validarTexto("tipo_transacao", transacao.tipoTransacao)
        try validarMoeda("moeda_local", transacao.moedaLocal)
        try validarTexto("origem", transacao.origem)

        guard !transacao.dadosBrutos.isEmpty else {
            throw ErroImportacao.transacaoInvalida(
                "Dados brutos da transação devem estar preenchidos."
            )
        }
    }

    private func validarNumeroLinha(_ numeroLinha: Int) throws {
        guard numeroLinha >= 0 else {
            throw ErroImportacao.transacaoInvalida("Número da linha não pode ser negativo.")
        }
    }

    private func validarTexto(_ nomeCampo: String, _ valor: String) throws {
        guard !valor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ErroImportacao.transacaoInvalida("O campo \(nomeCampo) deve estar preenchido.")
        }
    }

    private func validarMoeda(_ nomeCampo: String, _ valor: String) throws {
        try validarTexto(nomeCampo, valor)

        guard valor.count == 3, valor.allSatisfy(\.isLetter) else {
            throw ErroImportacao.transacaoInvalida(
                "O campo \(nomeCampo) deve conter uma moeda ISO de três letras."
            )
        }
    }
}
