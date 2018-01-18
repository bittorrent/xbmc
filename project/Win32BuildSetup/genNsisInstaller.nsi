;Application for Windows install script

# Dependency Requirements
# NSIS 3.0: http://nsis.sourceforge.net/Download
# Inetc: http://nsis.sourceforge.net/Inetc_plug-in
# nsisFirewall 1.2: http://wiz0u.free.fr/prog/nsisFirewall/
# UAC: http://nsis.sourceforge.net/UAC_plug-in

# Required compile time defines
# COMPANY_NAME
# APP_NAME
# VERSION_NUMBER
# BUILD_NUMBER

;--------------------------------
;Include Modern UI

!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"
!include "WinVer.nsh"

;--------------------------------
;Include custom functions

!include "UAC.nsh"
!include bench.nsh
!include create_guid.nsh

;--------------------------------
;Global vars for bench
Var /GLOBAL OSV
Var /GLOBAL LANG
Var /GLOBAL INSTALL_GUID 

;--------------------------------
;Global force install vars
Var /GLOBAL SILENT_AND_FORCEINSTALL
Var /GLOBAL FORCEINSTALL_ADD_START_MENU_LINK
Var /GLOBAL FORCEINSTALL_ADD_DESKTOP_LINK
Var /GLOBAL FORCEINSTALL_ADD_QUICKLAUNCH_LINK
Var /GLOBAL FORCEINSTALL_CREATE_UNINSTALLER_SETTINGS
Var /GLOBAL FORCEINSTALL_RUN_ON_SYSTEM_STARTUP
Var /GLOBAL FORCEINSTALL_ADD_FIREWALL_RULES

;--------------------------------
; Bittorrent Installer Args
; Installer Arg Definition: https://docs.google.com/document/d/1UYPz7L6tEZAU26EH47WzaXEgZfBv_PFQFFuNhDPPNOk/edit?ts=5a32b91c
Var /GLOBAL BITTORRENT_ARGS_NO_SHORTCUTS
Var /GLOBAL BITTORRENT_ARGS_SHORTCUTS
Var /GLOBAL BITTORRENT_INSTALLER_ARGS

; This is required by the UAC plugin
RequestExecutionLevel user

;--------------------------------
;General

  ;Name and file
  Name "${APP_NAME}"
  OutFile "${APP_NAME}Setup-${app_revision}-${app_branch}-x86.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\${COMPANY_NAME}\${APP_NAME}"

  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\${APP_NAME}" ""

  InstProgressFlags smooth

  ; Installer file properties
  VIProductVersion                   ${VERSION_NUMBER}
  VIAddVersionKey "ProductName"      "${APP_NAME}"
  VIAddVersionKey "Comments"         "This application and its source code are freely distributable."
  VIAddVersionKey "LegalCopyright"   "The trademark is owned by ${COMPANY_NAME}"
  VIAddVersionKey "CompanyName"      "${COMPANY_NAME}"
  VIAddVersionKey "FileDescription"  "${APP_NAME} ${VERSION_NUMBER} Setup"
  VIAddVersionKey "FileVersion"      "${VERSION_NUMBER}"
  VIAddVersionKey "ProductVersion"   "${VERSION_NUMBER}"
  VIAddVersionKey "LegalTrademarks"  "${APP_NAME}"
  ;VIAddVersionKey "OriginalFilename" "${APP_NAME}Setup-${app_revision}-${app_branch}.exe"

;--------------------------------
;Variables

  Var StartMenuFolder
  Var PageProfileState
  Var VSRedistSetupError
  Var /GLOBAL CleanDestDir

  !define BENCH_URL "http://i-5500.b-${BUILD_NUMBER}.${APP_NAME}.bench.utorrent.com/e?i=5500"

  !define ICON "..\..\tools\windows\packaging\media\application.ico"

;--------------------------------
;Interface Settings

  !define MUI_HEADERIMAGE
  !define MUI_ICON "${ICON}"
  !define MUI_UNICON "${ICON}"
  !define MUI_HEADERIMAGE_BITMAP "..\..\tools\windows\packaging\media\installer\header.bmp"
  !define MUI_HEADERIMAGE_UNBITMAP "..\..\tools\windows\packaging\media\installer\header.bmp"
  !define MUI_WELCOMEFINISHPAGE_BITMAP "..\..\tools\windows\packaging\media\installer\welcome-left.bmp"
  !define MUI_UNWELCOMEFINISHPAGE_BITMAP "..\..\tools\windows\packaging\media\installer\welcome-left.bmp"
  !define MUI_FINISHPAGE_LINK "Please visit ${WEBSITE} for more information."
  !define MUI_FINISHPAGE_LINK_LOCATION "${WEBSITE}"
  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_TEXT "Start Play and BitTorrent"
  !define MUI_FINISHPAGE_RUN_FUNCTION "RunApplication"
  !define MUI_ABORTWARNING
;--------------------------------
;Pages

  !insertmacro MUI_PAGE_WELCOME
  !define MUI_PAGE_CUSTOMFUNCTION_LEAVE CallbackDirLeave
  !insertmacro MUI_PAGE_LICENSE "..\..\BitTorrent-License.txt"

  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU"
  !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\${APP_NAME}"
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
  !insertmacro MUI_PAGE_STARTMENU 0 $StartMenuFolder

  !define MUI_PAGE_CUSTOMFUNCTION_PRE leftStartMenuPage
  !define MUI_PAGE_CUSTOMFUNCTION_LEAVE onError
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH
  !define MUI_CUSTOMFUNCTION_ABORT muiOnUserAbort

  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  UninstPage custom un.UnPageProfile un.UnPageProfileLeave
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH
  !define MUI_CUSTOMFUNCTION_UNABORT un.muiOnUserAbortUninstall

