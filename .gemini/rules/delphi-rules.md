---
description: "Regras de desenvolvimento Delphi (Object Pascal) — Convenções, SOLID, Clean Code"
globs: ["**/*.pas", "**/*.dpr", "**/*.dpk", "**/*.dfm", "**/*.fmx"]
alwaysApply: false
---

# Regras Delphi — Antigravity / Gemini

Consulte `AGENTS.md` na raiz do projeto para a referência completa.

## Resumo de Convenções

- **PascalCase** para identificadores, palavras reservadas em minúsculas
- Prefixos obrigatórios: `T` (classes), `I` (interfaces), `E` (exceptions), `F` (campos), `A` (parâmetros), `L` (variáveis locais)
- Units: `NomeProjeto.Camada.Dominio.Funcionalidade.pas`
- Componentes em forms: prefixo de 3 letras (`btn`, `edt`, `lbl`, `cmb`, etc.)

## Princípios SOLID

1. **SRP** — Uma classe = uma responsabilidade. Separar Validator, Repository, Service
2. **OCP** — Extensão via interfaces, não modificação de classes existentes
3. **LSP** — Subtipos substituíveis pelo tipo base
4. **ISP** — Interfaces pequenas e coesas (IReadable, IWritable separados)
5. **DIP** — Depender de interfaces, constructor injection para dependências

## Clean Code

- Métodos ≤ 20 linhas (ideal: 5-10)
- Nomes auto-descritivos (verbos para métodos, substantivos para properties)
- Guard clauses em vez de nesting profundo
- Constantes nomeadas em vez de números mágicos
- Try/except focado com exceptions específicas
- Try/finally para gerenciamento de memória

## Proibições

- ❌ `with` statement
- ❌ Variáveis globais
- ❌ Lógica de negócio em event handlers de forms
- ❌ Catch genérico (`except on E: Exception`)
- ❌ God classes / God units
- ❌ Strings hardcoded
- ❌ Ignorar `Free` de objetos temporários

## Arquitetura em Camadas

```
Domain → Entidades, Value Objects, Interfaces
Application → Services, Use Cases, DTOs
Infrastructure → Repositories (FireDAC), APIs
Presentation → Forms VCL/FMX, ViewModels
```

Regra: `Presentation → Application → Domain ← Infrastructure`

## Frameworks

Consulte skills específicas para cada framework:

- **Horse:** `.gemini/skills/horse-framework/SKILL.md` — APIs REST minimalistas (Express-like)
- **DMVC:** `.gemini/skills/dmvc-framework/SKILL.md` — APIs REST full-featured com Active Record
- **Dext Framework:** `.gemini/skills/dext-framework/SKILL.md` — APIs corporativas com DI, ORM e Minimal APIs (.NET-like)
- **Intraweb:** `.gemini/skills/intraweb-framework/SKILL.md` — Desenvolvimento web (VCL for the Web) stateful
- **ACBr:** `.gemini/skills/acbr-components/SKILL.md` — Bibliotecas Fiscais/Automação Comercial
- **DevExpress:** `.gemini/skills/devexpress-components/SKILL.md` — Componentes VCL avançados
- **Firebird Database:** `.gemini/skills/firebird-database/SKILL.md` — Conexão, PSQL, generators, transactions, migrations
- **PostgreSQL Database:** `.gemini/skills/postgresql-database/SKILL.md` — Conexão, PL/pgSQL, UPSERT, JSONB, full-text search
- **MySQL Database:** `.gemini/skills/mysql-database/SKILL.md` — Conexão, AUTO_INCREMENT, UPSERT, JSON, stored procedures
- **Threading:** `.gemini/skills/threading/SKILL.md` — TThread, TTask, Synchronize/Queue, thread-safety, PPL
- **TDD (DUnitX):** `.gemini/skills/tdd-dunitx/SKILL.md` — Test-Driven Development, Mocks, DUnitX
- **Clean Code:** `.gemini/skills/clean-code/SKILL.md` — Padrões pragmáticos de código limpo
- **Code Review:** `.gemini/skills/code-review/SKILL.md` — Checklist de revisão de código

