/// <summary>
///   Form principal da aplicação de cópia de arquivos.
///   Permite selecionar pasta de origem e destino, listar e copiar arquivos.
/// </summary>
unit FileCopy.Main.View;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Types,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Vcl.ExtCtrls,
  FileCopy.Service.Copier;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    pnlCenter: TPanel;
    pnlBottom: TPanel;
    stbMain: TStatusBar;
    lblSource: TLabel;
    edtSource: TEdit;
    btnSelectSource: TButton;
    lblDest: TLabel;
    edtDest: TEdit;
    btnSelectDest: TButton;
    lblFiles: TLabel;
    lbxFiles: TListBox;
    btnCopy: TButton;
    prgCopy: TProgressBar;
    dlgSelectFolder: TFileOpenDialog;
    procedure btnSelectSourceClick(Sender: TObject);
    procedure btnSelectDestClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
  private
    FCopierService: IFileCopierService;
    procedure LoadFileList;
    procedure SetStatus(const AMessage: string);
    function SelectFolder(const ATitle: string): string;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

{ TfrmMain }

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCopierService := TFileCopierService.Create;
  SetStatus('Selecione as pastas de origem e destino.');
end;

function TfrmMain.SelectFolder(const ATitle: string): string;
begin
  Result := '';
  dlgSelectFolder.Title := ATitle;
  if dlgSelectFolder.Execute then
    Result := dlgSelectFolder.FileName;
end;

procedure TfrmMain.btnSelectSourceClick(Sender: TObject);
var
  LFolder: string;
begin
  LFolder := SelectFolder('Selecionar Pasta de Origem');
  if LFolder.IsEmpty then
    Exit;

  edtSource.Text := LFolder;
  LoadFileList;
end;

procedure TfrmMain.btnSelectDestClick(Sender: TObject);
var
  LFolder: string;
begin
  LFolder := SelectFolder('Selecionar Pasta de Destino');
  if LFolder.IsEmpty then
    Exit;

  edtDest.Text := LFolder;
  SetStatus('Pasta de destino selecionada.');
end;

procedure TfrmMain.LoadFileList;
var
  LFiles: TStringDynArray;
  LFile: string;
begin
  lbxFiles.Items.Clear;

  if edtSource.Text.IsEmpty then
    Exit;

  LFiles := FCopierService.ListFiles(edtSource.Text);

  for LFile in LFiles do
    lbxFiles.Items.Add(TPath.GetFileName(LFile));

  SetStatus(Format('%d arquivo(s) encontrado(s).', [Length(LFiles)]));
end;

procedure TfrmMain.btnCopyClick(Sender: TObject);
var
  LCopied: Integer;
begin
  if edtSource.Text.IsEmpty then
  begin
    ShowMessage('Selecione a pasta de origem.');
    Exit;
  end;

  if edtDest.Text.IsEmpty then
  begin
    ShowMessage('Selecione a pasta de destino.');
    Exit;
  end;

  if lbxFiles.Items.Count = 0 then
  begin
    ShowMessage('Nenhum arquivo para copiar.');
    Exit;
  end;

  prgCopy.Position := 0;
  prgCopy.Max := lbxFiles.Items.Count;
  btnCopy.Enabled := False;
  try
    LCopied := FCopierService.CopyFiles(edtSource.Text, edtDest.Text,
      procedure(const AFileName: string; ACurrent, ATotal: Integer)
      begin
        prgCopy.Position := ACurrent;
        SetStatus(Format('Copiando: %s (%d/%d)', [AFileName, ACurrent, ATotal]));
        Application.ProcessMessages;
      end);

    SetStatus(Format('Concluído! %d arquivo(s) copiado(s).', [LCopied]));
    ShowMessage(Format('%d arquivo(s) copiado(s) com sucesso!', [LCopied]));
  except
    on E: Exception do
    begin
      SetStatus('Erro durante a cópia.');
      ShowMessage('Erro ao copiar: ' + E.Message);
    end;
  end;
  btnCopy.Enabled := True;
end;

procedure TfrmMain.SetStatus(const AMessage: string);
begin
  stbMain.Panels[0].Text := AMessage;
end;

end.
