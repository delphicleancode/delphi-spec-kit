# Technical Plan: [Feature Name]

## Overview

<!-- Summary of how the feature will be technically implemented -->

## Architecture

### Layer Diagram

```
Presentation (VCL/FMX Form)
    │
    ▼
Application (Service)
    │
    ▼
Domain (Entity + Interface)
    ▲
    │
Infrastructure (Repository FireDAC)
```

### Operation Sequence

```
[Form] → chama → [Service.Create()] → valida → [Repository.Insert()] → [DB]
```

## Components to Create

### Domain Layer

| Archive | Type | Description |
|---------|------|-----------|
| `*.Domain.[X].Entity.pas` | Entity | Class with domain properties and validations |
| `*.Domain.[X].Repository.Intf.pas` | Interface | Data access agreement |

### Application Layer

| Archive | Type | Description |
|---------|------|-----------|
| `*.Application.[X].Service.Intf.pas` | Interface | Service contract |
| `*.Application.[X].Service.pas` | Service | Business logic with constructor injection |

### Infrastructure Layer

| Archive | Type | Description |
|---------|------|-----------|
| `*.Infra.[X].Repository.pas` | Repository | FireDAC implementation of the repository |
| `*.Infra.Factory.pas` | Factory | Factory method to create service and repository |

### Presentation Layer

| Archive | Type | Description |
|---------|------|-----------|
| `*.Presentation.[X].List.pas` | Form | Listing/search screen |
| `*.Presentation.[X].Edit.pas` | Form | Inclusion/editing screen |

## Dependencies between Components

```
[Edit Form] → IService → IRepository → TFDConnection
```

## Database Migration

```sql
-- Migration: YYYY-MM-DD_create_[tabela]
CREATE TABLE IF NOT EXISTS [tabela] (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- campos
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);
```

## Risks and Considerations

- [Risk 1 and how to mitigate]
- [Risk 2 and how to mitigate]

## Compliance Checklist

- [ ] Follow SOLID (SRP, OCP, LSP, ISP, DIP)
- [ ] Clean code (methods ≤ 20 lines, descriptive names)
- [ ] Pascal conventions (prefixes T, I, E, F, A, L)
- [ ] XMLDoc in public APIs
- [ ] Try/finally for temporary objects
- [ ] Guard clauses instead of nesting
- [ ] No `with`, no globals, no generic catch
