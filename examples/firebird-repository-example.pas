/// <summary>
/// Complete example of Repository Pattern with FireDAC + Firebird.
/// Demonstrates: Firebird connection, generators, RETURNING, transactions,
/// stored procedures, error handling, domains and PSQL.
/// </summary>
unit Example.Infra.Firebird.Customer.Repository;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  FireDAC.Phys.FB,
  FireDAC.Stan.Option;

type
  // =========================================================================
  // Domain Exceptions for Firebird
  // =========================================================================

  EDatabaseException = class(Exception);
  ERecordLockedException = class(EDatabaseException);
  EDuplicateRecordException = class(EDatabaseException);
  EForeignKeyViolationException = class(EDatabaseException);

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
    FCreatedAt: TDateTime;
  public
    constructor Create(const AName: string);

    function IsActive: Boolean;

    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
    property Cpf: string read FCpf write FCpf;
    property Email: string read FEmail write FEmail;
    property Status: TCustomerStatus read FStatus write FStatus;
    property Notes: string read FNotes write FNotes;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
  end;

  // =========================================================================
  // Repository Interface (Domain — bank agnostic layer)
  // =========================================================================

  ICustomerRepository = interface
    ['{FB000001-0001-0001-0001-000000000001}']
    function FindById(AId: Integer): TCustomer;
    function FindAll: TObjectList<TCustomer>;
    function FindByCpf(const ACpf: string): TCustomer;
    function FindByStatus(AStatus: TCustomerStatus): TObjectList<TCustomer>;
    function Exists(AId: Integer): Boolean;
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
    procedure Deactivate(AId: Integer);
  end;

  // =========================================================================
  // Implementation with FireDAC + Firebird (Infrastructure)
  // =========================================================================

  /// <summary>
  /// Concrete implementation of the repository using FireDAC with Firebird.
  /// Demonstrates: RETURNING, generators, stored procedures, error handling.
  /// </summary>
  TFirebirdCustomerRepository = class(TInterfacedObject, ICustomerRepository)
  private
    FConnection: TFDConnection;

    /// <summary>
    /// Maps a TFDQuery record to the TCustomer entity.
    /// </summary>
    function MapToCustomer(AQuery: TFDQuery): TCustomer;

    /// <summary>
    /// Handles Firebird exceptions and converts them to domain exceptions.
    /// </summary>
    procedure HandleFirebirdException(AException: EFDDBEngineException);
  public
    constructor Create(AConnection: TFDConnection);

    { ICustomerRepository }
    function FindById(AId: Integer): TCustomer;
    function FindAll: TObjectList<TCustomer>;
    function FindByCpf(const ACpf: string): TCustomer;
    function FindByStatus(AStatus: TCustomerStatus): TObjectList<TCustomer>;
    function Exists(AId: Integer): Boolean;
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
    procedure Deactivate(AId: Integer);
  end;

  // =========================================================================
  // Firebird Connection Factory
  // =========================================================================

  /// <summary>
  /// Factory to create correctly configured Firebird connections.
  /// </summary>
  TFirebirdConnectionFactory = class
  public
    /// <summary>
    /// Creates Firebird connection with recommended settings.
    /// </summary>
    class function CreateConnection(
      const AServer: string;
      const ADatabase: string;
      const AUserName: string = 'SYSDBA';
      const APassword: string = 'masterkey'
    ): TFDConnection;
  end;

implementation

uses
  FireDAC.Stan.Error;

const
  { Generator names — centralized as constants }
  GENERATOR_CUSTOMER_ID = 'GEN_CUSTOMER_ID';

{ TCustomer }

constructor TCustomer.Create(const AName: string);
begin
  inherited Create;
  if AName.Trim.IsEmpty then
    raise EArgumentException.Create('Customer name cannot be empty');
  FName := AName.Trim;
  FStatus := csActive;
end;

function TCustomer.IsActive: Boolean;
begin
  Result := FStatus = csActive;
end;

{ TFirebirdCustomerRepository }

constructor TFirebirdCustomerRepository.Create(AConnection: TFDConnection);
begin
  inherited Create;
  if not Assigned(AConnection) then
    raise EArgumentNilException.Create('AConnection cannot be nil');
  FConnection := AConnection;
end;

function TFirebirdCustomerRepository.MapToCustomer(AQuery: TFDQuery): TCustomer;
begin
  Result := TCustomer.Create(AQuery.FieldByName('name').AsString);
  Result.Id := AQuery.FieldByName('id').AsInteger;
  Result.Cpf := AQuery.FieldByName('cpf').AsString;
  Result.Email := AQuery.FieldByName('e-mail').AsString;
  Result.Status := TCustomerStatus(AQuery.FieldByName('status').AsInteger);
  Result.Notes := AQuery.FieldByName('notes').AsString;
  Result.CreatedAt := AQuery.FieldByName('created_at').AsDateTime;
