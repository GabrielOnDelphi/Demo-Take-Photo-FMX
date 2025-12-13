program DemoTakePhoto;

uses
  {$IF Defined(MSWINDOWS)}
  {$IFDEF DEBUG}
  FastMM4,
  {$ENDIF }
  {$ENDIF }
  System.StartUpCopy,
  FMX.Forms,
  FormCamera in 'FormCamera.pas' {frmCamCapture},
  LightFmx.Common.CamUtils in '..\..\LightSaber\FrameFMX\LightFmx.Common.CamUtils.pas',
  LightFmx.Graph in '..\..\LightSaber\FrameFMX\LightFmx.Graph.pas',
  LightFmx.Common.AppData in '..\..\LightSaber\FrameFMX\LightFmx.Common.AppData.pas',
  LightCore.INIFile in '..\..\LightSaber\LightCore.INIFile.pas',
  LightCore.AppData in '..\..\LightSaber\LightCore.AppData.pas';

{$R *.res}

begin

  AppData:= TAppData.Create('Light FMX demo cam capture');
  AppData.CreateMainForm(TfrmCamCapture, frmCamCapture, asFull); // Change AutoState from asFull to asNone if you don't want to save form's state to disk.
  AppData.Run;
end.
