# Definition of Done

Uma entrega só pode ser considerada concluída quando atender aos critérios
abaixo.

## Critérios Gerais

- O projeto compila.
- A feature funciona na plataforma prevista.
- O código segue a arquitetura definida.
- O domínio financeiro continua separado da interface.
- Não há uso de `Double` ou `Float` para valores monetários.
- Não há dados financeiros reais versionados.
- O texto está em português brasileiro correto.
- Os nomes são claros, objetivos e coerentes com o domínio.

## Critérios De Teste

- Regras de negócio possuem testes.
- Correções possuem teste de regressão quando aplicável.
- Importadores possuem testes com arquivos fictícios.
- Cálculos financeiros possuem cenários de borda.
- O build e os testes passam antes da abertura do Pull Request.

## Critérios De Documentação

- Decisões relevantes estão documentadas.
- Comportamentos financeiros novos estão descritos.
- Regras novas possuem exemplos quando isso ajudar a compreensão.
- Comentários explicam decisões, regras de negócio ou trechos não óbvios.

## Critérios De Git

- O desenvolvimento foi feito a partir da branch `develop`.
- Os commits são pequenos.
- Os commits agrupam arquivos relacionados.
- As mensagens de commit usam a tag definida pelo projeto.
- O Pull Request para `main` possui descrição clara e sucinta.
