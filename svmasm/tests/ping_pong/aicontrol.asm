; aicontrol.asm
; *****
; Game AI

proc AITick()
var .tx = 0
  gc
  mov $.tx, $ball[!x]
  sub $.tx, $ai_racket[!x2]
  bg  $.tx, -2
  eq  $ball[!v], !bvRT
  and
  jn  !AITick.MR
  bg  2, $.tx
  eq  $ball[!v], !bvLT
  and
  jn  !AITick.ML
  jr
  ;;
  AITick.MR:
    call !racket.moveright($ai_racket)
  jr
  ;;
  AITick.ML:
    call !racket.moveleft($ai_racket)
  jr
endp
