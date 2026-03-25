# Constitution — Delphi Spec-Kit

> Fundamental principles that govern all development in this project.

## Language and Platform

This project uses **Delphi (Object Pascal)** with **VCL** and/or **FMX** frameworks and data access via **FireDAC**. All generated code MUST follow the conventions of the **Object Pascal Style Guide**.

## Non-Negotiable Principles

### 1. SOLID Always

- **SRP:** One class, one responsibility. Separate validation, persistence and presentation.
- **OCP:** Extension via interfaces and inheritance, not modification of existing classes.
- **LSP:** Replaceable subtypes without breaking behavior.
- **ISP:** Small, focused interfaces.
- **DIP:** Depend on abstractions (interfaces), use constructor injection.

### 2. Clean Code Always

- Methods ≤ 20 lines
- Self-describing names in PascalCase
- Guard clauses instead of nesting
- Named constants (no magic numbers)
- XMLDoc for public APIs

### 3. Layered Architecture

```
Presentation → Application → Domain ← Infrastructure
```

**Domain never depends** on other layers. Infrastructure implements the interfaces defined in Domain.

### 4. Pascal Guide Conventions

- Mandatory prefixes: `T`, `I`, `E`, `F`, `A`, `L`
- Units named as: `Projeto.Camada.Dominio.Funcionalidade.pas`
- Components with 3-letter prefix: `btn`, `edt`, `lbl`, `cmb`, `qry`, `ds`

### 5. Absolute Prohibitions

- ❌ `with` statement
- ❌ Global variables
- ❌ Business logic in form event handlers
- ❌ Generic exception catch
- ❌ God classes or God units
- ❌ Bypass memory management

## Development Process

1. **Specify** — Define requirements and acceptance criteria
2. **Plan** — Design interfaces and classes before implementing
3. **Implementary** — Clean code following SOLID and conventions
4. **Test** — DUnitX for unit testing
5. **Review** — Check adherence to the rules of this constitution
