!include "MUI2.nsh"
!include "x64.nsh"

; Values are supplied by ops/windows/package.ps1.
!ifndef APP_VERSION
  !define APP_VERSION "0.0.0"
!endif
!ifndef SOURCE_DIR
  !define SOURCE_DIR "build\\windows\\x64\\runner\\Release"
!endif
!ifndef OUTPUT_FILE
  !define OUTPUT_FILE "OmniConvert-${APP_VERSION}-windows-x64-setup.exe"
!endif

Name "OmniConvert"
Caption "OmniConvert ${APP_VERSION} Setup"
OutFile "${OUTPUT_FILE}"
InstallDir "$PROGRAMFILES64\\OmniConvert"
InstallDirRegKey HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OmniConvert" "InstallLocation"
RequestExecutionLevel admin
Unicode true
ManifestSupportedOS win10

VIProductVersion "${APP_VERSION}.0"
VIAddVersionKey "ProductName" "OmniConvert"
VIAddVersionKey "CompanyName" "OmniConvert"
VIAddVersionKey "FileDescription" "OmniConvert installer"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "Apache-2.0"

!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\\Contrib\\Graphics\\Icons\\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\\Contrib\\Graphics\\Icons\\modern-uninstall.ico"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\\omniconvert.exe"
!define MUI_FINISHPAGE_RUN_TEXT "启动 OmniConvert"
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "SimpChinese"

Section "OmniConvert" SEC_MAIN
  SectionIn RO
  SetOutPath "$INSTDIR"
  File /r "${SOURCE_DIR}\\*"

  CreateDirectory "$SMPROGRAMS\\OmniConvert"
  CreateShortcut "$SMPROGRAMS\\OmniConvert\\OmniConvert.lnk" "$INSTDIR\\omniconvert.exe"
  CreateShortcut "$DESKTOP\\OmniConvert.lnk" "$INSTDIR\\omniconvert.exe"

  WriteUninstaller "$INSTDIR\\uninstall.exe"
  WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OmniConvert" "DisplayName" "OmniConvert"
  WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OmniConvert" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OmniConvert" "Publisher" "OmniConvert"
  WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OmniConvert" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OmniConvert" "UninstallString" "$INSTDIR\\uninstall.exe"
  WriteRegDWORD HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OmniConvert" "NoModify" 1
  WriteRegDWORD HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OmniConvert" "NoRepair" 1
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\\OmniConvert.lnk"
  Delete "$SMPROGRAMS\\OmniConvert\\OmniConvert.lnk"
  RMDir "$SMPROGRAMS\\OmniConvert"
  DeleteRegKey HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OmniConvert"
  RMDir /r "$INSTDIR"
SectionEnd
