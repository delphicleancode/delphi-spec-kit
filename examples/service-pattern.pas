/// <summary>
/// Complete example of the Service pattern in Delphi.
/// Demonstrates: SRP, DIP, constructor injection, guard clauses,
/// business validation, named constants and XMLDoc.
/// </summary>
unit Example.Application.Customer.Service;

interface

uses
  System.SysUtils,
  Example.Domain.Customer.Repository;

type
  // =========================================================================
  // Domain exceptions (SRP — each exception has a purpose)
  // =========================================================================

  EBusinessRuleException = class(Exception);
  EEntityNotFoundException = class(Exception);
  EValidationException = class(Exception);

  // =========================================================================
  // Service Interface
  // =========================================================================

  /// <summary>
  /// Interface for business operations with customers.
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
  // Service Implementation (SRP + DIP)
  // =========================================================================

  /// <summary>
  /// Customer service with validation and orchestration.
  /// Depends on ICustomerRepository (DIP — abstraction, not implementation).
  /// </summary>
  TCustomerService = class(TInterfacedObject, ICustomerService)
  private
    FRepository: ICustomerRepository;
    procedure ValidateCpf(const ACpf: string);
    procedure ValidateEmail(const AEmail: string);
    procedure EnsureCpfNotDuplicated(const ACpf: string);
  public
    constructor Create(ARepository: ICustomerRepository);

    /// <summary>Search customer by ID. Throws exception if not found.</summary>
    function GetById(AId: Integer): TCustomer;

    /// <summary>Returns all customers.</summary>
    function GetAll: TObjectList<TCustomer>;

    /// <summary>Create new client with business validations.</summary>
    procedure CreateCustomer(const AName, ACpf, AEmail: string);

    /// <summary>Updates customer data.</summary>
    procedure UpdateCustomer(ACustomer: TCustomer);

    /// <summary>Excludes customer by ID.</summary>
    procedure DeleteCustomer(AId: Integer);

    /// <summary>Deactivate client (soft delete).</summary>
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
    raise EArgumentNilException.Create('ARepository cannot be nil');
  FRepository := ARepository;
end;

function TCustomerService.GetById(AId: Integer): TCustomer;
begin
  Result := FRepository.FindById(AId);
  if not Assigned(Result) then
    raise EEntityNotFoundException.CreateFmt('Customer not found: %d', [AId]);
end;

function TCustomerService.GetAll: TObjectList<TCustomer>;
begin
  Result := FRepository.FindAll;
end;

procedure TCustomerService.CreateCustomer(const AName, ACpf, AEmail: string);
var
  LCustomer: TCustomer;
begin
  // Guard clauses — validation at the beginning
  if AName.Trim.Length < MIN_NAME_LENGTH then
    raise EValidationException.CreateFmt(
      'Name must have at least %d characters', [MIN_NAME_LENGTH]);

  ValidateCpf(ACpf);
  ValidateEmail(AEmail);
  EnsureCpfNotDuplicated(ACpf);

  // Object creation with memory processing
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
    raise EArgumentNilException.Create('ACustomer cannot be nil');
  if not FRepository.Exists(ACustomer.Id) then
    raise EEntityNotFoundException.CreateFmt(
      'Customer not found: %d', [ACustomer.Id]);

  FRepository.Update(ACustomer);
end;

procedure TCustomerService.DeleteCustomer(AId: Integer);
begin
  if not FRepository.Exists(AId) then
    raise EEntityNotFoundException.CreateFmt(
      'Customer not found: %d', [AId]);

  FRepository.Delete(AId);
end;

procedure TCustomerService.DeactivateCustomer(AId: Integer);
var
  LCustomer: TCustomer;
begin
  LCustomer := GetById(AId); // Already raises exception if not found
  try
    LCustomer.Deactivate;
    FRepository.Update(LCustomer);
  finally
    LCustomer.Free;
  end;
end;

// =========================================================================
// Private validation methods (SRP — each one does one thing)
// =========================================================================

procedure TCustomerService.ValidateCpf(const ACpf: string);
begin
  if ACpf.Trim.IsEmpty then
    raise EValidationException.Create('CPF cannot be empty');
  if ACpf.Length <> CPF_LENGTH then
    raise EValidationException.CreateFmt(
      'CPF must have %d digits', [CPF_LENGTH]);
end;

procedure TCustomerService.ValidateEmail(const AEmail: string);
begin
  if AEmail.Trim.IsEmpty then
    raise EValidationException.Create('Email cannot be empty');
  if not AEmail.Contains('@') then
    raise EValidationException.Create('Invalid email');
end;

procedure TCustomerService.EnsureCpfNotDuplicated(const ACpf: string);
var
  LExisting: TCustomer;
begin
  LExisting := FRepository.FindByCpf(ACpf);
  try
    if Assigned(LExisting) then
      raise EBusinessRuleException.CreateFmt(
        'CPF already registered: %s', [ACpf]);
  finally
    LExisting.Free;
  end;
end;

end.

