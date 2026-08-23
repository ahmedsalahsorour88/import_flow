; =====================================================================
; ImportFlow ERP — Inno Setup Script
; Builds a Single Fast Windows Setup Wizard (.EXE Installer)
; =====================================================================

#define MyAppName "ImportFlow ERP"
#define MyAppVersion "1.0.1"
#define MyAppPublisher "Sorour Logistics"
#define MyAppURL "https://importflow.local"
#define MyAppExeName "Launch_ImportFlow.vbs"
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
OutputBaseFilename=ImportFlow_Setup_v{#MyAppVersion}
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
Source: "..\dist\ImportFlow_Standalone\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.db"

; Initial Master Database: Copied ONLY on fresh first install, NEVER overwritten or uninstalled during updates
Source: "..\dist\ImportFlow_Standalone\sorour_logistics.db"; DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; WorkingDir: "{app}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: shellexec postinstall nowait skipifsilent