end;

procedure TFirebirdCustomerRepository.HandleFirebirdException(
  AException: EFDDBEngineException);
begin
  case AException.Kind of
    ekRecordLocked:
      raise ERecordLockedException.Create(
        'Record locked by another transaction. Please try again.');
    ekUKViolated:
      raise EDuplicateRecordException.Create(
        'Duplicate record:' + AException.Message);
    ekFKViolated:
      raise EForeignKeyViolationException.Create(
        'Foreign key violation:' + AException.Message);
  else
    raise; { Re-raise unhandled exceptions }
  end;
end;

function TFirebirdCustomerRepository.FindById(AId: Integer): TCustomer;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'SELECT id, name, cpf, email, status, notes, created_at' +
      'FROM customers WHERE id = :id';
    LQuery.ParamByName('id').AsInteger := AId;
    LQuery.Open;

    if not LQuery.IsEmpty then
      Result := MapToCustomer(LQuery);
  finally
    LQuery.Free;
  end;
end;

function TFirebirdCustomerRepository.FindAll: TObjectList<TCustomer>;
var
  LQuery: TFDQuery;
begin
  Result := TObjectList<TCustomer>.Create(True);
  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      LQuery.SQL.Text :=
        'SELECT id, name, cpf, email, status, notes, created_at' +
        'FROM customers ORDER BY name';
      LQuery.Open;

      while not LQuery.Eof do
      begin
        Result.Add(MapToCustomer(LQuery));
        LQuery.Next;
      end;
    except
      on E: EFDDBEngineException do
        HandleFirebirdException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

function TFirebirdCustomerRepository.FindByCpf(const ACpf: string): TCustomer;
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
      'SELECT id, name, cpf, email, status, notes, created_at' +
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
/// Uses Firebird's Stored Procedure Selectable to search for status.
/// </summary>
function TFirebirdCustomerRepository.FindByStatus(
  AStatus: TCustomerStatus): TObjectList<TCustomer>;
var
  LQuery: TFDQuery;
begin
  Result := TObjectList<TCustomer>.Create(True);
  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      { Selectable Stored Procedure call — treated as SELECT }
      LQuery.SQL.Text :=
        'SELECT O_ID AS id, O_NAME AS name, O_CPF AS cpf,' +
        ''''''''' '''''''' AS email, O_STATUS AS status, '''''''''''''''' AS notes,' +
        'CURRENT_TIMESTAMP AS created_at' +
        'FROM SP_CUSTOMERS_BY_STATUS(:P_STATUS)';
      LQuery.ParamByName('P_STATUS').AsSmallInt := Ord(AStatus);
      LQuery.Open;

      while not LQuery.Eof do
      begin
        Result.Add(MapToCustomer(LQuery));
        LQuery.Next;
      end;
    except
      on E: EFDDBEngineException do
        HandleFirebirdException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

function TFirebirdCustomerRepository.Exists(AId: Integer): Boolean;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'SELECT COUNT(*) AS cnt FROM customers WHERE id = :id';
    LQuery.ParamByName('id').AsInteger := AId;
    LQuery.Open;
    Result := LQuery.FieldByName('cnt').AsInteger > 0;
  finally
    LQuery.Free;
  end;
end;

/// <summary>
/// Inserts customer using INSERT ... RETURNING to obtain the generated ID.
/// The GEN_CUSTOMER_ID generator is incremented by the TRG_CUSTOMER_BI trigger.
/// </summary>
procedure TFirebirdCustomerRepository.Insert(ACustomer: TCustomer);
var
  LQuery: TFDQuery;
begin
  if not Assigned(ACustomer) then
    raise EArgumentNilException.Create('ACustomer cannot be nil');

  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      { RETURNING returns the ID generated by the trigger/generator }
      LQuery.SQL.Text :=
        'INSERT INTO customers (name, cpf, email, status, notes)' +
        'VALUES (:name, :cpf, :email, :status, :notes)' +
        'RETURNING id, created_at';
      LQuery.ParamByName('name').AsString := ACustomer.Name;
      LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
      LQuery.ParamByName('e-mail').AsString := ACustomer.Email;
      LQuery.ParamByName('status').AsSmallInt := Ord(ACustomer.Status);
      LQuery.ParamByName('notes').AsString := ACustomer.Notes;

      { IMPORTANT: use Open (not ExecSQL) to receive the RETURNING value }
      LQuery.Open;
      ACustomer.Id := LQuery.FieldByName('id').AsInteger;
      ACustomer.CreatedAt := LQuery.FieldByName('created_at').AsDateTime;
    except
      on E: EFDDBEngineException do
        HandleFirebirdException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TFirebirdCustomerRepository.Update(ACustomer: TCustomer);
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
        'UPDATE customers SET' +
        '  name = :name, cpf = :cpf, email = :email,' +
        '  status = :status, notes = :notes' +
        'WHERE id = :id';
      LQuery.ParamByName('id').AsInteger := ACustomer.Id;
      LQuery.ParamByName('name').AsString := ACustomer.Name;
      LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
      LQuery.ParamByName('e-mail').AsString := ACustomer.Email;
      LQuery.ParamByName('status').AsSmallInt := Ord(ACustomer.Status);
      LQuery.ParamByName('notes').AsString := ACustomer.Notes;
      LQuery.ExecSQL;
    except
      on E: EFDDBEngineException do
        HandleFirebirdException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TFirebirdCustomerRepository.Delete(AId: Integer);
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
        HandleFirebirdException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

