---
name: "DUnitX Testing Patterns"
description: "Padrões de testes unitários com DUnitX para Delphi — fixtures, mocking, integration tests"
---

# DUnitX Testing Patterns — Skill

Use esta skill ao criar ou organizar testes unitários em projetos Delphi.

## Quando Usar

- Ao criar testes para novas funcionalidades
- Ao aplicar TDD (Test-Driven Development)
- Ao criar testes de integração com banco de dados
- Ao refatorar testes existentes

## Estrutura de Projeto de Testes

```
tests/
├── MeuApp.Tests.dpr                 ← Projeto de testes
├── Domain/
│   ├── MeuApp.Tests.Customer.Entity.pas
│   └── MeuApp.Tests.Order.Entity.pas
├── Application/
│   ├── MeuApp.Tests.Customer.Service.pas
│   └── MeuApp.Tests.Order.Service.pas
├── Infrastructure/
│   └── MeuApp.Tests.Customer.Repository.pas
└── Helpers/
    ├── MeuApp.Tests.Helpers.Database.pas
    └── MeuApp.Tests.Helpers.Mocks.pas
```

## Test Fixture Básico

```pascal
unit MeuApp.Tests.Customer.Service;

interface

uses
  DUnitX.TestFramework,
  MeuApp.Domain.Customer.Entity,
  MeuApp.Domain.Customer.Repository.Intf,
  MeuApp.Application.Customer.Service;

type
  [TestFixture]
  TCustomerServiceTest = class
  private
    FService: TCustomerService;
    FMockRepo: ICustomerRepository;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure CreateCustomer_WithValidData_ShouldSucceed;

    [Test]
    procedure CreateCustomer_WithEmptyName_ShouldRaiseException;

    [Test]
    procedure CreateCustomer_WithDuplicateCpf_ShouldRaiseException;

    [Test]
    procedure GetById_WithExistingId_ShouldReturnCustomer;

    [Test]
    procedure GetById_WithInvalidId_ShouldRaiseNotFoundException;
  end;

implementation

uses
  System.SysUtils;

{ TCustomerServiceTest }

procedure TCustomerServiceTest.Setup;
begin
  FMockRepo := TMemoryCustomerRepository.Create;
  FService := TCustomerService.Create(FMockRepo);
end;

procedure TCustomerServiceTest.TearDown;
begin
  FService.Free;
  // FMockRepo é interface — liberado automaticamente
end;

[Test]
procedure TCustomerServiceTest.CreateCustomer_WithValidData_ShouldSucceed;
begin
  Assert.WillNotRaiseAny(
    procedure
    begin
      FService.CreateCustomer('João Silva', '12345678901', 'joao@email.com');
    end
  );
end;

[Test]
procedure TCustomerServiceTest.CreateCustomer_WithEmptyName_ShouldRaiseException;
begin
  Assert.WillRaise(
    procedure
    begin
      FService.CreateCustomer('', '12345678901', 'joao@email.com');
    end,
    EValidationException
  );
end;

[Test]
procedure TCustomerServiceTest.CreateCustomer_WithDuplicateCpf_ShouldRaiseException;
begin
  FService.CreateCustomer('João', '12345678901', 'joao@email.com');

  Assert.WillRaise(
    procedure
    begin
      FService.CreateCustomer('Maria', '12345678901', 'maria@email.com');
    end,
    EBusinessRuleException
  );
end;

[Test]
procedure TCustomerServiceTest.GetById_WithExistingId_ShouldReturnCustomer;
var
  LCustomer: TCustomer;
begin
  FService.CreateCustomer('João', '12345678901', 'joao@email.com');

  LCustomer := FService.GetById(1);
  try
    Assert.IsNotNull(LCustomer);
    Assert.AreEqual('João', LCustomer.Name);
  finally
    LCustomer.Free;
  end;
end;

[Test]
procedure TCustomerServiceTest.GetById_WithInvalidId_ShouldRaiseNotFoundException;
begin
  Assert.WillRaise(
    procedure
    begin
      FService.GetById(999);
    end,
    EEntityNotFoundException
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TCustomerServiceTest);

end.
```

