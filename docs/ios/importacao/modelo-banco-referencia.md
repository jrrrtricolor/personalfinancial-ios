# Modelo De Banco De Referência

Este documento registra o modelo de banco que será usado como referência para o
`personalfinancial-ios`.

A fonte é o repositório `jrrrtricolor/PersonalFinancialSystem`, arquivo
`financeiro/models.py`.

## Decisão

O novo projeto deve preservar o mesmo desenho lógico do banco:

- camada STG para dados importados e auditáveis;
- camada Business para transações interpretadas;
- vínculos entre arquivo, registro bruto e transação;
- hashes determinísticos para evitar duplicidade;
- valores monetários com precisão decimal.

No app Apple-native, os nomes podem ser adaptados para Swift, mas os conceitos,
campos obrigatórios, relacionamentos e garantias devem permanecer equivalentes.

## Tabelas STG

### `stg_origens_importacao`

Representa fontes externas de dados financeiros.

Campos:

| Campo | Tipo lógico | Obrigatório | Regra |
| --- | --- | --- | --- |
| `id` | inteiro | sim | chave primária |
| `codigo` | texto | sim | único |
| `nome` | texto | sim | único |
| `ativo` | booleano | sim | padrão verdadeiro |
| `criado_em` | data e hora | sim | preenchido na criação |

Ordenação:

- `nome`.

### `stg_importacoes_arquivo`

Representa arquivos recebidos para importação.

Campos:

| Campo | Tipo lógico | Obrigatório | Regra |
| --- | --- | --- | --- |
| `id` | inteiro | sim | chave primária |
| `origem_id` | relacionamento | sim | origem protegida contra remoção |
| `nome_arquivo` | texto | sim | nome original do arquivo |
| `hash_arquivo` | texto | sim | SHA-256 do arquivo |
| `tipo_arquivo` | texto | sim | `csv` ou `pdf` |
| `tamanho_bytes` | inteiro | sim | maior que zero |
| `data_inicial` | data | sim | início do período importado |
| `data_final` | data | sim | fim do período importado |
| `status` | texto | sim | status da importação |
| `mensagem_erro` | texto | não | erro rastreável |
| `importado_em` | data e hora | sim | preenchido na criação |
| `atualizado_em` | data e hora | sim | atualizado a cada alteração |

Status aceitos:

- `pendente`;
- `processando`;
- `concluida`;
- `falhou`;
- `removida`.

Tipos de arquivo aceitos:

- `csv`;
- `pdf`.

Restrições:

- `origem_id` + `hash_arquivo` devem ser únicos;
- `hash_arquivo` deve estar preenchido;
- `tamanho_bytes` deve ser maior que zero;
- `data_final` deve ser maior ou igual a `data_inicial`.

Índices:

- `origem_id`, `status`;
- `hash_arquivo`;
- `importado_em`;
- `data_inicial`, `data_final`.

Ordenação:

- `importado_em` decrescente;
- `id` decrescente.

### `stg_registros_importados`

Representa registros brutos extraídos de arquivos importados.

Campos:

| Campo | Tipo lógico | Obrigatório | Regra |
| --- | --- | --- | --- |
| `id` | inteiro | sim | chave primária |
| `importacao_id` | relacionamento | sim | remoção em cascata com importação |
| `numero_linha` | inteiro | sim | `0` quando não se aplicar |
| `numero_pagina` | inteiro | sim | `0` quando não se aplicar |
| `secao` | texto | não | seção do arquivo ou PDF |
| `hash_registro` | texto | sim | SHA-256 determinístico do registro |
| `dados_brutos` | JSON | sim | conteúdo preservado |
| `criado_em` | data e hora | sim | preenchido na criação |

Restrições:

- `importacao_id` + `hash_registro` devem ser únicos;
- `importacao_id` + `numero_linha` devem ser únicos quando `numero_linha > 0`;
- `hash_registro` deve estar preenchido.

Índices:

- `importacao_id`;
- `secao`;
- `hash_registro`.

Ordenação:

- `importacao_id`;
- `numero_pagina`;
- `numero_linha`;
- `id`.

## Tabelas Business

### `business_categorias`

Representa categorias financeiras de negócio.

Campos:

