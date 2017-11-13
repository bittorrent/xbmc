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
	inetc::post '{"ostype": "windows", "osv": "$OSV", "v": "${VERSION}.${BUILD_NUMBER}", "l": "$LANG", "cl": "${PRODUCT_NAME}","eventName": "${EVENT_NAME}", "action": "installer.${BUILD_NUMBER}.${event}.${status}", "installerRunID": "$INSTALL_GUID"}' /SILENT ${BENCH_URL} "$TEMP\utweb_install.log"
!macroend

!macro BenchPingSave status
	Push $0
	Push $1
	Push $2
	Push $3

	StrCpy $1 $_BenchString

	${If} $_BenchStringCount > 0
		StrCpy $2 ',"${status}"'
	${Else}
		StrCpy $2 '"${status}"'
	${EndIf}

	StrCpy $1 "$1$2"
	StrCpy $_BenchString $1
	IntOp $_BenchStringCount $_BenchStringCount + 1

	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

!macro BenchPingFlush event
	inetc::post '{"ostype": "windows", "osv": "$OSV", "v": "${VERSION}.${BUILD_NUMBER}", "l": "$LANG", "cl": "${PRODUCT_NAME}","eventName": "${EVENT_NAME}", "action": "status.${BUILD_NUMBER}.${event}", "status": [$_BenchString], "installerRunID": "$INSTALL_GUID"}' /SILENT ${BENCH_URL} "$TEMP\utweb_install.log"
!macroend