## Mock Repository (em memória)

```pascal
unit MeuApp.Tests.Helpers.Mocks;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  MeuApp.Domain.Customer.Entity,
  MeuApp.Domain.Customer.Repository.Intf;

type
  TMemoryCustomerRepository = class(TInterfacedObject, ICustomerRepository)
  private
    FItems: TObjectList<TCustomer>;
    FNextId: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    function FindById(AId: Integer): TCustomer;
    function FindAll: TObjectList<TCustomer>;
    function FindByCpf(const ACpf: string): TCustomer;
    function Exists(AId: Integer): Boolean;
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
  end;

implementation

constructor TMemoryCustomerRepository.Create;
begin
  inherited Create;
  FItems := TObjectList<TCustomer>.Create(False);
  FNextId := 1;
end;

destructor TMemoryCustomerRepository.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TMemoryCustomerRepository.Insert(ACustomer: TCustomer);
begin
  ACustomer.Id := FNextId;
  Inc(FNextId);
  FItems.Add(ACustomer);
end;

// ... demais métodos seguem o mesmo padrão
```

## Convenções de Nomenclatura de Testes

```
MethodName_Scenario_ExpectedBehavior
```

| Exemplo | Significado |
|---------|-------------|
| `CreateCustomer_WithValidData_ShouldSucceed` | Cenário feliz |
| `CreateCustomer_WithEmptyName_ShouldRaiseException` | Validação |
| `GetById_WithInvalidId_ShouldRaiseNotFoundException` | Not found |
| `Delete_WhenItemHasDependencies_ShouldRaiseException` | Regra de negócio |

## Assertions Comuns do DUnitX

```pascal
// Igualdade
Assert.AreEqual(Expected, Actual);
Assert.AreEqual('João', LCustomer.Name);

// Nulidade
Assert.IsNotNull(LCustomer);
Assert.IsNull(LResult);

// Booleanos
Assert.IsTrue(LCustomer.IsActive);
Assert.IsFalse(LOrder.IsCancelled);

// Exceptions
Assert.WillRaise(AnonProc, EValidationException);
Assert.WillNotRaiseAny(AnonProc);

// Contagem
Assert.AreEqual(3, LList.Count);
```

## Teste de Integração com SQLite em Memória

```pascal
[TestFixture]
TCustomerRepositoryIntegrationTest = class
private
  FConnection: TFDConnection;
  FRepository: ICustomerRepository;
public
  [Setup]
  procedure Setup;

  [TearDown]
  procedure TearDown;
end;

procedure TCustomerRepositoryIntegrationTest.Setup;
begin
  FConnection := TFDConnection.Create(nil);
  FConnection.DriverName := 'SQLite';
  FConnection.Params.Database := ':memory:';
  FConnection.Connected := True;

  // Criar schema
  FConnection.ExecSQL(
    'CREATE TABLE customers (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name TEXT NOT NULL,' +
    '  cpf TEXT NOT NULL,' +
    '  email TEXT,' +
    '  status INTEGER DEFAULT 0' +
    ')'
  );

  FRepository := TFireDACCustomerRepository.Create(FConnection);
end;

procedure TCustomerRepositoryIntegrationTest.TearDown;
begin
  FConnection.Free;
end;
```

## Checklist de Testes

- [ ] Nome do teste segue `MethodName_Scenario_ExpectedBehavior`?
- [ ] Setup e TearDown limpos e sem efeitos colaterais?
- [ ] Teste verifica UMA coisa?
- [ ] Objetos liberados corretamente no TearDown e em try/finally?
- [ ] Mock repository usado para testes de Service?
- [ ] SQLite `:memory:` usado para testes de integração de Repository?
- [ ] Testa cenário feliz E cenários de erro?
