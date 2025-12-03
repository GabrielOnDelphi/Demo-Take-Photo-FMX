program DemoTakePhoto;

uses
  System.StartUpCopy,
  FMX.Forms,
  FormCamera in 'FormCamera.pas' {frmCamCapture},
  CamUtils in 'CamUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmCamCapture, frmCamCapture);
  Application.Run;
end.
