; ball.asm
; *****
; Ball.

; Ball[3]
;        [0] - x
;        [1] - y
;        [2] - moving vector

proc ball.create($.x, $.y, $.startvect)
var .b, .tx = 0, .ty = 0, .tv = 0
  push 3
  gpm
  push 1
  gpm
  newa
  pop  $.b
  mov  $.tx, $.x
  mov  $.ty, $.y
  push $.tx
  peek $.b[!x]
  push $.ty
  peek $.b[!y]
  mov  $.tv, $.startvect
  push $.tv
  peek $.b[!v]
  push $.b
endp

proc ball.back_ox($.b)
  eq $.b[!v], !bvLT
  jn !ball.back_ox.lt
  ;;
  eq $.b[!v], !bvLD
  jn !ball.back_ox.ld
  ;;
  eq $.b[!v], !bvRT
  jn !ball.back_ox.rt
  ;;
  eq $.b[!v], !bvRD
  jn !ball.back_ox.rd
  ;;
  jr
  ;;
  ball.back_ox.lt:
    mov $.b[!v], !bvRT
  jr
  ;;
  ball.back_ox.ld:
    mov $.b[!v], !bvRD
  jr
  ;;
  ball.back_ox.rt:
    mov $.b[!v], !bvLT
  jr
  ;;
  ball.back_ox.rd:
    mov $.b[!v], !bvLD
  jr
endp

proc ball.back_oy($.b)
  eq $.b[!v], !bvLT
  jn !ball.back_oy.lt
  ;;
  eq $.b[!v], !bvLD
  jn !ball.back_oy.ld
  ;;
  eq $.b[!v], !bvRT
  jn !ball.back_oy.rt
  ;;
  eq $.b[!v], !bvRD
  jn !ball.back_oy.rd
  ;;
  jr
  ;;
  ball.back_oy.lt:
    mov $.b[!v], !bvLD
  jr
  ;;
  ball.back_oy.ld:
    mov $.b[!v], !bvLT
  jr
  ;;
  ball.back_oy.rt:
    mov $.b[!v], !bvRD
  jr
  ;;
  ball.back_oy.rd:
    mov $.b[!v], !bvRT
  jr
endp

proc ball.back_xy($.b)
  eq $.b[!v], !bvLT
  jn !ball.back_xy.lt
  ;;
  eq $.b[!v], !bvLD
  jn !ball.back_xy.ld
  ;;
  eq $.b[!v], !bvRT
  jn !ball.back_xy.rt
  ;;
  eq $.b[!v], !bvRD
  jn !ball.back_xy.rd
  ;;
  jr
  ;;
  ball.back_xy.lt:
    mov $.b[!v], !bvRD
  jr
  ;;
  ball.back_xy.ld:
    mov $.b[!v], !bvRT
  jr
  ;;
  ball.back_xy.rt:
    mov $.b[!v], !bvLD
  jr
  ;;
  ball.back_xy.rd:
    mov $.b[!v], !bvLT
  jr
endp

proc ball.racketcheck_a($.r, $.x, $.y)
  call !points_eq($.r[!x], $.r[!y], $.x, $.y)
  call !points_eq($.r[!x3], $.r[!y3], $.x, $.y)
  or
endp

proc ball.racketcheck_b($.r, $.x, $.y)
  call !points_eq($.r[!x2], $.r[!y2], $.x, $.y)
endp

proc ball.moveself($.b)
var .px = 0, .py = 0, .x = 0, .y = 0
  mov  $.px, $.b[!x]
  mov  $.py, $.b[!y]
  eq $.b[!v], !bvLT
  jn !ball.moveself.lt
  ;;
  eq $.b[!v], !bvLD
  jn !ball.moveself.ld
  ;;
  eq $.b[!v], !bvRT
  jn !ball.moveself.rt
  ;;
  eq $.b[!v], !bvRD
  jn !ball.moveself.rd
  ;;
  jr
  ;;
  ball.moveself.lt:
    dec $.b[!x]
    dec $.b[!y]
    mov $.x, $.b[!x]
    mov $.y, $.b[!y]
    dec $.x
    dec $.y
    ;;
    call !border.checkat($.x, $.y)
    gpm
    jn !ball.moveself.bordercheck
    ;;
    call !ball.racketcheck_a($ai_racket, $.x, $.y)
    jn !ball.moveself.racketcheck_a
    ;;
    call !ball.racketcheck_b($ai_racket, $.x, $.y)
    jn !ball.moveself.racketcheck_b
  jump !ball.moveself.end
  ;;
  ball.moveself.ld:
    dec $.b[!x]
    inc $.b[!y]
    mov $.x, $.b[!x]
    mov $.y, $.b[!y]
    dec $.x
    inc $.y
    ;;
    call !border.checkat($.x, $.y)
    gpm
    jn !ball.moveself.bordercheck
    ;;
    call !ball.racketcheck_a($player_racket, $.x, $.y)
    jn !ball.moveself.racketcheck_pa
    ;;
    call !ball.racketcheck_b($player_racket, $.x, $.y)
    jn !ball.moveself.racketcheck_pb
  jump !ball.moveself.end
  ;;
  ball.moveself.rt:
    inc $.b[!x]
    dec $.b[!y]
    mov $.x, $.b[!x]
    mov $.y, $.b[!y]
    inc $.x
    dec $.y            
    ;;
    call !border.checkat($.x, $.y)
    gpm
    jn !ball.moveself.bordercheck
    ;;
    call !ball.racketcheck_a($ai_racket, $.x, $.y)
    jn !ball.moveself.racketcheck_a
    ;;
    call !ball.racketcheck_b($ai_racket, $.x, $.y)
    jn !ball.moveself.racketcheck_b
  jump !ball.moveself.end
  ;;
  ball.moveself.rd:
    inc $.b[!x]
    inc $.b[!y]
    mov $.x, $.b[!x]
    mov $.y, $.b[!y]
    inc $.x
    inc $.y        
    ;;
    call !border.checkat($.x, $.y)
    gpm
    jn !ball.moveself.bordercheck
    ;;
    call !ball.racketcheck_a($player_racket, $.x, $.y)
    jn !ball.moveself.racketcheck_pa
    ;;
    call !ball.racketcheck_b($player_racket, $.x, $.y)
    jn !ball.moveself.racketcheck_pb
  jump !ball.moveself.end
  ;;
  ball.moveself.bordercheck:
    call !ball.back_ox($.b)
  jump !ball.moveself.end
  ;;
  ball.moveself.racketcheck_a:
    call !ball.back_xy($.b)
  jump !ball.moveself.end
  ;;
  ball.moveself.racketcheck_b:
    call !ball.back_oy($.b)
  jump !ball.moveself.end
  ;;
  ball.moveself.racketcheck_pa:
    call !ball.back_xy($.b)
    inc  $score
  jump !ball.moveself.end
  ;;
  ball.moveself.racketcheck_pb:
    call !ball.back_oy($.b)
    inc  $score
  jump !ball.moveself.end
  ;;
  ball.moveself.end:
    call !FillXY($.px, $.py, " ")
    call !FillXY($.b[!x], $.b[!y], !chr_ball)
    rem  $.x
    rem  $.y
    rem  $.px
    rem  $.py
endp
