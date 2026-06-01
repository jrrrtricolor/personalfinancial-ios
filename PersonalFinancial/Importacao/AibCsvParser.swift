import Foundation

/// Extrai registros brutos de arquivos CSV do AIB.
final class AibCsvParser: ParserArquivoFinanceiro {
    private let urlArquivo: URL
    private let normalizador: NormalizadorRegistroBruto
    private let validador: ValidadorTransacaoExtraida

    private let colunasObrigatorias = [
        "Posted Account",
        "Posted Transactions Date",
        "Description1",
        "Description2",
        "Description3",
        "Debit Amount",
        "Credit Amount",
        "Balance",
        "Posted Currency",
        "Transaction Type",
        "Local Currency Amount",
        "Local Currency",
    ]

    private let tiposTransacaoSuportados = [
        "ATM",
        "Credit",
        "Debit",
        "Direct Debit",
    ]

    init(
        urlArquivo: URL,
        normalizador: NormalizadorRegistroBruto = NormalizadorRegistroBruto(),
        validador: ValidadorTransacaoExtraida = ValidadorTransacaoExtraida()
    ) {
        self.urlArquivo = urlArquivo
        self.normalizador = normalizador
        self.validador = validador
    }

    /// Extrair registros brutos do CSV do AIB.
    func extrair() throws -> [RegistroBruto] {
        let linhas = try lerLinhas()

        return try linhas.map { numeroLinha, linha in
            try RegistroBruto(numeroLinha: numeroLinha, secao: "aib_csv", dados: linha)
        }
    }

    /// Extrair transações estruturadas do CSV do AIB.
    func extrairTransacoes() throws -> [DadosTransacaoExtraida] {
        let linhas = try lerLinhas()

        return try linhas.map { numeroLinha, linha in
            try mapearTransacao(numeroLinha: numeroLinha, linha: linha)
        }
    }

    private func lerLinhas() throws -> [(Int, [String: String])] {
        guard FileManager.default.fileExists(atPath: urlArquivo.path) else {
            throw ErroImportacao.arquivoNaoEncontrado(urlArquivo)
        }

        let conteudo = try String(contentsOf: urlArquivo, encoding: .utf8)
        let delimitador = detectarDelimitador(conteudo)
        let linhasCsv = parseCsv(conteudo, delimitador: delimitador)

        guard let cabecalho = linhasCsv.first else {
            throw ErroImportacao.csvInvalido("O CSV do AIB está vazio.")
        }

        let colunas = cabecalho.enumerated().map { indice, coluna in
            limparCabecalho(coluna, removerBOM: indice == 0)
        }
        try validarColunas(colunas)
        return montarLinhas(colunas: colunas, linhas: Array(linhasCsv.dropFirst()))
    }

    private func validarColunas(_ colunas: [String]) throws {
        let ausentes = colunasObrigatorias.filter { !colunas.contains($0) }

        guard ausentes.isEmpty else {
            throw ErroImportacao.csvInvalido(
                "O CSV do AIB não possui colunas obrigatórias: \(ausentes.joined(separator: ", "))."
            )
        }
    }

    private func montarLinhas(
        colunas: [String],
        linhas: [[String]]
    ) -> [(Int, [String: String])] {
        linhas.enumerated().map { indice, valores in
            let dados = Dictionary(uniqueKeysWithValues: colunas.enumerated().map { colunaIndice, coluna in
                (coluna, colunaIndice < valores.count ? valores[colunaIndice] : "")
            })
            return (indice + 2, normalizador.normalizarDados(dados))
        }
    }

    private func mapearTransacao(
        numeroLinha: Int,
        linha: [String: String]
    ) throws -> DadosTransacaoExtraida {
        try validarTipoTransacao(numeroLinha: numeroLinha, tipo: linha["Transaction Type", default: ""])

        let transacao = try criarTransacao(numeroLinha: numeroLinha, linha: linha)
        try validador.validar(transacao)
        return transacao
    }

    private func criarTransacao(
        numeroLinha: Int,
        linha: [String: String]
    ) throws -> DadosTransacaoExtraida {
        let descricao = normalizador.montarDescricaoOriginal([
            linha["Description1", default: ""],
            linha["Description2", default: ""],
            linha["Description3", default: ""],
        ])

        return DadosTransacaoExtraida(
            numeroLinha: numeroLinha,
            conta: linha["Posted Account", default: ""].trimmingCharacters(in: .whitespacesAndNewlines),
            dataTransacao: try normalizador.parseDataAIB(numeroLinha: numeroLinha, valor: linha["Posted Transactions Date", default: ""]),
            descricaoOriginal: descricao,
            valor: try normalizador.calcularValorDebitoCredito(numeroLinha: numeroLinha, debito: linha["Debit Amount", default: ""], credito: linha["Credit Amount", default: ""]),
            moeda: linha["Posted Currency", default: ""].trimmingCharacters(in: .whitespacesAndNewlines),
            saldo: try normalizador.parseDecimal(numeroLinha: numeroLinha, nomeCampo: "Balance", valor: linha["Balance", default: ""]),
            tipoTransacao: linha["Transaction Type", default: ""].trimmingCharacters(in: .whitespacesAndNewlines),
            valorLocal: try normalizador.parseDecimal(numeroLinha: numeroLinha, nomeCampo: "Local Currency Amount", valor: linha["Local Currency Amount", default: ""]),
            moedaLocal: linha["Local Currency", default: ""].trimmingCharacters(in: .whitespacesAndNewlines),
            origem: "aib_csv",
            dadosBrutos: linha
        )
    }

    private func validarTipoTransacao(numeroLinha: Int, tipo: String) throws {
        guard tiposTransacaoSuportados.contains(tipo.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw ErroImportacao.csvInvalido(
                "Tipo de transação AIB não suportado na linha \(numeroLinha): \(tipo)."
            )
        }
    }

    private func detectarDelimitador(_ conteudo: String) -> Character {
        let primeiraLinha = conteudo.split(whereSeparator: \.isNewline).first ?? ""
        let candidatos: [Character] = [",", ";", "\t"]

        return candidatos.max { esquerda, direita in
            primeiraLinha.filter { $0 == esquerda }.count < primeiraLinha.filter { $0 == direita }.count
        } ?? ","
    }

    private func limparCabecalho(_ coluna: String, removerBOM: Bool) -> String {
        let texto = removerBOM ? coluna.replacingOccurrences(of: "\u{feff}", with: "") : coluna
        return texto.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseCsv(_ conteudo: String, delimitador: Character) -> [[String]] {
        conteudo
            .split(whereSeparator: \.isNewline)
            .map { parseLinhaCsv(String($0), delimitador: delimitador) }
            .filter { !$0.allSatisfy { $0.isEmpty } }
    }

    private func parseLinhaCsv(_ linha: String, delimitador: Character) -> [String] {
        var campos: [String] = []
        var campo = ""
        var dentroAspas = false

        for caractere in linha {
            if caractere == "\"" {
                dentroAspas.toggle()
            } else if caractere == delimitador && !dentroAspas {
                campos.append(campo)
                campo = ""
            } else {
                campo.append(caractere)
            }
        }

        campos.append(campo)
        return campos
    }
}
