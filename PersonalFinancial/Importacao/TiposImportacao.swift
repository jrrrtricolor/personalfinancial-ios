import Foundation

/// Erros conhecidos do fluxo de importação.
enum ErroImportacao: Error, Equatable {
    case arquivoNaoEncontrado(URL)
    case arquivoSemRegistros(URL)
    case origemNaoSuportada(String)
    case tipoArquivoNaoSuportado(String)
    case csvInvalido(String)
    case transacaoInvalida(String)
}

/// Registro bruto extraído de um arquivo financeiro.
struct RegistroBruto: Equatable {
    let numeroLinha: Int
    let numeroPagina: Int
    let secao: String
    let dados: [String: String]

    init(
        numeroLinha: Int,
        numeroPagina: Int = 0,
        secao: String,
        dados: [String: String]
    ) throws {
        guard numeroLinha >= 0 else {
            throw ErroImportacao.csvInvalido("O número da linha não pode ser negativo.")
        }

        guard numeroPagina >= 0 else {
            throw ErroImportacao.csvInvalido("O número da página não pode ser negativo.")
        }

        self.numeroLinha = numeroLinha
        self.numeroPagina = numeroPagina
        self.secao = secao
        self.dados = dados
    }
}

/// Dados estruturados de uma transação extraída de arquivo.
struct DadosTransacaoExtraida: Equatable {
    let numeroLinha: Int
    let conta: String
    let dataTransacao: Date
    let descricaoOriginal: String
    let valor: Decimal
    let moeda: String
    let saldo: Decimal
    let tipoTransacao: String
    let valorLocal: Decimal
    let moedaLocal: String
    let origem: String
    let dadosBrutos: [String: String]
}

/// Resultado da persistência de um arquivo na camada STG.
struct ResultadoImportacaoStg: Equatable {
    let importacaoId: Int64
    let registrosCriados: Int
    let registrosExistentes: Int
}

/// Resumo de uma importação para exibição na tela.
struct ImportacaoArquivoResumo: Identifiable, Equatable {
    let id: Int64
    let nomeArquivo: String
    let origemCodigo: String
    let status: String
    let importadoEm: String
    let totalRegistros: Int
    let totalTransacoes: Int
}
