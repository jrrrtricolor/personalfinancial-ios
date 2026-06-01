import CryptoKit
import Foundation

/// Calcula hashes determinísticos usados na importação financeira.
final class HashFinanceiro {
    /// Calcular SHA-256 do arquivo importado.
    func calcularHashArquivo(url: URL) throws -> String {
        let dados = try Data(contentsOf: url)
        return SHA256.hash(data: dados).map { String(format: "%02x", $0) }.joined()
    }

    /// Calcular SHA-256 determinístico de um registro bruto.
    func calcularHashRegistro(_ registro: RegistroBruto) throws -> String {
        let conteudo: [String: Any] = [
            "numero_linha": registro.numeroLinha,
            "numero_pagina": registro.numeroPagina,
            "secao": registro.secao,
            "dados": registro.dados,
        ]

        return try calcularHashJson(conteudo)
    }

    /// Calcular SHA-256 de conteúdo JSON com chaves ordenadas.
    func calcularHashJson(_ conteudo: [String: Any]) throws -> String {
        let dados = try JSONSerialization.data(
            withJSONObject: conteudo,
            options: [.sortedKeys]
        )

        return SHA256.hash(data: dados).map { String(format: "%02x", $0) }.joined()
    }
}
