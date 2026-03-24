---
name: "Delphi SOLID Patterns"
description: "Padrões de implementação SOLID para projetos Delphi — Repository, Service, Factory, Strategy com constructor injection e interfaces"
---

# Delphi SOLID Patterns — Skill

Use esta skill quando o usuário solicitar criação de classes, services, repositories ou qualquer estrutura que siga os princípios SOLID em Delphi.

## Quando Usar

- Ao criar uma nova **entidade** de domínio
- Ao criar um **repository** (acesso a dados)
- Ao criar um **service** (lógica de negócio)
- Ao implementar um **use case**
- Ao aplicar qualquer padrão de projeto (Factory, Strategy, Observer)

## Repository Pattern

### Interface do Repository

```pascal
unit MeuApp.Domain.Customer.Repository.Intf;

interface

uses
  System.Generics.Collections,
  MeuApp.Domain.Customer.Entity;

type
  /// <summary>
  ///   Interface para operações de leitura de clientes.
  /// </summary>
  ICustomerReadRepository = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function FindById(AId: Integer): TCustomer;
    function FindAll: TObjectList<TCustomer>;
    function FindByCpf(const ACpf: string): TCustomer;
  end;

  /// <summary>
  ///   Interface para operações de escrita de clientes.
  /// </summary>
  ICustomerWriteRepository = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
  end;

  /// <summary>
  ///   Interface completa de repository combinando leitura e escrita.
  /// </summary>
  ICustomerRepository = interface(ICustomerReadRepository)
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
  end;

implementation

end.
```

### Implementação com FireDAC

```pascal
unit MeuApp.Infra.Customer.Repository;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  MeuApp.Domain.Customer.Entity,
  MeuApp.Domain.Customer.Repository.Intf;

type
  TCustomerRepository = class(TInterfacedObject, ICustomerRepository)
  private
    FConnection: TFDConnection;
  public
    constructor Create(AConnection: TFDConnection);

    { ICustomerReadRepository }
    function FindById(AId: Integer): TCustomer;
    function FindAll: TObjectList<TCustomer>;
    function FindByCpf(const ACpf: string): TCustomer;

    { ICustomerWriteRepository }
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
  end;

implementation

constructor TCustomerRepository.Create(AConnection: TFDConnection);
begin
  inherited Create;
  if not Assigned(AConnection) then
    raise EArgumentNilException.Create('AConnection cannot be nil');
  FConnection := AConnection;
end;

function TCustomerRepository.FindById(AId: Integer): TCustomer;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := 'SELECT * FROM customers WHERE id = :id';
    LQuery.ParamByName('id').AsInteger := AId;
    LQuery.Open;

    if not LQuery.IsEmpty then
    begin
      Result := TCustomer.Create(LQuery.FieldByName('name').AsString);
      Result.Id := LQuery.FieldByName('id').AsInteger;
    end;
  finally
    LQuery.Free;
  end;
end;

// ... demais métodos seguem o mesmo padrão
```

## Service Pattern

### Interface do Service

```pascal
unit MeuApp.Application.Customer.Service.Intf;

interface

uses
  MeuApp.Domain.Customer.Entity;

type
  ICustomerService = interface
    ['{D4E5F6A7-B8C9-0123-DEF0-234567890123}']
    function GetById(AId: Integer): TCustomer;
    procedure CreateCustomer(const AName: string; const ACpf: string);
    procedure UpdateCustomer(ACustomer: TCustomer);
    procedure DeleteCustomer(AId: Integer);
  end;

implementation

end.
```

### Implementação do Service

