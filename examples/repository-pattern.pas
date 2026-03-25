/// <summary>
/// Complete example of the Repository pattern in Delphi.
/// Demonstrates: ISP, DIP, constructor injection, guard clauses,
/// try/finally, Pascal and XMLDoc naming.
/// </summary>
unit Example.Domain.Customer.Repository;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  FireDAC.Comp.Client;

type
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
  public
    constructor Create(const AName: string);

    function IsActive: Boolean;
    procedure Activate;
    procedure Deactivate;

    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
    property Cpf: string read FCpf write FCpf;
    property Email: string read FEmail write FEmail;
    property Status: TCustomerStatus read FStatus;
  end;

  // =========================================================================
  // Segregated interfaces (ISP)
  // =========================================================================

  /// <summary>
  /// Client reading interface.
  /// </summary>
  ICustomerReadRepository = interface
    ['{A1B2C3D4-0001-0001-0001-000000000001}']
    function FindById(AId: Integer): TCustomer;
    function FindAll: TObjectList<TCustomer>;
    function FindByCpf(const ACpf: string): TCustomer;
    function Exists(AId: Integer): Boolean;
  end;

  /// <summary>
  /// Client writing interface.
  /// </summary>
  ICustomerWriteRepository = interface
    ['{A1B2C3D4-0001-0001-0001-000000000002}']
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
  end;

  /// <summary>
  /// Complete interface combining reading and writing.
  /// </summary>
  ICustomerRepository = interface(ICustomerReadRepository)
    ['{A1B2C3D4-0001-0001-0001-000000000003}']
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
  end;

  // =========================================================================
  // Implementation with FireDAC (DIP — Infrastructure implements Domain)
  // =========================================================================

  /// <summary>
  /// Concrete implementation of the repository using FireDAC.
  /// </summary>
  TFireDACCustomerRepository = class(TInterfacedObject, ICustomerRepository)
  private
    FConnection: TFDConnection;
    function MapToCustomer(AQuery: TFDQuery): TCustomer;
  public
    constructor Create(AConnection: TFDConnection);

    { ICustomerReadRepository }
    function FindById(AId: Integer): TCustomer;
    function FindAll: TObjectList<TCustomer>;
    function FindByCpf(const ACpf: string): TCustomer;
    function Exists(AId: Integer): Boolean;

    { ICustomerWriteRepository }
    procedure Insert(ACustomer: TCustomer);
    procedure Update(ACustomer: TCustomer);
    procedure Delete(AId: Integer);
  end;

implementation

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

procedure TCustomer.Activate;
begin
  FStatus := csActive;
end;

procedure TCustomer.Deactivate;
begin
  FStatus := csInactive;
end;

{ TFireDACCustomerRepository }

constructor TFireDACCustomerRepository.Create(AConnection: TFDConnection);
begin
  inherited Create;
  if not Assigned(AConnection) then
    raise EArgumentNilException.Create('AConnection cannot be nil');
  FConnection := AConnection;
end;

function TFireDACCustomerRepository.MapToCustomer(AQuery: TFDQuery): TCustomer;
begin
  Result := TCustomer.Create(AQuery.FieldByName('name').AsString);
  Result.Id := AQuery.FieldByName('id').AsInteger;
  Result.Cpf := AQuery.FieldByName('cpf').AsString;
  Result.Email := AQuery.FieldByName('e-mail').AsString;
end;

function TFireDACCustomerRepository.FindById(AId: Integer): TCustomer;
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
      Result := MapToCustomer(LQuery);
  finally
    LQuery.Free;
  end;
end;

function TFireDACCustomerRepository.FindAll: TObjectList<TCustomer>;
var
  LQuery: TFDQuery;
begin
  Result := TObjectList<TCustomer>.Create(True);
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := 'SELECT * FROM customers ORDER BY name';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      Result.Add(MapToCustomer(LQuery));
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

function TFireDACCustomerRepository.FindByCpf(const ACpf: string): TCustomer;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := 'SELECT * FROM customers WHERE cpf = :cpf';
    LQuery.ParamByName('cpf').AsString := ACpf;
    LQuery.Open;

    if not LQuery.IsEmpty then
      Result := MapToCustomer(LQuery);
  finally
    LQuery.Free;
  end;
end;

function TFireDACCustomerRepository.Exists(AId: Integer): Boolean;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := 'SELECT COUNT(*) AS cnt FROM customers WHERE id = :id';
    LQuery.ParamByName('id').AsInteger := AId;
    LQuery.Open;
    Result := LQuery.FieldByName('cnt').AsInteger > 0;
  finally
    LQuery.Free;
  end;
end;

procedure TFireDACCustomerRepository.Insert(ACustomer: TCustomer);
var
  LQuery: TFDQuery;
begin
  if not Assigned(ACustomer) then
    raise EArgumentNilException.Create('ACustomer cannot be nil');

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'INSERT INTO customers (name, cpf, email, status)' +
      'VALUES (:name, :cpf, :email, :status)';
    LQuery.ParamByName('name').AsString := ACustomer.Name;
    LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
    LQuery.ParamByName('e-mail').AsString := ACustomer.Email;
    LQuery.ParamByName('status').AsInteger := Ord(ACustomer.Status);
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

procedure TFireDACCustomerRepository.Update(ACustomer: TCustomer);
var
  LQuery: TFDQuery;
begin
  if not Assigned(ACustomer) then
    raise EArgumentNilException.Create('ACustomer cannot be nil');

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'UPDATE customers SET name = :name, cpf = :cpf,' +
      'email = :email, status = :status WHERE id = :id';
    LQuery.ParamByName('id').AsInteger := ACustomer.Id;
    LQuery.ParamByName('name').AsString := ACustomer.Name;
    LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
    LQuery.ParamByName('e-mail').AsString := ACustomer.Email;
    LQuery.ParamByName('status').AsInteger := Ord(ACustomer.Status);
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

procedure TFireDACCustomerRepository.Delete(AId: Integer);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := 'DELETE FROM customers WHERE id = :id';
    LQuery.ParamByName('id').AsInteger := AId;
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

end.

