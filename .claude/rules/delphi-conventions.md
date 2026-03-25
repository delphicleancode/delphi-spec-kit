---
description: "Delphi Object Pascal conventions — naming, style, formatting"
globs: ["**/*.pas", "**/*.dpr", "**/*.dpk"]
alwaysApply: true
---

# Delphi Conventions — Claude Rules

## Nomenclatura

- **PascalCase** for all identifiers
- Reserved words in **lowercase** (`begin`, `end`, `if`, `nil`, `string`)
- Prefixes: `T` (classes), `I` (interfaces), `E` (exceptions), `F` (private fields), `A` (parameters), `L` (local variables)
- Units: `Projeto.Camada.Dominio.Funcionalidade.pas`
- Components: 3-letter prefix (`btn`, `edt`, `lbl`, `cmb`, `pnl`, `qry`, `ds`)

## Formatting

- Indentation: 2 spaces
- Limit: 120 characters per line
- `begin` on the same line for `if`/`for`/`while` blocks
- `begin` on new line for method body

## Unit Mandatory Sections

```pascal
unit Nome;
interface
uses { ... };
type { Enums → Interfaces → Classes }
implementation
uses { imports extras };
{ Implementação agrupada por classe }
end.
```

## Documentation

- XMLDoc for public methods and properties
- Comments in Portuguese for Brazilian projects
- Do not comment self-explanatory code

## Memory Management

- `try/finally` with `Free` for temporary objects
- Interfaces for automatic reference counting
- Local variables with prefix `L`
- Owner pattern for visual components

## Prohibitions

- ❌ `with` statement
- ❌ Global variables
- ❌ Generic Catch (`except on E: Exception`)
- ❌ Magic numbers — use constants
- ❌ Hardcoded strings — use `resourcestring` or constants
- ❌ Methods > 20 lines
