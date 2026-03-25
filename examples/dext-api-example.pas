/// <summary>
/// Complete example of Minimal API with Dext Framework (cesarliws/dext).
/// Demonstrates: Dependency injection, Model Binding via IResult types and Responses.
/// </summary>
program Example.Dext.MinimalApi;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Core,
  Dext.Web;

// =========================================================================
// Service Classes and Interfaces (Domain/Application)
// =========================================================================

type
  // DTO (Will be populated by the JSON request body natively)
  TUserRequestDto = record
    Name: string;
    Email: string;
    Age: Integer;
  end;

  TUserResponseDto = record
    Id: string;
    Message: string;
  end;

  IUserService = interface
    ['{F4F5A2A3-D953-48D1-84B9-A1C9A9CEB1C1}']
    function RegisterNewUser(const ADto: TUserRequestDto): string;
  end;

  TUserService = class(TInterfacedObject, IUserService)
  public
    function RegisterNewUser(const ADto: TUserRequestDto): string;
  end;

// =========================================================================
// Implementations
// =========================================================================

function TUserService.RegisterNewUser(const ADto: TUserRequestDto): string;
begin
  // In a real application, here we would save things with Dext.Entity
  // and we would apply business rules.
  Result := TGUID.NewGuid.ToString; // Returns the new ID
end;


// =========================================================================
//Startup (Host)
// =========================================================================

begin
  try
    // Start the Dext server application
    var App := WebApplication;
    var Builder := App.Builder;

    // 1. DI Registration - Container
    App.Services.AddScoped<IUserService, TUserService>;

    // 2. Route Mapping - Endpoints

    // Health Check Endpoint
    Builder.MapGet<IResult>('/api/health',
      function: IResult
      begin
        Result := Results.Ok('{"status": "API is running"}');
      end);

    // User Registration - Model Binding and IUserService Injection
    Builder.MapPost<TUserRequestDto, IUserService, IResult>('/api/users',
      function(Dto: TUserRequestDto; UserService: IUserService): IResult
      var
        LResponse: TUserResponseDto;
      begin
        // Validations in the Minimal API Handler or delegated via Filters.
        if (Dto.Name.Trim.IsEmpty) or (Dto.Email.Trim.IsEmpty) then
        begin
          Exit(Results.BadRequest('Name and Email are required'));
        end;

        if Dto.Age < 18 then
        begin
          Exit(Results.BadRequest('User must be older than 18'));
        end;

        LResponse.Id := UserService.RegisterNewUser(Dto);
        LResponse.Message := 'User created successfully';

        // Result.Json auto serializes the DTO Record and delivers Content-Type: application/json
        Result := Results.Created('/api/users/' + LResponse.Id, LResponse);
      end);
      
    // 3. Start and Listen
    Writeln('Dext Minimal API starting on default port (http://localhost:8080)...');
    App.Run(8080);
    
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

