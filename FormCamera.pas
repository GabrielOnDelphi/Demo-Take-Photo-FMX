UNIT FormCamera;

{=============================================================================================================
   www.GabrielMoraru.com
   2025.10
   Github.com/GabrielOnDelphi/Delphi-LightSaber/blob/main/System/Copyright.txt
--------------------------------------------------------------------------------------------------------------
   A FMX program that shows how to take snapshots with the video camera.
   Works on Win, Android and Mac!
=============================================================================================================}

// I have Android 12

INTERFACE

USES
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Permissions, System.Actions,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Layouts, FMX.Controls.Presentation,
  FMX.Objects, FMX.Platform, FMX.DialogService, FMX.Media, FMX.MediaLibrary, FMX.ActnList, FMX.StdActns, FMX.MediaLibrary.Actions,
  System.IOUtils, LightFmx.Common.AppData.Form;

TYPE
  TfrmCamCapture = class(TLightForm)
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
    btnSelectImage: TButton;
    Layout3: TLayout;
    btnSaveLocal: TButton;
    Button1: TButton;
    procedure btnServiceClick  (Sender: TObject);
    procedure btnActionClick   (Sender: TObject);
    procedure btnComponentClick(Sender: TObject);
    procedure SampleBufferReady(Sender: TObject; const ATime: TMediaTime);
    procedure chkActivateChange(Sender: TObject);
    procedure PhotoFinishTaking(BMP: TBitmap);
    procedure DoDidFinish      (BMP: TBitmap);
    procedure btnSelectImageClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSaveLocalClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    procedure DisplayCameraPreview;
    procedure TakePhotoAfterPermission_A;
    procedure TakePhotoAfterPermission_B;
    procedure SaveToPublicGallery(BMP: TBitmap);
  public
    procedure ProcessImage(const Path: string);   // Unused
  end;

VAR
  frmCamCapture: TfrmCamCapture;


IMPLEMENTATION {$R *.fmx}

USES 
  LightFmx.Common.CamUtils, LightFmx.Graph, LightFmx.Common.AppData;




procedure TfrmCamCapture.FormCreate(Sender: TObject);
begin
  {$IFDEF ANDROID}
    SetupImagePickerCallback(ProcessImage);  // Set call back
  {$ELSE}
  {$ENDIF}
end;


procedure TfrmCamCapture.ProcessImage(const Path: string);
begin
  if not Path.IsEmpty then 
  begin
    // Use the LoadImage utility which handles errors safely
    LightFmx.Graph.LoadImage(Path, imgPreview);
    Label1.Text:= 'Loaded from: ' + Path;
  end;
end;


{-------------------------------------------------------------------------------------------------------------
   Via IFMXCameraService
   Does not work on Windows.
-------------------------------------------------------------------------------------------------------------}
procedure TfrmCamCapture.btnServiceClick(Sender: TObject);
begin
  Label1.Text:= '';
  RequestCameraPermission(TakePhotoAfterPermission_A);
end;


procedure TfrmCamCapture.TakePhotoAfterPermission_A;
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
  SaveToPublicGallery(BMP);
end;




{-------------------------------------------------------------------------------------------------------------
   Via ACTION
   Does not work on Windows.
-------------------------------------------------------------------------------------------------------------}
procedure TfrmCamCapture.btnActionClick(Sender: TObject);
begin
  Label1.Text:= '';
  RequestCameraPermission(TakePhotoAfterPermission_B);
end;


procedure TfrmCamCapture.TakePhotoAfterPermission_B;
begin
  actTakePhoto.Execute;
end;


procedure TfrmCamCapture.PhotoFinishTaking(BMP: TBitmap);
begin
  imgPreview.Bitmap.Assign(BMP);
  SaveToPublicGallery(BMP);
end;





{-------------------------------------------------------------------------------------------------------------
   Via TCameraComponent (Live View)
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
  if imgPreview.Bitmap.IsEmpty
  then TDialogService.ShowMessage('No image to save! Ensure the camera is active.')
  else
  begin
    SaveToPublicGallery(imgPreview.Bitmap);
  end;
end;


procedure TfrmCamCapture.SampleBufferReady(Sender: TObject; const ATime: TMediaTime);
begin
  // Sync to main thread to update the preview image
  TThread.Synchronize(TThread.Current, DisplayCameraPreview);
end;


procedure TfrmCamCapture.DisplayCameraPreview;
begin
  CameraComp.SampleBufferToBitmap(imgPreview.Bitmap, True);
end;



{-------------------------------------------------------------------------------------------------------------
   SAVING LOGIC (Public Gallery)
-------------------------------------------------------------------------------------------------------------}
procedure TfrmCamCapture.SaveToPublicGallery(BMP: TBitmap);
begin
  {$IFDEF ANDROID}
    AddToPhotosAlbum(BMP);
    Label1.Text:= 'Saved to Gallery';
  {$ELSE}
    var Fn := GetNewTimestampFileName(GetPublicPicturesFolder);
    BMP.SaveToFile(Fn);
    Label1.Text:= 'Saved to: ' + Fn;
  {$ENDIF}
end;



{-------------------------------------------------------------------------------------------------------------
   LOAD IMAGES FROM GALLERY
-------------------------------------------------------------------------------------------------------------}
procedure TfrmCamCapture.btnSelectImageClick(Sender: TObject);
begin
  // Open the Android "Gallery" and let user select a photo.
  RequestStorageReadPermission(
        procedure
        begin
          PickImageFromGallery;
        end);
end;


{-------------------------------------------------------------------------------------------------------------
   TEST: SAVE IMAGE TO LOCAL & RELOAD
-------------------------------------------------------------------------------------------------------------}
procedure TfrmCamCapture.btnSaveLocalClick(Sender: TObject);
var
  TempBMP: TBitmap;
begin
  // Get Snapshot
  TempBMP := TBitmap.Create;
  try
    if CameraComp.Active
    then CameraComp.SampleBufferToBitmap(TempBMP, True)
    else
      if NOT imgPreview.Bitmap.IsEmpty
      then TempBMP.Assign(imgPreview.Bitmap)
      else
        begin
          TDialogService.ShowMessage('Start the camera (Checkbox) first to take a snapshot.');
          Exit;
        end;

    // Save
    try
      TempBMP.SaveToFile(LocalJpeg);      // SaveToFile calls TBitmapCodecManager. The manager looks at the file extension you provided (.jpg).
    except
      on E: Exception do
      begin
        TDialogService.ShowMessage('Save Failed: ' + E.Message);
        Exit;
      end;
    end;

    // Clear Preview to prove we are reloading
    imgPreview.Bitmap.Clear(TAlphaColorRec.Null);
    Label1.Text := 'Cleared...';
    Application.ProcessMessages;
    Sleep(700);                        // Tiny pause for visual confirmation (optional)

    Label1.Text := 'Reading from: ' + LocalJpeg;
    LightFmx.Graph.LoadImage(LocalJpeg, imgPreview);
  finally
    TempBMP.Free;
  end;
end;


procedure TfrmCamCapture.Button1Click(Sender: TObject);
begin
  // Clear Preview to prove we are reloading
  imgPreview.Bitmap.Clear(TAlphaColorRec.Null);
  Label1.Text := 'Cleared...';
  Application.ProcessMessages;
  Sleep(700); // Tiny pause for visual confirmation (optional)

  Label1.Text := 'Reading from: ' + LocalJpeg;
  LightFmx.Graph.LoadImage(LocalJpeg, imgPreview);
end;

end.
