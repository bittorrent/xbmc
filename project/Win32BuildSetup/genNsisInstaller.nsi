;Application for Windows install script

# Requirements
# NSIS 3.0: http://nsis.sourceforge.net/Download
# Inetc: http://nsis.sourceforge.net/Inetc_plug-in
# nsisFirewall 1.2: http://wiz0u.free.fr/prog/nsisFirewall/

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
!include "TextLog.nsh"

;--------------------------------
;Include custom functions

!include bench.nsh
!include create_guid.nsh

;--------------------------------
;Global vars for bench
Var /GLOBAL OSV
Var /GLOBAL LANG
Var /GLOBAL INSTALL_GUID

;--------------------------------
;General

  ;Name and file
  Name "${APP_NAME}"
  OutFile "${APP_NAME}Setup-${app_revision}-${app_branch}-x86.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\${APP_NAME}"

  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\${APP_NAME}" ""

  ;Request application privileges for Windows Vista
  RequestExecutionLevel admin

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

  ; FIXME Debug only
  !define BENCH_URL "http://i-5500.b-${BUILD_NUMBER}.${APP_NAME}.bench.staging.utorrent.com/e?i=5500&debug=1"
  !define EVENT_NAME "installer"

;--------------------------------
;Interface Settings

  !define MUI_HEADERIMAGE
  !define MUI_ICON "..\..\tools\windows\packaging\media\application.ico"
  !define MUI_UNICON "..\..\tools\windows\packaging\media\application.ico"
  !define MUI_HEADERIMAGE_BITMAP "..\..\tools\windows\packaging\media\installer\header.bmp"
  !define MUI_HEADERIMAGE_UNBITMAP "..\..\tools\windows\packaging\media\installer\header.bmp"
  !define MUI_WELCOMEFINISHPAGE_BITMAP "..\..\tools\windows\packaging\media\installer\welcome-left.bmp"
  !define MUI_UNWELCOMEFINISHPAGE_BITMAP "..\..\tools\windows\packaging\media\installer\welcome-left.bmp"
  !define MUI_FINISHPAGE_LINK "Please visit ${WEBSITE} for more information."
  !define MUI_FINISHPAGE_LINK_LOCATION "${WEBSITE}"
  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_CHECKED
  !define MUI_FINISHPAGE_RUN_FUNCTION "LaunchLink"
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

Function LaunchLink
  ${If} ${AtLeastWin10}
    ExecShell "open" "$SMPROGRAMS\${APP_NAME}-minimized.lnk"
  ${Else}
    ExecShell "open" "$SMPROGRAMS\${APP_NAME}.lnk"
  ${EndIf}
FunctionEnd

Function CallbackDirLeave
  ;deinstall kodi if it is already there in destination folder
  Call HandleKodiInDestDir
FunctionEnd

