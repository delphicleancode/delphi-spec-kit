/// <summary>
/// Complete REST API example with Horse Framework.
/// Demonstrates: server configuration, RESTful routes, middleware,
/// use of Services, guard clauses and error handling.
/// </summary>
program Example.Horse.Api;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  Horse,
  Horse.Jhonson,
  Horse.CORS,
  Horse.HandleException;

// =========================================================================
// Simplified model (in real projects, separate into separate units)
// =========================================================================

type
  EValidationException = class(Exception);
  ENotFoundException = class(Exception);

// =========================================================================
// Health Controller (Health Check)
// =========================================================================

type
  THealthController = class
  public
    class procedure RegisterRoutes;
  private
    class procedure HealthCheck(AReq: THorseRequest; ARes: THorseResponse;
      ANext: TProc);
  end;

class procedure THealthController.RegisterRoutes;
begin
  THorse.Get('/api/health', HealthCheck);
end;

class procedure THealthController.HealthCheck(
  AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
var
  LResult: TJSONObject;
begin
  LResult := TJSONObject.Create;
  LResult.AddPair('status', 'ok');
  LResult.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));
  ARes.Send<TJSONObject>(LResult).Status(THTTPStatus.OK);
end;

// =========================================================================
// Customer Controller
// =========================================================================

type
  TCustomerController = class
  public
    class procedure RegisterRoutes;
  private
    class procedure GetAll(AReq: THorseRequest; ARes: THorseResponse;
      ANext: TProc);
    class procedure GetById(AReq: THorseRequest; ARes: THorseResponse;
      ANext: TProc);
    class procedure CreateCustomer(AReq: THorseRequest; ARes: THorseResponse;
      ANext: TProc);
    class procedure UpdateCustomer(AReq: THorseRequest; ARes: THorseResponse;
      ANext: TProc);
    class procedure DeleteCustomer(AReq: THorseRequest; ARes: THorseResponse;
      ANext: TProc);
  end;

class procedure TCustomerController.RegisterRoutes;
begin
  THorse.Get('/api/customers', GetAll);
  THorse.Get('/api/customers/:id', GetById);
  THorse.Post('/api/customers', CreateCustomer);
  THorse.Put('/api/customers/:id', UpdateCustomer);
  THorse.Delete('/api/customers/:id', DeleteCustomer);
end;

class procedure TCustomerController.GetAll(
  AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
var
  LResult: TJSONArray;
  LCustomer: TJSONObject;
begin
  // In real projects, delegate to Service
  LResult := TJSONArray.Create;

  LCustomer := TJSONObject.Create;
  LCustomer.AddPair('id', TJSONNumber.Create(1));
  LCustomer.AddPair('name', 'John Silva');
  LCustomer.AddPair('cpf', '12345678901');
  LResult.AddElement(LCustomer);

  ARes.Send<TJSONArray>(LResult).Status(THTTPStatus.OK);
end;

class procedure TCustomerController.GetById(
  AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
var
  LId: Integer;
  LResult: TJSONObject;
begin
  // Guard clause — validate parameters
  if not TryStrToInt(AReq.Params['id'], LId) then
  begin
    ARes.Send('Invalid ID').Status(THTTPStatus.BadRequest);
    Exit;
  end;

  // In real projects, delegate to Service
  LResult := TJSONObject.Create;
  LResult.AddPair('id', TJSONNumber.Create(LId));
  LResult.AddPair('name', 'John Silva');
  ARes.Send<TJSONObject>(LResult).Status(THTTPStatus.OK);
end;

class procedure TCustomerController.CreateCustomer(
  AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
var
  LBody: TJSONObject;
  LName: string;
begin
  LBody := AReq.Body<TJSONObject>;

  // Guard clauses — validate body
  if not Assigned(LBody) then
  begin
    ARes.Send('Request body is required').Status(THTTPStatus.BadRequest);
    Exit;
  end;

  LName := LBody.GetValue<string>('name', '');
  if LName.Trim.IsEmpty then
  begin
    ARes.Send('Field "name" is required').Status(THTTPStatus.BadRequest);
    Exit;
  end;

  // In real projects, delegate to Service
  ARes.Send('Customer created').Status(THTTPStatus.Created);
end;

class procedure TCustomerController.UpdateCustomer(
  AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
var
  LId: Integer;
begin
  if not TryStrToInt(AReq.Params['id'], LId) then
  begin
    ARes.Send('Invalid ID').Status(THTTPStatus.BadRequest);
    Exit;
  end;

  // In real projects, delegate to Service
  ARes.Send('Customer updated').Status(THTTPStatus.OK);
end;

class procedure TCustomerController.DeleteCustomer(
  AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
var
  LId: Integer;
begin
  if not TryStrToInt(AReq.Params['id'], LId) then
  begin
    ARes.Send('Invalid ID').Status(THTTPStatus.BadRequest);
    Exit;
  end;

  // In real projects, delegate to Service
  ARes.Send('').Status(THTTPStatus.NoContent);
end;

// =========================================================================
// Logger Middleware
// =========================================================================

procedure LoggerMiddleware(
  AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
begin
  Writeln(Format('[%s] %s %s',
    [FormatDateTime('hh:nn:ss', Now),
     AReq.RawWebRequest.Method,
     AReq.RawWebRequest.PathInfo]));
  ANext;
end;

// =========================================================================
// Server Bootstrap
// =========================================================================

const
  SERVER_PORT = 9000;

begin
  // Register middleware (order matters!)
  THorse.Use(Jhonson);           // Automatic JSON
  THorse.Use(CORS);              // Cross-Origin Resource Sharing
  THorse.Use(HandleException);   // Error handler global
  THorse.Use(LoggerMiddleware);  // Logger customizado

  // Register routes
  THealthController.RegisterRoutes;
  TCustomerController.RegisterRoutes;

  // Start server
  THorse.Listen(SERVER_PORT,
    procedure
    begin
      Writeln(Format('Horse API running on http://localhost:%d', [SERVER_PORT]));
      Writeln('Press ENTER to stop...');
    end
  );
end.

