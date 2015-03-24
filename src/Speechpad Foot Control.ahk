/*
 * * * Compile_AHK SETTINGS BEGIN * * *

[AHK2EXE]
Exe_File=C:\GDrive\SpeechInk\Dev\Speechpad Foot Control\Speechpad Foot Control.exe
Alt_Bin=C:\Program Files (x86)\AutoHotkey\Compiler\Unicode 32-bit.bin
Compression=0
[ICONS]
Icon_1=%In_Dir%\icons\speechpad_icon.ico
Icon_2=%In_Dir%\icons\speechpad_icon.ico
Icon_3=%In_Dir%\icons\speechpad_icon_disabled.ico

* * * Compile_AHK SETTINGS END * * *
*/

#Persistent
#SingleInstance

; -------------------------------------------
; Global Variables
; -------------------------------------------

AppName := "Speechpad Foot Control"
Version := "0.4.0"
OSInfo := A_Is64bitOS ? A_OSVersion . "_64" : A_OSVersion . "_32" 

SpeechpadBaseUrl := "https://www.speechpad.com/app_usage/log_foot_control"
RawContentBaseUrl := "https://raw.githubusercontent.com/Speechpad/FootControl/master"
VersionUrl = %RawContentBaseUrl%/version.txt
EnabledIconUrl = %RawContentBaseUrl%/icons/speechpad_icon.ico
DisabledIconUrl = %RawContentBaseUrl%/icons/speechpad_icon_disabled.ico
DownloadUrl := "https://github.com/Speechpad/FootControl"

;TempDir = %A_Temp%\SpeechpadFootControl%A_Now%
TempDir = %A_Temp%\SpeechpadFootControl
IniFile = %A_ScriptDir%\Speechpad Foot Control.ini
EnabledIconPath = %A_ScriptDir%\speechpad_icon.ico
DisabledIconPath = %A_ScriptDir%\speechpad_icon_disabled.ico

InstanceUUID := "Unknown"
UsageDates := []

LeftPedalPressed := 0
CenterPedalPressed := 0
RightPedalPressed := 0
FootPedalDeviceHandle := 0

LeftDownKeyBinding := "!1"
LeftUpKeyBinding := "!2"
CenterDownKeyBinding := "!3"
CenterUpKeyBinding := "!4"
RightDownKeyBinding := "!5"
RightUpKeyBinding := "!6"



; -------------------------------------------
; Initialization
; -------------------------------------------

; Set up Windows tray menus

Menu, Tray, NoStandard ; remove standard Menu items
Menu, Tray, Add , &About, MenuCmdAbout
Menu, Tray, Add , &Suspend, MenuCmdSuspend
Menu, Tray, Add , E&xit, MenuCmdExit

Menu, Tray, Tip, %AppName%

; Load ini file. Populates pedal binding globals and other app info

IfExist, %IniFile%
{
     LoadIniFile()
}
else
{
     WriteIniFile()
}

;MsgBox InstanceUUID: %InstanceUUID%

; Set up device hook

OnMessage(0x00FF, "InputMessage")
RegisterHIDDevice(12, 3) ; Register Foot Pedal

if (not A_IsCompiled)
{
     ; Retrieve icon files if necessary
     IfNotExist, %EnabledIconPath%
     {
          DownloadIcons()
     }
     
     ; Change the tray icon to use the downloaded one
     Menu, Tray, Icon, %EnabledIconPath%, 1, 1
}
else
{
     ;Menu, Tray, Icon , %A_ScriptFullPath%, 1, 1
}

CheckInWithServer("startup")

Return

; -------------------------------------------
; Menu Handlers
; -------------------------------------------

MenuCmdAbout:
MsgBox 0, About %AppName%, %AppName% `n`nVersion %Version%`nInstance ID: %InstanceUUID%`nOS: %OSInfo%
Return

MenuCmdSuspend:
Suspend Toggle
Menu Tray, ToggleCheck, &Suspend

if (A_IsSuspended) 
{
     Menu, Tray, Tip, %AppName% (Suspended)
     ;Menu, Tray, Icon, %DisabledIconPath%, 1, 1
     
     if (A_IsCompiled)
     {
          ;Menu Tray, Icon,  %A_ScriptFullPath%, 5, 1
     }
     else
     {
          Menu, Tray, Icon, %DisabledIconPath%, 1, 1
     }
}
Else 
{
     Menu, Tray, Tip, %AppName%
     
     if (A_IsCompiled)
     {
          ;Menu, Tray, Icon , %A_ScriptFullPath%, 1, 1
     }
     else
     {
          Menu, Tray, Icon, %EnabledIconPath%, 1, 1
     }
}
     
