unit CamUtils;

// Usage Instructions:
// 1. Add necessary permissions to Android manifest: <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" /> (for Android 13+)
//    or <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" /> for older.
// 2. Before calling PickImageFromGallery, request permission: RequestStorageReadPermission(procedure begin PickImageFromGallery; end);
// 3. In your form's OnCreate: SetupImagePickerCallback(procedure(const Path: string) begin if not Path.IsEmpty then ProcessImage(Path); end);
// 4. To save: AddToPhotosAlbum(MyBitmap);

INTERFACE

USES
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Permissions, System.IOUtils, System.JSON, System.Messaging,
  FMX.Platform.Android, FMX.Types, FMX.Graphics, FMX.MediaLibrary, FMX.Platform, FMX.DialogService;


TYPE
  TImageSelectedEvent = procedure(const Path: string) of object;

procedure RequestCameraPermission(const AOnGranted: TProc);
procedure RequestStorageReadPermission(const AOnGranted: TProc);  // For image picking on Android 13+

function GetSaveFolder: string;
function GetSaveName: string;

procedure AddToPhotosAlbum(const ABitmap: TBitmap);  // Saves to gallery, handles indexing

procedure ScanMediaFile(const AFileName: string);  // If manually saving files

const
  REQUEST_PICK_IMAGE = 1;

procedure PickImageFromGallery;  // Opens the Photos/Gallery picker

procedure SetupImagePickerCallback(const AOnImageSelected: TImageSelectedEvent);

//function GetPathFromUri(const AUri: Jnet_Uri): string;
//function CopyUriToCacheFile(const AUri: Jnet_Uri; const AFileExtension: string = '.jpg'): string;

IMPLEMENTATION

{$IFDEF ANDROID}
uses
  Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.JavaTypes, Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Net, Androidapi.JNI.App, Androidapi.JNI.Media, Androidapi.JNI.Provider, Androidapi.JNIBridge, FMX.Helpers.Android;
{$ENDIF}


procedure RequestCameraPermission(const AOnGranted: TProc);
begin
{$IFDEF ANDROID}
  var CameraPermission := JStringToString(TJManifest_permission.JavaClass.CAMERA);
  PermissionsService.RequestPermissions([CameraPermission],
      procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
      begin
        if (Length(AGrantResults) = 1) and (AGrantResults[0] = TPermissionStatus.Granted) then
        begin
          if Assigned(AOnGranted) then
            AOnGranted;
        end
        else
          TDialogService.ShowMessage('Cannot access the camera because the required permission has not been granted');
      end);
{$ELSE}
  if Assigned(AOnGranted) then
    AOnGranted;  // No permission needed on non-Android platforms
{$ENDIF}
end;

procedure RequestStorageReadPermission(const AOnGranted: TProc);
begin
{$IFDEF ANDROID}
  var ReadPermission: string;
  if TOSVersion.Major >= 13 then
    ReadPermission := JStringToString(TJManifest_permission.JavaClass.READ_MEDIA_IMAGES)
  else
    ReadPermission := JStringToString(TJManifest_permission.JavaClass.READ_EXTERNAL_STORAGE);
  PermissionsService.RequestPermissions([ReadPermission],
      procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
      begin
        if (Length(AGrantResults) = 1) and (AGrantResults[0] = TPermissionStatus.Granted) then
        begin
          if Assigned(AOnGranted)
          then AOnGranted;
        end
        else
          TDialogService.ShowMessage('Cannot access storage because the required permission has not been granted');
      end);
{$ELSE}
  if Assigned(AOnGranted) then AOnGranted;  // No permission needed on non-Android platforms
{$ENDIF}
end;

function GetSaveFolder: string;
begin
  {$IFDEF MSWINDOWS}
  Result := TPath.Combine(TPath.GetHomePath, 'AppData\Roaming\LightSaber-DemoAppPhotos');
  {$ELSEIF DEFINED(ANDROID)}
  Result := TPath.GetSharedPicturesPath;
  {$ELSE}
  Result := TPath.GetDocumentsPath;
  {$ENDIF}
end;

function GetSaveName: string;
var
  FolderPath: string;
begin
  FolderPath := GetSaveFolder;
  if not DirectoryExists(FolderPath) then
    ForceDirectories(FolderPath);
  Result := TPath.Combine(FolderPath, FormatDateTime('yyyy.mm.dd hh.nn.ss', Now) + '.jpg');
end;

procedure AddToPhotosAlbum(const ABitmap: TBitmap);
var
  PhotoLibrary: IFMXPhotoLibrary;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXPhotoLibrary, PhotoLibrary) then
  begin
    PhotoLibrary.AddImageToSavedPhotosAlbum(ABitmap);
    // No need for ScanMediaFile here, as AddImageToSavedPhotosAlbum handles indexing internally on Android
  end;
end;

procedure ScanMediaFile(const AFileName: string);
begin
{$IFDEF ANDROID}
  var Intent: JIntent;
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_MEDIA_SCANNER_SCAN_FILE);
  Intent.setData(TJnet_Uri.JavaClass.fromFile(TJFile.JavaClass.&init(StringToJString(AFileName))));
  TAndroidHelper.Activity.sendBroadcast(Intent);
{$ENDIF}
end;


// Before calling PickImageFromGallery, request permission: RequestStorageReadPermission(procedure begin PickImageFromGallery; end);
procedure PickImageFromGallery;
begin
{$IFDEF ANDROID}
  VAR Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_PICK);
  Intent.setType(StringToJString('image/*'));
  MainActivity.startActivityForResult(Intent, REQUEST_PICK_IMAGE);
{$ENDIF}
end;


