program DemoTakePhoto;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainForm in 'MainForm.pas' {frmCamCapture};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmCamCapture, frmCamCapture);
  Application.Run;
end.
