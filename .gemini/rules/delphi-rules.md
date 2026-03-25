---
description: "Delphi (Object Pascal) development rules — Conventions, SOLID, Clean Code"
globs: ["**/*.pas", "**/*.dpr", "**/*.dpk", "**/*.dfm", "**/*.fmx"]
alwaysApply: false
---

# Delphi Rules — Antigravity / Gemini

See `AGENTS.md` in the project root for the complete reference.

## Convention Summary

- **PascalCase** for identifiers, lowercase reserved words
- Mandatory prefixes: `T` (classes), `I` (interfaces), `E` (exceptions), `F` (fields), `A` (parameters), `L` (local variables)
- Units: `NomeProjeto.Camada.Dominio.Funcionalidade.pas`
- Components in forms: 3-letter prefix (`btn`, `edt`, `lbl`, `cmb`, etc.)

## SOLID Principles

1. **SRP** — One class = one responsibility. Separate Validator, Repository, Service
2. **OCP** — Extension via interfaces, not modification of existing classes
3. **LSP** — Subtypes replaceable by the base type
4. **ISP** — Small and cohesive interfaces (separate IReadable, IWritable)
5. **DIP** — Depend on interfaces, constructor injection for dependencies

## Clean Code

- Methods ≤ 20 lines (ideal: 5-10)
- Self-descriptive names (verbs for methods, nouns for properties)
- Guard clauses instead of deep nesting
- Named constants instead of magic numbers
- Try/except focused with specific exceptions
- Try/finally for memory management

## Prohibitions

- ❌ `with` statement
- ❌ Global variables
- ❌ Business logic in form event handlers
- ❌ Generic Catch (`except on E: Exception`)
- ❌ God classes / God units
- ❌ Hardcoded strings
- ❌ Ignore `Free` of temporary objects

## Layered Architecture

```
Domain → Entidades, Value Objects, Interfaces
Application → Services, Use Cases, DTOs
Infrastructure → Repositories (FireDAC), APIs
Presentation → Forms VCL/FMX, ViewModels
```

Rule: `Presentation → Application → Domain ← Infrastructure`

## Frameworks

Consult specific skills for each framework:

- **Horse:** `.gemini/skills/horse-framework/SKILL.md` — Minimalist (Express-like) REST APIs
- **DMVC:** `.gemini/skills/dmvc-framework/SKILL.md` — Full-featured REST APIs with Active Record
- **Dext Framework:** `.gemini/skills/dext-framework/SKILL.md` — Enterprise APIs with DI, ORM and Minimal APIs (.NET-like)
- **Intraweb:** `.gemini/skills/intraweb-framework/SKILL.md` — Stateful web development (VCL for the Web)
- **ACBr:** `.gemini/skills/acbr-components/SKILL.md` — Tax Libraries/Commercial Automation
- **DevExpress:** `.gemini/skills/devexpress-components/SKILL.md` — Advanced VCL components
- **Firebird Database:** `.gemini/skills/firebird-database/SKILL.md` — Connection, PSQL, generators, transactions, migrations
- **PostgreSQL Database:** `.gemini/skills/postgresql-database/SKILL.md` — Connection, PL/pgSQL, UPSERT, JSONB, full-text search
- **MySQL Database:** `.gemini/skills/mysql-database/SKILL.md` — Connection, AUTO_INCREMENT, UPSERT, JSON, stored procedures
- **Threading:** `.gemini/skills/threading/SKILL.md` — TThread, TTask, Synchronize/Queue, thread-safety, PPL
- **TDD (DUnitX):** `.gemini/skills/tdd-dunitx/SKILL.md` — Test-Driven Development, Mocks, DUnitX
- **Clean Code:** `.gemini/skills/clean-code/SKILL.md` — Pragmatic clean code standards
- **Code Review:** `.gemini/skills/code-review/SKILL.md` — Code review checklist

