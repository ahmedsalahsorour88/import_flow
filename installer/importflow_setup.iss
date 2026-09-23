; =====================================================================
; Sorour Logistics ERP — Inno Setup Script
; Builds a Single Fast Windows Setup Wizard (.EXE Installer)
; =====================================================================

#define MyAppName "Sorour Logistics"
#define MyAppVersion "2.0.3"
#define MyAppPublisher "Sorour Logistics"
#define MyAppURL "https://sorourlogistics.com"
#define MyAppExeName "Launch_Sorour_Logistics.vbs"
#define AppIconPath "app_icon.ico"

[Setup]
AppId={{D37B4254-8B6A-4A73-B5DF-719584C8A69E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\dist\releases
OutputBaseFilename=Sorour_Logistics_Setup_v2.0.3
SetupIconFile={#AppIconPath}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\app_icon.ico
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Standalone Package Application Binaries & Assets (Excludes Database)
Source: "..\dist\Sorour_Logistics_Standalone\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.db"

; Full Operational Database: Deployed with automatic safety backup of any existing database
Source: "..\dist\Sorour_Logistics_Standalone\sorour_logistics.db"; DestDir: "{app}"; Flags: ignoreversion uninsneveruninstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; WorkingDir: "{app}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: shellexec postinstall nowait skipifsilent

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  AppDb, BackupDb: string;
begin
  if CurStep = ssInstall then
  begin
    AppDb := ExpandConstant('{app}\sorour_logistics.db');
    if FileExists(AppDb) then
    begin
      BackupDb := ExpandConstant('{app}\sorour_logistics_backup_' + GetDateTimeString('yyyymmdd_hhnnss', #0, #0) + '.db');
      FileCopy(AppDb, BackupDb, False);
    end;
  end;
end;
