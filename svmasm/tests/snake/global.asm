; global.asm
; *****
; Global program constants.

str  chr_border "#"
str  chr_snake  "@"
str  chr_food   "*"

; Blocks & Snake properties
word x 0
word y 1

; Room size
var mapsz_w, mapsz_h

; Snake & border's vector's
var vsnake, vborders

; Food x/y
var food_x, food_y

; Game score
var score

; Game tick delay
var TickDelay

proc InitGame()
  push   100
  pop    $TickDelay
  push   0
  pop    $score
  invoke !Randomize
  invoke !Crt.ClrScr
  invoke !Crt.CursorOff
  ;invoke !Crt.GetWindMaxX
  push   40
  pop    $mapsz_w
  ;invoke !Crt.GetWindMaxY
  push   20
  pop    $mapsz_h
  call   !vector.create
  call   !vector.create
  pop    $vsnake
  pop    $vborders
  call   !MoveFood()
endp

proc FreeGame()
  call   !vector.free($vsnake)
  call   !vector.free($vborders)
  invoke !Crt.ClrScr
  invoke !Crt.CursorOn
endp

proc FillXY($.x, $.y, $.ch)
  invoke !Crt.GotoXY32($.y, $.x)     ; #1 Bug in crt.lib...
  invoke !Print($.ch)
endp
