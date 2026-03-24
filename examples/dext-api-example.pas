/// <summary>
///   Exemplo completo de Minimal API com Dext Framework (cesarliws/dext).
///   Demonstra: Injeção de dependências, Model Binding via tipos e Responses IResult.
/// </summary>
program Example.Dext.MinimalApi;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Core,
  Dext.Web;

// =========================================================================
// Classes de Serviço e Interfaces (Domain/Application)
// =========================================================================

type
  // DTO (Será preenchido pelo JSON request body nativamente)
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
// Implementações
// =========================================================================

function TUserService.RegisterNewUser(const ADto: TUserRequestDto): string;
begin
  // Em uma aplicação real, aqui salvaríamos as coisas com o Dext.Entity
  // e aplicaríamos regras de negócio.
  Result := TGUID.NewGuid.ToString; // Retorna Novo ID
end;


// =========================================================================
// Startup (Host)
// =========================================================================

begin
  try
    // Inicia a aplicação server do Dext
    var App := WebApplication;
    var Builder := App.Builder;

    // 1. DI Registration - Container
    App.Services.AddScoped<IUserService, TUserService>;

    // 2. Mapeamento de Rotas - Endpoints

    // Health Check Endpoint
    Builder.MapGet<IResult>('/api/health',
      function: IResult
      begin
        Result := Results.Ok('{"status": "API is running"}');
      end);

    // Registro de Usuario - Model Binding e Injection do IUserService
    Builder.MapPost<TUserRequestDto, IUserService, IResult>('/api/users',
      function(Dto: TUserRequestDto; UserService: IUserService): IResult
      var
        LResponse: TUserResponseDto;
      begin
        // Validções no Minimal API Handler ou delegadas via Filters.
        if (Dto.Name.Trim.IsEmpty) or (Dto.Email.Trim.IsEmpty) then
        begin
          Exit(Results.BadRequest('Name and Email are required'));
        end;

        if Dto.Age < 18 then
        begin
          Exit(Results.BadRequest('User must be older than 18'));
        end;

        LResponse.Id := UserService.RegisterNewUser(Dto);
        LResponse.Message := 'User successfully created';

        // Result.Json auto serializa o DTO Record e entrega Content-Type: application/json
        Result := Results.Created('/api/users/' + LResponse.Id, LResponse);
      end);
      
    // 3. Start e Listen
    Writeln('Dext Minimal API starting on default port (http://localhost:8080)...');
    App.Run(8080);
    
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
