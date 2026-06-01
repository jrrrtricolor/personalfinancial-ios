import Foundation

/// Importa registros brutos para a camada STG.
final class ImportadorStg {
    private let repositorio: RepositorioImportacaoSQLite
    private let parserFactory: ParserArquivoFactory
    private let hashFinanceiro: HashFinanceiro

    init(
        repositorio: RepositorioImportacaoSQLite,
        parserFactory: ParserArquivoFactory = ParserArquivoFactory(),
        hashFinanceiro: HashFinanceiro = HashFinanceiro()
    ) {
        self.repositorio = repositorio
        self.parserFactory = parserFactory
        self.hashFinanceiro = hashFinanceiro
    }

    /// Persistir um arquivo financeiro na camada STG.
    func importar(origem: String, urlArquivo: URL) throws -> ResultadoImportacaoStg {
        guard FileManager.default.fileExists(atPath: urlArquivo.path) else {
            throw ErroImportacao.arquivoNaoEncontrado(urlArquivo)
        }

        let origemNormalizada = normalizarOrigem(origem: origem, urlArquivo: urlArquivo)
        let parser = try parserFactory.criar(origem: origemNormalizada, urlArquivo: urlArquivo)
        let registros = try parser.extrair()

        guard !registros.isEmpty else {
            throw ErroImportacao.arquivoSemRegistros(urlArquivo)
        }

        let transacoes = try parser.extrairTransacoes()
        let periodo = try extrairPeriodo(transacoes)
        return try persistir(urlArquivo, origemNormalizada, registros, periodo)
    }

    private func persistir(
        _ urlArquivo: URL,
        _ origem: String,
        _ registros: [RegistroBruto],
        _ periodo: (Date, Date)
    ) throws -> ResultadoImportacaoStg {
        try repositorio.emTransacao {
            let origemId = try repositorio.obterOuCriarOrigem(codigo: origem, nome: origem)
            let dados = try montarDadosImportacao(urlArquivo, origemId, origem, periodo)
            let (importacaoId, _) = try repositorio.obterOuCriarImportacao(dados)
            let totais = try persistirRegistros(importacaoId: importacaoId, registros: registros)
            try repositorio.atualizarImportacao(id: importacaoId, status: "concluida")
            return ResultadoImportacaoStg(
                importacaoId: importacaoId,
                registrosCriados: totais.criados,
                registrosExistentes: totais.existentes
            )
        }
    }

    private func persistirRegistros(
        importacaoId: Int64,
        registros: [RegistroBruto]
    ) throws -> (criados: Int, existentes: Int) {
        var criados = 0
        var existentes = 0

        for registro in registros {
            let hash = try hashFinanceiro.calcularHashRegistro(registro)
            if try repositorio.persistirRegistro(importacaoId: importacaoId, registro: registro, hashRegistro: hash) {
                criados += 1
            } else {
                existentes += 1
            }
        }

        return (criados, existentes)
    }

    private func montarDadosImportacao(
        _ urlArquivo: URL,
        _ origemId: Int64,
        _ origem: String,
        _ periodo: (Date, Date)
    ) throws -> DadosImportacaoArquivo {
        DadosImportacaoArquivo(
            origemId: origemId,
            nomeArquivo: urlArquivo.lastPathComponent,
            hashArquivo: try hashFinanceiro.calcularHashArquivo(url: urlArquivo),
            tipoArquivo: try identificarTipoArquivo(urlArquivo),
            tamanhoBytes: try tamanhoArquivo(urlArquivo),
            dataInicial: formatarData(periodo.0),
            dataFinal: formatarData(periodo.1),
            status: "processando"
        )
    }

    private func normalizarOrigem(origem: String, urlArquivo: URL) -> String {
        let origemSugerida = sugerirOrigem(urlArquivo)
        return origem.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == origemSugerida
            ? origemSugerida
            : origemSugerida
    }

    private func sugerirOrigem(_ urlArquivo: URL) -> String {
        let nome = urlArquivo.lastPathComponent.lowercased()
        return urlArquivo.pathExtension.lowercased() == "pdf" || nome.contains("revolut")
            ? "revolut_pdf"
            : "aib_csv"
    }

    private func identificarTipoArquivo(_ urlArquivo: URL) throws -> String {
        switch urlArquivo.pathExtension.lowercased() {
        case "csv":
            return "csv"
        case "pdf":
            return "pdf"
        default:
            throw ErroImportacao.tipoArquivoNaoSuportado(urlArquivo.pathExtension)
        }
    }

    private func extrairPeriodo(_ transacoes: [DadosTransacaoExtraida]) throws -> (Date, Date) {
        let datas = transacoes.map(\.dataTransacao)

        guard let inicial = datas.min(), let final = datas.max() else {
            throw ErroImportacao.csvInvalido("Não há transações para extrair período.")
        }

        return (inicial, final)
    }

    private func tamanhoArquivo(_ urlArquivo: URL) throws -> Int64 {
        let atributos = try FileManager.default.attributesOfItem(atPath: urlArquivo.path)
        return (atributos[.size] as? NSNumber)?.int64Value ?? 0
    }

    private func formatarData(_ data: Date) -> String {
        let formatador = DateFormatter()
        formatador.calendar = Calendar(identifier: .gregorian)
        formatador.locale = Locale(identifier: "en_US_POSIX")
        formatador.dateFormat = "yyyy-MM-dd"
        return formatador.string(from: data)
    }
}
