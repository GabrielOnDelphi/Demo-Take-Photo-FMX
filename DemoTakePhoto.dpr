program DemoTakePhoto;

uses
  System.StartUpCopy,
  FMX.Forms,
  FormCamera in 'FormCamera.pas' {frmCamCapture},
  LightFmx.Common.CamUtils in '..\..\LightSaber\FrameFMX\LightFmx.Common.CamUtils.pas',
  LightFmx.Graph in '..\..\LightSaber\FrameFMX\LightFmx.Graph.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmCamCapture, frmCamCapture);
  Application.Run;
end.
