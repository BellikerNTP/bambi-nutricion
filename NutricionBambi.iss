#define MyAppName "Nutrición Hogar Bambi"
#define MyAppVersion "0.9.9"
#define MyAppPublisher "Hogar Bambi"
#define MongoHost "bambinutricion.27sir9d.mongodb.net"
#define MongoOptions "/?appName=bambiNutricion"
#define FlutterReleaseDir "Nutricion-flutter\build\windows\x64\runner\Release"
#define BackendExe       "backend\dist\nutricion_backend.exe"
#define BackendEnv       "backend\.env"
#define MyAppExeName     "nutricion_front.exe"


[Setup]
AppId={{B7B5E4F5-6C27-4F64-9A2E-5E3A9F1A1234}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={pf}\NutricionBambi
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=NutricionBambiSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Files]
; Todo lo que genera Flutter
Source: "{#FlutterReleaseDir}\*"; DestDir: "{app}"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

; Ejecutable del backend (PyInstaller onefile)
Source: "{#BackendExe}"; DestDir: "{app}"; Flags: ignoreversion

; Plantilla inicial de .env (el wizard luego la sobreescribe con usuario/clave)
Source: "{#BackendEnv}"; DestDir: "{app}"; DestName: ".env"; Flags: ignoreversion

[Icons]
; Acceso directo en el menú Inicio
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
; Acceso directo en el escritorio
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el Escritorio"; GroupDescription: "Accesos directos:"; Flags: unchecked

[Code]

var
  MongoPage: TWizardPage;
  MongoUserEdit: TNewEdit;
  MongoPassEdit: TNewEdit;
  MongoDbEdit: TNewEdit;

procedure InitializeWizard;
var
  L: TNewStaticText;
begin
  { Página para pedir datos de MongoDB }
  MongoPage := CreateCustomPage(
    wpSelectDir,
    'Configuración de base de datos',
    'Conexión a MongoDB'
  );

  { Usuario }
  L := TNewStaticText.Create(MongoPage);
  L.Parent := MongoPage.Surface;
  L.Left := 0;
  L.Top := 8;
  L.Width := 120;
  L.Caption := 'Usuario:';

  MongoUserEdit := TNewEdit.Create(MongoPage);
  MongoUserEdit.Parent := MongoPage.Surface;
  MongoUserEdit.Left := 250;
  MongoUserEdit.Top := 6;
  MongoUserEdit.Width := MongoPage.SurfaceWidth - 130;
  MongoUserEdit.Text := '';

  { Contraseña }
  L := TNewStaticText.Create(MongoPage);
  L.Parent := MongoPage.Surface;
  L.Left := 0;
  L.Top := 45;
  L.Width := 120;
  L.Caption := 'Contraseña:';

  MongoPassEdit := TNewEdit.Create(MongoPage);
  MongoPassEdit.Parent := MongoPage.Surface;
  MongoPassEdit.Left := 250;
  MongoPassEdit.Top := 43;
  MongoPassEdit.Width := MongoPage.SurfaceWidth - 130;
  MongoPassEdit.PasswordChar := '*';
  MongoPassEdit.Text := '';

  { Nombre de BD }
  L := TNewStaticText.Create(MongoPage);
  L.Parent := MongoPage.Surface;
  L.Left := 0;
  L.Top := 80;
  L.Width := 120;
  L.Caption := 'MONGODB_DB:';

  MongoDbEdit := TNewEdit.Create(MongoPage);
  MongoDbEdit.Parent := MongoPage.Surface;
  MongoDbEdit.Left := 250;
  MongoDbEdit.Top := 78;
  MongoDbEdit.Width := MongoPage.SurfaceWidth - 130;
  MongoDbEdit.Text := 'nutricion_hogar_bambi';
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = MongoPage.ID then
  begin
    if (Trim(MongoUserEdit.Text) = '') or (Trim(MongoPassEdit.Text) = '') then
    begin
      MsgBox('Debes introducir usuario y contraseña de MongoDB.',
        mbError, MB_OK);
      Result := False;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  EnvPath: string;
  Content: string;
begin
  if CurStep = ssPostInstall then
  begin
    EnvPath := ExpandConstant('{app}\.env');

    { OJO: si la contraseña tiene caracteres especiales,
      deben venir ya escapados en formato de URL. }
    Content :=
      'MONGODB_URI=mongodb+srv://' +
      MongoUserEdit.Text + ':' + MongoPassEdit.Text + '@' +
      '{#MongoHost}' + '{#MongoOptions}' + #13#10 +
      'MONGODB_DB=' + MongoDbEdit.Text + #13#10;

    if not SaveStringToFile(EnvPath, Content, False) then
    begin
      MsgBox('No se pudo escribir el archivo .env en: ' + EnvPath,
        mbError, MB_OK);
    end;
  end;
end;























