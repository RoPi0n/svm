; racket.asm
; *****
; Racket.

; Racket[6] :
;            [0] - x1
;            [1] - y1
;            [2] - x2
;            [3] - y2
;            [4] - x3
;            [5] - y4

proc racket.create($.x, $.y)
var .r, .bx, .by
  push 6
  gpm
  push 1
  gpm
  newa
  pop  $.r
  ;;;
  new  $.bx
  new  $.by
  mov  $.bx, $.x
  mov  $.by, $.y
  push $.bx
  peek $.r[!x2]
  push $.by
  peek $.r[!y2]
  ;;;
  new  $.bx
  new  $.by
  mov  $.bx, $.x
  mov  $.by, $.y
  dec  $.bx
  push $.bx
  peek $.r[!x]
  push $.by
  peek $.r[!y]
  ;;;
  new  $.bx
  new  $.by
  mov  $.bx, $.x
  mov  $.by, $.y
  inc  $.bx
  push $.bx
  peek $.r[!x3]
  push $.by
  peek $.r[!y3]
  ;;;
  push $.r
endp

proc racket.drawself($.r)
  call !FillXY($.r[!x], $.r[!y], !chr_racket)
  call !FillXY($.r[!x2], $.r[!y2], !chr_racket)
  call !FillXY($.r[!x3], $.r[!y3], !chr_racket)
endp

proc racket.moveleft($.r)
  bg  $.r[!x], 2
  jz  !racket.moveleft.end
    call !FillXY($.r[!x3], $.r[!y3], " ")
    dec $.r[!x]
    dec $.r[!x2]
    dec $.r[!x3]
    call !FillXY($.r[!x], $.r[!y], !chr_racket)
  racket.moveleft.end:
endp

proc racket.moveright($.r)
  bg  60, $.r[!x3]
  jz  !racket.moveright.end
    call !FillXY($.r[!x], $.r[!y], " ")
    inc $.r[!x]
    inc $.r[!x2]
    inc $.r[!x3]
    call !FillXY($.r[!x3], $.r[!y3], !chr_racket)
  racket.moveright.end:
endp

proc racket.moveleft_p($.r)
  bg  $.r[!x], 2
  jz  !racket.moveleft_p.end
    dec $.r[!x]
    dec $.r[!x2]
    dec $.r[!x3]
  racket.moveleft_p.end:
endp

proc racket.moveright_p($.r)
  bg  60, $.r[!x3]
  jz  !racket.moveright_p.end
    inc $.r[!x]
    inc $.r[!x2]
    inc $.r[!x3]
  racket.moveright_p.end:
endp
