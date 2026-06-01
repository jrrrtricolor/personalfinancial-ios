# Visão Do Produto

## Objetivo

Criar o `personalfinancial-ios`, um sistema Apple-native de clareza financeira
pessoal para macOS, iPhone e Apple Watch.

O projeto usará o sistema `jrrrtricolor/PersonalFinancialSystem` como referência
funcional e conceitual. A nova implementação deve respeitar as regras de domínio
já consolidadas, mas será construída com tecnologias próprias do ecossistema
Apple.

## Princípio Central

Movimentação de dinheiro não significa necessariamente despesa.

O sistema deve separar:

- despesa real;
- receita;
- transferência;
- provisionamento;
- investimento;
- estorno;
- taxa;
- movimento desconhecido.

## Natureza Do Produto

O sistema não deve ser tratado como um aplicativo tradicional de orçamento.

Ele deve ser um mecanismo de observabilidade financeira pessoal, capaz de
responder com clareza o que realmente aconteceu com o dinheiro.

## Experiência Por Plataforma

### macOS

O macOS será a plataforma principal para tarefas completas.

Responsabilidades:

- importar arquivos;
- auditar dados brutos;
- revisar importações;
- manter regras manuais;
- analisar relatórios completos;
- executar manutenção da base local.

### iPhone

O iPhone será a plataforma principal de consulta diária.

Responsabilidades:

- acompanhar indicadores financeiros;
- consultar períodos;
- revisar valor não explicado;
- categorizar descrições recorrentes;
- acompanhar gasto real e valor disponível.

### Apple Watch

O Apple Watch deve exibir apenas informações resumidas e acionáveis.

Responsabilidades:

- mostrar gasto real do mês;
- mostrar valor disponível;
- mostrar receita do período;
- mostrar dinheiro reservado;
- mostrar data da última atualização.

O Apple Watch não deve executar importação de arquivos nem manutenção avançada.

## MVP

A primeira versão útil deve entregar:

- estrutura SwiftUI para macOS e iPhone;
- modelo de domínio financeiro;
- persistência local com SwiftData;
- importação de AIB CSV;
- normalização de transações;
- classificação determinística;
- relatório de clareza financeira;
- categorização manual de descrições;
- resumo básico para Apple Watch.

## Fases Futuras

Possíveis evoluções:

- importação de Revolut PDF;
- sincronização via iCloud;
- widgets para iOS e macOS;
- complication para Apple Watch;
- alertas financeiros;
- reconciliação entre AIB e Revolut;
- exportação CSV ou JSON;
- modo auditoria;
- edição completa de regras manuais;
- backup e restauração local;
- suporte ampliado a múltiplas moedas.
