unit I18nApp.Model.Connection;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.VCLUI.Wait, Data.DB,
  FireDAC.Comp.Client, System.IOUtils;

type
  TConnection = class(TDataModule)
    FDConnection: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
  private
    function GetDatabasePath: string;
    procedure SetupDatabase;
  public
    { Public declarations }
  end;

var
  Connection: TConnection;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TConnection.DataModuleCreate(Sender: TObject);
begin
  SetupDatabase;
end;

function TConnection.GetDatabasePath: string;
var
  LAppPath: string;
begin
  LAppPath := TPath.GetDirectoryName(ParamStr(0));
  Result := TPath.Combine(LAppPath, 'database.sqlite');
end;

procedure TConnection.SetupDatabase;
var
  LScriptPath: string;
  LScript: string;
  LAppPath: string;
begin
  FDConnection.Params.Clear;
  FDConnection.Params.Add('DriverID=SQLite');
  FDConnection.Params.Add('Database=' + GetDatabasePath);
  FDConnection.Connected := True;

  // Execute DDL if database is empty (or we just created it)
  LAppPath := TPath.GetDirectoryName(ParamStr(0));
  LScriptPath := TPath.Combine(LAppPath, 'scripts\database.sql');
  
  if not TFile.Exists(LScriptPath) then
  begin
    // Fallback if running via IDE
    LScriptPath := TPath.Combine(TPath.Combine(LAppPath, '..\..\'), 'scripts\database.sql');
    if not TFile.Exists(LScriptPath) then
      LScriptPath := TPath.Combine(TPath.Combine(LAppPath, '..\..\..\'), 'scripts\database.sql');
  end;

  if TFile.Exists(LScriptPath) then
  begin
    LScript := TFile.ReadAllText(LScriptPath);
    FDConnection.ExecSQL(LScript);
  end;
end;

end.

