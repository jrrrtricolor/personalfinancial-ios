import Foundation
import SQLite3

/// Persiste e consulta dados do fluxo de importação no SQLite local.
final class RepositorioImportacaoSQLite {
    private let bancoDados: BancoDados

    init(bancoDados: BancoDados) {
        self.bancoDados = bancoDados
    }

    /// Listar importações com totais de STG e Business.
    func listarImportacoes() throws -> [ImportacaoArquivoResumo] {
        let sql = """
        SELECT i.id, i.nome_arquivo, o.codigo, i.status, i.importado_em,
               COUNT(DISTINCT r.id), COUNT(DISTINCT t.id)
        FROM stg_importacoes_arquivo i
        JOIN stg_origens_importacao o ON o.id = i.origem_id
        LEFT JOIN stg_registros_importados r ON r.importacao_id = i.id
        LEFT JOIN business_transacoes t ON t.importacao_id = i.id
        GROUP BY i.id
        ORDER BY i.importado_em DESC, i.id DESC;
        """
        let declaracao = try preparar(sql)
        defer { sqlite3_finalize(declaracao) }

        return try lerResumosImportacao(declaracao: declaracao)
    }

    /// Obter ou criar origem de importação.
    func obterOuCriarOrigem(codigo: String, nome: String) throws -> Int64 {
        if let id = try buscarId("SELECT id FROM stg_origens_importacao WHERE codigo = ?;", codigo) {
            return id
        }

        let sql = """
        INSERT INTO stg_origens_importacao (codigo, nome, ativo, criado_em)
        VALUES (?, ?, 1, ?);
        """
        try executar(sql, [codigo, nome, dataHoraAtual()])
        return sqlite3_last_insert_rowid(try bancoDados.conexaoAtiva())
    }

    /// Obter ou criar registro de importação de arquivo.
    func obterOuCriarImportacao(_ dados: DadosImportacaoArquivo) throws -> (Int64, Bool) {
        let busca = """
        SELECT id FROM stg_importacoes_arquivo
        WHERE origem_id = ? AND hash_arquivo = ?;
        """

        if let id = try buscarId(busca, dados.origemId, dados.hashArquivo) {
            return (id, false)
        }

        try inserirImportacao(dados)
        return (sqlite3_last_insert_rowid(try bancoDados.conexaoAtiva()), true)
    }

    /// Persistir registro bruto, retornando se foi criado.
    func persistirRegistro(
        importacaoId: Int64,
        registro: RegistroBruto,
        hashRegistro: String
    ) throws -> Bool {
        let busca = """
        SELECT id FROM stg_registros_importados
        WHERE importacao_id = ? AND hash_registro = ?;
        """

        if try buscarId(busca, importacaoId, hashRegistro) != nil {
            return false
        }

        try inserirRegistro(importacaoId: importacaoId, registro: registro, hashRegistro: hashRegistro)
        return true
    }

    /// Atualizar status de uma importação.
    func atualizarImportacao(id: Int64, status: String, mensagemErro: String = "") throws {
        let sql = """
        UPDATE stg_importacoes_arquivo
        SET status = ?, mensagem_erro = ?, atualizado_em = ?
        WHERE id = ?;
        """
        try executar(sql, [status, mensagemErro, dataHoraAtual(), id])
    }

    /// Executar bloco dentro de transação.
    func emTransacao<T>(_ bloco: () throws -> T) throws -> T {
        try bancoDados.executar("BEGIN;")
        do {
            let resultado = try bloco()
            try bancoDados.executar("COMMIT;")
            return resultado
        } catch {
            try? bancoDados.executar("ROLLBACK;")
            throw error
        }
    }

    private func inserirImportacao(_ dados: DadosImportacaoArquivo) throws {
        let sql = """
        INSERT INTO stg_importacoes_arquivo (
            nome_arquivo, hash_arquivo, tipo_arquivo, tamanho_bytes,
            data_inicial, data_final, status, mensagem_erro,
            importado_em, atualizado_em, origem_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, '', ?, ?, ?);
        """
        let agora = dataHoraAtual()
        try executar(sql, dados.valoresInsercao(agora: agora))
    }

