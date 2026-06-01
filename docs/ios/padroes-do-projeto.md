# Padrões Do Projeto

## Orientação Geral

O projeto deve usar orientação a objetos e manter classes objetivas, com nomes
claros e responsabilidades bem definidas.

A implementação deve favorecer código simples, explícito, testável e fácil de
revisar.

## Idioma

Funções, variáveis, comentários, exemplos, documentação, mensagens de commit e
descrições de Pull Request devem ser escritos em português brasileiro correto.

Também devem ser escritos em português brasileiro os nomes ligados ao domínio
financeiro, como transação, categoria, tipo de movimento, gasto real e valor
disponível.

Exceções aceitáveis:

- APIs da Apple;
- tipos nativos do Swift;
- nomes de frameworks;
- protocolos técnicos;
- convenções inevitáveis da linguagem ou plataforma.

## Qualidade De Texto

Não devem ser aceitos:

- erros de gramática;
- erros de conjugação verbal;
- comentários ambíguos;
- nomes genéricos;
- mensagens de commit vagas;
- documentação que não explique a decisão tomada.

Comentários devem explicar regras de negócio, decisões técnicas ou trechos não
óbvios. Comentários não devem apenas repetir o que o código já expressa.

## Nomes

Nomes devem ser claros, objetivos e específicos.

Exemplos recomendados:

```swift
final class CalculadoraGastoReal {
    func calcularGastoReal(transacoes: [TransacaoFinanceira]) -> Decimal {
        // Implementação.
    }
}
```

Outros exemplos:

```text
ImportadorAIBCSV
NormalizadorDescricao
ClassificadorTipoMovimento
RepositorioTransacoes
MontadorPainelClareza
```

Evitar nomes genéricos quando houver alternativa mais precisa:

```text
Manager
Helper
Utils
Processor
Service
```

Esses termos só devem ser usados quando forem realmente o melhor nome para a
responsabilidade da classe.

## Tamanho De Funções

Funções devem ter, como regra geral, entre 20 e 30 linhas no máximo.

Quando uma função ultrapassar esse limite, deve ser avaliada a extração para:

- método privado;
- classe de domínio;
- objeto de valor;
- estratégia de regra;
- componente especializado.

A prioridade é manter cada função com uma responsabilidade clara.

## Classes

Classes devem ser:

- objetivas;
- pequenas quando possível;
- nomeadas com clareza;
- focadas em uma responsabilidade;
- fáceis de testar isoladamente.

Uma classe não deve acumular responsabilidades de domínio, persistência e
interface ao mesmo tempo.

## Dinheiro

Valores monetários devem usar `Decimal`.

É proibido usar `Double` ou `Float` para representar dinheiro.

Essa regra vale para:

- transações;
- saldos;
- totais;
- médias;
- indicadores;
- importações;
- relatórios.

## Regras Financeiras

O sistema deve preservar a regra central:

```text
Movimentação de dinheiro não significa necessariamente despesa.
```

Tipos de movimento obrigatórios:

```text
despesa
receita
transferencia
provisionamento
investimento
estorno
taxa
desconhecido
```

Categorias iniciais:

```text
alimentacao
investimento
transferencia
contas
assinatura
saude
receita
desconhecido
```

Toda transação deve preservar:

- descrição original;
- descrição normalizada;
- valor;
- moeda;
- data;
- conta;
- categoria;
- tipo de movimento;
- origem;
- vínculo com dado bruto;
- hash da transação;
- hash canônico.

## Testes

A prioridade de testes deve ser:

- cálculo de gasto real;
- diferenciação entre despesa e transferência;
- provisionamento;
- investimentos;
- normalização;
- importação AIB CSV;
- regras manuais de categoria;
- prevenção de duplicidade por hash.

Regras novas de classificação financeira devem ter testes.
