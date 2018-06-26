; Virtual stack.
;
; [0] - *value
; [1] -  next node exists (true/false)
; [2] - *next node

uses <bf.asm>

proc vstack.getval($.hn)
  push $.hn[0]
endp

proc vstack.nextexist($.hn)
  eq $.hn[1], !true
  jn !vstack.nextexist.if_true
  push !false
  jump !vstack.nextexist.exit
  vstack.nextexist.if_true:
    push !true
  vstack.nextexist.exit:
endp

proc vstack.getlast($.hn)
var .r
  vstack.getlast.lp:
    call !vstack.nextexist($.hn)
    pop  $.r
    eq   $.r, !true
    rem  $.r
    jz   !vstack.getlast.lp_exit
    movl $.hn, $.hn[2]
    jump !vstack.getlast.lp
  vstack.getlast.lp_exit:
  push $.hn
endp

proc vstack.dellast($.hn)
var .r, .phn
  vstack.dellast.lp:
    call !vstack.nextexist($.hn)
    pop  $.r
    eq   $.r, !true
    rem  $.r
    jz   !vstack.dellast.lp_exit
    movl $.phn, $.hn
    movl $.hn, $.hn[2]
    jump !vstack.dellast.lp
  vstack.dellast.lp_exit:
  push $.hn
  gpa
  pop
  gpm  $.hn[1]
  mov  $.phn[1], !false
endp

proc vstack.addnode($.hn, $.val)
var .r
  vstack.addnode.lp:
    call !vstack.nextexist($.hn)
    pop  $.r
    eq   $.r, !true
    rem  $.r
    jz   !vstack.addnode.lp_exit
    movl $.hn, $.hn[2]
    jump !vstack.addnode.lp
  vstack.addnode.lp_exit:
  push 3
  gpm
  push 1
  gpm
  newa
  peek $.hn[2]
  mov  $.hn[1], !true
  movl $.hn, $.hn[2]
  push $.val
  peek $.hn[0]
  push !false
  peek $.hn[1]
endp