/// <summary>
/// Disables client via Firebird's Stored Procedure Executable.
/// </summary>
procedure TFirebirdCustomerRepository.Deactivate(AId: Integer);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      { Executable Stored Procedure — use EXECUTE PROCEDURE }
      LQuery.SQL.Text := 'EXECUTE PROCEDURE SP_DEACTIVATE_CUSTOMER(:P_CUSTOMER_ID)';
      LQuery.ParamByName('P_CUSTOMER_ID').AsInteger := AId;
      LQuery.ExecSQL;
    except
      on E: EFDDBEngineException do
        HandleFirebirdException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

{ TFirebirdConnectionFactory }

class function TFirebirdConnectionFactory.CreateConnection(
  const AServer, ADatabase, AUserName, APassword: string): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.DriverName := 'FB';
    Result.Params.Values['Server'] := AServer;
    Result.Params.Database := ADatabase;
    Result.Params.UserName := AUserName;
    Result.Params.Password := APassword;

    { Mandatory Firebird settings }
    Result.Params.Values['CharacterSet'] := 'UTF8';
    Result.Params.Values['SQLDialect'] := '3';
    Result.Params.Values['Protocol'] := 'TCPIP';
    Result.Params.Values['Port'] := '3050';
    Result.Params.Values['PageSize'] := '16384';

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
  SQL for creating tables and objects used in this example:
  ============================================================================

  -- Domains
  CREATE DOMAIN DM_ID     AS INTEGER NOT NULL;
  CREATE DOMAIN DM_NAME   AS VARCHAR(100) NOT NULL;
  CREATE DOMAIN DM_CPF    AS VARCHAR(14);
  CREATE DOMAIN DM_EMAIL  AS VARCHAR(150);
  CREATE DOMAIN DM_MEMO   AS BLOB SUB_TYPE TEXT SEGMENT SIZE 4096;
  CREATE DOMAIN DM_STATUS AS SMALLINT DEFAULT 0 CHECK (VALUE BETWEEN 0 AND 2);

  -- Generator
  CREATE GENERATOR GEN_CUSTOMER_ID;

  -- Table
  CREATE TABLE customers (
    id         DM_ID,
    name       DM_NAME,
    cpf        DM_CPF,
    email      DM_EMAIL,
    status     DM_STATUS,
    notes      DM_MEMO,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_CUSTOMER PRIMARY KEY (id),
    CONSTRAINT UQ_CUSTOMER_CPF UNIQUE (cpf)
  );

  CREATE INDEX IDX_CUSTOMER_NAME ON customers (name);

  -- Auto-increment trigger
  SET TERM ^;
  CREATE TRIGGER TRG_CUSTOMER_BI FOR customers
    ACTIVE BEFORE INSERT POSITION 0
  AS
  BEGIN
    IF (NEW.id IS NULL OR NEW.id = 0) THEN
      NEW.id = GEN_ID(GEN_CUSTOMER_ID, 1);
  END^

  -- Stored Procedure Selectable
  CREATE OR ALTER PROCEDURE SP_CUSTOMERS_BY_STATUS (
    P_STATUS SMALLINT
  )
  RETURNS (
    O_ID     INTEGER,
    O_NAME   VARCHAR(100),
    O_CPF    VARCHAR(14),
    O_STATUS SMALLINT
  )
  AS
  BEGIN
    FOR SELECT id, name, cpf, status
        FROM customers
        WHERE status = :P_STATUS
        INTO :O_ID, :O_NAME, :O_CPF, :O_STATUS
    DO
      SUSPEND;
  END^

  -- Stored Procedure Executable
  CREATE OR ALTER PROCEDURE SP_DEACTIVATE_CUSTOMER (
    P_CUSTOMER_ID INTEGER
  )
  AS
  BEGIN
    UPDATE customers SET status = 1 WHERE id = :P_CUSTOMER_ID;
  END^

  SET TERM ;^
}

end.

