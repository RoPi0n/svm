; Vector.
;
; [0] - *value
; [1] -  next node exists (true/false)
; [2] - *next node

uses <bf.asm>

proc vector.getval($.v)
  push $.v[0]
endp

proc vector.nextexist($.v)
  eq $.v[1], !true
  jn !vector.nextexist.if_true
  push !false
  jump !vector.nextexist.exit
  vector.nextexist.if_true:
    push !true
  vector.nextexist.exit:
endp

proc vector.countnodes($.v)
var .r, .cnt = 0
  vector.countnodes.lp:
    call !vector.nextexist($.v)
    pop  $.r
    eq   $.r, !true
    rem  $.r
    jz   !vector.countnodes.lp_exit
    movl $.v, $.v[2]
    inc  $.cnt
    jump !vector.countnodes.lp
  vector.countnodes.lp_exit:
  push $.cnt
endp

proc vector.count($.v)
  jump !vector.getval($.v)

proc vector.nodeat($.v, $.index)
var .r, .cnt = 0
  vector.nodeat.lp:
    call !vector.nextexist($.v)
    pop  $.r
    eq   $.r, !true
    rem  $.r
    jz   !vector.nodeat.lp_exit
    be   $.cnt, $.index
    movl $.v, $.v[2]
    inc  $.cnt
    jn   !vector.nodeat.lp_exit
    jump !vector.nodeat.lp
  vector.nodeat.lp_exit:
  push $.v
  rem  $.cnt
endp

proc vector.at($.v, $.index)
  call !vector.nodeat($.v, $.index)
  call !vector.getval()
endp

proc vector.getlast($.v)
var .r
  vector.getlast.lp:
    call !vector.nextexist($.v)
    pop  $.r
    eq   $.r, !true
    rem  $.r
    jz   !vector.getlast.lp_exit
    movl $.v, $.v[2]
    jump !vector.getlast.lp
  vector.getlast.lp_exit:
  push $.v
endp

proc vector.popfirst($.v)
var .n
  dec  $.v[0]
  push $.v[2]
  call !vector.getval
  movl $.n, $.v[2]
  mov  $.v[1], $.n[1]
  rem  $.n[1]
  push $.n
  gpa
  pop
  movl $.v[2], $.n[2]
endp

proc vector.dellast($.v)
var .r, .v
  dec $.v[0]
  vector.dellast.lp:
    call !vector.nextexist($.v)
    pop  $.r
    eq   $.r, !true
    rem  $.r
    jz   !vector.dellast.lp_exit
    movl $.pv, $.v
    movl $.v, $.v[2]
    jump !vector.dellast.lp
  vector.dellast.lp_exit:
  push $.v
  gpa
  pop
  gpm  $.v[1]
  mov  $.pv[1], !false
endp

proc vector.popback($.v)
  call !vector.getlast($.v)
  call !vector.getval
  call !vector.dellast($.v)
endp

proc vector.peekback($.v)
  call !vector.getlast($.v)
  call !vector.getval
endp

proc vector.pushback($.v, $.val)
var .r
  inc $.v[0]
  vector.pushback.lp:
    call !vector.nextexist($.v)
    pop  $.r
    eq   $.r, !true
    rem  $.r
    jz   !vector.pushback.lp_exit
    movl $.v, $.v[2]
    jump !vector.pushback.lp
  vector.pushback.lp_exit:
  push 3
  gpm
  push 1
  gpm
  newa
  peek $.v[2]
  mov  $.v[1], !true
  movl $.v, $.v[2]
  push $.val
  peek $.v[0]
  push !false
  peek $.v[1]
endp

proc vector.delete($.v, $.index)
var .n, .t
  dec  $.v[0]
  push $.index
  jn !vector.delete.b
    be $.v[0], $.index
    jn !vector.delete.b.b
      movl $.t, $.v[2]
      rem  $.t[1]
      mov  $.v[1], !false
      push $.t
      gpa
      pop
      jump !vector.delete.exit
    vector.delete.b.b:
      movl $.t, $.v[2]
      movl $.n, $.t[2]
      rem  $.t[1]
      push $.v[2]
      gpa
      pop
      movl $.v[2], $.n
      jump !vector.delete.exit
  vector.delete.b:
    dec  $.index
    call !vector.nodeat($.v, $.index)
    pop  $.v
    movl $.t, $.v[2]
    movl $.n, $.v[2]
    mov  $.v[1], $.n[1]
    movl $.v[2], $.t[2]
    rem  $.n[1]
    push $.n
    gpa
    pop
  vector.delete.exit:
endp

proc vector.foreach($.v, $.callbackproc)
var .r
  vector.foreach.lp:
    call !vector.nextexist($.v)
    pop  $.r
    eq   $.r, !true
    rem  $.r
    jz   !vector.foreach.lp_exit
    movl $.v, $.v[2]
    call !vector.getval($.v)
    call $.callbackproc()
    jump !vector.foreach.lp
  vector.foreach.lp_exit:
endp

proc vector.foreach_withoutlast($.v, $.callbackproc)
var .r
  vector.foreach_withoutlast.lp:
    call !vector.nextexist($.v)
    pop  $.r
    eq   $.r, !true
    rem  $.r
    jz   !vector.foreach_withoutlast.lp_exit
    movl $.v, $.v[2]
    call !vector.nextexist($.v)
    pop  $.r
    eq   $.r, !true
    rem  $.r
    jz   !vector.foreach_withoutlast.lp_exit
    call !vector.getval($.v)
    call $.callbackproc()
    jump !vector.foreach_withoutlast.lp
  vector.foreach_withoutlast.lp_exit:
endp

proc vector.create()
var .v
  push 3
  push 1
  newa
  pop  $.v
  push 0
  peek $.v[0]
  push !false
  peek $.v[1]
  push $.v
endp

proc vector.free($.v)
var .i
  vector.free.lp:
    call !vector.nextexist($.v)
    jz   !vector.free.fn
    call !vector.getlast($.v)
    pop  $.i
    rem  $.i[1]
    call !vector.dellast($.v)
    jump !vector.free.lp
  vector.free.fn:
  rem  $.v[0]
  rem  $.v[1]
  push $.v
  gpa
  pop
endp
