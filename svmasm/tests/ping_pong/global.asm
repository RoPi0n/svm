; global.asm
; *****
; Global program constants.

str  chr_border "#"
str  chr_racket "="
str  chr_ball   "@"

; Blocks & Racket properties
word x  0
word y  1
word x2 2
word y2 3
word x3 4
word y3 5
word v  2

; Room size
var mapsz_w, mapsz_h

; Border's vector's
var vborders

; Game tick delay
var TickDelay

; Rackets
var player_racket, ai_racket

; Ball
var ball

; Score
var score

; Ball vectors
word bvLT 0
word bvLD 1
word bvRT 2
word bvRD 3

proc InitGame()
  push   50
  pop    $TickDelay
  invoke !Randomize
  invoke !Crt.ClrScr
  invoke !Crt.CursorOff
  ;invoke !Crt.GetWindMaxX
  push   61
  pop    $mapsz_w
  ;invoke !Crt.GetWindMaxY
  push   20
  pop    $mapsz_h
  push   0
  pop    $score
  call   !vector.create
  pop    $vborders
  call   !racket.create(31,19)
  pop    $player_racket
  call   !racket.create(31,1)
  pop    $ai_racket
  call   !racket.drawself($player_racket)
  call   !racket.drawself($ai_racket)
  call   !ball.create(31,19,!bvRT)
  pop    $ball
endp

proc FreeGame()
  invoke !Crt.ClrScr
  invoke !Crt.CursorOn
endp

proc FillXY($.x, $.y, $.ch)
  invoke !Crt.GotoXY32($.y, $.x)     ; #1 Bug in crt.lib...
  invoke !Print($.ch)
endp

proc points_eq($.x1, $.y1, $.x2, $.y2)
  eq $.x1, $.x2
  eq $.y1, $.y2
  and
endp