;--------------------------------
;Languages

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
;HelperFunction

Function RunApplication
  ; Run app with the calculated flags
  ; DEV Note: Add extra startup flags here by
  ; concatenating onto $2
  StrCpy $1 "${APP_NAME}.exe"
  StrCpy $2 ""

  !insertmacro BenchPing "install" "RunApplication"

  ; Runs the Play.exe
  !insertmacro UAC_AsUser_ExecShell "" "$1" "$2" "$INSTDIR" "SW_SHOWMINIMIZED"

  ; Runs the Bittorrent.exe via the Desktop shortcut which is always set via this installer's force installer args when bittorrent is installed.

  IfFileExists "$APPDATA\BitTorrent\BitTorrent.exe" 0 LaunchBittorrentFromProgramFiles
    !insertmacro UAC_AsUser_ExecShell "" "BitTorrent.exe" "" "$APPDATA\BitTorrent" "SW_SHOWMINIMIZED"
    LogEx::Write "Launched BitTorrent from app data."
    Goto Launched

  LaunchBittorrentFromProgramFiles:
    IfFileExists "$PROGRAMFILES\BitTorrent\BitTorrent.exe" 0 LaunchBittorrentFromProgramFiles64
      !insertmacro UAC_AsUser_ExecShell "" "BitTorrent.exe" "" "$PROGRAMFILES\BitTorrent" "SW_SHOWMINIMIZED"
    LogEx::Write "Launched BitTorrent from app program files (x86)."
    Goto Launched

  LaunchBittorrentFromProgramFiles64:
    IfFileExists "$PROGRAMFILES64\BitTorrent\BitTorrent.exe" 0 Launched
      !insertmacro UAC_AsUser_ExecShell "" "BitTorrent.exe" "" "$PROGRAMFILES64\BitTorrent" "SW_SHOWMINIMIZED"
    LogEx::Write "Launched BitTorrent from app program files (64)."
    Goto Launched

  Launched:
    LogEx::Write "Finished attempting launch of the Play and Bittorrent apps."
FunctionEnd

Function CallbackDirLeave
  ;deinstall Play if it is already there in destination folder
  Call HandlePlayInDestDir
FunctionEnd

