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
  System.IOUtils, Camutils;

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
    btnLoadImage: TButton;
    procedure btnServiceClick  (Sender: TObject);
    procedure btnActionClick   (Sender: TObject);
    procedure btnComponentClick(Sender: TObject);
    procedure SampleBufferReady(Sender: TObject; const ATime: TMediaTime);
    procedure chkActivateChange(Sender: TObject);
    procedure PhotoFinishTaking(BMP: TBitmap);
    procedure DoDidFinish      (BMP: TBitmap);
    procedure btnLoadImageClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure DisplayCameraPreview;
    procedure TakePhotoAfterPermission_A;
    procedure TakePhotoAfterPermission_B;
    procedure SaveImage(BMP: TBitmap);
    procedure ProcessImage(const Path: string);
  public
  end;

VAR
  frmCamCapture: TfrmCamCapture;


IMPLEMENTATION
{$R *.fmx}


procedure TfrmCamCapture.ProcessImage(const Path: string);
begin
  if not Path.IsEmpty then Label1.Text := Path;
end;

procedure TfrmCamCapture.FormCreate(Sender: TObject);
begin
  SetupImagePickerCallback(ProcessImage);
end;



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
  SaveImage(BMP);
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
  SaveImage(BMP);
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
  if imgPreview.Bitmap.IsEmpty
  then TDialogService.ShowMessage('No image to save! Ensure the camera is active.')
  else
    begin
      SaveImage(imgPreview.Bitmap);
      Label1.Text:= 'Saved to: ' + GetSaveName;
    end;
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


procedure TfrmCamCapture.SaveImage(BMP: TBitmap);
begin
  {$IFDEF ANDROID}
    AddToPhotosAlbum(BMP);
  {$ELSE}
    BMP.SaveToFile(GetSaveName);
    Label1.Text:= 'Saved to: ' + GetSaveName;
  {$ENDIF}
  //ToDo: mac
end;


procedure TfrmCamCapture.btnLoadImageClick(Sender: TObject);
begin
  RequestStorageReadPermission(
        procedure
        begin
          PickImageFromGallery;
        end);
end;


end.
