/// <summary>
///   Exemplo completo do padrão Service em Delphi.
///   Demonstra: SRP, DIP, constructor injection, guard clauses,
///   validação de negócio, constantes nomeadas e XMLDoc.
/// </summary>
unit Example.Application.Customer.Service;

interface

uses
  System.SysUtils,
  Example.Domain.Customer.Repository;

type
  // =========================================================================
  // Exceptions de domínio (SRP — cada exception tem um propósito)
  // =========================================================================

  EBusinessRuleException = class(Exception);
  EEntityNotFoundException = class(Exception);
  EValidationException = class(Exception);

  // =========================================================================
  // Interface do Service
  // =========================================================================

  /// <summary>
  ///   Interface para operações de negócio com clientes.
  /// </summary>
  ICustomerService = interface
    ['{B2C3D4E5-0002-0002-0002-000000000001}']
    function GetById(AId: Integer): TCustomer;
    function GetAll: TObjectList<TCustomer>;
    procedure CreateCustomer(const AName, ACpf, AEmail: string);
    procedure UpdateCustomer(ACustomer: TCustomer);
    procedure DeleteCustomer(AId: Integer);
    procedure DeactivateCustomer(AId: Integer);
  end;

  // =========================================================================
  // Implementação do Service (SRP + DIP)
  // =========================================================================

  /// <summary>
  ///   Service de clientes com validação e orquestração.
  ///   Depende de ICustomerRepository (DIP — abstração, não implementação).
  /// </summary>
  TCustomerService = class(TInterfacedObject, ICustomerService)
  private
    FRepository: ICustomerRepository;
    procedure ValidateCpf(const ACpf: string);
    procedure ValidateEmail(const AEmail: string);
    procedure EnsureCpfNotDuplicated(const ACpf: string);
  public
    constructor Create(ARepository: ICustomerRepository);

    /// <summary>Busca cliente por ID. Lança exception se não encontrado.</summary>
    function GetById(AId: Integer): TCustomer;

    /// <summary>Retorna todos os clientes.</summary>
    function GetAll: TObjectList<TCustomer>;

    /// <summary>Cria novo cliente com validações de negócio.</summary>
    procedure CreateCustomer(const AName, ACpf, AEmail: string);

    /// <summary>Atualiza dados do cliente.</summary>
    procedure UpdateCustomer(ACustomer: TCustomer);

    /// <summary>Exclui cliente por ID.</summary>
    procedure DeleteCustomer(AId: Integer);

    /// <summary>Desativa cliente (soft delete).</summary>
    procedure DeactivateCustomer(AId: Integer);
  end;

implementation

const
  CPF_LENGTH = 11;
  MIN_NAME_LENGTH = 3;

{ TCustomerService }

constructor TCustomerService.Create(ARepository: ICustomerRepository);
begin
  inherited Create;
  if not Assigned(ARepository) then
    raise EArgumentNilException.Create('ARepository não pode ser nil');
  FRepository := ARepository;
end;

function TCustomerService.GetById(AId: Integer): TCustomer;
begin
  Result := FRepository.FindById(AId);
  if not Assigned(Result) then
    raise EEntityNotFoundException.CreateFmt('Cliente não encontrado: %d', [AId]);
end;

function TCustomerService.GetAll: TObjectList<TCustomer>;
begin
  Result := FRepository.FindAll;
end;

procedure TCustomerService.CreateCustomer(const AName, ACpf, AEmail: string);
var
  LCustomer: TCustomer;
begin
  // Guard clauses — validação no início
  if AName.Trim.Length < MIN_NAME_LENGTH then
    raise EValidationException.CreateFmt(
      'Nome deve ter pelo menos %d caracteres', [MIN_NAME_LENGTH]);

  ValidateCpf(ACpf);
  ValidateEmail(AEmail);
  EnsureCpfNotDuplicated(ACpf);

  // Criação do objeto com tratamento de memória
  LCustomer := TCustomer.Create(AName);
  try
    LCustomer.Cpf := ACpf;
    LCustomer.Email := AEmail;
    FRepository.Insert(LCustomer);
  except
    LCustomer.Free;
    raise;
  end;
end;

procedure TCustomerService.UpdateCustomer(ACustomer: TCustomer);
begin
  if not Assigned(ACustomer) then
    raise EArgumentNilException.Create('ACustomer não pode ser nil');
  if not FRepository.Exists(ACustomer.Id) then
    raise EEntityNotFoundException.CreateFmt(
      'Cliente não encontrado: %d', [ACustomer.Id]);

  FRepository.Update(ACustomer);
end;

procedure TCustomerService.DeleteCustomer(AId: Integer);
begin
  if not FRepository.Exists(AId) then
    raise EEntityNotFoundException.CreateFmt(
      'Cliente não encontrado: %d', [AId]);

  FRepository.Delete(AId);
end;

procedure TCustomerService.DeactivateCustomer(AId: Integer);
var
  LCustomer: TCustomer;
begin
  LCustomer := GetById(AId); // Já lança exception se não encontrado
  try
    LCustomer.Deactivate;
    FRepository.Update(LCustomer);
  finally
    LCustomer.Free;
  end;
end;

// =========================================================================
// Métodos privados de validação (SRP — cada um faz uma coisa)
// =========================================================================

procedure TCustomerService.ValidateCpf(const ACpf: string);
begin
  if ACpf.Trim.IsEmpty then
    raise EValidationException.Create('CPF não pode ser vazio');
  if ACpf.Length <> CPF_LENGTH then
    raise EValidationException.CreateFmt(
      'CPF deve ter %d dígitos', [CPF_LENGTH]);
end;

procedure TCustomerService.ValidateEmail(const AEmail: string);
begin
  if AEmail.Trim.IsEmpty then
    raise EValidationException.Create('E-mail não pode ser vazio');
  if not AEmail.Contains('@') then
    raise EValidationException.Create('E-mail inválido');
end;

procedure TCustomerService.EnsureCpfNotDuplicated(const ACpf: string);
var
  LExisting: TCustomer;
begin
  LExisting := FRepository.FindByCpf(ACpf);
  try
    if Assigned(LExisting) then
      raise EBusinessRuleException.CreateFmt(
        'CPF já cadastrado: %s', [ACpf]);
  finally
    LExisting.Free;
  end;
end;

end.
