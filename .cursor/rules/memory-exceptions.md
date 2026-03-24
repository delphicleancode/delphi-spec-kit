---
description: Boas práticas de gerenciamento de memória (try..finally), vazamento de memória e tratamento focado de exceções em Delphi
globs: *.pas, *.dfm, *.fmx, *.dpr, *.dpk
---

# Regras de Memória e Exceções (Delphi)

- **Sempre utilize `try..finally`** assim que instanciar um objeto (`.Create`), colocando o `.Free` ou `FreeAndNil()` no `finally`. Abertura do `try` deve ser IMEDIATAMENTE na próxima linha da criação.
- **NÃO crie múltiplos objetos fora de um bloco seguro.** Se você tiver dependências entre eles, aninhe os blocos `try..finally`. Instanciou, `try` na linha de baixo.
- **Prefira Interfaces (IInterface)** sempre que construir classes injetáveis de Serviços e Repositórios para se beneficiar da Gestão por Contagem de Referência do compilador (ARC), reduzindo poluição e eliminando o risco de instanciar sem chamadas `Free`.
- **NÃO "Cale" Exceções:** Ao implementar blocos `try..except`, sempre defina o tipo exato do erro a tratar (Ex: `on E: EFDDBEngineException do`). NÃO use exceptions cegas genéricas ou supressão brutal (`try ... except ... end`) a menos que explicitamente exigido e com documentação/justificativa extensa.
- **DDD Exceptions:** Para falhas de lógica corporativa, emita Exceções personalizadas que herdam de `Exception` (Ex: `raise EBusinessRuleException.Create('Idade inválida para essa operação');`).
- **Relançamento Seguro:** Use a palavra `raise;` pura quando quiser repassar o stacktrace pra frente num `except`. Padrão: Tratamento em Infra, captura/intercepto/log e `raise;` puro.
