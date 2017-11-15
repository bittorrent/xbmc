!define CreateGUID `!insertmacro _CreateGUID`

!macro _CreateGUID _RetVar
	System::Call 'ole32::CoCreateGuid(g .s)'
	!if ${_RetVar} != s
		Pop ${_RetVar}
	!endif
!macroend
