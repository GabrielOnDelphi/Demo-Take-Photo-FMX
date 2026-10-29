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
  {$IFDEF AUTOPILOT}Autopilot.Bridge.Fmx in 'c:\Projects\Projects AI\Autopilot for Delphi\Source\Bridge\Autopilot.Bridge.Fmx.pas',{$ENDIF}{Optional}
  LightCore.CamUtils in '..\..\LightSaber\LightCore.CamUtils.pas',
  LightFmx.Common.CamUtils in '..\..\LightSaber\FrameFMX\LightFmx.Common.CamUtils.pas',
  LightFmx.Common.Graph in '..\..\LightSaber\FrameFMX\LightFmx.Common.Graph.pas',
  LightFmx.Common.AppData in '..\..\LightSaber\FrameFMX\LightFmx.Common.AppData.pas',
  LightCore.INIFile in '..\..\LightSaber\LightCore.INIFile.pas',
  LightCore.AppData in '..\..\LightSaber\LightCore.AppData.pas';

{$R *.res}

begin

  AppData:= TAppData.Create('Light FMX demo cam capture');
  AppData.CreateMainForm(TfrmCamCapture, frmCamCapture, asFull); // Change AutoState from asFull to asNone if you don't want to save form's state to disk.

  { Optional: Via Autopilot, Claude can run/debug/test this program for you.
    For example, with "Activate" unchecked, press "Save local" & check that it asks you to start the camera first.
    Don't have AUTOPILOT? Undefine $AUTOPILOT or get it from www.GabrielMoraru.com }
  {$IFDEF AUTOPILOT}
   Autopilot.Bridge.Fmx.StartBridge;
  {$ENDIF}
  AppData.Run;
end.
