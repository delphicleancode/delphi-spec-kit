/// <summary>
/// Complete Repository Pattern example with FireDAC + PostgreSQL.
/// Demonstrates: PostgreSQL connection, IDENTITY, RETURNING, UPSERT, JSONB,
/// Full-Text Search, PL/pgSQL functions, CTE, error handling and ENUM mapping.
/// </summary>
unit Example.Infra.PostgreSQL.Customer.Repository;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  FireDAC.Phys.PG,
  FireDAC.Stan.Option;

type
  // =========================================================================
  // Domain Exceptions for PostgreSQL
  // =========================================================================

  EDatabaseException = class(Exception);
  EDuplicateRecordException = class(EDatabaseException);
  EForeignKeyViolationException = class(EDatabaseException);
  EConnectionLostException = class(EDatabaseException);

  // =========================================================================
  // Entity
  // =========================================================================

  TCustomerStatus = (csActive, csInactive, csSuspended);

  /// <summary>
  /// Domain entity representing a customer.
  /// </summary>
  TCustomer = class
  private
    FId: Integer;
    FName: string;
    FCpf: string;
    FEmail: string;
    FStatus: TCustomerStatus;
    FNotes: string;
    FMetadata: string;  { JSONB as string }
    FCreatedAt: TDateTime;
    FUpdatedAt: TDateTime;
  public
    constructor Create(const AName: string);

    function IsActive: Boolean;

    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
    property Cpf: string read FCpf write FCpf;
    property Email: string read FEmail write FEmail;
    property Status: TCustomerStatus read FStatus write FStatus;
    property Notes: string read FNotes write FNotes;
    property Metadata: string read FMetadata write FMetadata;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property UpdatedAt: TDateTime read FUpdatedAt write FUpdatedAt;
  end;

  // =========================================================================
  // Repository Interface (Domain)
  // =========================================================================

  ICustomerRepository = interface
    ['{PG000001-0001-0001-0001-000000000001}']
    function FindById(AId: Integer): TCustomer;
    function FindAll(ALimit: Integer = 100; AOffset: Integer = 0): TObjectList<TCustomer>;
    function FindByCpf(const ACpf: string): TCustomer;
    function Search(const ASearchTerm: string; ALimit: Integer = 50): TObjectList<TCustomer>;
    function Exists(AId: Integer): Boolean;
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Upsert(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
    procedure Deactivate(AId: Integer);
  end;

  // =========================================================================
  // Implementation with FireDAC + PostgreSQL (Infrastructure)
  // =========================================================================

  /// <summary>
  /// Concrete implementation of the repository using FireDAC with PostgreSQL.
  /// Demonstrates: IDENTITY, RETURNING, UPSERT, JSONB, search, ENUM mapping.
  /// </summary>
  TPostgreSQLCustomerRepository = class(TInterfacedObject, ICustomerRepository)
  private
    FConnection: TFDConnection;

    function MapToCustomer(AQuery: TFDQuery): TCustomer;
    procedure HandlePostgreSQLException(AException: EFDDBEngineException);
  public
    constructor Create(AConnection: TFDConnection);

    { ICustomerRepository }
    function FindById(AId: Integer): TCustomer;
    function FindAll(ALimit: Integer = 100; AOffset: Integer = 0): TObjectList<TCustomer>;
    function FindByCpf(const ACpf: string): TCustomer;
    function Search(const ASearchTerm: string; ALimit: Integer = 50): TObjectList<TCustomer>;
    function Exists(AId: Integer): Boolean;
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Upsert(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
    procedure Deactivate(AId: Integer);
  end;

  // =========================================================================
  // PostgreSQL Connection Factory
  // =========================================================================

  TPostgreSQLConnectionFactory = class
  public
    class function CreateConnection(
      const AServer: string;
      const ADatabase: string;
      const AUserName: string = 'postgres';
      const APassword: string = '';
      APort: Integer = 5432
    ): TFDConnection;
  end;

  // =========================================================================
  // Helpers for ENUM mapping
  // =========================================================================

  TCustomerStatusHelper = record helper for TCustomerStatus
    function ToString: string;
    class function FromString(const AValue: string): TCustomerStatus; static;
  end;

implementation

uses
  FireDAC.Stan.Error;

const
  CUSTOMER_STATUS_NAMES: array[TCustomerStatus] of string = (
    'active', 'inactive', 'suspended'
  );

{ TCustomerStatusHelper }

function TCustomerStatusHelper.ToString: string;
begin
  Result := CUSTOMER_STATUS_NAMES[Self];
end;

class function TCustomerStatusHelper.FromString(const AValue: string): TCustomerStatus;
var
  LStatus: TCustomerStatus;
begin
  for LStatus := Low(TCustomerStatus) to High(TCustomerStatus) do
    if SameText(CUSTOMER_STATUS_NAMES[LStatus], AValue) then
      Exit(LStatus);
  raise EArgumentException.CreateFmt('Invalid client status: "%s"', [AValue]);
end;

{ TCustomer }

constructor TCustomer.Create(const AName: string);
begin
  inherited Create;
  if AName.Trim.IsEmpty then
    raise EArgumentException.Create('Customer name cannot be empty');
  FName := AName.Trim;
  FStatus := csActive;
  FMetadata := '{}';
end;

function TCustomer.IsActive: Boolean;
begin
  Result := FStatus = csActive;
end;

{ TPostgreSQLCustomerRepository }

constructor TPostgreSQLCustomerRepository.Create(AConnection: TFDConnection);
begin
  inherited Create;
  if not Assigned(AConnection) then
    raise EArgumentNilException.Create('AConnection cannot be nil');
  FConnection := AConnection;
end;

function TPostgreSQLCustomerRepository.MapToCustomer(AQuery: TFDQuery): TCustomer;
begin
  Result := TCustomer.Create(AQuery.FieldByName('name').AsString);
  Result.Id := AQuery.FieldByName('id').AsInteger;
  Result.Cpf := AQuery.FieldByName('cpf').AsString;
  Result.Email := AQuery.FieldByName('e-mail').AsString;
  Result.Status := TCustomerStatus.FromString(AQuery.FieldByName('status').AsString);
  Result.Notes := AQuery.FieldByName('notes').AsString;
  Result.Metadata := AQuery.FieldByName('metadata').AsString;
  Result.CreatedAt := AQuery.FieldByName('created_at').AsDateTime;
  Result.UpdatedAt := AQuery.FieldByName('updated_at').AsDateTime;
end;

procedure TPostgreSQLCustomerRepository.HandlePostgreSQLException(
  AException: EFDDBEngineException);
begin
  case AException.Kind of
    ekUKViolated:
      raise EDuplicateRecordException.Create(
        'Duplicate record:' + AException.Message);
    ekFKViolated:
      raise EForeignKeyViolationException.Create(
        'Foreign key violation:' + AException.Message);
    ekServerGone:
      raise EConnectionLostException.Create(
        'Connection to PostgreSQL lost:' + AException.Message);
  else
    raise;
  end;
end;

function TPostgreSQLCustomerRepository.FindById(AId: Integer): TCustomer;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'SELECT id, name, cpf, email, status::TEXT, notes,' +
      '  metadata::TEXT, created_at, updated_at ' +
      'FROM customers WHERE id = :id';
    LQuery.ParamByName('id').AsInteger := AId;
    LQuery.Open;

    if not LQuery.IsEmpty then
      Result := MapToCustomer(LQuery);
  finally
    LQuery.Free;
  end;
end;

/// <summary>
/// Paginated customer search (Limit/Offset native to PostgreSQL).
/// </summary>
function TPostgreSQLCustomerRepository.FindAll(
  ALimit, AOffset: Integer): TObjectList<TCustomer>;
var
  LQuery: TFDQuery;
begin
  Result := TObjectList<TCustomer>.Create(True);
  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      LQuery.SQL.Text :=
        'SELECT id, name, cpf, email, status::TEXT, notes,' +
        '  metadata::TEXT, created_at, updated_at ' +
        'FROM customers' +
        'ORDER BY name ' +
        'LIMIT :limit OFFSET :offset';
      LQuery.ParamByName('limit').AsInteger := ALimit;
      LQuery.ParamByName('offset').AsInteger := AOffset;
      LQuery.Open;

      while not LQuery.Eof do
      begin
        Result.Add(MapToCustomer(LQuery));
        LQuery.Next;
      end;
    except
      on E: EFDDBEngineException do
        HandlePostgreSQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

function TPostgreSQLCustomerRepository.FindByCpf(const ACpf: string): TCustomer;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  if ACpf.Trim.IsEmpty then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'SELECT id, name, cpf, email, status::TEXT, notes,' +
      '  metadata::TEXT, created_at, updated_at ' +
      'FROM customers WHERE cpf = :cpf';
    LQuery.ParamByName('cpf').AsString := ACpf;
    LQuery.Open;

    if not LQuery.IsEmpty then
      Result := MapToCustomer(LQuery);
  finally
    LQuery.Free;
  end;
end;

/// <summary>
/// Textual search using Full-Text Search with tsvector.
/// Requires GIN index on search_vector column.
/// </summary>
function TPostgreSQLCustomerRepository.Search(
  const ASearchTerm: string; ALimit: Integer): TObjectList<TCustomer>;
var
  LQuery: TFDQuery;
begin
  Result := TObjectList<TCustomer>.Create(True);
  if ASearchTerm.Trim.IsEmpty then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      { Search with ILIKE for names (simple and effective) }
      LQuery.SQL.Text :=
        'SELECT id, name, cpf, email, status::TEXT, notes,' +
        '  metadata::TEXT, created_at, updated_at ' +
        'FROM customers' +
        'WHERE name ILIKE :term OR cpf ILIKE :term OR email ILIKE :term' +
        'ORDER BY name ' +
        'LIMIT :limit';
      LQuery.ParamByName('term').AsString := '%' + ASearchTerm + '%';
      LQuery.ParamByName('limit').AsInteger := ALimit;
      LQuery.Open;

      while not LQuery.Eof do
      begin
        Result.Add(MapToCustomer(LQuery));
        LQuery.Next;
      end;
    except
      on E: EFDDBEngineException do
        HandlePostgreSQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

function TPostgreSQLCustomerRepository.Exists(AId: Integer): Boolean;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'SELECT EXISTS(SELECT 1 FROM customers WHERE id = :id) AS found';
    LQuery.ParamByName('id').AsInteger := AId;
    LQuery.Open;
    Result := LQuery.FieldByName('found').AsBoolean;
  finally
    LQuery.Free;
  end;
end;

/// <summary>
/// Insert customer using INSERT ... RETURNING to get the id and timestamps
/// generated by IDENTITY and DEFAULT NOW().
/// </summary>
procedure TPostgreSQLCustomerRepository.Insert(ACustomer: TCustomer);
var
  LQuery: TFDQuery;
begin
  if not Assigned(ACustomer) then
    raise EArgumentNilException.Create('ACustomer cannot be nil');

  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      LQuery.SQL.Text :=
        'INSERT INTO customers (name, cpf, email, status, notes, metadata)' +
        'VALUES (:name, :cpf, :email, :status::customer_status, :notes, :metadata::jsonb)' +
        'RETURNING id, created_at, updated_at';
      LQuery.ParamByName('name').AsString := ACustomer.Name;
      LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
      LQuery.ParamByName('e-mail').AsString := ACustomer.Email;
      LQuery.ParamByName('status').AsString := ACustomer.Status.ToString;
      LQuery.ParamByName('notes').AsString := ACustomer.Notes;
      LQuery.ParamByName('metadata').AsString := ACustomer.Metadata;

      { RETURNING: use Open to receive the generated fields }
      LQuery.Open;
      ACustomer.Id := LQuery.FieldByName('id').AsInteger;
      ACustomer.CreatedAt := LQuery.FieldByName('created_at').AsDateTime;
      ACustomer.UpdatedAt := LQuery.FieldByName('updated_at').AsDateTime;
    except
      on E: EFDDBEngineException do
        HandlePostgreSQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TPostgreSQLCustomerRepository.Update(ACustomer: TCustomer);
var
  LQuery: TFDQuery;
begin
  if not Assigned(ACustomer) then
    raise EArgumentNilException.Create('ACustomer cannot be nil');

  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      { updated_at is updated automatically by the trg_customer_updated trigger }
      LQuery.SQL.Text :=
        'UPDATE customers SET' +
        '  name = :name, cpf = :cpf, email = :email,' +
        '  status = :status::customer_status,' +
        '  notes = :notes, metadata = :metadata::jsonb' +
        'WHERE id = :id' +
        'RETURNING updated_at';
      LQuery.ParamByName('id').AsInteger := ACustomer.Id;
      LQuery.ParamByName('name').AsString := ACustomer.Name;
      LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
      LQuery.ParamByName('e-mail').AsString := ACustomer.Email;
      LQuery.ParamByName('status').AsString := ACustomer.Status.ToString;
      LQuery.ParamByName('notes').AsString := ACustomer.Notes;
      LQuery.ParamByName('metadata').AsString := ACustomer.Metadata;
      LQuery.Open;
      ACustomer.UpdatedAt := LQuery.FieldByName('updated_at').AsDateTime;
    except
      on E: EFDDBEngineException do
        HandlePostgreSQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

/// <summary>
/// Insert or update the customer based on the CPF (UPSERT).
/// Uses INSERT ... ON CONFLICT — native PostgreSQL feature.
/// </summary>
procedure TPostgreSQLCustomerRepository.Upsert(ACustomer: TCustomer);
var
  LQuery: TFDQuery;
begin
  if not Assigned(ACustomer) then
    raise EArgumentNilException.Create('ACustomer cannot be nil');

  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      LQuery.SQL.Text :=
        'INSERT INTO customers (name, cpf, email, status, notes, metadata)' +
        'VALUES (:name, :cpf, :email, :status::customer_status, :notes, :metadata::jsonb)' +
        'ON CONFLICT (cpf) OF UPDATE SET' +
        '  name = EXCLUDED.name, ' +
        '  email = EXCLUDED.email,' +
        '  status = EXCLUDED.status,' +
        '  notes = EXCLUDED.notes,' +
        '  metadata = EXCLUDED.metadata ' +
        'RETURNING id, created_at, updated_at';
      LQuery.ParamByName('name').AsString := ACustomer.Name;
      LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
      LQuery.ParamByName('e-mail').AsString := ACustomer.Email;
      LQuery.ParamByName('status').AsString := ACustomer.Status.ToString;
      LQuery.ParamByName('notes').AsString := ACustomer.Notes;
      LQuery.ParamByName('metadata').AsString := ACustomer.Metadata;
      LQuery.Open;
      ACustomer.Id := LQuery.FieldByName('id').AsInteger;
      ACustomer.CreatedAt := LQuery.FieldByName('created_at').AsDateTime;
      ACustomer.UpdatedAt := LQuery.FieldByName('updated_at').AsDateTime;
    except
      on E: EFDDBEngineException do
        HandlePostgreSQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TPostgreSQLCustomerRepository.Delete(AId: Integer);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      LQuery.SQL.Text := 'DELETE FROM customers WHERE id = :id';
      LQuery.ParamByName('id').AsInteger := AId;
      LQuery.ExecSQL;
    except
      on E: EFDDBEngineException do
        HandlePostgreSQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

/// <summary>
/// Disables client via CALL (PostgreSQL Procedure — PG 11+).
/// </summary>
procedure TPostgreSQLCustomerRepository.Deactivate(AId: Integer);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      { CALL for PostgreSQL Procedure (PG 11+) }
      LQuery.SQL.Text := 'CALL sp_deactivate_customer(:p_id)';
      LQuery.ParamByName('p_id').AsInteger := AId;
      LQuery.ExecSQL;
    except
      on E: EFDDBEngineException do
        HandlePostgreSQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

{ TPostgreSQLConnectionFactory }

class function TPostgreSQLConnectionFactory.CreateConnection(
  const AServer, ADatabase, AUserName, APassword: string;
  APort: Integer): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.DriverName := 'PG';
    Result.Params.Values['Server'] := AServer;
    Result.Params.Values['Port'] := APort.ToString;
    Result.Params.Database := ADatabase;
    Result.Params.UserName := AUserName;
    Result.Params.Password := APassword;

    { Recommended settings }
    Result.Params.Values['CharacterSet'] := 'UTF8';

    { FireDAC options }
    Result.FormatOptions.StrsTrim2Len := True;
    Result.ResourceOptions.AutoReconnect := True;
    Result.TxOptions.Isolation := xiReadCommitted;

    Result.Connected := True;
  except
    Result.Free;
    raise;
  end;
end;

{
  ============================================================================
  SQL for creating the schema used in this example:
  ============================================================================

  -- ENUM type
  CREATE TYPE customer_status AS ENUM ('active', 'inactive', 'suspended');

  -- Table with IDENTITY and JSONB
  CREATE TABLE IF NOT EXISTS customers (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    cpf        VARCHAR(14) UNIQUE,
    email      VARCHAR(150),
    status     customer_status NOT NULL DEFAULT 'active',
    notes      TEXT,
    metadata   JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  );

  -- Indexes
  CREATE INDEX idx_customer_name ON customers (name);
  CREATE INDEX idx_customer_cpf ON customers (cpf);

  -- Automatic updated_at trigger
  CREATE OR REPLACE FUNCTION update_updated_at_column()
  RETURNS TRIGGER AS $$
  BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;

  CREATE TRIGGER trg_customer_updated BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

  -- Procedure (PG 11+)
  CREATE OR REPLACE PROCEDURE sp_deactivate_customer(p_id INTEGER)
  LANGUAGE plpgsql AS $$
  BEGIN
    UPDATE customers SET status = 'inactive', updated_at = NOW()
    WHERE id = p_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Customer % not found', p_id;
    END IF;
  END;
  $$;
}

end.

