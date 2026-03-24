unit I18nApp.Core.LanguageManager;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  I18nApp.Core.Resources;

type
  TLanguageObserver = interface
    ['{F4A78A03-A287-4DF2-B8E5-1C9C5874B514}']
    procedure LanguageChanged(const ALang: string);
  end;

  TLanguageManager = class
  private
    FObservers: TList<TLanguageObserver>;
    FCurrentLang: string;
    FResources: TResources;
    class var FInstance: TLanguageManager;
    constructor CreateInstance;
    procedure NotifyObservers;
    procedure ApplyFormatSettings;
  public
    class function GetInstance: TLanguageManager;
    class destructor DestroyLanguageManager;
    
    destructor Destroy; override;

    procedure RegisterObserver(AObserver: TLanguageObserver);
    procedure UnregisterObserver(AObserver: TLanguageObserver);
    procedure SetLanguage(const ALang: string);
    function GetString(const AKey: string): string;
    function IsRTL: Boolean;
    
    property CurrentLang: string read FCurrentLang;
  end;

implementation

{ TLanguageManager }

class function TLanguageManager.GetInstance: TLanguageManager;
begin
  if not Assigned(FInstance) then
    FInstance := TLanguageManager.CreateInstance;
  Result := FInstance;
end;

class destructor TLanguageManager.DestroyLanguageManager;
begin
  if Assigned(FInstance) then
    FInstance.Free;
end;

destructor TLanguageManager.Destroy;
begin
  FObservers.Free;
  FResources.Free;
  inherited Destroy;
end;

constructor TLanguageManager.CreateInstance;
begin
  inherited Create;
  FObservers := TList<TLanguageObserver>.Create;
  FResources := TResources.Create;
  FCurrentLang := 'pt-BR'; // Default fallback
  FResources.LoadFromFile(FCurrentLang);
  ApplyFormatSettings;
end;

procedure TLanguageManager.ApplyFormatSettings;
var
  LFormatSettings: TFormatSettings;
begin
  if FCurrentLang = 'pt-BR' then
    LFormatSettings := TFormatSettings.Create('pt-BR')
  else if FCurrentLang = 'en-US' then
    LFormatSettings := TFormatSettings.Create('en-US')
  else
    LFormatSettings := TFormatSettings.Create(''); // Local System Defaults

  // Update global format settings
  FormatSettings := LFormatSettings;
end;

procedure TLanguageManager.NotifyObservers;
var
  LObserver: TLanguageObserver;
begin
  for LObserver in FObservers do
    LObserver.LanguageChanged(FCurrentLang);
end;

procedure TLanguageManager.RegisterObserver(AObserver: TLanguageObserver);
begin
  if not FObservers.Contains(AObserver) then
    FObservers.Add(AObserver);
end;

procedure TLanguageManager.UnregisterObserver(AObserver: TLanguageObserver);
begin
  FObservers.Remove(AObserver);
end;

procedure TLanguageManager.SetLanguage(const ALang: string);
begin
  if FCurrentLang <> ALang then
  begin
    FCurrentLang := ALang;
    FResources.LoadFromFile(FCurrentLang);
    ApplyFormatSettings;
    NotifyObservers;
  end;
end;

function TLanguageManager.GetString(const AKey: string): string;
begin
  Result := FResources.GetString(AKey);
end;

function TLanguageManager.IsRTL: Boolean;
begin
  Result := FCurrentLang.StartsWith('ar') or FCurrentLang.StartsWith('he');
end;

end.
