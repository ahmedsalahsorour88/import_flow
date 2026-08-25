; =====================================================================
; Sorour Logistics ERP — Inno Setup Script
; Builds a Single Fast Windows Setup Wizard (.EXE Installer)
; =====================================================================

#define MyAppName "Sorour Logistics"
#define MyAppVersion "1.0.14"
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
OutputBaseFilename=Sorour_Logistics_Setup_v1.0.14
SetupIconFile={#AppIconPath}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Standalone Package Application Binaries & Assets (Excludes Database)
Source: "..\dist\Sorour_Logistics_Standalone\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.db"

; Initial Master Database: Copied ONLY on fresh first install, NEVER overwritten or uninstalled during updates
Source: "..\dist\Sorour_Logistics_Standalone\sorour_logistics.db"; DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; WorkingDir: "{app}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: shellexec postinstall nowait skipifsilent
