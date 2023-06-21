#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Assets\MSEdgeRedirect.ico
#AutoIt3Wrapper_Outfile=MSEdgeRedirect_x86.exe
#AutoIt3Wrapper_Outfile_x64=MSEdgeRedirect.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=https://www.msedgeredirect.com
#AutoIt3Wrapper_Res_CompanyName=Robert Maehl Software
#AutoIt3Wrapper_Res_Description=MSEdgeRedirect
#AutoIt3Wrapper_Res_Fileversion=0.7.4.0
#AutoIt3Wrapper_Res_ProductName=MSEdgeRedirect App & Service
#AutoIt3Wrapper_Res_ProductVersion=0.7.4.0
#AutoIt3Wrapper_Res_LegalCopyright=Robert Maehl, using LGPL 3 License
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Res_Compatibility=Win8,Win81,Win10
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7 -v1 -v2 -v3
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/so
#AutoIt3Wrapper_Res_Icon_Add=Assets\MSEdgeRedirect.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <Date.au3>
#include <Misc.au3>
#include <Array.au3>
#include <WinAPIHObj.au3>
#include <WinAPIProc.au3>
#include <WinAPIShPath.au3>
#include <EditConstants.au3>
#include <TrayConstants.au3>
#include <ComboConstants.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>

#include "Includes\_Logging.au3"
#include "Includes\_Theming.au3"
#include "Includes\_Security.au3"
#include "Includes\_Settings.au3"
#include "Includes\_Translation.au3"
#include "Includes\_URLModifications.au3"

#include "Includes\Base64.au3"
#include "Includes\ResourcesEx.au3"

Opt("TrayMenuMode", 3)
Opt("TrayAutoPause", 0)
Opt("GUICloseOnESC", 0)

#include "MSEdgeRedirect_Wrapper.au3"
#include "MSEdgeRedirect_Troubleshooter.au3"

SetupAppdata()
ProcessCMDLine()

Func ActiveMode(ByRef $aCMDLine)

	Local $sCMDLine = ""
	Local $sParent = _WinAPI_GetProcessName(_WinAPI_GetParentProcess())


	$aCMDLine = FixTreeIntegrity($aCMDLine)
	CheckEdgeIntegrity($aCMDLine[1])
	$aCMDLine[1] = StringReplace($aCMDLine[1], "msedge.exe", "msedge_IFEO.exe")

	Select
		Case $aCMDLine[0] = 1 ; No Parameters
			ContinueCase
		Case $aCMDLine[0] = 2 And UBound($aCMDLine) < 2
			ReDim $aCMDLine[3]
			$aCMDLine[2] = ""
			ContinueCase
		Case $aCMDLine[0] = 2 And $aCMDLine[2] = "--uninstall" ; Uninstalling Edge
			ContinueCase
		Case $aCMDLine[0] = 2 And $aCMDLine[2] = "--suspend-background-mode" ; Uninstalling Edge
			ContinueCase
		Case $aCMDLine[0] = 2 And $aCMDLine[2] = "--from-installer" ; Installing Edge
			ContinueCase
		Case $aCMDLine[0] = 2 And $aCMDLine[2] = "--inprivate" ; In Private Browsing, No Parameters
			ContinueCase
		Case _ArraySearch($aCMDLine, "--winrt-background-task-event", 2, 0, 0, 1) > 0 ; #94 & #95, Apps
			ContinueCase
		Case _ArraySearch($aCMDLine, "--web-widget-jumplist-launch", 2, 0, 0, 1) > 0 ; #123, EdgeBar
			ContinueCase
		Case _ArraySearch($aCMDLine, "--notification-launch-id", 2, 0, 0, 1) > 0 ; #225, Web App Notifications
			ContinueCase
		Case _ArraySearch($aCMDLine, "--app-id", 2, 0, 0, 1) > 0 And Not _GetSettingValue("NoApps")
			ContinueCase
		Case _ArraySearch($aCMDLine, "--remote-debugging-port=", 2, 0, 0, 1) > 0 ; #271, Debugging Apps
			ContinueCase
		Case _ArraySearch($aCMDLine, "--profile-directory=", 2, 0, 0, 1) > 0 ; #68, Multiple Profiles
			$sCMDLine = _ArrayToString($aCMDLine, " ", 2, -1)
			_SafeRun($aCMDLine[1], $sCMDLine)
		Case $sParent = "BrowserSelect.exe"
			ContinueCase
		Case $sParent = "BrowserSelector.exe"
			ContinueCase			
		Case $sParent = "Hurl.exe"
			ContinueCase
		Case $aCMDLine[0] = 2 And $aCMDLine[2] = "--continue-active-setup"
			_SafeRun($aCMDLine[1], $aCMDLine[2])
		Case _ArraySearch($aCMDLine, "localhost:", 2, 0, 0, 1) > 0 ; Improve on #162
			ContinueCase
		Case _ArraySearch($aCMDLine, "localhost/", 2, 0, 0, 1) > 0 ; Improve on #162
			ContinueCase
		Case _ArraySearch($aCMDLine, @ComputerName & ":", 2, 0, 0, 1) > 0 ; Improve on #162
			ContinueCase
		Case _ArraySearch($aCMDLine, @ComputerName & "/", 2, 0, 0, 1) > 0 ; Improve on #162
			ContinueCase
		Case _ArraySearch($aCMDLine, "127.0.0.1", 2, 0, 0, 1) > 0 ; #162
			$sCMDLine = _ArrayToString($aCMDLine, " ", 2, -1)
			FileWrite($hLogs[$URIFailures], _NowCalc() & " - Skipped Localhost URL: " & $sCMDLine & @CRLF)
		Case Else
			$sCMDLine = _ArrayToString($aCMDLine, " ", 2, -1)
			_DecodeAndRun($aCMDLine[1], $sCMDLine)
	EndSelect