function CopyUriToCache(const AUri: Jnet_Uri): string;
var
  InputStream: JInputStream;
  OutputStream: JFileOutputStream;
  CacheFile: JFile;
  Buffer: TArray<Byte>;
  BytesRead: Integer;
begin
  Result := '';
  CacheFile := TJFile.JavaClass.createTempFile(StringToJString('img_'), StringToJString('.jpg'), TAndroidHelper.Context.getCacheDir);
  if CacheFile <> nil then
  begin
    Result := JStringToString(CacheFile.getAbsolutePath);
    InputStream := TAndroidHelper.ContentResolver.openInputStream(AUri);
    if InputStream <> nil then
    try
      OutputStream := TJFileOutputStream.JavaClass.&init(CacheFile);
      try
        SetLength(Buffer, 4096);
        BytesRead := InputStream.read(TJavaArray<Byte>.Create(Length(Buffer)));
        while BytesRead > 0 do
        begin
          OutputStream.write(TJavaArray<Byte>.Create(Length(Buffer)), 0, BytesRead);
          BytesRead := InputStream.read(TJavaArray<Byte>.Create(Length(Buffer)));
        end;
      finally
        OutputStream.close;
      end;
    finally
      InputStream.close;
    end;
  end;
end;


// Call this once (e.g., in FormCreate) to handle the picker result asynchronously
// Callback receives the full file path or empty if canceled
procedure SetupImagePickerCallback(const AOnImageSelected: TImageSelectedEvent);
begin
  //GImageSelectedCallback := AOnImageSelected;
  TMessageManager.DefaultManager.SubscribeToMessage(TMessageResultNotification,
    procedure(const Sender: TObject; const M: TMessage)
    var
      Msg: TMessageResultNotification absolute M;
      Uri: Jnet_Uri;
      Path: string;
    begin
      if Msg.RequestCode = REQUEST_PICK_IMAGE then
      begin
        if Msg.ResultCode = TJActivity.JavaClass.RESULT_OK then
        begin
          Uri := Msg.Value.getData;
          Path := CopyUriToCache(Uri);
          //if Path.IsEmpty then error  // Fallback to copy if path query fails
          if Assigned(AOnImageSelected)
          then AOnImageSelected(Path);
        end
        else
          if Assigned(AOnImageSelected)
          then AOnImageSelected('');
      end;
    end);
end;




(*
// Helper to copy from URI to app's cache dir and return a usable path (fallback if GetPathFromUri fails or for reliability)
function CopyUriToCacheFile(const AUri: Jnet_Uri; const AFileExtension: string = '.jpg'): string;
{$IFDEF ANDROID}
var
  InputStream: JInputStream;
  OutputStream: JFileOutputStream;
  CacheFile: JFile;
  Buffer: TArray<Byte>;
  BytesRead: Integer;
begin
  Result := '';
  if AUri = nil then Exit;
  // Create a temp file in cache dir
  CacheFile := TJFile.JavaClass.createTempFile(StringToJString('temp_image_'), StringToJString(AFileExtension),
    TAndroidHelper.Context.getCacheDir);
  if CacheFile = nil then Exit;
  Result := JStringToString(CacheFile.getAbsolutePath);
  InputStream := TAndroidHelper.ContentResolver.openInputStream(AUri);
  if InputStream = nil then Exit;
  try
    OutputStream := TJFileOutputStream.JavaClass.&init(CacheFile);
    try
      SetLength(Buffer, 4096);
      BytesRead := InputStream.read(TJavaArray<Byte>.Create(Buffer));
      while BytesRead > 0 do
      begin
        OutputStream.write(TJavaArray<Byte>.Create(Buffer), 0, BytesRead);
        BytesRead := InputStream.read(TJavaArray<Byte>.Create(Buffer));
      end;
    finally
      OutputStream.close;
    end;
  finally
    InputStream.close;
  end;
{$ELSE}
begin
  Result := '';
{$ENDIF}
end;  *)



{dave notage said "There is already an import for it in the Androidapi.JNI.Provider unit. In Delphi 10.4.1, starting at line 3658".
https://en.delphipraxis.net/topic/3856-open-android-gallery-with-intent/
 
It is not there anymore in D13. I looked in Androidapi.JNI.Provider. I can find TJMediaStore_Images but not MediaStore_Images_Media.
}

// Attempts to get absolute path; may not always work on Android 10+
(*
function GetPathFromUri(const AUri: Jnet_Uri): string;
{$IFDEF ANDROID}
var
  Cursor: JCursor;
  ColumnIndex: Integer;
  Projection: TJavaObjectArray<JString>;
begin
  Result := '';
  if AUri = nil then Exit;

  Projection := TJavaObjectArray<JString>.Create(1);
  Projection.Items[0] := TJMediaStore_Images_Media.JavaClass.DATA;

  Cursor := TAndroidHelper.ContentResolver.query(AUri, Projection, nil, nil, nil);
  if Cursor <> nil then
  try
    if Cursor.moveToFirst then
    begin
      ColumnIndex := Cursor.getColumnIndexOrThrow(TJMediaStore_Images_Media.JavaClass.DATA);
      Result := JStringToString(Cursor.getString(ColumnIndex));
    end;
  finally
    Cursor.close;
  end;
{$ELSE}
begin
  Result := '';  // No-op on non-Android platforms
{$ENDIF}
end;  *)




end.