| Campo | Tipo lógico | Obrigatório | Regra |
| --- | --- | --- | --- |
| `id` | inteiro | sim | chave primária |
| `codigo` | texto | sim | único |
| `nome` | texto | sim | único |
| `ativo` | booleano | sim | padrão verdadeiro |
| `criado_em` | data e hora | sim | preenchido na criação |

Ordenação:

- `nome`.

### `business_tipos_movimento`

Representa tipos semânticos de movimentação financeira.

Campos:

| Campo | Tipo lógico | Obrigatório | Regra |
| --- | --- | --- | --- |
| `id` | inteiro | sim | chave primária |
| `codigo` | texto | sim | único |
| `nome` | texto | sim | único |
| `ativo` | booleano | sim | padrão verdadeiro |
| `criado_em` | data e hora | sim | preenchido na criação |

Ordenação:

- `nome`.

Tipos iniciais:

- `despesa`;
- `receita`;
- `transferencia`;
- `provisionamento`;
- `investimento`;
- `estorno`;
- `taxa`;
- `desconhecido`.

### `business_regras_categoria_manual`

Representa regras manuais para categorizar descrições recorrentes.

Campos:

| Campo | Tipo lógico | Obrigatório | Regra |
| --- | --- | --- | --- |
| `id` | inteiro | sim | chave primária |
| `categoria_id` | relacionamento | sim | categoria protegida contra remoção |
| `descricao_normalizada` | texto | sim | único |
| `descricao_exibicao` | texto | sim | descrição legível |
| `ativo` | booleano | sim | padrão verdadeiro |
| `criado_em` | data e hora | sim | preenchido na criação |
| `atualizado_em` | data e hora | sim | atualizado a cada alteração |

Restrições:

- `descricao_normalizada` deve estar preenchida;
- `descricao_exibicao` deve estar preenchida.

Índices:

- `ativo`, `categoria_id`;
- `criado_em`.

Ordenação:

- `descricao_exibicao`.

### `business_transacoes`

Representa transações normalizadas e interpretadas.

Campos:

| Campo | Tipo lógico | Obrigatório | Regra |
| --- | --- | --- | --- |
| `id` | inteiro | sim | chave primária |
| `importacao_id` | relacionamento | sim | importação protegida contra remoção |
| `registro_importado_id` | relacionamento | sim | vínculo único com registro bruto |
| `categoria_id` | relacionamento | sim | categoria protegida contra remoção |
| `tipo_movimento_id` | relacionamento | sim | tipo protegido contra remoção |
| `nome_conta` | texto | sim | conta de origem |
| `data_transacao` | data | sim | data normalizada |
| `descricao_original` | texto | sim | descrição preservada |
| `descricao_normalizada` | texto | sim | descrição determinística |
| `valor` | decimal | sim | valor monetário assinado |
| `moeda` | texto | sim | moeda ISO |
| `saldo` | decimal | sim | saldo informado pela fonte |
| `hash_transacao` | texto | sim | hash dentro da importação |
| `hash_canonico` | texto | sim | hash global da identidade financeira |
| `dados_interpretacao` | JSON | não | metadados da interpretação |
| `criado_em` | data e hora | sim | preenchido na criação |
| `atualizado_em` | data e hora | sim | atualizado a cada alteração |

Restrições:

- `importacao_id` + `hash_transacao` devem ser únicos;
- `hash_canonico` deve ser único;
- `moeda` deve estar preenchida;
- `hash_transacao` deve estar preenchido;
- `hash_canonico` deve estar preenchido;
- cada registro bruto deve gerar, no máximo, uma transação Business.

Índices:

- `data_transacao`;
- `categoria_id`, `data_transacao`;
- `tipo_movimento_id`, `data_transacao`;
- `nome_conta`, `data_transacao`;
- `hash_transacao`;
- `hash_canonico`.

Ordenação:

- `data_transacao`;
- `id`.

## Observações Para SwiftData

SwiftData pode não expressar todas as restrições exatamente como o banco Django.
Quando a restrição não existir no armazenamento, ela deve ser garantida no código
de domínio ou persistência.

Regras que não podem ser perdidas:

- não importar o mesmo arquivo duas vezes para a mesma origem;
- não duplicar registros brutos dentro da mesma importação;
- não criar duas transações para o mesmo registro bruto;
- não usar `Double` ou `Float` para dinheiro;
- preservar o JSON ou estrutura equivalente dos dados brutos;
- manter vínculo auditável entre arquivo, registro bruto e transação.
