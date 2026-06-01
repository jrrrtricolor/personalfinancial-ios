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
        let json = try serializarJsonCanonico(conteudo)
        let dados = Data(json.utf8)

        return SHA256.hash(data: dados).map { String(format: "%02x", $0) }.joined()
    }

    private func serializarJsonCanonico(_ valor: Any) throws -> String {
        if let dicionario = valor as? [String: Any] {
            return try serializarDicionario(dicionario)
        }

        if let texto = valor as? String {
            return serializarTexto(texto)
        }

        if let inteiro = valor as? Int {
            return String(inteiro)
        }

        throw ErroImportacao.csvInvalido("Valor não suportado para hash JSON.")
    }

    private func serializarDicionario(_ dicionario: [String: Any]) throws -> String {
        let pares = try dicionario.keys.sorted().map { chave in
            let valor = try serializarJsonCanonico(dicionario[chave] as Any)
            return "\(serializarTexto(chave)):\(valor)"
        }

        return "{\(pares.joined(separator: ","))}"
    }

    private func serializarTexto(_ texto: String) -> String {
        let dados = try? JSONSerialization.data(withJSONObject: [texto])
        let json = dados.flatMap { String(data: $0, encoding: .utf8) } ?? "[\"\"]"
        let inicio = json.index(after: json.startIndex)
        let fim = json.index(before: json.endIndex)

        return String(json[inicio..<fim])
            .replacingOccurrences(of: "\\/", with: "/")
    }
}
