; control.asm
;
; Game keyboard input thread.

proc ControlThreadJoin()
super QuickThread
var .key
  pop   $player_racket
  ControlThreadJoin.Loop:
    gc
    invoke !Crt.ReadKey()
    peek   $.key
    gpm
    pop
    ;;;
    eq     $.key, "a"
    jn     !ControlThreadJoin.KeyA
    eq     $.key, "d"
    jn     !ControlThreadJoin.KeyD
    jump !ControlThreadJoin.Loop
    ;;;
    ControlThreadJoin.KeyA:
       call !racket.moveleft_p($player_racket)
    jump !ControlThreadJoin.Loop
    ;;;
    ControlThreadJoin.KeyD:
       call !racket.moveright_p($player_racket)
    jump !ControlThreadJoin.Loop
endp

proc RunControlThread()
  push $player_racket
  push !ControlThreadJoin
  cthr
  rthr
endp
