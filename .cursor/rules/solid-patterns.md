---
description: "SOLID Patterns and Design Patterns for Delphi — Repository, Service, Factory, Strategy"
globs: ["**/*.pas"]
alwaysApply: false
---

# SOLID Patterns — Cursor Rules

Use these rules when creating new classes, services or repositories in Delphi.

## SOLID Principles

### SRP — Single Responsibility
- One class = one responsibility
- Separate: `TCustomerValidator`, `TCustomerRepository`, `TCustomerService`
- Do not put business logic in forms

### OCP — Open/Closed
- Use interfaces for extension
- New features = new classes implementing existing interface

### LSP — Liskov Substitution
- Any implementation of `ICustomerRepository` must work interchangeably

### ISP — Interface Segregation
- `IReadableRepository<T>` separated from `IWritableRepository<T>`
- Small and cohesive interfaces

### DIP — Dependency Inversion
- Always use **constructor injection**
- Dependencies via interfaces, never concrete classes

## Repository Creation Pattern

```pascal
// 1. Interface no Domain
ICustomerRepository = interface
  ['{GUID}']
  function FindById(AId: Integer): TCustomer;
  procedure Save(ACustomer: TCustomer);
end;

// 2. Implementaction no Infrastructure
TCustomerRepository = class(TInterfacedObject, ICustomerRepository)
  constructor Create(AConnection: TFDConnection);
end;
```

## Service Creation Pattern

```pascal
// 1. Interface no Application
ICustomerService = interface
  ['{GUID}']
  procedure CreateCustomer(const AName, ACpf: string);
end;

// 2. Implementaction com constructor injection
TCustomerService = class(TInterfacedObject, ICustomerService)
  constructor Create(ARepository: ICustomerRepository);
end;
```

##Checklist

- [ ] Interfaces defined in the Domain
- [ ] Constructor injection for all dependencies
- [ ] Guard clauses at the beginning of methods
- [ ] Try/finally for temporary objects
- [ ] XMLDoc in public methods
- [ ] No global variables, no `with`, no generic catch
