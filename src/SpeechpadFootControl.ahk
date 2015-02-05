#Persistent

; -------------------------------------------
; Global Variables
; -------------------------------------------

FootPedalBindingsPath = %A_ScriptDir%\SpeechpadFootPedalBindings.txt

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

IfExist, %FootPedalBindingsPath%
{
     LoadPedalKeyBindings()
}
else
{
     WritePedalKeyBindings()
}

OnMessage(0x00FF, "InputMessage")
RegisterHIDDevice(12, 3) ; Register Foot Pedal

Return

; -------------------------------------------
; Functions
; -------------------------------------------

WritePedalKeyBindings()
{
     global FootPedalBindingsPath
     global LeftDownKeyBinding
     global LeftUpKeyBinding
     global CenterDownKeyBinding
     global CenterUpKeyBinding
     global RightDownKeyBinding
     global RightUpKeyBinding

     IniWrite %LeftDownKeyBinding%, %FootPedalBindingsPath%, KeyBindings, LeftDown
     IniWrite %LeftUpKeyBinding%, %FootPedalBindingsPath%, KeyBindings, LeftUp
     IniWrite %CenterDownKeyBinding%, %FootPedalBindingsPath%, KeyBindings, CenterDown
     IniWrite %CenterUpKeyBinding%, %FootPedalBindingsPath%, KeyBindings, CenterUp
     IniWrite %RightDownKeyBinding%, %FootPedalBindingsPath%, KeyBindings, RightDown
     IniWrite %RightUpKeyBinding%, %FootPedalBindingsPath%, KeyBindings, RightUp
}

LoadPedalKeyBindings()
{
     global FootPedalBindingsPath
     global LeftDownKeyBinding
     global LeftUpKeyBinding
     global CenterDownKeyBinding
     global CenterUpKeyBinding
     global RightDownKeyBinding
     global RightUpKeyBinding

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

     ToolTip L:%LeftPedalPressed% C:%CenterPedalPressed% R:%RightPedalPressed%
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
     if (Res = 0)
          MsgBox, Failed to register for HID Device
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
