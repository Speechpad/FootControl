/*
 * * * Compile_AHK SETTINGS BEGIN * * *

[AHK2EXE]
Exe_File=C:\GDrive\SpeechInk\Dev\Speechpad Foot Control\SpeechpadFootControl.exe
Alt_Bin=C:\Program Files (x86)\AutoHotkey\Compiler\Unicode 32-bit.bin
Compression=0
[ICONS]
Icon_1=%In_Dir%\speechpad_icon.ico
Icon_2=%In_Dir%\speechpad_icon.ico
Icon_3=%In_Dir%\speechpad_icon_disabled.ico

* * * Compile_AHK SETTINGS END * * *
*/

#Persistent
#SingleInstance

; -------------------------------------------
; Global Variables
; -------------------------------------------

AppName := "Speechpad Foot Control"
Version := "0.3.0"
RawContentBaseUrl := "https://raw.githubusercontent.com/Speechpad/FootControl/master"
VersionUrl = %RawContentBaseUrl%\version.txt
EnabledIconUrl = %RawContentBaseUrl%\src/speechpad_icon.ico
DisabledIconUrl = %RawContentBaseUrl%/src/speechpad_icon_disabled.ico
DownloadUrl := "https://github.com/Speechpad/FootControl"

;TempDir = %A_Temp%\SpeechpadFootControl%A_Now%
TempDir = %A_Temp%\SpeechpadFootControl
FootPedalBindingsPath = %A_ScriptDir%\SpeechpadFootControlBindings.txt
EnabledIconPath = %A_ScriptDir%\speechpad_icon.ico
DisabledIconPath = %A_ScriptDir%\speechpad_icon_disabled.ico

SystemID := "Unknown"

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

; Load bindings file. Populates pedal binding globals and SystemID global

IfExist, %FootPedalBindingsPath%
{
     LoadPedalKeyBindings()
}
else
{
     WritePedalKeyBindings()
}

;MsgBox System ID: %SystemID%
;ToolTip System ID: %SystemID%

; Set up device hook

OnMessage(0x00FF, "InputMessage")
RegisterHIDDevice(12, 3) ; Register Foot Pedal

; Retrieve icon files if necessary
IfNotExist, %EnabledIconPath%
{
     URLDownloadToFile %EnabledIconUrl%, %EnabledIconPath%
     URLDownloadToFile %DisabledIconUrl%, %DisabledIconPath%
}

; Change the tray icon to use the downloaded one
Menu, Tray, Icon, %EnabledIconPath%, 1, 1

; Check for newer version

FileCreateDir %TempDir%

; Retrieve latest version number.
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


Return

; -------------------------------------------
; Menu Handlers
; -------------------------------------------

MenuCmdAbout:
MsgBox 0, About %AppName%, %AppName% `nVersion %Version%
Return

MenuCmdSuspend:
Suspend Toggle
Menu Tray, ToggleCheck, &Suspend

if (A_IsSuspended) 
{
     Menu, Tray, Tip, %AppName% (Suspended)
     Menu, Tray, Icon, %DisabledIconPath%, 1, 1
     
     if (A_IsCompiled)
     {
          ;Menu Tray, Icon,  %A_ScriptFullPath%, 5, 1
     }
}
Else 
{
     Menu, Tray, Tip, %AppName%
     Menu, Tray, Icon, %EnabledIconPath%, 1, 1
     
     if (A_IsCompiled)
     {
          ;Menu, Tray, Icon , %A_ScriptFullPath%, 1, 1
     }
}

Return 


MenuCmdExit:
ExitApp

; -------------------------------------------
; Functions
; -------------------------------------------

WritePedalKeyBindings()
{
     global SystemID
     global FootPedalBindingsPath
     global LeftDownKeyBinding
     global LeftUpKeyBinding
     global CenterDownKeyBinding
     global CenterUpKeyBinding
     global RightDownKeyBinding
     global RightUpKeyBinding

     SystemID := GetUniqueSystemID()
     IniWrite %SystemID%, %FootPedalBindingsPath%, SystemInfo, SystemID

     IniWrite %LeftDownKeyBinding%, %FootPedalBindingsPath%, KeyBindings, LeftDown
     IniWrite %LeftUpKeyBinding%, %FootPedalBindingsPath%, KeyBindings, LeftUp
     IniWrite %CenterDownKeyBinding%, %FootPedalBindingsPath%, KeyBindings, CenterDown
     IniWrite %CenterUpKeyBinding%, %FootPedalBindingsPath%, KeyBindings, CenterUp
     IniWrite %RightDownKeyBinding%, %FootPedalBindingsPath%, KeyBindings, RightDown
     IniWrite %RightUpKeyBinding%, %FootPedalBindingsPath%, KeyBindings, RightUp
}

LoadPedalKeyBindings()
{
     global SystemID
     global FootPedalBindingsPath
     global LeftDownKeyBinding
     global LeftUpKeyBinding
     global CenterDownKeyBinding
     global CenterUpKeyBinding
     global RightDownKeyBinding
     global RightUpKeyBinding

     IniRead SystemID, %FootPedalBindingsPath%, SystemInfo, SystemID, Unknown
     if ( SystemID = "Unknown" )
     {
          ; If we get here, a prior version of the pedal bindings file did not include
          ; the SystemID variable. Generate it here and write it back to the file.
          SystemID := GetUniqueSystemID()
          IniWrite %SystemID%, %FootPedalBindingsPath%, SystemInfo, SystemID
     }

     IniRead LeftDownKeyBinding, %FootPedalBindingsPath%, KeyBindings, LeftDown, %LeftDownKeyBinding%
     IniRead LeftUpKeyBinding, %FootPedalBindingsPath%, KeyBindings, LeftUp, %LeftUpKeyBinding%
     IniRead CenterDownKeyBinding, %FootPedalBindingsPath%, KeyBindings, CenterDown, %CenterDownKeyBinding%
     IniRead CenterUpKeyBinding, %FootPedalBindingsPath%, KeyBindings, CenterUp, %CenterUpKeyBinding%
     IniRead RightDownKeyBinding, %FootPedalBindingsPath%, KeyBindings, RightDown, %RightDownKeyBinding%
     IniRead RightUpKeyBinding, %FootPedalBindingsPath%, KeyBindings, RightUp, %RightUpKeyBinding%
}

ShowPedalState()
{
     global LeftPedalPressed
     global CenterPedalPressed
     global RightPedalPressed

     ;ToolTip L:%LeftPedalPressed% C:%CenterPedalPressed% R:%RightPedalPressed%
}


ProcessPedalInput(input)
{
     global LeftPedalPressed
     global CenterPedalPressed
     global RightPedalPressed
     
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
     ShowPedalState()
     
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
     ShowPedalState()
     
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

GetUniqueSystemID(){
     TypeLib := ComObjCreate("Scriptlet.TypeLib")
     NewGUID := TypeLib.Guid
     ;macAddress := GetMacAddress()
     systemID = %A_ComputerName%__%A_OSType%__%A_OSVersion%__%NewGUID%
     ;MsgBox, %systemID%
     return %systemID%
}