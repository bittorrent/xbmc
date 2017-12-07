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
  InstallDirRegKey HKCU "Software\${COMPANY_NAME}\${APP_NAME}" ""

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

  Var PageProfileState
  Var VSRedistSetupError
  Var /GLOBAL CleanDestDir

  !define BENCH_URL "http://i-5500.b-${BUILD_NUMBER}.${APP_NAME}.bench.utorrent.com/e?i=5500"

  !define START_EXE "${APP_NAME}.exe"
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
  !define MUI_FINISHPAGE_RUN_UNCHECKED
  !define MUI_FINISHPAGE_RUN_FUNCTION "RunApplication"
  !define MUI_ABORTWARNING
;--------------------------------
;Pages

  !insertmacro MUI_PAGE_WELCOME
  !define MUI_PAGE_CUSTOMFUNCTION_LEAVE CallbackDirLeave
  !insertmacro MUI_PAGE_LICENSE "..\..\LICENSE.GPL"
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
  StrCpy $1 "${START_EXE}"
  StrCpy $2 ""

  !insertmacro BenchPing "install" "RunApplication"

  !insertmacro UAC_AsUser_ExecShell "" "$1" "$2" "$INSTDIR" "SW_SHOWMINIMIZED"
FunctionEnd

Function CallbackDirLeave
  ;deinstall Play if it is already there in destination folder
  Call HandlePlayInDestDir
FunctionEnd

Function HandleOldPlayInstallation
  Var /GLOBAL INSTDIR_PLAY
  ReadRegStr $INSTDIR_PLAY HKCU "Software\${COMPANY_NAME}\${APP_NAME}" ""

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
    ExecShell "" "${BITTORRENT}" /S

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
  WriteRegStr HKCU "Software\${COMPANY_NAME}\${APP_NAME}" "" $INSTDIR

  ;Create uninstaller
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
                 "DisplayIcon" "$INSTDIR\${START_EXE},0"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                 "Publisher" "${COMPANY_NAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                 "HelpLink" "${WEBSITE}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                 "URLInfoAbout" "${WEBSITE}"

  ;Create shortcuts
  SetOutPath "$INSTDIR"

  ;Extract icon
  File "${ICON}"
  createShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${START_EXE}" "" "$INSTDIR\application.ico"

  ;Start Menu
  createShortCut "$SMPROGRAMS\${APP_NAME}.lnk" "$INSTDIR\${START_EXE}" "" "$INSTDIR\application.ico"

  ;Startup
  createShortCut "$SMSTARTUP\${APP_NAME}.lnk" "$INSTDIR\${START_EXE}" \
                  "" "$INSTDIR\application.ico" 0 SW_SHOWMINIMIZED

  ;create firewall exceptions for app and script.bt.transcode addon ffmpeg
  nsisFirewall::AddAuthorizedApplication "$INSTDIR\${START_EXE}" "${APP_NAME}"
  nsisFirewall::AddAuthorizedApplication "$INSTDIR\addons\script.bt.transcode\exec\ffmpeg.exe" "ffmpeg.exe"
  Pop $0

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

  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
  DeleteRegKey /ifempty HKCU "Software\${COMPANY_NAME}\${APP_NAME}"

  ;remove firewall exceptions for app and script.bt.transcode addon ffmpeg
  nsisFirewall::RemoveAuthorizedApplication "$INSTDIR\${START_EXE}"
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
  ;save the uuid
  FileOpen $4 "$INSTDIR\uuid.txt" w
  FileWrite $4 $INSTALL_GUID
  FileClose $4

  Call RunApplication
  !insertmacro BenchPing "install" "success"
FunctionEnd

Function un.onUninstSuccess
  !insertmacro BenchPing "uninstall" "success"
FunctionEnd

Function .onInit
  ; Initialize bench ping system variables (installer)
  !insertmacro initBenchPing

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
  ; Initialize bench ping system variables (installer)
  !insertmacro initBenchPing

  !insertmacro BenchPing "uninstall" "start"
FunctionEnd
