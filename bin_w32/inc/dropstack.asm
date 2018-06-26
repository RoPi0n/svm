; DropStack.
;
; store <var> & load <var> operations.

uses <vstack.asm>

var __DropStack

proc __InitDropStack()
  push 3
  push 1
  newa
  pop  $__DropStack
  push !false
  peek $__DropStack[1]
endp

proc __FreeDropStack()
  __FreeDropStack.Lp:
    call !vstack.nextexist($__DropStack)
    jz   !__FreeDropStack.Fn
    call !vstack.getlast($__DropStack)
    call !vstack.getval
    rem
    call !vstack.dellast($__DropStack)
    jump !__FreeDropStack.Lp
  __FreeDropStack.Fn:
  rem  $__DropStack[1]
  push $__DropStack
  gpa
  pop
  gc
endp

proc store($.val)
var .m
  new  $.m
  mov  $.m, $.val
  call !vstack.addnode($__DropStack, $.m)
endp


proc load($.val)
var .m
  call !vstack.getlast($__DropStack)
  call !vstack.getval
  pop  $.m
  mov  $.val, $.m
  rem  $.m
  call !vstack.dellast($__DropStack)
endp