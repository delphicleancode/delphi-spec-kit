unit I18nApp.Core.Resources;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  System.Generics.Collections;

type
  TResources = class
  private
    FCache: TDictionary<string, string>;
    function GetResourceFilePath(const ALang: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure LoadFromFile(const ALang: string);
    function GetString(const AKey: string): string;
  end;

implementation

{ TResources }

constructor TResources.Create;
begin
  inherited Create;
  FCache := TDictionary<string, string>.Create;
end;

destructor TResources.Destroy;
begin
  FCache.Free;
  inherited Destroy;
end;

function TResources.GetResourceFilePath(const ALang: string): string;
var
  LAppPath: string;
begin
  // Assuming resources folder is either next to the exe or in project root
  LAppPath := TPath.GetDirectoryName(ParamStr(0));
  Result := TPath.Combine(LAppPath, 'resources\' + ALang + '.json');
  
  if not TFile.Exists(Result) then
  begin
    // Fallback if running via IDE and bin folder is deep.
    Result := TPath.Combine(TPath.Combine(LAppPath, '..\..\'), 'resources\' + ALang + '.json');
    if not TFile.Exists(Result) then
        Result := TPath.Combine(TPath.Combine(LAppPath, '..\..\..\'), 'resources\' + ALang + '.json');
  end;
end;

procedure TResources.LoadFromFile(const ALang: string);
var
  LFilePath: string;
  LJsonStr: string;
  LJsonObj: TJSONObject;
  LPair: TJSONPair;
  I: Integer;
begin
  FCache.Clear;
  LFilePath := GetResourceFilePath(ALang);
  
  if not TFile.Exists(LFilePath) then
  begin
    // Silently fallback to pt-BR if file doesn't exist
    if ALang <> 'pt-BR' then
      LoadFromFile('pt-BR');
    Exit;
  end;

  LJsonStr := TFile.ReadAllText(LFilePath, TEncoding.UTF8);
  LJsonObj := TJSONObject.ParseJSONValue(LJsonStr) as TJSONObject;
  
  if Assigned(LJsonObj) then
  begin
    try
      try
        for I := 0 to LJsonObj.Count - 1 do
        begin
          LPair := LJsonObj.Pairs[I];
          FCache.AddOrSetValue(LPair.JsonString.Value, LPair.JsonValue.Value);
        end;
      except
        on E: Exception do
          // Passive fallback in case of parse error
          ;
      end;
    finally
      LJsonObj.Free;
    end;
  end;
end;

function TResources.GetString(const AKey: string): string;
begin
  if not FCache.TryGetValue(AKey, Result) then
    Result := '[' + AKey + ']'; // Mark missing keys
end;

end.

