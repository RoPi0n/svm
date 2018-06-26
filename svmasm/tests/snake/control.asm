; control.asm
;
; Game keyboard input thread.

proc ControlThreadJoin()
super QuickThread
var .key = "x", .lastkey = " ", .t
  pop   $snake_vect
  ControlThreadJoin.Loop:
    gc
    invoke !Crt.ReadKey()
    peek   $.key
    gpm
    pop
    ;;;
    eq     $.key, $.lastkey
    mov    $.lastkey, $.key
    jn     !ControlThreadJoin.Loop
    eq     $.key, "w"
    jn     !ControlThreadJoin.KeyW
    eq     $.key, "a"
    jn     !ControlThreadJoin.KeyA
    eq     $.key, "s"
    jn     !ControlThreadJoin.KeyS
    eq     $.key, "d"
    jn     !ControlThreadJoin.KeyD
    jump !ControlThreadJoin.Loop
    ;;;
    ControlThreadJoin.KeyW:
       mov $snake_vect,  !svUp
    jump !ControlThreadJoin.Loop
    ;;;
    ControlThreadJoin.KeyA:
       mov $snake_vect,  !svLeft
    jump !ControlThreadJoin.Loop
    ;;;
    ControlThreadJoin.KeyS:
       mov $snake_vect,  !svDown
    jump !ControlThreadJoin.Loop
    ;;;
    ControlThreadJoin.KeyD:
       mov $snake_vect,  !svRight
    jump !ControlThreadJoin.Loop
endp

proc RunControlThread()
  push $snake_vect
  push !ControlThreadJoin
  cthr
  rthr
endp