EndFunc

Func CheckEdgeIntegrity($sLocation)
	If StringInStr($sLocation, "ie_to_edge_stub") Then
		;;;
	ElseIf $sLocation = "" Then
		Exit
	Else
		Select
			Case Not FileExists(StringReplace($sLocation, "\msedge.exe", "\msedge_IFEO.exe"))
				If WinExists(_Translate($aMUI[1], "Admin File Copy Required")) Then Exit ; #202
				If MsgBox($MB_YESNO + $MB_ICONINFORMATION + $MB_TOPMOST, _
					_Translate($aMUI[1], "Admin Rights Required"), _
					_Translate($aMUI[1], "The IFEO junctions for MSEdgeRedirect are missing and need to be created. Create Now?"), _
					0) = $IDYES Then ShellExecuteWait(@ScriptFullPath, "/repair", @ScriptDir, "RunAs")
				If @error Then MsgBox($MB_ICONERROR+$MB_OK, _
					"Copy Failed", _
					"Unable to create the IFEO junction without Admin Rights!")
			Case Else
				;;;
		EndSelect
	EndIf
EndFunc

Func FixTreeIntegrity($aCMDLine)

	Local $iParent = _WinAPI_GetParentProcess()

	If _WinAPI_GetProcessName($iParent) = "MSEdge.exe" Then

		FileWrite($hLogs[$AppGeneral], _NowCalc() & " - " & "Caught MSEdge Parent Process, Launched by " & _WinAPI_GetProcessName(_WinAPI_GetParentProcess($iParent)) & ", Grabbing Parameters." & @CRLF)

		Local $aAdjust

		; Enable "SeDebugPrivilege" privilege for obtain full access rights to another processes
		Local $hToken = _WinAPI_OpenProcessToken(BitOR($TOKEN_ADJUST_PRIVILEGES, $TOKEN_QUERY))

		_WinAPI_AdjustTokenPrivileges($hToken, $SE_DEBUG_NAME, $SE_PRIVILEGE_ENABLED, $aAdjust)

		Redim $aCMDLine[2]
		$aCMDLine[0] = 0
		$aCMDLine[1] = _WinAPI_GetProcessFileName($iParent)

		_ArrayConcatenate($aCMDLine, StringSplit(_WinAPI_GetProcessCommandLine($iParent), " ", $STR_NOCOUNT))

		$aCMDLine[0] = UBound($aCMDLine) - 1

		ProcessClose($iParent)

	EndIf

	Return $aCMDLine

EndFunc



