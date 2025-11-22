UNIT MainForm;

{=============================================================================================================
   www.GabrielMoraru.com
   2025.10
   Github.com/GabrielOnDelphi/Delphi-LightSaber/blob/main/System/Copyright.txt
--------------------------------------------------------------------------------------------------------------
   A FMX program that shows how to take snapshots with the video camera.
   Works on Win, Android and Mac!
=============================================================================================================}

INTERFACE

USES
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Permissions, System.Actions,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Layouts, FMX.Controls.Presentation,
  FMX.Objects, FMX.Platform, FMX.DialogService, FMX.Media, FMX.MediaLibrary, FMX.ActnList, FMX.StdActns, FMX.MediaLibrary.Actions,
  System.IOUtils;

TYPE
  TfrmCamCapture = class(TForm)
    imgPreview: TImage;
    Label1: TLabel;
    Layout1: TLayout;
    Layout2: TLayout;
    chkActivate: TCheckBox;
    ActionList: TActionList;
    CameraComp: TCameraComponent;
    actTakePhoto: TTakePhotoFromCameraAction;
    btnService: TButton;
    btnAction: TButton;
    btnComponent: TButton;
    procedure btnServiceClick  (Sender: TObject);
    procedure btnActionClick   (Sender: TObject);
    procedure btnComponentClick(Sender: TObject);
    procedure SampleBufferReady(Sender: TObject; const ATime: TMediaTime);
    procedure chkActivateChange(Sender: TObject);
    procedure PhotoFinishTaking(BMP: TBitmap);
    procedure DoDidFinish      (BMP: TBitmap);
  private
    procedure DisplayCameraPreview;
    procedure SavePhoto;
    procedure TakePhotoAfterPermission1;
    procedure TakePhotoAfterPermission2;
  public
  end;

VAR
  frmCamCapture: TfrmCamCapture;

function GetSaveFolder: string;
function GetSaveName: string;


IMPLEMENTATION
{$R *.fmx}

{$IFDEF ANDROID}
USES Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.JavaTypes;
{$ENDIF}


{-------------------------------------------------------------------------------------------------------------
   Shared Permission Procedure
-------------------------------------------------------------------------------------------------------------}
procedure RequestCameraPermission(const AOnGranted: TProc);
begin
  var CameraPermission:= JStringToString(TJManifest_permission.JavaClass.CAMERA);
  PermissionsService.RequestPermissions([CameraPermission],
      procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
      begin
        if (Length(AGrantResults) = 1)
        and (AGrantResults[0] = TPermissionStatus.Granted)
        then
          if Assigned(AOnGranted)
          then AOnGranted
          else
        else
          TDialogService.ShowMessage('Cannot access the camera because the required permission has not been granted');
      end);
end;


{-------------------------------------------------------------------------------------------------------------
   Via SERVICE
   Does not work on Windows.
   docwiki.embarcadero.com/RADStudio/Florence/en/Taking_Pictures_Using_FireMonkey_Interfaces
-------------------------------------------------------------------------------------------------------------}
procedure TfrmCamCapture.btnServiceClick(Sender: TObject);
begin
  Label1.Text:= '';
  RequestCameraPermission(TakePhotoAfterPermission1);
end;


procedure TfrmCamCapture.TakePhotoAfterPermission1;
var
  Service: IFMXCameraService;
  Params: TParamsPhotoQuery;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXCameraService, Service)
  then
    begin
      Params.Editable           := True;                      // Allows editing on iOS; ignored on Android
      Params.NeedSaveToAlbum    := False;                     // Do not save to photo library; we'll save manually
      Params.RequiredResolution := TSize.Create(1920, 1200);
      Params.OnDidFinishTaking  := DoDidFinish;
      Service.TakePhoto(btnService, Params);
    end
  else
    TDialogService.ShowMessage('This device does not support the camera service!');
end;


procedure TfrmCamCapture.DoDidFinish(BMP: TBitmap);
begin
  imgPreview.Bitmap.Assign(BMP);
  BMP.SaveToFile(GetSaveName);
  Label1.Text:= 'Saved to: ' + GetSaveName;
end;




{-------------------------------------------------------------------------------------------------------------
   Via ACTION
   Does not work on Windows.
-------------------------------------------------------------------------------------------------------------}
procedure TfrmCamCapture.btnActionClick(Sender: TObject);
begin
  Label1.Text:= '';
  RequestCameraPermission(TakePhotoAfterPermission2);
end;


procedure TfrmCamCapture.TakePhotoAfterPermission2;
begin
  actTakePhoto.Execute;
end;


procedure TfrmCamCapture.PhotoFinishTaking(BMP: TBitmap);
begin
  imgPreview.Bitmap.Assign(BMP);
  BMP.SaveToFile(GetSaveName);
  Label1.Text:= 'Saved to: ' + GetSaveName;
end;





{-------------------------------------------------------------------------------------------------------------
   Via TCameraComponent
   Works on Windows!
-------------------------------------------------------------------------------------------------------------}
procedure TfrmCamCapture.chkActivateChange(Sender: TObject);
begin
  CameraComp.Quality:= TVideoCaptureQuality.HighQuality;
  CameraComp.Active := chkActivate.IsChecked;
end;


procedure TfrmCamCapture.btnComponentClick(Sender: TObject);
begin
  Label1.Text:= '';
  SavePhoto;
end;


procedure TfrmCamCapture.SampleBufferReady(Sender: TObject; const ATime: TMediaTime);
begin
  // Sync to main thread to update the preview image
  TThread.Synchronize(TThread.Current,
      procedure
      begin
        DisplayCameraPreview;
      end);
end;


procedure TfrmCamCapture.DisplayCameraPreview;
begin
  CameraComp.SampleBufferToBitmap(imgPreview.Bitmap, True);
end;


procedure TfrmCamCapture.SavePhoto;
begin
  if imgPreview.Bitmap.IsEmpty
  then TDialogService.ShowMessage('No image to save! Ensure the camera is active.')
  else
    begin
      imgPreview.Bitmap.SaveToFile(GetSaveName);
      Label1.Text:= 'Saved to: ' + GetSaveName;
    end;
end;





{-------------------------------------------------------------------------------------------------------------
   UTILS
-------------------------------------------------------------------------------------------------------------}
function GetSaveFolder: string;
begin
  {$IFDEF MSWINDOWS}
  Result:= TPath.Combine(TPath.GetHomePath, 'AppData\Roaming\LightSaber-DemoAppPhotos');
  {$ELSE}
  Result:= TPath.Combine(TPath.GetDocumentsPath, 'LightSaber-DemoAppPhotos');
  {$ENDIF}
end;


function GetSaveName: string;
VAR FolderPath: string;
begin
  // Save to app's documents folder (equivalent to AppData on mobile)
  FolderPath:= GetSaveFolder;
  if NOT DirectoryExists(FolderPath) then ForceDirectories(FolderPath);
  Result:= TPath.Combine(FolderPath, FormatDateTime('yyyy.mm.dd hh.nn.ss', Now) + '.jpg');
end;




end.