```pascal
unit MeuApp.Application.Customer.Service;

interface

uses
  System.SysUtils,
  MeuApp.Domain.Customer.Entity,
  MeuApp.Domain.Customer.Repository.Intf,
  MeuApp.Application.Customer.Service.Intf;

type
  /// <summary>
  ///   Service de clientes com validação e orquestração de dependências.
  /// </summary>
  TCustomerService = class(TInterfacedObject, ICustomerService)
  private
    FRepository: ICustomerRepository;
    procedure ValidateCpf(const ACpf: string);
  public
    constructor Create(ARepository: ICustomerRepository);
    function GetById(AId: Integer): TCustomer;
    procedure CreateCustomer(const AName: string; const ACpf: string);
    procedure UpdateCustomer(ACustomer: TCustomer);
    procedure DeleteCustomer(AId: Integer);
  end;

implementation

constructor TCustomerService.Create(ARepository: ICustomerRepository);
begin
  inherited Create;
  if not Assigned(ARepository) then
    raise EArgumentNilException.Create('ARepository cannot be nil');
  FRepository := ARepository;
end;

function TCustomerService.GetById(AId: Integer): TCustomer;
begin
  Result := FRepository.FindById(AId);
  if not Assigned(Result) then
    raise EEntityNotFoundException.CreateFmt('Customer not found: %d', [AId]);
end;

procedure TCustomerService.CreateCustomer(const AName: string; const ACpf: string);
var
  LCustomer: TCustomer;
  LExisting: TCustomer;
begin
  ValidateCpf(ACpf);

  LExisting := FRepository.FindByCpf(ACpf);
  if Assigned(LExisting) then
    raise EBusinessRuleException.CreateFmt('CPF already registered: %s', [ACpf]);

  LCustomer := TCustomer.Create(AName);
  try
    LCustomer.Cpf := ACpf;
    FRepository.Insert(LCustomer);
  except
    LCustomer.Free;
    raise;
  end;
end;

procedure TCustomerService.ValidateCpf(const ACpf: string);
const
  CPF_LENGTH = 11;
begin
  if ACpf.Trim.IsEmpty then
    raise EValidationException.Create('CPF cannot be empty');
  if ACpf.Length <> CPF_LENGTH then
    raise EValidationException.CreateFmt('CPF must have %d digits', [CPF_LENGTH]);
end;

// ... demais métodos
```

## Factory Pattern

```pascal
unit MeuApp.Infra.Factory;

interface

uses
  FireDAC.Comp.Client,
  MeuApp.Domain.Customer.Repository.Intf,
  MeuApp.Application.Customer.Service.Intf;

type
  /// <summary>
  ///   Factory para criar instâncias de services e repositories.
  /// </summary>
  TServiceFactory = class
  public
    class function CreateCustomerRepository(AConnection: TFDConnection): ICustomerRepository;
    class function CreateCustomerService(AConnection: TFDConnection): ICustomerService;
  end;

implementation

uses
  MeuApp.Infra.Customer.Repository,
  MeuApp.Application.Customer.Service;

class function TServiceFactory.CreateCustomerRepository(AConnection: TFDConnection): ICustomerRepository;
begin
  Result := TCustomerRepository.Create(AConnection);
end;

class function TServiceFactory.CreateCustomerService(AConnection: TFDConnection): ICustomerService;
var
  LRepo: ICustomerRepository;
begin
  LRepo := CreateCustomerRepository(AConnection);
  Result := TCustomerService.Create(LRepo);
end;
```

## Strategy Pattern

```pascal
unit MeuApp.Domain.Tax.Strategy;

interface

type
  /// <summary>
  ///   Interface para estratégias de cálculo de imposto.
  /// </summary>
  ITaxCalculator = interface
    ['{E5F6A7B8-C9D0-1234-EF01-345678901234}']
    function Calculate(ABaseValue: Currency): Currency;
    function GetDescription: string;
  end;

  TSimplesTaxCalculator = class(TInterfacedObject, ITaxCalculator)
  public
    function Calculate(ABaseValue: Currency): Currency;
    function GetDescription: string;
  end;

  TLucroPresumidoTaxCalculator = class(TInterfacedObject, ITaxCalculator)
  public
    function Calculate(ABaseValue: Currency): Currency;
    function GetDescription: string;
  end;

implementation

{ TSimplesTaxCalculator }

function TSimplesTaxCalculator.Calculate(ABaseValue: Currency): Currency;
const
  SIMPLES_RATE = 0.06;
begin
  Result := ABaseValue * SIMPLES_RATE;
end;

function TSimplesTaxCalculator.GetDescription: string;
begin
  Result := 'Simples Nacional (6%)';
end;

{ TLucroPresumidoTaxCalculator }

function TLucroPresumidoTaxCalculator.Calculate(ABaseValue: Currency): Currency;
const
  LUCRO_PRESUMIDO_RATE = 0.15;
begin
  Result := ABaseValue * LUCRO_PRESUMIDO_RATE;
end;

function TLucroPresumidoTaxCalculator.GetDescription: string;
begin
  Result := 'Lucro Presumido (15%)';
end;
```

## Checklist para Novas Implementações

Ao criar qualquer nova funcionalidade, verificar:

- [ ] Interface definida no Domain?
- [ ] Implementação no Infrastructure?
- [ ] Service no Application com constructor injection?
- [ ] Factory method atualizado?
- [ ] Guard clauses no início dos métodos?
- [ ] Try/finally para objetos temporários?
- [ ] Nomes seguindo convenções (T, I, E, F, A, L)?
- [ ] XMLDoc nos métodos públicos?
- [ ] Métodos ≤ 20 linhas?
- [ ] Sem `with`, sem variáveis globais, sem números mágicos?