    private func inserirRegistro(
        importacaoId: Int64,
        registro: RegistroBruto,
        hashRegistro: String
    ) throws {
        let sql = """
        INSERT INTO stg_registros_importados (
            numero_linha, numero_pagina, secao, hash_registro,
            dados_brutos, criado_em, importacao_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        try executar(sql, valoresRegistro(importacaoId, registro, hashRegistro))
    }

    private func valoresRegistro(
        _ importacaoId: Int64,
        _ registro: RegistroBruto,
        _ hashRegistro: String
    ) throws -> [Any] {
        let dadosJson = try serializarJson(registro.dados)
        return [
            Int64(registro.numeroLinha),
            Int64(registro.numeroPagina),
            registro.secao,
            hashRegistro,
            dadosJson,
            dataHoraAtual(),
            importacaoId,
        ]
    }

    private func lerResumosImportacao(
        declaracao: OpaquePointer?
    ) throws -> [ImportacaoArquivoResumo] {
        var importacoes: [ImportacaoArquivoResumo] = []

        while sqlite3_step(declaracao) == SQLITE_ROW {
            importacoes.append(
                ImportacaoArquivoResumo(
                    id: sqlite3_column_int64(declaracao, 0),
                    nomeArquivo: textoColuna(declaracao, 1),
                    origemCodigo: textoColuna(declaracao, 2),
                    status: textoColuna(declaracao, 3),
                    importadoEm: textoColuna(declaracao, 4),
                    totalRegistros: Int(sqlite3_column_int(declaracao, 5)),
                    totalTransacoes: Int(sqlite3_column_int(declaracao, 6))
                )
            )
        }

        return importacoes
    }

    private func buscarId(_ sql: String, _ valores: Any...) throws -> Int64? {
        let declaracao = try preparar(sql)
        defer { sqlite3_finalize(declaracao) }

        try vincular(valores, em: declaracao)

        if sqlite3_step(declaracao) == SQLITE_ROW {
            return sqlite3_column_int64(declaracao, 0)
        }

        return nil
    }

    private func executar(_ sql: String, _ valores: [Any]) throws {
        let declaracao = try preparar(sql)
        defer { sqlite3_finalize(declaracao) }
        try vincular(valores, em: declaracao)

        guard sqlite3_step(declaracao) == SQLITE_DONE else {
            throw ErroBancoDados.execucaoFalhou(mensagemErro())
        }
    }

    private func preparar(_ sql: String) throws -> OpaquePointer? {
        let conexao = try bancoDados.conexaoAtiva()
        var declaracao: OpaquePointer?

        guard sqlite3_prepare_v2(conexao, sql, -1, &declaracao, nil) == SQLITE_OK else {
            throw ErroBancoDados.execucaoFalhou(mensagemErro())
        }

        return declaracao
    }

    private func vincular(_ valores: [Any], em declaracao: OpaquePointer?) throws {
        for (indice, valor) in valores.enumerated() {
            try vincularValor(valor, indice: Int32(indice + 1), declaracao: declaracao)
        }
    }

    private func vincularValor(
        _ valor: Any,
        indice: Int32,
        declaracao: OpaquePointer?
    ) throws {
        switch valor {
        case let texto as String:
            sqlite3_bind_text(declaracao, indice, texto, -1, SQLITE_TRANSIENT)
        case let inteiro as Int64:
            sqlite3_bind_int64(declaracao, indice, inteiro)
        default:
            throw ErroBancoDados.execucaoFalhou("Tipo de valor não suportado no SQLite.")
        }
    }

    private func textoColuna(_ declaracao: OpaquePointer?, _ indice: Int32) -> String {
        guard let texto = sqlite3_column_text(declaracao, indice) else {
            return ""
        }

        return String(cString: texto)
    }

    private func serializarJson(_ dados: [String: String]) throws -> String {
        let json = try JSONSerialization.data(withJSONObject: dados, options: [.sortedKeys])
        return String(data: json, encoding: .utf8) ?? "{}"
    }

    private func dataHoraAtual() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private func mensagemErro() -> String {
        String(cString: sqlite3_errmsg(try? bancoDados.conexaoAtiva()))
    }
}

/// Dados necessários para criar uma importação de arquivo.
struct DadosImportacaoArquivo {
    let origemId: Int64
    let nomeArquivo: String
    let hashArquivo: String
    let tipoArquivo: String
    let tamanhoBytes: Int64
    let dataInicial: String
    let dataFinal: String
    let status: String

    func valoresInsercao(agora: String) -> [Any] {
        [
            nomeArquivo,
            hashArquivo,
            tipoArquivo,
            tamanhoBytes,
            dataInicial,
            dataFinal,
            status,
            agora,
            agora,
            origemId,
        ]
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