Return 


MenuCmdExit:
ExitApp

; -------------------------------------------
; Functions
; -------------------------------------------

CheckInWithServer(event)
{
     global SpeechpadBaseUrl
     global TempDir
     global Version
     global OSInfo
     global InstanceUUID
     global UsageDates
     global VersionUrl
     global DownloadUrl

; Check in with Speechpad server
FileCreateDir %TempDir%

checkInUrl := SpeechpadBaseUrl . "?version=" . Version . "&operating_system=" . OSInfo . "&instance_uuid=" . InstanceUUID . "&event=" event
usageDatesStr := "[" . st_glue(UsageDates, ",", """") . "]"
checkInUrl .= "&usage_statistics=" . usageDatesStr
;Clipboard := checkInUrl

URLDownloadToFile %checkInUrl%, %TempDir%\checkInResponse.txt
FileRead checkInResponse, %TempDir%\checkInResponse.txt

; To-Do: Parse JSON results from server


; Retrieve latest version number.
; To-Do: Update this code when Speechpad server starts returning results

URLDownloadToFile %VersionUrl%, %TempDir%\version.txt
FileRead latestVersion, %TempDir%\version.txt

StringSplit, latest_version_array, latestVersion, .
StringSplit, this_version_array, Version, .
this_numeric_version := this_version_array1 * 100 * 100 + this_version_array2 * 100 + this_version_array3
latest_numeric_version := latest_version_array1 * 100 * 100 + latest_version_array2 * 100 + latest_version_array3
;latest_numeric_version := 0 * 100 * 100 + 1 * 100 + 0

if ( this_numeric_version < latest_numeric_version )
{
     msgText := "A newer version of the Speechpad Foot Controller app is available.`n`nThis Version: " Version "`nLatest Version: " latestVersion "`n`nDownload newer version?"
     MsgBox 4, "Newer Version Available", %msgText%
     IfMsgBox Yes
          Run %DownloadUrl%
}
;MsgBox latest_numeric_version is %latest_numeric_version%

}


DownloadIcons()
{
     global EnabledIconUrl
     global EnabledIconPath
     global DisabledIconUrl
     global DisabledIconPath
     
     URLDownloadToFile %EnabledIconUrl%, %EnabledIconPath%
     if ErrorLevel
     {
          FileDelete %EnabledIconPath%
     }
     else
     {
          FileRead DownloadedContents, %EnabledIconPath%
          IfInString, DownloadedContents, Not Found
               FileDelete %EnabledIconPath%
     }

     URLDownloadToFile %DisabledIconUrl%, %DisabledIconPath%
     if ErrorLevel
     {
          FileDelete %DisabledIconPath%
     }
     else
     {
          FileRead DownloadedContents, %DisabledIconPath%
          IfInString, DownloadedContents, Not Found
               FileDelete %DisabledIconPath%
     }
}

WriteIniFile()
{
     global InstanceUUID
     global IniFile
     global LeftDownKeyBinding
     global LeftUpKeyBinding
     global CenterDownKeyBinding
     global CenterUpKeyBinding
     global RightDownKeyBinding
     global RightUpKeyBinding

     if ( InstanceUUID = "Unknown" )
     {
          InstanceUUID := CreateUniqueInstanceID()
     }
     IniWrite %InstanceUUID%, %IniFile%, SystemInfo, InstanceUUID

     IniWrite %LeftDownKeyBinding%, %IniFile%, KeyBindings, LeftDown
     IniWrite %LeftUpKeyBinding%, %IniFile%, KeyBindings, LeftUp
     IniWrite %CenterDownKeyBinding%, %IniFile%, KeyBindings, CenterDown
     IniWrite %CenterUpKeyBinding%, %IniFile%, KeyBindings, CenterUp
     IniWrite %RightDownKeyBinding%, %IniFile%, KeyBindings, RightDown
     IniWrite %RightUpKeyBinding%, %IniFile%, KeyBindings, RightUp
}

LoadIniFile()
{
     global IniFile
     global InstanceUUID
     global UsageDates
     global LeftDownKeyBinding
     global LeftUpKeyBinding
     global CenterDownKeyBinding
     global CenterUpKeyBinding
     global RightDownKeyBinding
     global RightUpKeyBinding

     IniRead InstanceUUID, %IniFile%, SystemInfo, InstanceUUID, Unknown
     if ( InstanceUUID = "Unknown" )
     {
          ; If we get here, a prior version of the pedal bindings file did not include
          ; the InstanceUUID variable. Generate it here and write it back to the file.
          InstanceUUID := CreateUniqueInstanceID()
          IniWrite %InstanceUUID%, %IniFile%, SystemInfo, InstanceUUID
     }
     
     IniRead usageDatesStr, %IniFile%, UsageInfo, UsageDates, %A_Space%
     UsageDates := st_split(usageDatesStr, ",")

     IniRead LeftDownKeyBinding, %IniFile%, KeyBindings, LeftDown, %LeftDownKeyBinding%
     IniRead LeftUpKeyBinding, %IniFile%, KeyBindings, LeftUp, %LeftUpKeyBinding%
     IniRead CenterDownKeyBinding, %IniFile%, KeyBindings, CenterDown, %CenterDownKeyBinding%
     IniRead CenterUpKeyBinding, %IniFile%, KeyBindings, CenterUp, %CenterUpKeyBinding%
     IniRead RightDownKeyBinding, %IniFile%, KeyBindings, RightDown, %RightDownKeyBinding%
     IniRead RightUpKeyBinding, %IniFile%, KeyBindings, RightUp, %RightUpKeyBinding%
}

ShowPedalState()
{
     global LeftPedalPressed
     global CenterPedalPressed
     global RightPedalPressed

     ToolTip L:%LeftPedalPressed% C:%CenterPedalPressed% R:%RightPedalPressed%
}


ProcessPedalInput(input)
{
     global LeftPedalPressed
     global CenterPedalPressed
     global RightPedalPressed
     global DateOfLastUse
     
     UpdateUsageDates()
     
     ; The input are combinations of 1, 2, 4 with 00 appended to the end
     ; indicating which pedals are pressed.
     ; For example, pressing the leftmost pedal triggers input 100, middle pedal 200, etc.
     ; all three pedals presses together will trigger 700 (1 ^ 2 ^ 4 = 7)
     ; Release of pedal trigger an input indicating what pedals are still held down
     
     input := input//100
     
     ; Handle Left Pedal
     If (input & 1) {
          ; current state of left pedal is down
          If (LeftPedalPressed = 0) {
               LeftPedalPressed = 1
               PressKey(1)
          }
     } Else {
          ; current state of left pedal is up
          If (LeftPedalPressed) {
               LeftPedalPressed = 0
               ReleaseKey(1)
          }
     }
     
     ; Handle Center Pedal
     If (input & 2) {
          ; current state of center pedal is down
          If (CenterPedalPressed = 0) {
               CenterPedalPressed = 1
               PressKey(2)
          }
     } Else {
          ; current state of center pedal is up
          If (CenterPedalPressed) {
               CenterPedalPressed = 0
               ReleaseKey(2)
          }
     }
     
     
     ; Handle Right Pedal
     If (input & 4) {
          ; current state of right pedal is down
          If (RightPedalPressed = 0) {
               RightPedalPressed = 1
               PressKey(4)
          }
     } Else {
          ; current state of right pedal is up
          If (RightPedalPressed) {
               RightPedalPressed = 0
               ReleaseKey(4)
          }
     }
     
     
}

PressKey(bits)
{
     global LeftDownKeyBinding
     global CenterDownKeyBinding
     global RightDownKeyBinding

     ; ToolTip Pressing %bits%
     ;ShowPedalState()
     
     If (bits & 1) ; left pedal
     {
          ;SendInput Left pedal pressed. Bits %bits%{enter}
          ;ToolTip SendInput LD
          SendInput %LeftDownKeyBinding%
     }
     Else If (bits & 4) ; right pedal
     {
          ;SendInput Right pedal pressed. Bits %bits%{enter}
          ;ToolTip SendInput RD
          SendInput %RightDownKeyBinding%
     }
     Else ; center pedal
     {
          ;SendInput Center pedal pressed. Bits %bits%{enter}
          ;ToolTip SendInput CD
          SendInput %CenterDownKeyBinding%
     }
}

ReleaseKey(bits)
{
     global LeftUpKeyBinding
     global CenterUpKeyBinding
     global RightUpKeyBinding
     
     ; ToolTip Releasing %bits%
     ;ShowPedalState()
     
     If (bits & 1)
     {
          ;SendInput Left pedal up. Bits %bits%{enter}
          ;ToolTip SendInput LU
          SendInput %LeftUpKeyBinding%
     }
     Else If (bits & 4)
     {
          ;SendInput Right pedal up. Bits %bits%{enter}
          ;ToolTip SendInput RU          
          SendInput %RightUpKeyBinding%
     }
     Else
     {
          ;SendInput Center pedal up. Bits %bits%{enter}
          ;ToolTip SendInput CU
          SendInput %CenterUpKeyBinding%
     }    
}

Mem2Hex( pointer, len )
{
     A_FI := A_FormatInteger
     SetFormat, Integer, Hex
     Loop, %len%  {
          Hex := *Pointer+0
          StringReplace, Hex, Hex, 0x, 0x0
          StringRight Hex, Hex, 2         
          hexDump := hexDump . hex
          Pointer ++
     }
     SetFormat, Integer, %A_FI%
     StringUpper, hexDump, hexDump
     Return hexDump
}

; Keyboards are always Usage Page 1, Usage 6, Mice are Usage Page 1, Usage 2.
; Foot pedal is Usage Page 12, Usage 3.
; HID devices specify their top level collection in the info block
RegisterHIDDevice(UsagePage,Usage)
{
     ; local RawDevice,HWND
     RIDEV_INPUTSINK := 0x00000100
     DetectHiddenWindows, on
     HWND := WinExist("ahk_class AutoHotkey ahk_pid " DllCall("GetCurrentProcessId"))
     DetectHiddenWindows, off
     
     VarSetCapacity(RawDevice, 12)
     NumPut(UsagePage, RawDevice, 0, "UShort")
     NumPut(Usage, RawDevice, 2, "UShort")   
     NumPut(RIDEV_INPUTSINK, RawDevice, 4)
     NumPut(HWND, RawDevice, 8)
     
     Res := DllCall("RegisterRawInputDevices", "UInt", &RawDevice, UInt, 1, UInt, 12)
     ; MsgBox DllCall RegisterRawInputDevices result: %Res%
     if (Res = "")
          MsgBox, Could not detect foot control.`nPlease ensure it is connected and drivers are properly installed.
}  

InputMessage(wParam, lParam, msg, hwnd)
{
     global FootPedalDeviceHandle
     
     RID_INPUT   := 0x10000003
     SizeOfHeader := 8 + A_PtrSize + A_PtrSize 
     RIM_TYPEHID := 2
     SizeOfHeader := 8 + A_PtrSize + A_PtrSize 
     SizeofRidDeviceInfo := 32
     RIDI_DEVICEINFO := 0x2000000b

     DllCall("GetRawInputData", "Ptr", lParam, "UInt", RID_INPUT, "Ptr", 0, "UIntP", Size, "UInt", SizeOfHeader, "UInt")
     VarSetCapacity(Buffer, Size)
     DllCall("GetRawInputData", "Ptr", lParam, "UInt", RID_INPUT, "Ptr", &Buffer, "UIntP", Size, "UInt", SizeOfHeader, "UInt")
     DeviceType := NumGet(Buffer, 0 * 4, "UInt")
     Size := NumGet(Buffer, 1 * 4, "UInt")
     FootPedalDeviceHandle := NumGet(Buffer, 2 * 4, "UPtr")

     ;SendInput InputMessage: wParam=%wParam%, lParam=%lParam%, msg=%msg%, hwnd=%hwnd%, handle=%FootPedalDeviceHandle%, DeviceType=%DeviceType% `n
     
     VarSetCapacity(Info, SizeofRidDeviceInfo) 
     NumPut(SizeofRidDeviceInfo, Info, 0)
     
     DllCall("GetRawInputDeviceInfo", "Ptr", FootPedalDeviceHandle, "UInt", RIDI_DEVICEINFO, "Ptr", &Info, "UIntP", SizeofRidDeviceInfo)
     VenderID := NumGet(Info, 4 * 2, "UInt")
     Product := NumGet(Info, 4 * 3, "UInt")
     ;tooltip %VenderID% %Product%
     
     if (DeviceType = RIM_TYPEHID)
     {
          SizeHid := NumGet(Buffer, (SizeOfHeader + 0), "UInt")
          InputCount := NumGet(Buffer, (SizeOfHeader + 4), "UInt")
          ;SendInput InputCount=%InputCount% `n
          Loop %InputCount%
          {
               Addr := &Buffer + SizeOfHeader + 8 + ((A_Index - 1) * SizeHid)
               BAddr := &Buffer
               Input := Mem2Hex(Addr, SizeHid)
               If (VenderID = 1523 && Product = 255) ; need special function to process foot pedal input
                    ProcessPedalInput(Input)
               Else If (IsLabel(Input))
               {
                    Gosub, %Input%
               }
          }
     }
}


NewInputMessage(wParam, lParam, msg, hwnd)
{
   RID_INPUT   := 0x10000003
   RIM_TYPEHID := 2
   SizeOfHeader := 8 + A_PtrSize + A_PtrSize 
   SizeofRidDeviceInfo := 32
   RIDI_DEVICEINFO := 0x2000000b
   DllCall("GetRawInputData", "Ptr", lParam, "UInt", RID_INPUT, "Ptr", 0, "UIntP", Size, "UInt", SizeOfHeader, "UInt")
   VarSetCapacity(Buffer, Size)
   DllCall("GetRawInputData", "Ptr", lParam, "UInt", RID_INPUT, "Ptr", &Buffer, "UIntP", Size, "UInt", SizeOfHeader, "UInt")
   Type := NumGet(Buffer, 0 * 4, "UInt")
   Size := NumGet(Buffer, 1 * 4, "UInt")
   Handle := NumGet(Buffer, 2 * 4, "UPtr")
   VarSetCapacity(Info, SizeofRidDeviceInfo) 
   NumPut(SizeofRidDeviceInfo, Info, 0)
   Length := SizeofRidDeviceInfo
   DllCall("GetRawInputDeviceInfo", "Ptr", Handle, "UInt", RIDI_DEVICEINFO, "Ptr", &Info, "UIntP", SizeofRidDeviceInfo)
   VenderID := NumGet(Info, 4 * 2, "UInt")
   Product := NumGet(Info, 4 * 3, "UInt")
   ;   tooltip %VenderID% %Product%
   if (Type = RIM_TYPEHID)
   {
      SizeHid := NumGet(Buffer, (SizeOfHeader + 0), "UInt")
      InputCount := NumGet(Buffer, (SizeOfHeader + 4), "UInt")
      SendInput InputCount=%InputCount%
      Loop %InputCount%
      {
         Addr := &Buffer + SizeOfHeader + 8 + ((A_Index - 1) * SizeHid)
         BAddr := &Buffer
         Input := Mem2Hex(Addr, SizeHid)
         If (VenderID = 1523 && Product = 255) ; need special function to process foot pedal input
            ProcessPedalInput(Input)
         Else If (IsLabel(Input))
         {
            Gosub, %Input%
         }
      }
   }
}


/*
GetMacAddress(){
    tempfile = %A_Temp%\mac.txt
    RunWait, %ComSpec% /c getmac /NH > %tempfile%, , Hide ; ipconfig (slow)
    FileRead, thetext, %tempfile%
    RegExMatch(thetext, ".*?([0-9A-Z].{16})(?!\w\\Device)", mac)
    ;MsgBox, %mac1%
    return %mac1%
}
*/

CreateUniqueInstanceID(){
     TypeLib := ComObjCreate("Scriptlet.TypeLib")
     NewGUID := Trim( TypeLib.Guid, "{}" )
     ;instanceUUID = %A_ComputerName%__%A_OSType%__%A_OSVersion%__%NewGUID%
     return %NewGUID%
}


UpdateUsageDates()
{
     global UsageDates
     global IniFile
     
     FormatTime Today, , yyyy-MM-dd
     if (UsageDates[1] == Today)
     {
          return
     }
     
     Loop 4
     {
          UsageDates[6-A_Index] := UsageDates[5-A_Index]
     }
     
     UsageDates[1] := Today

     usageDatesStr := st_glue(UsageDates, ",")
     IniWrite %usageDatesStr%, %IniFile%, UsageInfo, UsageDates
     
     CheckInWithServer("update")
     ;MsgBox %usageDatesStr%
}


; -------------------
; --- Array stuff ---
; -------------------

/*
Split
   Split a string into an array. "Split" one item into many items.

   string  = The text you want to split into pieces.
   delim   = The character(s) that define where to split.
   exclude = The character(s) you want to ignore when splitting.

example: st_split("aaa|bbb|ccc")
output:  array("aaa", "bbb", "ccc")
*/
st_split(string, delim="`n", exclude="`r")
{
   arr:=[]
   loop, parse, string, %delim%, %exclude%
      arr.insert(A_LoopField)
   return arr
}


/*
Glue
   Take an array and turn it into a string. "Glue" many items into one item.

   array = An array that will be turned into a string.
   delim = This is what separates each item in the newly formed string.

example: st_glue(arr, "|") ; where arr is an array containing: ["aaa", "bbb", "ccc"]
output:  aaa|bbb|ccc
*/
st_glue(array, delim="`n", quoteChar="")
{
   for k,v in array
      new.=quoteChar v quoteChar delim
   return trim(new, delim)
}
