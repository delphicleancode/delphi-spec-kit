---
description: "Padrões SOLID e Design Patterns para Delphi — Repository, Service, Factory, Strategy"
globs: ["**/*.pas"]
alwaysApply: false
---

# Padrões SOLID — Cursor Rules

Use estas regras quando criar novas classes, services ou repositories em Delphi.

## Princípios SOLID

### SRP — Single Responsibility
- Uma classe = uma responsabilidade
- Separar: `TCustomerValidator`, `TCustomerRepository`, `TCustomerService`
- Não colocar lógica de negócio em forms

### OCP — Open/Closed
- Usar interfaces para extensão
- Novas funcionalidades = novas classes implementando interface existente

### LSP — Liskov Substitution
- Qualquer implementação de `ICustomerRepository` deve funcionar de forma intercambiável

### ISP — Interface Segregation
- `IReadableRepository<T>` separado de `IWritableRepository<T>`
- Interfaces pequenas e coesas

### DIP — Dependency Inversion
- Sempre usar **constructor injection**
- Dependências via interfaces, nunca classes concretas

## Padrão de Criação de Repository

```pascal
// 1. Interface no Domain
ICustomerRepository = interface
  ['{GUID}']
  function FindById(AId: Integer): TCustomer;
  procedure Save(ACustomer: TCustomer);
end;

// 2. Implementação no Infrastructure
TCustomerRepository = class(TInterfacedObject, ICustomerRepository)
  constructor Create(AConnection: TFDConnection);
end;
```

## Padrão de Criação de Service

```pascal
// 1. Interface no Application
ICustomerService = interface
  ['{GUID}']
  procedure CreateCustomer(const AName, ACpf: string);
end;

// 2. Implementação com constructor injection
TCustomerService = class(TInterfacedObject, ICustomerService)
  constructor Create(ARepository: ICustomerRepository);
end;
```

## Checklist

- [ ] Interfaces definidas no Domain
- [ ] Constructor injection para todas as dependências
- [ ] Guard clauses no início dos métodos
- [ ] Try/finally para objetos temporários
- [ ] XMLDoc nos métodos públicos
- [ ] Sem variáveis globais, sem `with`, sem catch genérico
