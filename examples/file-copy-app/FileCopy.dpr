program FileCopy;

uses
  Vcl.Forms,
  FileCopy.Main.View in 'FileCopy.Main.View.pas' {frmMain},
  FileCopy.Service.Copier in 'FileCopy.Service.Copy.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'File Copy - Copy Files';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

