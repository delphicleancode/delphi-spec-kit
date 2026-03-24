# Plano Técnico: [Nome da Feature]

## Visão Geral

<!-- Resumo de como a feature será implementada tecnicamente -->

## Arquitetura

### Diagrama de Camadas

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

### Sequência de Operação

```
[Form] → chama → [Service.Create()] → valida → [Repository.Insert()] → [DB]
```

## Componentes a Criar

### Domain Layer

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `*.Domain.[X].Entity.pas` | Entidade | Classe com propriedades e validações de domínio |
| `*.Domain.[X].Repository.Intf.pas` | Interface | Contrato de acesso a dados |

### Application Layer

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `*.Application.[X].Service.Intf.pas` | Interface | Contrato do service |
| `*.Application.[X].Service.pas` | Service | Lógica de negócio com constructor injection |

### Infrastructure Layer

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `*.Infra.[X].Repository.pas` | Repository | Implementação FireDAC do repository |
| `*.Infra.Factory.pas` | Factory | Factory method para criar service e repository |

### Presentation Layer

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `*.Presentation.[X].List.pas` | Form | Tela de listagem/pesquisa |
| `*.Presentation.[X].Edit.pas` | Form | Tela de inclusão/edição |

## Dependências entre Componentes

```
[Edit Form] → IService → IRepository → TFDConnection
```

## Migração de Banco de Dados

```sql
-- Migration: YYYY-MM-DD_create_[tabela]
CREATE TABLE IF NOT EXISTS [tabela] (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- campos
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);
```

## Riscos e Considerações

- [Risco 1 e como mitigar]
- [Risco 2 e como mitigar]

## Checklist de Conformidade

- [ ] Segue SOLID (SRP, OCP, LSP, ISP, DIP)
- [ ] Clean code (métodos ≤ 20 linhas, nomes descritivos)
- [ ] Convenções Pascal (prefixos T, I, E, F, A, L)
- [ ] XMLDoc em APIs públicas
- [ ] Try/finally para objetos temporários
- [ ] Guard clauses em vez de nesting
- [ ] Sem `with`, sem globals, sem catch genérico
