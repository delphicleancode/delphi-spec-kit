/// <summary>
///   Exemplo completo de Repository Pattern com FireDAC + MySQL.
///   Demonstra: AUTO_INCREMENT, LAST_INSERT_ID(), ON DUPLICATE KEY UPDATE,
///   JSON nativo, CALL procedure, FULLTEXT search, error handling.
/// </summary>
unit Example.Infra.MySQL.Customer.Repository;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  FireDAC.Phys.MySQL,
  FireDAC.Stan.Option;

type
  // =========================================================================
  // Exceções de Domínio para MySQL
  // =========================================================================

  EDatabaseException = class(Exception);
  EDuplicateRecordException = class(EDatabaseException);
  EForeignKeyViolationException = class(EDatabaseException);
  EConnectionLostException = class(EDatabaseException);

  // =========================================================================
  // Entidade
  // =========================================================================

  TCustomerStatus = (csActive, csInactive, csSuspended);

  TCustomer = class
  private
    FId: Integer;
    FName: string;
    FCpf: string;
    FEmail: string;
    FStatus: TCustomerStatus;
    FNotes: string;
    FMetadata: string;  { JSON como string }
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
    ['{MY000001-0001-0001-0001-000000000001}']
    function FindById(AId: Integer): TCustomer;
    function FindAll(ALimit: Integer = 100; AOffset: Integer = 0): TObjectList<TCustomer>;
    function FindByCpf(const ACpf: string): TCustomer;
    function Search(const ASearchTerm: string; ALimit: Integer = 50): TObjectList<TCustomer>;
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Upsert(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
    procedure Deactivate(AId: Integer);
  end;

  // =========================================================================
  // Implementação com FireDAC + MySQL (Infrastructure)
  // =========================================================================

  TMySQLCustomerRepository = class(TInterfacedObject, ICustomerRepository)
  private
    FConnection: TFDConnection;
    function MapToCustomer(AQuery: TFDQuery): TCustomer;
    procedure HandleMySQLException(AException: EFDDBEngineException);
  public
    constructor Create(AConnection: TFDConnection);

    function FindById(AId: Integer): TCustomer;
    function FindAll(ALimit: Integer = 100; AOffset: Integer = 0): TObjectList<TCustomer>;
    function FindByCpf(const ACpf: string): TCustomer;
    function Search(const ASearchTerm: string; ALimit: Integer = 50): TObjectList<TCustomer>;
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Upsert(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
    procedure Deactivate(AId: Integer);
  end;

  // =========================================================================
  // Factory de Conexão MySQL
  // =========================================================================

  TMySQLConnectionFactory = class
  public
    class function CreateConnection(
      const AServer: string;
      const ADatabase: string;
      const AUserName: string = 'root';
      const APassword: string = '';
      APort: Integer = 3306
    ): TFDConnection;
  end;

implementation

uses
  FireDAC.Stan.Error;

{ TCustomer }

constructor TCustomer.Create(const AName: string);
begin
  inherited Create;
  if AName.Trim.IsEmpty then
    raise EArgumentException.Create('Nome do cliente não pode ser vazio');
  FName := AName.Trim;
  FStatus := csActive;
end;

function TCustomer.IsActive: Boolean;
begin
  Result := FStatus = csActive;
end;

{ TMySQLCustomerRepository }

constructor TMySQLCustomerRepository.Create(AConnection: TFDConnection);
begin
  inherited Create;
  if not Assigned(AConnection) then
    raise EArgumentNilException.Create('AConnection não pode ser nil');
  FConnection := AConnection;
end;

function TMySQLCustomerRepository.MapToCustomer(AQuery: TFDQuery): TCustomer;
begin
  Result := TCustomer.Create(AQuery.FieldByName('name').AsString);
  Result.Id := AQuery.FieldByName('id').AsInteger;
  Result.Cpf := AQuery.FieldByName('cpf').AsString;
  Result.Email := AQuery.FieldByName('email').AsString;
  Result.Status := TCustomerStatus(AQuery.FieldByName('status').AsSmallInt);
  Result.Notes := AQuery.FieldByName('notes').AsString;

  if not AQuery.FieldByName('metadata').IsNull then
    Result.Metadata := AQuery.FieldByName('metadata').AsString;

  Result.CreatedAt := AQuery.FieldByName('created_at').AsDateTime;
  Result.UpdatedAt := AQuery.FieldByName('updated_at').AsDateTime;
end;

procedure TMySQLCustomerRepository.HandleMySQLException(
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
        'Conexão com MySQL perdida: ' + AException.Message);
  else
    raise;
  end;
end;

function TMySQLCustomerRepository.FindById(AId: Integer): TCustomer;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'SELECT id, name, cpf, email, status, notes, ' +
      '  metadata, created_at, updated_at ' +
      'FROM customers WHERE id = :id';
    LQuery.ParamByName('id').AsInteger := AId;
    LQuery.Open;

    if not LQuery.IsEmpty then
      Result := MapToCustomer(LQuery);
  finally
    LQuery.Free;
  end;
end;

function TMySQLCustomerRepository.FindAll(
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
        'SELECT id, name, cpf, email, status, notes, ' +
        '  metadata, created_at, updated_at ' +
        'FROM customers ORDER BY name LIMIT :limit OFFSET :offset';
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
        HandleMySQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

function TMySQLCustomerRepository.FindByCpf(const ACpf: string): TCustomer;
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
      'SELECT id, name, cpf, email, status, notes, ' +
      '  metadata, created_at, updated_at ' +
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
///   Busca textual usando LIKE (simples) ou FULLTEXT (se índice disponível).
/// </summary>
function TMySQLCustomerRepository.Search(
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
      LQuery.SQL.Text :=
        'SELECT id, name, cpf, email, status, notes, ' +
        '  metadata, created_at, updated_at ' +
        'FROM customers ' +
        'WHERE name LIKE :term OR cpf LIKE :term OR email LIKE :term ' +
        'ORDER BY name LIMIT :limit';
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
        HandleMySQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

/// <summary>
///   Insere cliente usando AUTO_INCREMENT + LAST_INSERT_ID().
///   MySQL NÃO suporta RETURNING — diferença crítica vs Firebird/PG.
/// </summary>
procedure TMySQLCustomerRepository.Insert(ACustomer: TCustomer);
var
  LQuery: TFDQuery;
begin
  if not Assigned(ACustomer) then
    raise EArgumentNilException.Create('ACustomer não pode ser nil');

  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;

      { INSERT — sem RETURNING (não existe no MySQL!) }
      LQuery.SQL.Text :=
        'INSERT INTO customers (name, cpf, email, status, notes, metadata) ' +
        'VALUES (:name, :cpf, :email, :status, :notes, :metadata)';
      LQuery.ParamByName('name').AsString := ACustomer.Name;
      LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
      LQuery.ParamByName('email').AsString := ACustomer.Email;
      LQuery.ParamByName('status').AsSmallInt := Ord(ACustomer.Status);
      LQuery.ParamByName('notes').AsString := ACustomer.Notes;
      LQuery.ParamByName('metadata').AsString := ACustomer.Metadata;
      LQuery.ExecSQL;

      { Obter ID gerado via LAST_INSERT_ID() }
      LQuery.SQL.Text := 'SELECT LAST_INSERT_ID() AS new_id';
      LQuery.Open;
      ACustomer.Id := LQuery.FieldByName('new_id').AsInteger;
    except
      on E: EFDDBEngineException do
        HandleMySQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TMySQLCustomerRepository.Update(ACustomer: TCustomer);
var
  LQuery: TFDQuery;
begin
  if not Assigned(ACustomer) then
    raise EArgumentNilException.Create('ACustomer não pode ser nil');

  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      { updated_at é atualizado automaticamente via ON UPDATE CURRENT_TIMESTAMP }
      LQuery.SQL.Text :=
        'UPDATE customers SET ' +
        '  name = :name, cpf = :cpf, email = :email, ' +
        '  status = :status, notes = :notes, metadata = :metadata ' +
        'WHERE id = :id';
      LQuery.ParamByName('id').AsInteger := ACustomer.Id;
      LQuery.ParamByName('name').AsString := ACustomer.Name;
      LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
      LQuery.ParamByName('email').AsString := ACustomer.Email;
      LQuery.ParamByName('status').AsSmallInt := Ord(ACustomer.Status);
      LQuery.ParamByName('notes').AsString := ACustomer.Notes;
      LQuery.ParamByName('metadata').AsString := ACustomer.Metadata;
      LQuery.ExecSQL;
    except
      on E: EFDDBEngineException do
        HandleMySQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

/// <summary>
///   Insere ou atualiza com base no CPF (UPSERT).
///   Usa INSERT ... ON DUPLICATE KEY UPDATE — recurso nativo do MySQL.
/// </summary>
procedure TMySQLCustomerRepository.Upsert(ACustomer: TCustomer);
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
        'VALUES (:name, :cpf, :email, :status, :notes, :metadata) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '  name = VALUES(name), ' +
        '  email = VALUES(email), ' +
        '  status = VALUES(status), ' +
        '  notes = VALUES(notes), ' +
        '  metadata = VALUES(metadata)';
      LQuery.ParamByName('name').AsString := ACustomer.Name;
      LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
      LQuery.ParamByName('email').AsString := ACustomer.Email;
      LQuery.ParamByName('status').AsSmallInt := Ord(ACustomer.Status);
      LQuery.ParamByName('notes').AsString := ACustomer.Notes;
      LQuery.ParamByName('metadata').AsString := ACustomer.Metadata;
      LQuery.ExecSQL;

      { Obter ID }
      LQuery.SQL.Text := 'SELECT LAST_INSERT_ID() AS new_id';
      LQuery.Open;
      ACustomer.Id := LQuery.FieldByName('new_id').AsInteger;
    except
      on E: EFDDBEngineException do
        HandleMySQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TMySQLCustomerRepository.Delete(AId: Integer);
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
        HandleMySQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

/// <summary>
///   Desativa cliente via CALL (MySQL Stored Procedure).
/// </summary>
procedure TMySQLCustomerRepository.Deactivate(AId: Integer);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    try
      LQuery.Connection := FConnection;
      LQuery.SQL.Text := 'CALL sp_deactivate_customer(:p_id)';
      LQuery.ParamByName('p_id').AsInteger := AId;
      LQuery.ExecSQL;
    except
      on E: EFDDBEngineException do
        HandleMySQLException(E);
    end;
  finally
    LQuery.Free;
  end;
end;

{ TMySQLConnectionFactory }

class function TMySQLConnectionFactory.CreateConnection(
  const AServer, ADatabase, AUserName, APassword: string;
  APort: Integer): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.DriverName := 'MySQL';
    Result.Params.Values['Server'] := AServer;
    Result.Params.Values['Port'] := APort.ToString;
    Result.Params.Database := ADatabase;
    Result.Params.UserName := AUserName;
    Result.Params.Password := APassword;

    { utf8mb4 SEMPRE — utf8 do MySQL só tem 3 bytes! }
    Result.Params.Values['CharacterSet'] := 'utf8mb4';

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

  CREATE TABLE IF NOT EXISTS customers (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    cpf        VARCHAR(14) UNIQUE,
    email      VARCHAR(150),
    status     TINYINT NOT NULL DEFAULT 0 COMMENT '0=active, 1=inactive, 2=suspended',
    notes      TEXT,
    metadata   JSON,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer_name (name),
    INDEX idx_customer_cpf (cpf)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  DELIMITER //
  CREATE PROCEDURE sp_deactivate_customer(IN p_id INT)
  BEGIN
    UPDATE customers SET status = 1 WHERE id = p_id;
    IF ROW_COUNT() = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer not found';
    END IF;
  END //
  DELIMITER ;
}

end.
