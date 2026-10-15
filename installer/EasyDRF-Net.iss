; EasyDRF - SSTV Net installer
; Installs Daz Man's official EasyDRF.exe (unchanged) with a net preset.
; Built automatically by .github/workflows/build-installer.yml
;
; EasyDRF is free software under the GNU GPL v3.
; Source: https://github.com/DazDSP/EasyDRF  (this installer: https://github.com/brandandon/easydrf)

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0-dev"
#endif

#define MyAppName "EasyDRF"
#define MyAppExe  "EasyDRF.exe"
#define SourceUrl "https://github.com/brandandon/easydrf"

; ---- SSTV net modem preset (PROVISIONAL - set from on-air tests) ----
; QAM: 4, 16 or 64     MODE: 0=A, 1=B, 2=E     BW: 0 or 1
; Interleave: 0 or 1   RS: 0=off, 4=RS1, 5=RS2, 6=RS3, 7=RS4
#define NetQAM "16"
#define NetMode "1"
#define NetBW "1"
#define NetInterleave "1"
#define NetRS "5"

[Setup]
AppId=EasyDRF-SSTV-Net
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} (SSTV Net installer {#MyAppVersion})
AppPublisher=EasyDRF by Daz Man - net installer by brandandon
AppPublisherURL={#SourceUrl}
AppSupportURL={#SourceUrl}
; EasyDRF saves settings and received files next to itself, so it must live
; in a folder the user can write to. A per-user install also avoids the
; admin (UAC) prompt.
PrivilegesRequired=lowest
DefaultDirName={autopf}\EasyDRF
DisableProgramGroupPage=yes
DisableDirPage=yes
LicenseFile=..\GNU General Public License v3.0 - GNU Project - Free Software Foundation (FSF).html
InfoBeforeFile=NOTICE.txt
OutputDir=output
OutputBaseFilename=EasyDRF-Net-Setup-{#MyAppVersion}
SetupIconFile=..\EasyDRF.ico
UninstallDisplayIcon={app}\{#MyAppExe}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[Dirs]
; Received images. Kept on uninstall so nobody loses their pictures.
Name: "{app}\Rx Files"; Flags: uninsneveruninstall

[Files]
Source: "..\Release\EasyDRF.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\GNU General Public License v3.0 - GNU Project - Free Software Foundation (FSF).html"; DestDir: "{app}"; DestName: "LICENSE (GPL v3).html"
Source: "NOTICE.txt"; DestDir: "{app}"

[Icons]
; WorkingDir matters: EasyDRF looks for settings.txt and "Rx Files" in its working folder.
Name: "{autoprograms}\EasyDRF"; Filename: "{app}\{#MyAppExe}"; WorkingDir: "{app}"
Name: "{autoprograms}\EasyDRF Received Images"; Filename: "{app}\Rx Files"
Name: "{autodesktop}\EasyDRF"; Filename: "{app}\{#MyAppExe}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExe}"; WorkingDir: "{app}"; Description: "Start EasyDRF now"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: files; Name: "{app}\bsrreq.bin"

[Code]
var
  CallPage: TInputQueryWizardPage;

function SettingsPath(): String;
begin
  Result := ExpandConstant('{app}\settings.txt');
end;

{ Only ask for a callsign on a fresh install. Upgrades keep the member's settings. }
function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := (PageID = CallPage.ID) and FileExists(WizardDirValue() + '\settings.txt');
end;

procedure InitializeWizard();
begin
  CallPage := CreateInputQueryPage(wpInfoBefore,
    'Your callsign', 'EasyDRF sends your callsign with every image.',
    'Enter your amateur radio callsign (for example KD9DD), then click Next.');
  CallPage.Add('Callsign:', False);
end;

function CleanCall(S: String): String;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  S := Uppercase(Trim(S));
  for i := 1 to Length(S) do
  begin
    c := S[i];
    if ((c >= 'A') and (c <= 'Z')) or ((c >= '0') and (c <= '9')) or (c = '/') then
      Result := Result + c;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  Call: String;
begin
  Result := True;
  if CurPageID = CallPage.ID then
  begin
    Call := CleanCall(CallPage.Values[0]);
    if (Length(Call) < 3) or (Length(Call) > 12) then
    begin
      MsgBox('Please enter a valid callsign (3 to 12 letters and numbers).', mbError, MB_OK);
      Result := False;
    end
    else
      CallPage.Values[0] := Call;
  end;
end;

{ Write the SSTV net preset. Line order matters: EasyDRF reads settings.txt by position. }
procedure WriteNetPreset(Call: String);
var
  Lines: TArrayOfString;
begin
  SetArrayLength(Lines, 19);
  Lines[0]  := '0 TX_Port';
  Lines[1]  := Call + ' Call';
  Lines[2]  := '0 TX_Sound_OUT_Device';
  Lines[3]  := '0 TX_Sound_IN_Device';
  Lines[4]  := '0 RX_Sound_OUT_Device';
  Lines[5]  := '0 RX_Sound_IN_Device';
  Lines[6]  := '1 Send_Text_Message';
  Lines[7]  := '8 Display_Type';
  Lines[8]  := '0 RX_Audfilt';
  Lines[9]  := '0 FAC_mute';
  { --- Net modem preset (provisional - confirm with on-air tests) --- }
  Lines[10] := '{#NetQAM} QAM';
  Lines[11] := '{#NetMode} MODE';
  Lines[12] := '{#NetBW} BW';
  Lines[13] := '{#NetInterleave} Interleave';
  Lines[14] := '0 FastReset';
  Lines[15] := '{#NetRS} Instances/RS';
  Lines[16] := '100 100 0 0 WindowPosition';
  Lines[17] := '0 TxLevel';
  Lines[18] := '1 Allow_Text_Message';
  SaveStringsToFile(SettingsPath(), Lines, False);
  SaveStringToFile(SettingsPath(), '1 DV_Compressor' + #13#10, True);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and (not FileExists(SettingsPath())) then
    WriteNetPreset(CallPage.Values[0]);
end;
