# PersonalFinancial iOS

Sistema Apple-native de clareza financeira pessoal para macOS, iPhone e Apple
Watch.

O projeto usa o repositório `jrrrtricolor/PersonalFinancialSystem` como
referência funcional. A implementação deve começar simples e crescer apenas
quando houver necessidade real.

## Princípio Central

Movimentação de dinheiro não significa necessariamente despesa.

## Documentação

A documentação inicial está em [docs/ios](docs/ios/README.md).

## Execução Local

Para testar manualmente no macOS:

1. Abra o arquivo `PersonalFinancial.xcodeproj` no Xcode.
2. Selecione o scheme `PersonalFinancial`.
3. Selecione o destino `My Mac`.
4. Execute com `Run`.

O `Package.swift` existe apenas como apoio para build via terminal. Para testar
a interface gráfica, use o projeto Xcode.
