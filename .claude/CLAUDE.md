# Delphi AI Spec-Kit

Este é o **Delphi AI Spec-Kit**, o guia mestre para desenvolvimento Delphi (Object Pascal) neste repositório.

## Stack do Projeto
- **Linguagem:** Object Pascal (Delphi)
- **IDE Nativa:** RAD Studio / Delphi
- **Frameworks Principais:** VCL, FMX, FireDAC
- **Testes:** DUnitX
- **Build / Tooling:** MSBuild, dcc32/dcc64, Boss (Package Manager)

## Diretivas Cruciais (Memory Management)
- **Blocos Vigiados (Obrigatório):** TUDO o que você instanciar com `.Create` (se for `TObject` e não tiver `Owner`) **DEVE** ter um `try..finally` na linha IMEDIATAMENTE subsequente.
  ```pascal
  Obj := TMyClass.Create;
  try
    Obj.DoSomething;
  finally
    Obj.Free; // ou FreeAndNil(Obj)
  end;
  ```
- **NÃO use** `with`.
- **NÃO crie** God Classes. Use Princípios SOLID.
- Isole componentes visuais (FMX/VCL) de regras de negócio estritas. Não acesse DBGrid ou edits do form em units lógicas puras.
- Para injeção de dependências, passe abstrações no constructor.

## File Organization & Naming (PascalCase)
- Classes: Começam com `T` (ex: `TCustomer`).
- Interfaces: Começam com `I` (ex: `ICustomer`).
- Exceptions: Começam com `E` (ex: `EValidationError`).
- Atributos ou Campos privados: Começam com `F` (ex: `FName`).
- Variáveis locais: Começam com `L` (ex: `LCustomer`).
- Parâmetros: Começam com `A` (ex: `ACustomer`).
- Nomenclatura das Units: `NomeProjeto.Camada.Dominio.Funcionalidade.pas`

*(Veja o arquivo global `AGENTS.md` e a pasta `rules/` para diretrizes específicas de frameworks como FireDAC, Rest, Horse e Banco de Dados).*