Func ProcessCMDLine()

	Local $aPIDs
	Local $bHide = _GetSettingValue("NoTray")
	Local $hFile = @ScriptDir & ".\Setup.ini"
	Local $iParams = $CmdLine[0]
	Local $sCMDLine = _ArrayToString($CmdLine, " ", 1)
	Local $bSilent = False
	Local $aInstall[3]
	Local $bPortable = False

	If DriveGetType(@ScriptDir) = "Removable" Then $bPortable = True

	If $iParams > 0 Then

		$CMDLine = RepairCMDLine($CMDLine)

		If _ArraySearch($aEdges, $CMDLine[1]) > 0 Then ; Image File Execution Options Mode
			RunHTTPCheck()
			ActiveMode($CMDLine)
			If Not _GetSettingValue("NoUpdates") And Random(1, 10, 1) = 1 Then RunUpdateCheck()
			Exit
		EndIf

		Do
			Switch $CmdLine[1]
				Case "/?", "/help"
					MsgBox(0, "Help and Flags", _
							"MSEdgeRedirect" & @CRLF & _
							@CRLF & _
							@TAB & "/admin    " & @TAB & "Attempts to run MSEdgeRedirect as admin" & @CRLF & _
							@TAB & "/change   " & @TAB & "Reruns Installer" & @CRLF & _
							@TAB & "/hide     " & @TAB & "Hides the tray icon" & @CRLF & _
							@TAB & "/kill     " & @TAB & "Kills other MSEdgeRedirect processes" & @CRLF & _
							@TAB & "/portable " & @TAB & "Runs MSEdgeRedirect in portable mode" & @CRLF & _
							@TAB & "/repair   " & @TAB & "Repairs IFEO directory junctions" & @CRLF & _
							@TAB & "/settings " & @TAB & "Opens Settings Menu" & @CRLF & _
							@TAB & "/si       " & @TAB & "Runs a Silent Install" & @CRLF & _
							@TAB & "/update   " & @TAB & "Downloads the latest RELEASE (default) or DEV build" & @CRLF & _
							@TAB & "/uninstall" & @TAB & "Uninstalls MSEdgeRedirect" & @CRLF & _
							@CRLF & _
							@CRLF)
					Exit 0
				Case "/admin"
					If Not $bIsAdmin Then
						ShellExecute(@ScriptFullPath, $sCMDLine, @ScriptDir, "RunAs")
						Exit
					Else
						_ArrayDelete($CmdLine, 1)
					EndIf
				Case "/change"
					RunSetup(True, $bSilent, 1)
					Exit
				Case "/h", "/hide"
					$bHide = True
					_ArrayDelete($CmdLine, 1)
				Case "/kill"
					$aPIDs = ProcessList(@ScriptName)
					For $iLoop = 1 To $aPIDs[0][0] Step 1
						If $aPIDs[$iLoop][1] <> @AutoItPID Then ProcessClose($aPIDs[$iLoop][1])
					Next
					Exit
				Case "/p", "/portable"
					$bPortable = True
					_GetSettingValue("SetPortable")
					_ArrayDelete($CmdLine, 1)
				Case "/repair"
					RunRepair()
					Exit
				Case "/settings"
					If $bIsPriv Then
						If Not $bIsAdmin Then
							ShellExecute(@ScriptFullPath, "/settings", @ScriptDir, "RunAs")
							Exit
						EndIf
					Else
						$aPIDs = ProcessList(@ScriptName)
						For $iLoop = 1 To $aPIDs[0][0] Step 1
							If $aPIDs[$iLoop][1] <> @AutoItPID Then ProcessClose($aPIDs[$iLoop][1])
						Next
					EndIf
					RunSetup(True, False, 2)
					If Not $bIsPriv Then ShellExecute(@ScriptFullPath)
					Exit
				Case "/si", "/silentinstall"
					$bSilent = True
					Select
						Case UBound($CmdLine) = 2
							_ArrayDelete($CmdLine, 1)
						Case UBound($CmdLine) > 2 And FileExists($CmdLine[2])
							$hFile = $CmdLine[2]
							_ArrayDelete($CmdLine, "1-2")
						Case StringLeft($CmdLine[2], 1) = "/"
							_ArrayDelete($CmdLine, 1)
						Case Else
							MsgBox(0, _
								"Invalid", _
								'Invalid file - "' & $CmdLine[2] & @CRLF)
							Exit 87 ; ERROR_INVALID_PARAMETER
					EndSelect
				#cs
				Case "/u", "/update"
					Select
						Case UBound($CmdLine) = 2
							InetGet("https://fcofix.org/MSEdgeRedirect/releases/latest/download/MSEdgeRedirect.exe", @ScriptDir & "\MSEdgeRedirect_Latest.exe")
							_ArrayDelete($CmdLine, 1)
						Case UBound($CmdLine) > 2 And $CmdLine[2] = "dev"
							InetGet("https://nightly.link/rcmaehl/MSEdgeRedirect/workflows/mser/main/mser.zip", @ScriptDir & "\MSEdgeRedirect_dev.zip")
							_ArrayDelete($CmdLine, "1-2")
						Case UBound($CmdLine) > 2 And $CmdLine[2] = "release"
							InetGet("https://fcofix.org/MSEdgeRedirect/releases/latest/download/MSEdgeRedirect.exe", @ScriptDir & "\MSEdgeRedirect_Latest.exe")
							_ArrayDelete($CmdLine, "1-2")
						Case StringLeft($CmdLine[2], 1) = "/"
							InetGet("https://fcofix.org/MSEdgeRedirect/releases/latest/download/MSEdgeRedirect.exe", @ScriptDir & "\MSEdgeRedirect_Latest.exe")
							_ArrayDelete($CmdLine, 1)
						Case Else
							MsgBox(0, _
								"Invalid", _
								'Invalid release type - "' & $CmdLine[2] & "." & @CRLF)
							Exit 87 ; ERROR_INVALID_PARAMETER
					EndSelect
				#ce
				Case "/uninstall"
					RunRemoval()
					Exit
				Case "/wingetinstall"
					$bSilent = True
					$hFile = "WINGET"
					_ArrayDelete($CmdLine, 1)
				Case Else
					FileWrite($hLogs[$PEBIAT], _NowCalc() & " - " & "Unexpected Commandline: " & _ArrayToString($CmdLine) & @CRLF)
					If @Compiled Then ; support for running non-compiled script - mLipok
						MsgBox(0, _
							"Invalid", _
							'Invalid parameter - "' & $CmdLine[1] & "." & @CRLF)
						Exit 87 ; ERROR_INVALID_PARAMETER
					EndIf
			EndSwitch
		Until UBound($CmdLine) <= 1
	Else
		;;;
	EndIf

	If $hFile = "WINGET" Then
		;;;
	Else
		RunArchCheck($bSilent)
		RunHTTPCheck($bSilent)
	EndIf

	If Not $bPortable Then
		$aInstall = _IsInstalled()

		Select
			Case Not $aInstall[0] ; Not Installed
				RunSetup(False, $bSilent, 0, $hFile)
			Case _VersionCompare($sVersion, $aInstall[2]) ; Installed, Out of Date
				Select
					Case StringInStr($aInstall[1], "HKCU") ; Installed, Service Mode
						RunSetup($aInstall[0], $bSilent, 0, $hFile)
					Case StringInStr($aInstall[1], "HKLM") And Not $bIsAdmin And @Compiled; Installed, Active Mode, Not Admin
						ShellExecute(@ScriptFullPath, $sCMDLine, @ScriptDir, "RunAs")
						If @error Then
							If Not $bSilent Then MsgBox($MB_ICONWARNING+$MB_OK, _
								"Existing Active Mode Install", _
								"Unable to update an existing Active Mode install without Admin Rights! The installer will continue however.")
							ContinueCase
						Else
							Exit
						EndIf
					Case StringInStr($aInstall[1], "HKLM") ; Installed, Active Mode
						RunSetup($aInstall[0], $bSilent, 0, $hFile)
				EndSelect
			Case StringInStr($aInstall[1], "HKCU") ; Installed, Up to Date, Service Mode
				If @ScriptDir <> @LocalAppDataDir & "\MSEdgeRedirect" Then
					RunSetup($aInstall[0], $bSilent, 0, $hFile)
					;ShellExecute(@LocalAppDataDir & "\MSEdgeRedirect\MSEdgeRedirect.exe", "", @LocalAppDataDir & "\MSEdgeRedirect\")
				Else
					$aPIDs = ProcessList(@ScriptName)
					For $iLoop = 1 To $aPIDs[0][0] Step 1
						If $aPIDs[$iLoop][1] <> @AutoItPID Then
							$bHide = False
							ProcessClose($aPIDs[$iLoop][1])
						EndIf
					Next
				EndIf
			Case StringInStr($aInstall[1], "HKLM") And Not $bIsAdmin ; Installed, Up to Date, Active Mode, Not Admin
				ShellExecute(@ScriptFullPath, $sCMDLine, @ScriptDir, "RunAs")
				If @error Then
					If Not $bSilent Then MsgBox($MB_ICONWARNING+$MB_OK, _
						"Existing Active Mode Install", _
						"Unable to update an existing Active Mode install without Admin Rights! The installer will continue however.")
					ContinueCase
				Else
					Exit
				EndIf
			Case Else
				RunSetup(True, $bSilent, 0, $hFile)
		EndSelect
	EndIf
	ReactiveMode($bHide)

EndFunc

Func ReactiveMode($bHide = False)

	Local $aAdjust

	Local $hMsg

	; Enable "SeDebugPrivilege" privilege for obtain full access rights to another processes
	Local $hToken = _WinAPI_OpenProcessToken(BitOR($TOKEN_ADJUST_PRIVILEGES, $TOKEN_QUERY))

	_WinAPI_AdjustTokenPrivileges($hToken, $SE_DEBUG_NAME, $SE_PRIVILEGE_ENABLED, $aAdjust)

	TrayCreateItem($sVersion)
	TrayItemSetState(-1, $TRAY_DISABLE)
	TrayCreateItem("")
	Local $hSettings = TrayCreateItem("Settings")
	Local $hDonate = TrayCreateItem("Donate")
	TrayCreateItem("")
	Local $hUpdate = TrayCreateItem("Check for Updates")
	Local $hExit = TrayCreateItem("Exit")

	If $bHide Then TraySetState($TRAY_ICONSTATE_HIDE)

	Local $sRegex
	Local $iSIHost = ProcessExists("sihost.exe")
	Local $aProcessList
	Local $sCommandline

	If _GetSettingValue("NoApps") Then
		$sRegex = "(?i).*(microsoft\-edge|app\-id).*"
	Else
		$sRegex = "(?i).*(microsoft\-edge).*"
	EndIf

	While True
		$hMsg = TrayGetMsg()

		$aProcessList = _WinAPI_EnumChildProcess($iSIHost)
		If @error Then 
			;;;
		Else
			ProcessClose($aProcessList[1][0])
			$sCommandline = _WinAPI_GetProcessCommandLine($aProcessList[1][0])
			If StringRegExp($sCommandline, $sRegex) Then
				_DecodeAndRun(Default, $sCommandline)
			EndIf
		EndIf

#cs
		$aProcessList = ProcessList("msedge.exe")
		For $iLoop = 1 To $aProcessList[0][0] - 1
			$sCommandline = _WinAPI_GetProcessCommandLine($aProcessList[$iLoop][1])
			If StringRegExp($sCommandline, $sRegex) Then
				ProcessClose($aProcessList[$iLoop][1])
				_DecodeAndRun(Default, $sCommandline)
			EndIf
		Next
#ce

		Switch $hMsg

			Case $hSettings
				ShellExecute(@ScriptFullPath, "/settings", @ScriptDir)

			Case $hExit
				ExitLoop

			Case $hDonate
				ShellExecute("https://paypal.me/rhsky")

			Case $hUpdate
				RunUpdateCheck(True)

			Case Else

		EndSwitch
	WEnd

	_WinAPI_AdjustTokenPrivileges($hToken, $aAdjust, 0, $aAdjust)
	_WinAPI_CloseHandle($hToken)
	For $iLoop = 0 To UBound($hLogs) - 1
		FileClose($hLogs[$iLoop])
	Next
	Exit

EndFunc

Func RepairCMDLine($aCMDLine)

	Local $sCMDLine
	Local $sDelim = _ArraySafeDelim($aCMDLine)

	$sCMDLine = _ArrayToString($aCMDLine, $sDelim)
	Select
		Case StringInStr($sCMDLine, "Program" & $sDelim & "Files" & $sDelim & "(x86)")
			$sCMDLine = StringReplace($sCMDLine, "Program" & $sDelim & "Files" & $sDelim & "(x86)", "Program Files (x86)")
		Case StringInStr($sCMDLine, $sDelim & "--" & $sDelim)
			$sCMDLine = StringReplace($sCMDLine, "--" & $sDelim, "")
		Case Else
		;;;
	EndSelect

	$aCMDLine = StringSplit($sCMDLine, $sDelim, $STR_ENTIRESPLIT+$STR_NOCOUNT)
	$aCMDLine[0] = UBound($aCMDLine) - 1

	Return $aCMDLine

EndFunc

Func RunArchCheck($bSilent = False)
	If @Compiled And $bIsWOW64 Then
		If Not $bSilent Then
			MsgBox($MB_ICONERROR+$MB_OK, _
				"Wrong Version", _
				"The 64-bit Version of MSEdgeRedirect must be used with 64-bit Windows!")
		EndIf
		FileWrite($hLogs[$AppFailures], _NowCalc() & " - " & "32 Bit Version on 64 Bit System. EXITING!" & @CRLF)
		For $iLoop = 0 To UBound($hLogs) - 1
			FileClose($hLogs[$iLoop])
		Next
		Exit 216 ; ERROR_EXE_MACHINE_TYPE_MISMATCH
	EndIf
EndFunc

Func RunHTTPCheck($bSilent = False)

	Local $aDefaults[3]
	Local Enum $hHTTP, $hHTTPS, $hMSEdge

	$aDefaults[$hHTTP] = RegRead("HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice", "ProgId")
	$aDefaults[$hHTTPS] = RegRead("HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice", "ProgId")
	$aDefaults[$hMSEdge] = RegRead("HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\microsoft-edge\UserChoice", "ProgId")

	If StringInStr($aDefaults[$hMSEdge], "MSEdge") Then
		If $aDefaults[$hHTTP] = $aDefaults[$hMSEdge] Or $aDefaults[$hHTTPS] = $aDefaults[$hMSEdge] Then
			If Not $bSilent Then
				MsgBox($MB_ICONERROR+$MB_OK, _
					"Edge Set As Default", _
					"You must set a different Default Browser to use MSEdgeRedirect!")
			EndIf
			FileWrite($hLogs[$AppFailures], _NowCalc() & " - " & "Found same MS Edge for both default browser and microsoft-edge handling, EXITING!" & @CRLF)
			For $iLoop = 0 To UBound($hLogs) - 1
				FileClose($hLogs[$iLoop])
			Next
			Exit 4315 ; ERROR_MEDIA_INCOMPATIBLE
		EndIf
	EndIf

EndFunc

Func _DecodeAndRun($sEdge = $aEdges[1], $sCMDLine = "")

	Local $sURL = ""
	Local $aCMDLine

	Select
		Case StringLeft($sCMDLine, 2) = "--" And _GetSettingValue("RunUnsafe")
			_SafeRun($sEdge, $sCMDLine)
		Case StringInStr($sCMDLine, "--default-search-provider=?")
			FileWrite($hLogs[$URIFailures], _NowCalc() & " - Skipped Settings URL: " & $sCMDLine & @CRLF)
		Case StringInStr($sCMDLine, "profiles_settings")
			FileWrite($hLogs[$URIFailures], _NowCalc() & " - Skipped Profile Settings URL: " & $sCMDLine & @CRLF)
		Case StringInStr($sCMDLine, ".pdf")
			If _GetSettingValue("NoPDFs") Then
				$sCMDLine = StringReplace($sCMDLine, "--single-argument ", "")
				Switch _GetSettingValue("PDFApp")
					Case "Default"
						If RunPDFCheck() And _IsSafePDF($sCMDLine) Then ShellExecute($sCMDLine)
					Case Else
						ShellExecute(_GetSettingValue("PDFApp"), '"' & $sCMDLine & '"')
				EndSwitch
			Else
				$sCMDLine = StringReplace($sCMDLine, "--single-argument ", "")
				_SafeRun($sEdge, $sCMDLine)
				If Not _IsPriviledgedInstall() Then Sleep(1000)
			EndIf
		Case StringInStr($sCMDLine, "--app-id")
			Select
				Case StringInStr($sCMDLine, "--app-fallback-url=") And _GetSettingValue("NoApps"); Windows Store "Apps"
					$sCMDLine = StringRegExpReplace($sCMDLine, "(?i)(.*)(--app-fallback-url=)", "")
					$sCMDLine = StringRegExpReplace($sCMDLine, "(?i)(?= --)(.*)", "")
					If _IsSafeURL($sCMDLine) Then
						ShellExecute($sCMDLine)
					Else
						FileWrite($hLogs[$URIFailures], _NowCalc() & " - Invalid App URL: " & $sCMDLine & @CRLF)
					EndIf
				Case StringInStr($sCMDLine, "--ip-aumid=") ; Edge "Apps"
					If _IsSafeApp($sCMDLine) Then
						_SafeRun($sEdge, $sCMDLine)
					Else
						FileWrite($hLogs[$URIFailures], _NowCalc() & " - Invalid App URL: " & $sCMDLine & @CRLF)
					EndIf
				Case Else
					FileWrite($hLogs[$URIFailures], _NowCalc() & " - Invalid App URL: " & $sCMDLine & @CRLF)
			EndSelect
		Case StringInStr($sCMDLine, "bing.com/chat") ; Fix BingAI
			If _GetSettingValue("NoPDFs") Then _SafeRun($sEdge, $sCMDLine)
		Case StringInStr($sCMDLine, "&url=") ; Fix Windows 11 Widgets
			ContinueCase
		Case StringInStr($sCMDLine, "--edge-redirect")
			$aCMDLine = _RedirectCMDDecode($sCMDLine)

			For $iLoop = 0 To Ubound($aCMDLine) - 1 Step 1
				If $aCMDLine[$iLoop][0] = "url" Then
					$sURL = $aCMDLine[$iLoop][1]
					If StringInStr($sURL, "%2F") Then $sURL = _WinAPI_UrlUnescape($sURL)
					ExitLoop
				EndIf
			Next

			If $sURL = "" Then
				FileWrite($hLogs[$URIFailures], _NowCalc() & " - Command Line Missing Needed Parameters: " & $sCMDLine & @CRLF)
			Else
				FileWrite($hLogs[$AppGeneral], _NowCalc() & " - Redirected 'Edge-Redirect' Call:" & @CRLF & _ArrayToString($aCMDLine, ": ") & @CRLF)
				If _IsSafeURL($sURL) Then
					$sURL = _ModifyURL($sURL)
					ShellExecute($sURL)
				EndIf
			EndIf
		Case StringInStr($sCMDLine, "microsoft-edge:")
			$aCMDLine = _RedirectCMDDecode($sCMDLine)

			For $iLoop = 0 To Ubound($aCMDLine) - 1 Step 1
				If $aCMDLine[$iLoop][0] = "url" Then
					$sURL = $aCMDLine[$iLoop][1]
					If StringInStr($sURL, "%2F") Then $sURL = _WinAPI_UrlUnescape($sURL)
					ExitLoop
				EndIf
			Next

			If $sURL = "" Then
				FileWrite($hLogs[$URIFailures], _NowCalc() & " - Command Line Missing Needed Parameters: " & $sCMDLine & @CRLF)
			Else
				FileWrite($hLogs[$AppGeneral], _NowCalc() & " - Redirected 'Microsoft-Edge' Call:" & @CRLF & _ArrayToString($aCMDLine, ": ") & @CRLF)
				If _IsSafeURL($sURL) Then
					$sURL = _ModifyURL($sURL)
					ShellExecute($sURL)
				EndIf
			EndIf
		Case Else
			$sCMDLine = StringRegExpReplace($sCMDLine, "(?i)(.*) microsoft-edge:[\/]*", "") ; Legacy Installs
			$sCMDLine = StringReplace($sCMDLine, "?url=", "")
			If StringInStr($sCMDLine, "%2F") Then $sCMDLine = _WinAPI_UrlUnescape($sCMDLine)
			FileWrite($hLogs[$AppGeneral], _NowCalc() & " - Redirected Legacy Edge Call:" & @CRLF & $sCMDLine & @CRLF)
			If _IsSafeURL($sCMDLine) Then
				$sCMDLine = _ModifyURL($sCMDLine)
				ShellExecute($sCMDLine)
			Else
				FileWrite($hLogs[$URIFailures], _NowCalc() & " - Invalid URL: " & $sCMDLine & @CRLF)
			EndIf
	EndSelect
EndFunc

Func _GetDefaultBrowser()

	Local $sProg
	Local Static $sBrowser

	If $sBrowser <> "" Then
		;;;
	Else
		$sProg = RegRead("HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice", "ProgID")
		$sBrowser = RegRead("HKCR\" & $sProg & "\shell\open\command", "")
		$sBrowser = StringReplace($sBrowser, "%1", "")
	EndIf

	Return $sBrowser

EndFunc