Function HandleOldKodiInstallation
  Var /GLOBAL INSTDIR_KODI
  ReadRegStr $INSTDIR_KODI HKCU "Software\${APP_NAME}" ""

  ;if former Kodi installation was detected in a different directory then the destination dir
  ;ask for uninstallation
  ;only ask about the other installation if user didn't already
  ;decide to not overwrite the installation in his originally selected destination dir
  ${IfNot}    $CleanDestDir == "0"
  ${AndIfNot} $INSTDIR_KODI == ""
  ${AndIfNot} $INSTDIR_KODI == $INSTDIR
    MessageBox MB_YESNO|MB_ICONQUESTION  "A previous ${APP_NAME} installation in a different folder was detected. Would you like to uninstall it?$\nYour current settings and library data will be kept intact." IDYES true IDNO false
    true:
      DetailPrint "Uninstalling $INSTDIR_KODI"
      SetDetailsPrint none
      ExecWait '"$INSTDIR_KODI\uninstall.exe" /S _?=$INSTDIR_KODI'
      SetDetailsPrint both
      ;this also removes the uninstall.exe which doesn't remove it self...
      Delete "$INSTDIR_KODI\uninstall.exe"
      ;if the directory is now empty we can safely remove it (rmdir won't remove non-empty dirs!)
      RmDir "$INSTDIR_KODI"
    false:
  ${EndIf}
FunctionEnd

Function HandleKodiInDestDir
  ;if former Kodi installation was detected in the destination directory - uninstall it first
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

Function DeinstallKodiInDestDir
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

Section "${APP_NAME}" SecAPP

  SetShellVarContext all
  SectionIn RO

  ;deinstall kodi in destination dir if $CleanDestDir == "1" - meaning user has confirmed it
  Call DeinstallKodiInDestDir

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

  ;Create shortcuts
  SetOutPath "$INSTDIR"

  CreateShortCut "$SMPROGRAMS\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" \
                  "" "$INSTDIR\${APP_NAME}.exe" 0 SW_SHOWNORMAL \
                  "" "Start ${APP_NAME}."
  ${If} ${AtLeastWin10}
    CreateShortCut "$SMPROGRAMS\${APP_NAME}-minimized.lnk" "$INSTDIR\${APP_NAME}.exe" \
                    "" "$INSTDIR\${APP_NAME}.exe" 0 SW_SHOWMINIMIZED \
                    "" "Start ${APP_NAME} minimized."
  ${EndIf}

  CreateShortCut "$SMPROGRAMS\Uninstall ${APP_NAME}.lnk" "$INSTDIR\Uninstall.exe" \
                  "" "$INSTDIR\Uninstall.exe" 0 SW_SHOWNORMAL \
                  "" "Uninstall ${APP_NAME}."

  WriteINIStr "$SMPROGRAMS\Visit ${APP_NAME} Online.url" "InternetShortcut" "URL" "${WEBSITE}"

  ;create firewall exceptions for app and script.bt.transcode addon ffmpeg
  nsisFirewall::AddAuthorizedApplication "$INSTDIR\${APP_NAME}.exe" "${APP_NAME}"
  nsisFirewall::AddAuthorizedApplication "$INSTDIR\addons\script.bt.transcode\exec\ffmpeg.exe" "ffmpeg.exe"
  Pop $0

  ;vs redist installer Section
  SetOutPath "$TEMP\vc2015"
  File "${app_root}\..\dependencies\vcredist\2015\vcredist_x86.exe"
  ExecWait '"$TEMP\vc2015\vcredist_x86.exe" /install /quiet /norestart' $VSRedistSetupError
  RMDir /r "$TEMP\vc2015"
  DetailPrint "Finished VS2015 re-distributable setup"

  IfSilent "" +2 ; If the installer is always silent then you don't need this check
  Call LaunchLink

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

  SetShellVarContext all

  ;ADD YOUR OWN FILES HERE...
  RMDir /r "$INSTDIR\addons"
  RMDir /r "$INSTDIR\language"
  RMDir /r "$INSTDIR\media"
  RMDir /r "$INSTDIR\system"
  RMDir /r "$INSTDIR\userdata"
  Delete "$INSTDIR\*.*"

  ;Un-install User Data if option is checked, otherwise skip
  ${If} $UnPageProfileCheckbox_State == ${BST_CHECKED}
    SetShellVarContext current
    RMDir /r "$APPDATA\${APP_NAME}\"
    SetShellVarContext all
    RMDir /r "$INSTDIR\portable_data\"
  ${EndIf}
  RMDir "$INSTDIR"

  Delete "$SMPROGRAMS\${APP_NAME}.lnk"
  ${If} ${AtLeastWin10}
    Delete "$SMPROGRAMS\${APP_NAME}-minimized.lnk"
  ${EndIf}
  Delete "$SMPROGRAMS\Uninstall ${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\Visit ${APP_NAME} Online.url"
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
  !insertmacro BenchPing "install" "success"
FunctionEnd

Function un.onUninstSuccess
  !insertmacro BenchPing "uninstall" "success"
FunctionEnd

Function .onInit
  ; Initialize logging
  ${LogSetFileName} "$INSTDIR\MyInstallLog.txt"
  ${LogSetOn}
  ${LogText} "In .onInit"

  ; Initialize bench ping system variables (installer)
  !insertmacro initBenchPing

  ; WinVista SP2 is minimum requirement
  ${IfNot} ${AtLeastWinVista}
  ${OrIf} ${IsWinVista}
  ${AndIfNot} ${AtLeastServicePack} 2
    MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Windows Vista SP2 or above required.$\nInstall Service Pack 2 for Windows Vista and run setup again."
    Quit
  ${EndIf}
  ; Win7 SP1 is minimum requirement
  ${If} ${IsWin7}
  ${AndIfNot} ${AtLeastServicePack} 1
    MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Windows 7 SP1 or above required.$\nInstall Service Pack 1 for Windows 7 and run setup again."
    Quit
  ${EndIf}

  Var /GLOBAL HotFixID
  ${If} ${IsWinVista}
    StrCpy $HotFixID "971644" ; Platform Update for Windows Vista SP2
  ${ElseIf} ${IsWin7}
    StrCpy $HotFixID "2670838" ; Platform Update for Windows 7 SP1
  ${Else}
    StrCpy $HotFixID ""
  ${Endif}
  ${If} $HotFixID != ""
    nsExec::ExecToStack 'cmd /Q /C "%SYSTEMROOT%\System32\wbem\wmic.exe /?"'
    Pop $0 ; return value (it always 0 even if an error occured)
    Pop $1 ; command output
    ${If} $0 != 0
    ${OrIf} $1 == ""
      MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Unable to run the Windows program wmic.exe to verify that Windows Update KB$HotFixID is installed.$\nWmic is not installed correctly.$\nPlease fix this issue and try again to install Kodi."
      Quit
    ${EndIf}
    nsExec::ExecToStack 'cmd /Q /C "%SYSTEMROOT%\System32\findstr.exe /?"'
    Pop $0 ; return value (it always 0 even if an error occured)
    Pop $1 ; command output
    ${If} $0 != 0
    ${OrIf} $1 == ""
      MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Unable to run the Windows program findstr.exe to verify that Windows Update KB$HotFixID is installed.$\nFindstr is not installed correctly.$\nPlease fix this issue and try again to install Kodi."
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
