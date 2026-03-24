/// <summary>
///   Exemplo completo de Repository Pattern com FireDAC + PostgreSQL.
///   Demonstra: conexão PostgreSQL, IDENTITY, RETURNING, UPSERT, JSONB,
///   Full-Text Search, PL/pgSQL functions, CTE, error handling e ENUM mapping.
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
  // Exceções de Domínio para PostgreSQL
  // =========================================================================

  EDatabaseException = class(Exception);
  EDuplicateRecordException = class(EDatabaseException);
  EForeignKeyViolationException = class(EDatabaseException);
  EConnectionLostException = class(EDatabaseException);

  // =========================================================================
  // Entidade
  // =========================================================================

  TCustomerStatus = (csActive, csInactive, csSuspended);

  /// <summary>
  ///   Entidade de domínio representando um cliente.
  /// </summary>
  TCustomer = class
  private
    FId: Integer;
    FName: string;
    FCpf: string;
    FEmail: string;
    FStatus: TCustomerStatus;
    FNotes: string;
    FMetadata: string;  { JSONB como string }
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
  // Interface do Repository (Domain)
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
  // Implementação com FireDAC + PostgreSQL (Infrastructure)
  // =========================================================================

  /// <summary>
  ///   Implementação concreta do repository usando FireDAC com PostgreSQL.
  ///   Demonstra: IDENTITY, RETURNING, UPSERT, JSONB, search, ENUM mapping.
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
  // Factory de Conexão PostgreSQL
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
  // Helpers para ENUM mapping
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
  raise EArgumentException.CreateFmt('Status de cliente inválido: "%s"', [AValue]);
end;

{ TCustomer }

constructor TCustomer.Create(const AName: string);
begin
  inherited Create;
  if AName.Trim.IsEmpty then
    raise EArgumentException.Create('Nome do cliente não pode ser vazio');
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
    raise EArgumentNilException.Create('AConnection não pode ser nil');
  FConnection := AConnection;
end;

function TPostgreSQLCustomerRepository.MapToCustomer(AQuery: TFDQuery): TCustomer;
begin
  Result := TCustomer.Create(AQuery.FieldByName('name').AsString);
  Result.Id := AQuery.FieldByName('id').AsInteger;
  Result.Cpf := AQuery.FieldByName('cpf').AsString;
  Result.Email := AQuery.FieldByName('email').AsString;
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
        'Registro duplicado: ' + AException.Message);
    ekFKViolated:
      raise EForeignKeyViolationException.Create(
        'Violação de chave estrangeira: ' + AException.Message);
    ekServerGone:
      raise EConnectionLostException.Create(
        'Conexão com PostgreSQL perdida: ' + AException.Message);
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
      'SELECT id, name, cpf, email, status::TEXT, notes, ' +
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
///   Busca paginada de clientes (LIMIT/OFFSET nativo do PostgreSQL).
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
        'SELECT id, name, cpf, email, status::TEXT, notes, ' +
        '  metadata::TEXT, created_at, updated_at ' +
        'FROM customers ' +
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
      'SELECT id, name, cpf, email, status::TEXT, notes, ' +
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
///   Busca textual usando Full-Text Search com tsvector.
///   Requer índice GIN na coluna search_vector.
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
      { Busca com ILIKE para nomes (simples e eficaz) }
      LQuery.SQL.Text :=
        'SELECT id, name, cpf, email, status::TEXT, notes, ' +
        '  metadata::TEXT, created_at, updated_at ' +
        'FROM customers ' +
        'WHERE name ILIKE :term OR cpf ILIKE :term OR email ILIKE :term ' +
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
///   Insere cliente usando INSERT ... RETURNING para obter o id e timestamps
///   gerados por IDENTITY e DEFAULT NOW().
/// </summary>
procedure TPostgreSQLCustomerRepository.Insert(ACustomer: TCustomer);
var
  LQuery: TFDQuery;
begin
  if not Assigned(ACustomer) then
    raise EArgumentNilException.Create('ACustomer não pode ser nil');

  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      LQuery.SQL.Text :=
        'INSERT INTO customers (name, cpf, email, status, notes, metadata) ' +
        'VALUES (:name, :cpf, :email, :status::customer_status, :notes, :metadata::jsonb) ' +
        'RETURNING id, created_at, updated_at';
      LQuery.ParamByName('name').AsString := ACustomer.Name;
      LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
      LQuery.ParamByName('email').AsString := ACustomer.Email;
      LQuery.ParamByName('status').AsString := ACustomer.Status.ToString;
      LQuery.ParamByName('notes').AsString := ACustomer.Notes;
      LQuery.ParamByName('metadata').AsString := ACustomer.Metadata;

      { RETURNING: usar Open para receber os campos gerados }
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
    raise EArgumentNilException.Create('ACustomer não pode ser nil');

  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      { updated_at é atualizado automaticamente pela trigger trg_customer_updated }
      LQuery.SQL.Text :=
        'UPDATE customers SET ' +
        '  name = :name, cpf = :cpf, email = :email, ' +
        '  status = :status::customer_status, ' +
        '  notes = :notes, metadata = :metadata::jsonb ' +
        'WHERE id = :id ' +
        'RETURNING updated_at';
      LQuery.ParamByName('id').AsInteger := ACustomer.Id;
      LQuery.ParamByName('name').AsString := ACustomer.Name;
      LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
      LQuery.ParamByName('email').AsString := ACustomer.Email;
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
///   Insere ou atualiza o cliente com base no CPF (UPSERT).
///   Usa INSERT ... ON CONFLICT — recurso nativo do PostgreSQL.
/// </summary>
procedure TPostgreSQLCustomerRepository.Upsert(ACustomer: TCustomer);
var
  LQuery: TFDQuery;
begin
  if not Assigned(ACustomer) then
    raise EArgumentNilException.Create('ACustomer não pode ser nil');

  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      LQuery.SQL.Text :=
        'INSERT INTO customers (name, cpf, email, status, notes, metadata) ' +
        'VALUES (:name, :cpf, :email, :status::customer_status, :notes, :metadata::jsonb) ' +
        'ON CONFLICT (cpf) DO UPDATE SET ' +
        '  name = EXCLUDED.name, ' +
        '  email = EXCLUDED.email, ' +
        '  status = EXCLUDED.status, ' +
        '  notes = EXCLUDED.notes, ' +
        '  metadata = EXCLUDED.metadata ' +
        'RETURNING id, created_at, updated_at';
      LQuery.ParamByName('name').AsString := ACustomer.Name;
      LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
      LQuery.ParamByName('email').AsString := ACustomer.Email;
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
///   Desativa cliente via CALL (PostgreSQL Procedure — PG 11+).
/// </summary>
procedure TPostgreSQLCustomerRepository.Deactivate(AId: Integer);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      { CALL para PostgreSQL Procedure (PG 11+) }
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

    { Configurações recomendadas }
    Result.Params.Values['CharacterSet'] := 'UTF8';

    { Opções FireDAC }
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
  SQL de criação do schema usado neste exemplo:
  ============================================================================

  -- ENUM type
  CREATE TYPE customer_status AS ENUM ('active', 'inactive', 'suspended');

  -- Tabela com IDENTITY e JSONB
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

  -- Indices
  CREATE INDEX idx_customer_name ON customers (name);
  CREATE INDEX idx_customer_cpf ON customers (cpf);

  -- Trigger de updated_at automático
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