Function HandleOldPlayInstallation
  Var /GLOBAL INSTDIR_PLAY
  ReadRegStr $INSTDIR_PLAY HKCU "Software\${APP_NAME}" ""

  ;if former Play installation was detected in a different directory then the destination dir
  ;ask for uninstallation
  ;only ask about the other installation if user didn't already
  ;decide to not overwrite the installation in his originally selected destination dir
  ${IfNot}    $CleanDestDir == "0"
  ${AndIfNot} $INSTDIR_PLAY == ""
  ${AndIfNot} $INSTDIR_PLAY == $INSTDIR
    MessageBox MB_YESNO|MB_ICONQUESTION  "A previous ${APP_NAME} installation in a different folder was detected. Would you like to uninstall it?$\nYour current settings and library data will be kept intact." IDYES true IDNO false
    true:
      DetailPrint "Uninstalling $INSTDIR_PLAY"
      SetDetailsPrint none
      ExecWait '"$INSTDIR_PLAY\uninstall.exe" /S _?=$INSTDIR_PLAY'
      SetDetailsPrint both
      ;this also removes the uninstall.exe which doesn't remove it self...
      Delete "$INSTDIR_PLAY\uninstall.exe"
      ;if the directory is now empty we can safely remove it (rmdir won't remove non-empty dirs!)
      RmDir "$INSTDIR_PLAY"
    false:
  ${EndIf}
FunctionEnd

Function HandlePlayInDestDir
  ;if former Play installation was detected in the destination directory - uninstall it first
  ${IfNot} $INSTDIR == ""
  ${AndIf} ${FileExists} "$INSTDIR\uninstall.exe"
    MessageBox MB_YESNO|MB_ICONQUESTION  "A previous installation was detected in the selected destination folder. Do you really want to overwrite it?$\nYour settings and library data will be kept intact." IDYES true IDNO false
    true:
      StrCpy $CleanDestDir "1"
      Goto done
    false:
      StrCpy $CleanDestDir "0"
      Abort
    done:
  ${EndIf}
FunctionEnd

Function DeinstallPlayInDestDir
  ${If} $CleanDestDir == "1"
    DetailPrint "Uninstalling former ${APP_NAME} Installation in $INSTDIR"
    SetDetailsPrint none
    ExecWait '"$INSTDIR\uninstall.exe" /S _?=$INSTDIR'
    SetDetailsPrint both
    ;this also removes the uninstall.exe which doesn't remove it self...
    Delete "$INSTDIR\uninstall.exe"
  ${EndIf}
FunctionEnd

Function onError
  ${If} ${Abort}
  !insertmacro BenchPing "install" "fail"
  ${EndIf}
FunctionEnd

Function leftStartMenuPage

  ; check the StartMenuFolder and if it begins with "<" then that means the
  ; user selected 'no shortcuts'
  Var /GLOBAL ShortcutCheckboxState
  StrCpy $ShortcutCheckboxState "$StartMenuFolder" 1

  ; Set the Bittorrent Installer Args to install shortcuts
  ${If} $ShortcutCheckboxState == ">"
    StrCpy $BITTORRENT_INSTALLER_ARGS "$BITTORRENT_ARGS_NO_SHORTCUTS"
  ${Else}
    StrCpy $BITTORRENT_INSTALLER_ARGS "$BITTORRENT_ARGS_SHORTCUTS"
  ${EndIf}

FunctionEnd

;--------------------------------
;Installer Sections

; These are the programs that are needed by Play.
Section -Prerequisites

  SetOutPath $INSTDIR\Prerequisites
  File /nonfatal /r "${app_root}\application\Prerequisites\*.*"

  !define BONJOUR "$INSTDIR\Prerequisites\Bonjour64.msi"
  !define BITTORRENT "$INSTDIR\Prerequisites\BitTorrent.exe"

  IfFileExists "${BONJOUR}" 0 +2
    ExecWait '"msiexec" /i "${BONJOUR}" /quiet'

  IfFileExists "${BITTORRENT}" 0 +2
	ClearErrors
    Exec '"${BITTORRENT}" /S /FORCEINSTALL $BITTORRENT_INSTALLER_ARGS'
	IfErrors 0 +2
		DetailPrint "Error installing bittorrent."

SectionEnd

Section -StartMenu
  !insertmacro MUI_STARTMENU_WRITE_BEGIN 0 ;This macro sets $SMDir and skips to MUI_STARTMENU_WRITE_END if the "Don't create shortcuts" checkbox is checked...
  SetOutPath "$INSTDIR"

  ; Create Shortcuts

  ${If} $SILENT_AND_FORCEINSTALL = 1 
    ${If} $FORCEINSTALL_ADD_START_MENU_LINK = 1
      LogEx::Write "Adding start menu link under silent force install"
      CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
      CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" \
         "" "$INSTDIR\${APP_NAME}.exe" 0 SW_SHOWNORMAL \
         "" "Start ${APP_NAME}."

      CreateShortCut "$SMPROGRAMS\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" \
         "" "$INSTDIR\${APP_NAME}.exe" 0 SW_SHOWNORMAL \
         "" "Start ${APP_NAME}."
    ${EndIf}
  ${Else}
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" \
       "" "$INSTDIR\${APP_NAME}.exe" 0 SW_SHOWNORMAL \
       "" "Start ${APP_NAME}."
   CreateShortCut "$SMPROGRAMS\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" \
       "" "$INSTDIR\${APP_NAME}.exe" 0 SW_SHOWNORMAL \
       "" "Start ${APP_NAME}."
  ${EndIf}


  ${If} $SILENT_AND_FORCEINSTALL = 1 
    ${If} $FORCEINSTALL_CREATE_UNINSTALLER_SETTINGS = 1
      ${AndIf} $FORCEINSTALL_ADD_START_MENU_LINK = 1
        LogEx::Write "Adding uninstaller link in start menu under silent force install"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall ${APP_NAME}.lnk" "$INSTDIR\Uninstall.exe" \
           "" "$INSTDIR\Uninstall.exe" 0 SW_SHOWNORMAL \
           "" "Uninstall ${APP_NAME}."
    ${EndIf}
  ${Else}
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall ${APP_NAME}.lnk" "$INSTDIR\Uninstall.exe" \
       "" "$INSTDIR\Uninstall.exe" 0 SW_SHOWNORMAL \
       "" "Uninstall ${APP_NAME}."
  ${EndIf}

  ${If} $SILENT_AND_FORCEINSTALL = 1 
    ${If} $FORCEINSTALL_ADD_QUICKLAUNCH_LINK = 1
      LogEx::Write "Adding quick launch link under silent force install"
      CreateShortCut "$QUICKLAUNCH\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" \
         "" "$INSTDIR\${APP_NAME}.exe" 0 SW_SHOWNORMAL \
         "" "Start ${APP_NAME}."
    ${EndIf}
  ${Else}
    CreateShortCut "$QUICKLAUNCH\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" \
       "" "$INSTDIR\${APP_NAME}.exe" 0 SW_SHOWNORMAL \
       "" "Start ${APP_NAME}."
  ${EndIf}

  ; Desktop Shortcut
  ${If} $SILENT_AND_FORCEINSTALL = 1 
    ${If} $FORCEINSTALL_ADD_DESKTOP_LINK = 1
      LogEx::Write "Adding desktop shortcut under silent force install"
      File "${ICON}"
      createShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" "" "$INSTDIR\application.ico"
    ${EndIf}
  ${Else}
    File "${ICON}"
    createShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" "" "$INSTDIR\application.ico"
  ${EndIf}


  ; Start play at startup
  ${If} $SILENT_AND_FORCEINSTALL = 1 
    ${If} $FORCEINSTALL_RUN_ON_SYSTEM_STARTUP = 1
      LogEx::Write "Adding play to system startup folder under force install"
      CreateShortCut "$SMSSTARTUP\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" \
         "" "$INSTDIR\${APP_NAME}.exe" 0 SW_SHOWNORMAL \
         "" "Start ${APP_NAME}."
    ${EndIf}
  ${EndIf}
  
  ; Set the Bittorrent Installer Args to install shortcuts
  ${If} $SILENT_AND_FORCEINSTALL = 0
    ; only set the bittorrent installer args like this if we are NOT in a silent install.
    StrCpy $BITTORRENT_INSTALLER_ARGS "$BITTORRENT_ARGS_SHORTCUTS"
  ${EndIf}


  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

Section "${APP_NAME}" SecAPP

  SectionIn RO

  ;deinstall Play in destination dir if $CleanDestDir == "1" - meaning user has confirmed it
  Call DeinstallPlayInDestDir

  ;Start copying files
  SetOutPath "$INSTDIR"
  File "${app_root}\application\*.*"
  SetOutPath "$INSTDIR\addons"
  File /r "${app_root}\application\addons\*.*"
  File /nonfatal /r "${app_root}\addons\peripheral.*"
  SetOutPath "$INSTDIR\media"
  File /r "${app_root}\application\media\*.*"
  SetOutPath "$INSTDIR\system"
  File /r "${app_root}\application\system\*.*"
  SetOutPath "$INSTDIR\userdata"
  File /r "${app_root}\application\userdata\*.*"

  ;Store installation folder
  WriteRegStr HKCU "Software\${APP_NAME}" "" $INSTDIR

  ;Create uninstaller
  ${If} $SILENT_AND_FORCEINSTALL = 1 
    ${If} $FORCEINSTALL_CREATE_UNINSTALLER_SETTINGS = 1
      LogEx::Write "Adding uninstaller under silent force install"
      SetOutPath "$INSTDIR"
      WriteUninstaller "$INSTDIR\Uninstall.exe"
      ;add entry to add/remove programs
      WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "DisplayName" "${APP_NAME}"
      WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "UninstallString" "$INSTDIR\uninstall.exe"
      WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "NoModify" 1
      WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "NoRepair" 1
      WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "InstallLocation" "$INSTDIR"
      WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "DisplayIcon" "$INSTDIR\${APP_NAME}.exe,0"
      WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "Publisher" "${COMPANY_NAME}"
      WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "HelpLink" "${WEBSITE}"
      WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "URLInfoAbout" "${WEBSITE}"
    ${EndIf}
  ${Else}
    SetOutPath "$INSTDIR"
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    ;add entry to add/remove programs
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                   "DisplayName" "${APP_NAME}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                   "UninstallString" "$INSTDIR\uninstall.exe"
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                   "NoModify" 1
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                   "NoRepair" 1
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                   "InstallLocation" "$INSTDIR"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                   "DisplayIcon" "$INSTDIR\${APP_NAME}.exe,0"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                   "Publisher" "${COMPANY_NAME}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                   "HelpLink" "${WEBSITE}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                   "URLInfoAbout" "${WEBSITE}"
  ${EndIf}

  
  ;create firewall exceptions for app and script.bt.transcode addon ffmpeg
  ${If} $SILENT_AND_FORCEINSTALL = 1 
    ${If} $FORCEINSTALL_ADD_FIREWALL_RULES = 1
      LogEx::Write "Adding firewall rules under silent force install"
      nsisFirewall::AddAuthorizedApplication "$INSTDIR\${APP_NAME}.exe" "${APP_NAME}"
      Pop $0
      nsisFirewall::AddAuthorizedApplication "$INSTDIR\addons\script.bt.transcode\exec\ffmpeg.exe" "ffmpeg.exe"
      Pop $0
    ${EndIf}
  ${Else}
    nsisFirewall::AddAuthorizedApplication "$INSTDIR\${APP_NAME}.exe" "${APP_NAME}"
    Pop $0
    nsisFirewall::AddAuthorizedApplication "$INSTDIR\addons\script.bt.transcode\exec\ffmpeg.exe" "ffmpeg.exe"
    Pop $0
  ${EndIf}

  ;vs redist installer Section
  SetOutPath "$TEMP\vc2015"

  File "${app_root}\..\dependencies\vcredist\2015\vcredist_x86.exe"
  ExecWait '"$TEMP\vc2015\vcredist_x86.exe" /install /quiet /norestart' $VSRedistSetupError
  RMDir /r "$TEMP\vc2015"
  DetailPrint "Finished VS2015 re-distributable setup"

SectionEnd

;--------------------------------
;Uninstaller Section

Var UnPageProfileDialog
Var UnPageProfileCheckbox
Var UnPageProfileCheckbox_State
Var UnPageProfileEditBox

Function un.UnPageProfile
    !insertmacro MUI_HEADER_TEXT "Uninstall ${APP_NAME}" "Remove ${APP_NAME}'s profile folder from your computer."
  nsDialogs::Create /NOUNLOAD 1018
  Pop $UnPageProfileDialog

  ${If} $UnPageProfileDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 12u "Do you want to delete the profile folder which contains your ${APP_NAME} settings and library data?"
  Pop $0

  ${NSD_CreateText} 0 13u 100% 12u "$APPDATA\${APP_NAME}\"
  Pop $UnPageProfileEditBox
    SendMessage $UnPageProfileEditBox ${EM_SETREADONLY} 1 0

  ${NSD_CreateLabel} 0 30u 100% 24u "Leave the option box below unchecked to keep the profile folder which contains ${APP_NAME}'s settings and library data for later use. If you are sure you want to delete the profile folder you may check the option box.$\nWARNING: Deletion of the profile folder cannot be undone and you will lose all settings and library data."
  Pop $0

  ${NSD_CreateCheckbox} 0 71u 100% 8u "Yes, I am sure and grant permission to also delete the profile folder."
  Pop $UnPageProfileCheckbox

  nsDialogs::Show
FunctionEnd

Function un.UnPageProfileLeave
${NSD_GetState} $UnPageProfileCheckbox $UnPageProfileCheckbox_State
FunctionEnd

Section "Uninstall"
  SetOutPath $TEMP

  ;ADD YOUR OWN FILES HERE...
  RMDir /r "$INSTDIR\addons"
  RMDir /r "$INSTDIR\language"
  RMDir /r "$INSTDIR\media"
  RMDir /r "$INSTDIR\system"
  RMDir /r "$INSTDIR\userdata"
  RMDir /r "$INSTDIR\Prerequisites"
  RMDir /r "$INSTDIR\updates"
  Delete "$INSTDIR\*.*"

  ;Un-install User Data if option is checked, otherwise skip
  ${If} $UnPageProfileCheckbox_State == ${BST_CHECKED}
    RMDir /r "$APPDATA\${APP_NAME}\"
    RMDir /r "$INSTDIR\portable_data\"
  ${EndIf}

  ;Remove the installation dir for Play and the parent dir if needed
  RMDir "$INSTDIR"
  RMDir "$PROGRAMFILES\${COMPANY_NAME}"

  Delete "$DESKTOP\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}.lnk"
  Delete "$SMSTARTUP\${APP_NAME}.lnk"

  !insertmacro MUI_STARTMENU_GETFOLDER 0 $StartMenuFolder
  Delete "$SMPROGRAMS\$StartMenuFolder\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall ${APP_NAME}.lnk"
  RMDir "$SMPROGRAMS\$StartMenuFolder"

  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
  DeleteRegKey /ifempty HKCU "Software\${APP_NAME}"

  ;remove firewall exceptions for app and script.bt.transcode addon ffmpeg
  nsisFirewall::RemoveAuthorizedApplication "$INSTDIR\${APP_NAME}.exe"
  nsisFirewall::RemoveAuthorizedApplication "$INSTDIR\addons\script.bt.transcode\exec\ffmpeg.exe"
  Pop $0

SectionEnd

; Abort handlers
;-------------------
Function muiOnUserAbort
  !insertmacro BenchPing "install" "cancel"
FunctionEnd

Function un.muiOnUserAbortUninstall
  !insertmacro BenchPing "uninstall" "cancel"
FunctionEnd

; Install/Uninstall success handlers
;-------------------

Function .onInstSuccess
  ${If} $SILENT_AND_FORCEINSTALL = 1
    Call RunApplication
  ${EndIf}

  LogEx::Write "Installer Succeeded"
  LogEx::Close

  ;save the uuid
  FileOpen $4 "$INSTDIR\uuid.txt" w
  FileWrite $4 $INSTALL_GUID
  FileClose $4

  RMDir /r "$INSTDIR\Prerequisites"

  !insertmacro BenchPing "install" "success"
FunctionEnd

Function un.onUninstSuccess
  !insertmacro BenchPing "uninstall" "success"
FunctionEnd

!macro CMDPAR Tag OutVar
	Push ${TAG}
	Call GetParameters
	Pop ${OutVar}
!macroend
 
!define CMDPAR "!insertmacro CMDPAR"

Function .onInit
  SetOutPath "$INSTDIR"
  LogEx::Init true "$INSTDIR\install.log"
  LogEx::Write "Installer entered onInit"

  ; Initialize bench ping system variables (installer)
  !insertmacro initBenchPing

  Var /GLOBAL FORCEINSTALL_BIN_STRING
  StrCpy $SILENT_AND_FORCEINSTALL 0

  LogEx::Write "Bench initialized"
  
  ${If} ${Silent}
    LogEx::Write "Installer is running in silent mode"
    ; First check if forceinstall was set, if not bail out. 
    ; Set forceinstall vars if they exist and if silent install
    ${CMDPAR} "/FORCEINSTALL" $FORCEINSTALL_BIN_STRING
    
    LogEx::Write "FORCEINSTALL ARG: $FORCEINSTALL_BIN_STRING"

    ${IfNot} $FORCEINSTALL_BIN_STRING == ""
	Push $FORCEINSTALL_BIN_STRING
	Call validateAndApplyForceInstallOptions
    ${EndIf}
  ${EndIf}

  ${If} $SILENT_AND_FORCEINSTALL = 0
    ; Initialize bittorrent installer args
    ; Installer Arg Definition: https://docs.google.com/document/d/1UYPz7L6tEZAU26EH47WzaXEgZfBv_PFQFFuNhDPPNOk/edit?ts=5a32b91c
    StrCpy $BITTORRENT_ARGS_NO_SHORTCUTS "1110010101111000"
    StrCpy $BITTORRENT_ARGS_SHORTCUTS "1110010101111110"
    StrCpy $BITTORRENT_INSTALLER_ARGS $BITTORRENT_ARGS_NO_SHORTCUTS ; No start menu and no desktop shortcuts
  ${EndIf}

  LogEx::Write "About to elevate and start the install." 

  !insertmacro BenchPing "install" "start"

  ; Elevate with the UAC plugin. Code below derived from:
  ; http://nsis.sourceforge.net/UAC_plug-in
  ; The switch below is necessary to handle elevation failures
  ; and secondary process termination on successes (and failures)
  uac_tryagain:
  !insertmacro UAC_RunElevated
  ${Switch} $0
  ${Case} 0
  ${IfThen} $1 = 1 ${|} Quit ${|} ;we are the outer process, the inner process has done its work, we are done
  ${IfThen} $3 <> 0 ${|} ${Break} ${|} ;we are admin, let the show go on
  ${If} $1 = 3 ;RunAs completed successfully, but with a non-admin user
  MessageBox mb_YesNo|mb_IconExclamation|mb_TopMost|mb_SetForeground "Installing ${APP_NAME} requires admin privileges, please try again" /SD IDNO IDYES uac_tryagain IDNO 0
  ${EndIf}
  ;fall-through and die
  ${Case} 1223
  MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "Installing ${APP_NAME} requires admin privileges, aborting!"
    !insertmacro BenchPing "install" "error_elevation_noadmin"
  Quit
  ${Case} 1062
  MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "Logon service not running, aborting!"
    !insertmacro BenchPing "install" "error_elevation_nologon"
  Quit
  ${Default}
  MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "Unable to elevate, error $0"
    !insertmacro BenchPing "install" "error_elevation_abort"
  Quit
  ${EndSwitch}

  ; Win7 SP1 is minimum requirement
  ; Note that BitTorrent does not require SP1 so if this installer chain installs
  ; BitTorrent then we will lose those users
  ${IfNot} ${AtLeastWin7}
  ${AndIfNot} ${AtLeastServicePack} 1
    !insertmacro BenchPing "install" "notAtLeastWin7SP1"
    MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Windows 7 SP1 or above required.$\nInstall Service Pack 1 for Windows 7 and run setup again."
    Quit
  ${EndIf}

  Var /GLOBAL HotFixID
  ${If} ${IsWin7}
    StrCpy $HotFixID "2670838" ; Platform Update for Windows 7 SP1
  ${ElseIf} ${IsWin8}
    StrCpy $HotFixID "2999226" ; Platform Update for Windows 8
  ${Else}
    StrCpy $HotFixID ""
  ${Endif}
  ${If} $HotFixID != ""
    nsExec::ExecToStack 'cmd /Q /C "%SYSTEMROOT%\System32\wbem\wmic.exe /?"'
    Pop $0 ; return value (it always 0 even if an error occured)
    Pop $1 ; command output
    ${If} $0 != 0
    ${OrIf} $1 == ""
      MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Unable to run the Windows program wmic.exe to verify that Windows Update KB$HotFixID is installed.$\nWmic is not installed correctly.$\nPlease fix this issue and try again to install Play."
      Quit
    ${EndIf}
    nsExec::ExecToStack 'cmd /Q /C "%SYSTEMROOT%\System32\findstr.exe /?"'
    Pop $0 ; return value (it always 0 even if an error occured)
    Pop $1 ; command output
    ${If} $0 != 0
    ${OrIf} $1 == ""
      MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Unable to run the Windows program findstr.exe to verify that Windows Update KB$HotFixID is installed.$\nFindstr is not installed correctly.$\nPlease fix this issue and try again to install Play."
      Quit
    ${EndIf}
    nsExec::ExecToStack 'cmd /Q /C "%SYSTEMROOT%\System32\wbem\wmic.exe qfe get hotfixid | %SYSTEMROOT%\System32\findstr.exe "^KB$HotFixID[^0-9]""'
    Pop $0 ; return value (it always 0 even if an error occured)
    Pop $1 ; command output
    ${If} $0 != 0
    ${OrIf} $1 == ""
      MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Platform Update for Windows (KB$HotFixID) is required.$\nDownload and install Platform Update for Windows then run setup again."
      ExecShell "open" "http://support.microsoft.com/kb/$HotFixID"
      Quit
    ${EndIf}
    SetOutPath "$INSTDIR"
  ${EndIf}
  StrCpy $CleanDestDir "-1"
FunctionEnd

Function un.onInit
  ; Initialize bench ping system variables (uninstaller)
  !insertmacro initBenchPing

  !insertmacro BenchPing "uninstall" "start"

  ; Elevate with the UAC plugin. Code below derived from:
  ; http://nsis.sourceforge.net/UAC_plug-in
  ; The switch below is necessary to handle elevation failures
  ; and secondary process termination on successes (and failures)
  uac_tryagain_u:
  !insertmacro UAC_RunElevated
  ${Switch} $0
  ${Case} 0
  ${IfThen} $1 = 1 ${|} Quit ${|} ;we are the outer process, the inner process has done its work, we are done
  ${IfThen} $3 <> 0 ${|} ${Break} ${|} ;we are admin, let the show go on
  ${If} $1 = 3 ;RunAs completed successfully, but with a non-admin user
  MessageBox mb_YesNo|mb_IconExclamation|mb_TopMost|mb_SetForeground "Uninstalling ${APP_NAME} requires admin privileges, please try again" /SD IDNO IDYES uac_tryagain_u IDNO 0
  ${EndIf}
  ;fall-through and die
  ${Case} 1223
  MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "Uninstalling ${APP_NAME} requires admin privileges, aborting!"
    !insertmacro BenchPing "uninstall" "error_elevation_noadmin"
  Quit
  ${Case} 1062
  MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "Logon service not running, aborting!"
    !insertmacro BenchPing "uninstall" "error_elevation_nologon"
  Quit
  ${Default}
  MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "Unable to elevate, error $0"
    !insertmacro BenchPing "uninstall" "error_elevation_abort"
  Quit
  ${EndSwitch}
FunctionEnd

Function validateAndApplyForceInstallOptions
  ; validates, roughly, that the force install options are valid
  ; and takes the options and first applys them to the bittorrent
  ; installer silent force install options, then parses and sets
  ; global vars for the install options for play.
  Var /GLOBAL forceInstallOptions
  Var /GLOBAL lenOfForceInstallOptions
  
  Pop $forceInstallOptions
  StrLen $lenOfForceInstallOptions $forceInstallOptions

  StrCpy $BITTORRENT_INSTALLER_ARGS $forceInstallOptions

  LogEx::Write "Validating and setting install options."

  ${If} $lenOfForceInstallOptions = 16
    StrCpy $SILENT_AND_FORCEINSTALL 1
    Var /GLOBAL optionChar
    Var /GLOBAL i

    ${ForEach} $i 15 0 - 1
      StrCpy $optionChar "$forceInstallOptions" 1 $i

      ${Switch} $i
        ${Case} 15 ; position 1
	  ; [Placeholder, not used - set to 0]
	  ${Break}

	${Case} 14 ; position 2
	  ; Add Start Menu link (see note in “Format of the Installer UI”)
	  StrCpy $FORCEINSTALL_ADD_START_MENU_LINK "$optionChar"
	  ${Break}

	${Case} 13 ; position 3
	  ; Add Desktop shortcut (see note in “Format of the Installer UI”)
	  StrCpy $FORCEINSTALL_ADD_DESKTOP_LINK "$optionChar"
          ${Break}

	${Case} 12 ; position 4
	  ; Add QuickLaunch shortcut
	  StrCpy $FORCEINSTALL_ADD_QUICKLAUNCH_LINK "$optionChar"
          ${Break}

	${Case} 11 ; position 5
	  ; Associate .torrent file extension
	  ; This will only affect bittorrent so no need to parse and check for play
          ${Break}

	${Case} 10 ; position 6
	  ; Associate .btSearch file extension - Use default, set to 1
	  ; This will only affect bittorrent so no need to parse and check for play
          ${Break}

	${Case} 9 ; position 7
	  ; “Copy don’t move” - copy the executable to the install location instead of moving it. - Use default, set to 1 
	  ; This will only affect bittorrent so no need to parse and check for play
	  ${Break}

	${Case} 8 ; position 8
	  ; [Not used - set to 0] 
	  ${Break}

	${Case} 7 ; position 9
	  ; Create Uninstall settings - Use default, set to 1
	  StrCpy $FORCEINSTALL_CREATE_UNINSTALLER_SETTINGS "$optionChar"
	  ${Break}

	${Case} 6 ; position 10
	  ; [Not used - set to 0]
	  ${Break}

	${Case} 5 ; position 11
	  ; Configure uTorrent to run on system startup
	  StrCpy $FORCEINSTALL_RUN_ON_SYSTEM_STARTUP "$optionChar"
	  ${Break}

	${Case} 4 ; position 12
	  ; [Not used - set to 0]
	  ${Break}

	${Case} 3 ; position 13
	  ; [Not used - set to 0]
	  ${Break}

	${Case} 2 ; position 14
	  ; Add Firewall rules
	  StrCpy $FORCEINSTALL_ADD_FIREWALL_RULES "$optionChar"
	  ${Break}

	${Case} 1 ; position 15
	  ; Associate Magnet files
	  ; This will only affect bittorrent so no need to parse and check for play
	  ${Break}

	${Case} 0 ; position 16
	  ; Associate bittorrent files
	  ; This will only affect bittorrent so no need to parse and check for play
	  ${Break}
      ${EndSwitch}
    ${Next}
  ${Else}
     StrCpy $SILENT_AND_FORCEINSTALL 0
  ${EndIf}

FunctionEnd

/*
	This function will search for the requested command-line option
	and return the value.  If the value is not found, the function 
	returns an empty string.
[USAGE]
	${CMDPAR} [TAG] [Variable for result] 
		[Tag] is a unique string to identify the parameter (ie "/B=", etc.)
		[Variable for result] is the variable in which to hold the result
[RULES]
-	Each parameter value must start with the character indicated by PARAM_CHAR.
-	This function will not verify any parameter--this will be up to the script
        developer!
-	Parameters CANNOT be "nested" (a parameter within a parameter)
-	The function takes advantage of the StrCmp function, which is 
	NOT case-sensative.  (In other works "/l" and "/L" will be the same)
-	This function assumes that $CMDLINE will have a installer / setup file that ends in .exe at the beginning of the
        cmdline.
-	The return value will be trimmed automatically (no spaces at either end)	
[VARIABLES]
$0 (str):	string indicating the what the format of the command should be (example: "/B")
$1 (int): 	Pointer value indicating the current position in the search string
$2 (str): 	string value of the parameter portion of the command line
$3 (str): 	Final value of the parameter (When $3=$0, stop copying the 
                parameter to $R1)
$4 (bln): 	A 1 or 0 value indicating when to start/stop adding characters
                to the parameter result (1 means start, 0 means stop)
$5 (int):	Total Length of the $CMDLINE variable, including the parameter part
$6 (int):	Single-character string of each character in the parameter field
$R1 (str):	Value of the requested parameter value
$7 (int):	Temporary variable for holding numbers
$R2 (bool):     Test var for determining end of the .exe substring (.)
$R3 (bool):     Test var for determining end of the .exe substring (e)
$R4 (bool):     Test var for determining end of the .exe substring (x)
$R5 (bool):     Test var for determining end of the .exe substring (e)
*/
 
Function GetParameters
        LogEx::Write "In GetParameters"
	; all parameters must start with PARAM_CHAR.  (Change value as needed.)
	!define PARAM_CHAR "/"	
	Exch $0 ; $0 now contains the TAG string
	Push $R1
        Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
	Push $R2
	Push $R3
	Push $R4
	Push $R5

	StrCpy $R2 0
	StrCpy $R3 0
	StrCpy $R4 0
	StrCpy $R5 0

	StrCpy $1 0	; Initialize the pointer variable
	StrLen $5 $CMDLINE
	LogEx::Write "Finding start of params..."
	FindParam:	; Start loop to find the parameter portion of the $CMDLINE
		IntOp $1 $1 + 1
		StrCpy $6 $CMDLINE 1 $1

		${If} $1 > $5
		  LogEx::Write "Did not find the start of the parameters section, reached end of cmdline string."
		  Goto ExitFindParam
		${EndIf}

		${If} $R2 = 0
		  ${AndIf} $6 == "."
		    StrCpy $R2 1 
		    Goto FindParam
		${Else}
		  ${If} $R2 = 1
		    ${AndIf} $R3 = 0
		    ${AndIf} $6 == "e"
		      StrCpy $R3 1
		      Goto FindParam
		  ${Else}
		    ${If} $R2 = 1
		      ${AndIf} $R3 = 1
		      ${AndIf} $R4 = 0
		      ${AndIf} $6 == "x"
		        StrCpy $R4 1
		        Goto FindParam
		    ${Else}
		      ${If} $R2 = 1
		        ${AndIf} $R3 = 1
		        ${AndIf} $R4 = 1
		        ${AndIf} $R5 = 0
		        ${AndIf} $6 == "e"
			  LogEx::Write "Found .exe, exiting the find param section loop."
		          Goto ExitFindParam
		      ${EndIf}
		    ${EndIf}
		  ${EndIf}
		${EndIf}
		
		StrCpy $R2 0
		StrCpy $R3 0
		StrCpy $R4 0
		StrCpy $R5 0

		Goto FindParam
	ExitFindParam:
	IntOp $1 $1 + 2	;  Increment pointer one space to move it one character past the quotes
	IntOp $7 $5 - $1	; Difference between total string length and the length of the parameter portion
	IntCmp $7 0 ParamDone ParamDone 0	;If this value is zero, then no parameters have been defined (exit)
	;MessageBox MB_YESNO|MB_ICONQUESTION "Difference between total string length and the length of the parameter portion:  $7$\n$\r$\n$\rContinue?" IDNO ParamDone
	StrCpy $2 $CMDLINE $7 $1
	;MessageBox MB_OK "Parameter portion: [$2]"
	StrCpy $2 "X$2" ;	 Add one character to the start of the parameter string
	StrCpy $1 0	; Reset the pointer
	StrCpy $4 0	; keep characters from being copied to $R1 until we've found a match to the parameter tag
	FindParamValue:	;Start loop to find the requested parameter value
		IntOp $1 $1 + 1
		strCpy $6 $2 1 $1
		;MessageBox MB_YESNO|MB_ICONQUESTION "Character value: [$6]$\r$\n$$PARAM_CHAR: [${PARAM_CHAR}]$\r$\nContinue?" IDNO PARAMDONE
		StrCmp $6 "" ParamDone 0 ;Exit if this is the end of the parameter string
		StrCmp $6 ${PARAM_CHAR} Reset4 NoReset4	; Reset $4 if this is a new parameter
		Reset4:
		;StrCpy $R1 ""
		StrCpy $4 0
		StrCpy $3 ""
		NoReset4:
		StrCpy $3 "$3$6"
		IntCmp $4 0 NoBuildR1 BuildR1
		BuildR1:
		StrCpy $R1 "$R1$6"
		NoBuildR1:
		;MessageBox MB_YESNO|MB_ICONQUESTION "$$3: [$3]$\r$\n$$0: [$0]$\r$\n$\r$\nContinue?" IDNO PARAMDONE
		StrCmp $3 $0 0 FindParamValue
		StrCpy $4 1
 
	Goto FindParamValue
 
	ParamDone:
	;	This last part of the script will trim the spaces off either end of $R1:
	StrCpy $2 "X$R1"
	strCpy $R1 ""
	StrCpy $1 0
	KeepTrimming:
		IntOp $1 $1 + 1
		strCpy $6 $2 1 $1
		StrCmp $6 "" DoneTrimming 0
		strCmp $6 " " NoCopyCharR1 CopyCharR1
		copyCharR1:
		StrCpy $R1 "$R1$6"
		Goto KeepTrimming
		NoCopyCharR1:
		Goto KeepTrimming
	DoneTrimming:
        Pop $R5 
        Pop $R4
        Pop $R3
        Pop $R2
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
	Push $R1
	!undef PARAM_CHAR
FunctionEnd
