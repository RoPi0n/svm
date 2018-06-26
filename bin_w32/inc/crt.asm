import Crt.CursorBig      "crt.lib" "CURSORBIG"
import Crt.CursorOff      "crt.lib" "CURSOROFF"
import Crt.CursorOn       "crt.lib" "CURSORON"
import Crt.DelLine        "crt.lib" "DELLINE"
import Crt.GotoXY32       "crt.lib" "GOTOXY32"
import Crt.InsLine        "crt.lib" "INSLINE"
import Crt.KeyPressed     "crt.lib" "KEYPRESSED"
import Crt.ReadKey        "crt.lib" "READKEY"
import Crt.Sound          "crt.lib" "SOUND"
import Crt.WhereX32       "crt.lib" "WHEREX32"
import Crt.WhereY32       "crt.lib" "WHEREY32"
import Crt.Window32       "crt.lib" "WINDOW32"
import Crt.ClrEOL         "crt.lib" "CLREOL"
import Crt.ClrScr         "crt.lib" "CLRSCR"
import Crt.GetDirectVideo "crt.lib" "GETDIRECTVIDEO"
import Crt.GetLastMode    "crt.lib" "GETLASTMODE"
import Crt.GetTextAttr    "crt.lib" "GETTEXTATTR"
import Crt.GetWindMax     "crt.lib" "GETWINDMAX"
import Crt.GetWindMaxX    "crt.lib" "GETWINDMAXX"
import Crt.GetWindMaxY    "crt.lib" "GETWINDMAXY"
import Crt.GetWindMin     "crt.lib" "GETWINDMIN"
import Crt.GetWindMinX    "crt.lib" "GETWINDMINX"
import Crt.GetWindMinY    "crt.lib" "GETWINDMINY"
import Crt.GetCheckBreak  "crt.lib" "GETCHECKBREAK"
import Crt.GetCheckEOF    "crt.lib" "GETCHECKEOF"
import Crt.GetCheckSnow   "crt.lib" "GETCHECKSNOW"
import Print              "crt.lib" "PRINT"
import PrintLn            "crt.lib" "PRINTLN"
import PrintFormat        "crt.lib" "PRINTFORMAT"
import Input              "crt.lib" "INPUT"
import InputLn            "crt.lib" "INPUTLN"

; CRT modes
word  Crt.BW40           0            ; 40x25 B/W on Color Adapter
word  Crt.CO40           1            ; 40x25 Color on Color Adapter
word  Crt.BW80           2            ; 80x25 B/W on Color Adapter
word  Crt.CO80           3            ; 80x25 Color on Color Adapter
word  Crt.Mono           7            ; 80x25 on Monochrome Adapter
word  Crt.Font8x8        256          ; Add-in for ROM font

; Foreground and background color constants
word Crt.Black          0
word Crt.Blue           1
word Crt.Green          2
word Crt.Cyan           3
word Crt.Red            4
word Crt.Magenta        5
word Crt.Brown          6
word Crt.LightGray      7

; Foreground color constants
word Crt.DarkGray       8
word Crt.LightBlue      9
word Crt.LightGreen     10
word Crt.LightCyan      11
word Crt.LightRed       12
word Crt.LightMagenta   13
word Crt.Yellow         14
word Crt.White          15

; Add-in for blinking
word Crt.Blink          128

;Functions & procedures for work with CRT

var Crt.TextAttr

proc Crt.Init()
  push 0x07
  pop  $Crt.TextAttr
endp

proc Crt.TextColor($.color)
  and  $.color, 143
  and  $Crt.TextAttr, 112
  or   $Crt.TextAttr, $.color
endp

proc Crt.TextBackground($.color)
var .buf = 0xf0
  store $.color
  and  $.buf,          $.color
  shl  $.color,        4
  and  $.color,        $.buf
  mov  $.buf,          0x0f
  or   $.buf,          !Crt.Blink
  and  $.buf,          $Crt.TextAttr
  or   $.color,        $.buf
  mov  $Crt.TextAttr, $.color
  load $.color
endp

proc Crt.NormVideo()
  push 7
  call !Crt.TextColor
  push 0
  call !Crt.TextBackGround
endp

proc Crt.WhereX()
  invoke !Crt.WhereX32
  push   256
  gpm
  swp
  mod
endp

proc Crt.WhereY()
  invoke !Crt.WhereY32
  push   256
  gpm
  swp
  mod
endp

proc Crt.Pause()
  gc
  invoke !Crt.KeyPressed
  gpm
  jz !Crt.Pause
endp

proc PrintFmt()
  push $.Crt.TextAttr
  swp
  invoke !PrintFormat
endp

proc PrintLnFmt()
  push $Crt.TextAttr
  swp
  invoke !PrintFormat
  push ""
  gpm
  invoke !PrintLn
endp
