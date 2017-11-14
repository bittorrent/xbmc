Var _BenchString
Var _BenchStringCount

!macro initBenchPing
	!insertmacro _initBenchPing
	; Generate GUID for this install session
	${CreateGUID} $INSTALL_GUID
!macroend

!macro _initBenchPing
	StrCpy $_BenchStringCount 0
	${If} ${IsWin7}
		StrCpy $OSV "6.1" ;"Win7"
	${ElseIf} ${IsWin8}
		StrCpy $OSV "6.2" ;"Win8"
	${ElseIf} ${IsWin8.1}
		StrCpy $OSV "6.3" ;"Win8.1"
	${ElseIf} ${IsWin10}
		StrCpy $OSV "10.0" ;"Win10"
	${Else}
		StrCpy $OSV "6.x" ;"Win Unknown"
	${EndIf}

	System::Alloc "${NSIS_MAX_STRLEN}"
	Pop $0
	System::Call "Kernel32::GetSystemDefaultLocaleName(t,i)i(.r0,${NSIS_MAX_STRLEN})i"
	StrCpy $LANG $0
!macroend

!macro BenchPing event status
	inetc::post '{"ostype": "windows", "osv": "$OSV", "v": "${VERSION_NUMBER}.${BUILD_NUMBER}", "l": "$LANG", "cl": "${APP_NAME}","eventName": "${APP_NAME}", "action": "installer.${BUILD_NUMBER}.${event}.${status}", "installerRunID": "$INSTALL_GUID"}' /SILENT ${BENCH_URL} /END
	Pop $0
  ; MessageBox MB_OK|MB_ICONEXCLAMATION 'DEBUG: http result: $0 for ${BENCH_URL} ostype:windows osv:$OSV v:${VERSION_NUMBER}.${BUILD_NUMBER} l:$LANG cl:${APP_NAME} eventName:${APP_NAME} action: installer.${BUILD_NUMBER}.${event}.${status}' /SD IDOK
!macroend
