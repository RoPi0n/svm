uses <bf.asm>
uses <crt.asm>


proc PrintArray($.arr)
var .len, .i             
    push   $.arr
    alen
    pop    $.len
    push   0
    pop    $.i
    invoke !Print("Array: ")
    PrintArray_Loop:
      invoke  !Print($.arr[$.i])
      invoke  !Print(" ")
      gc
      inc     $.i
      bg      $.len, $.i
      jn      !PrintArray_Loop
    invoke !PrintLn(" ")
    rem    $.len
    rem    $.i
    gc
endp 


proc SortArray($.arr)
var .len, .i = 0, .cnterr = 0 
    push   $.arr  
    alen
    pop    $.len
    dec    $.len
    SortArray_Loop:
      rem     $.cnterr
      push    0
      pop     $.cnterr
      rem     $.i
      push    0
      pop     $.i
      SortArray_Loop2:
        push    $.arr[$.i]
        inc     $.i
        push    $.arr[$.i]
        dec     $.i
        be
        gpm
        jz      !SortArray_IfSt1
        jump    !SortArray_IfSt1_End
        SortArray_IfSt1:
          inc     $.cnterr
          push    $.arr[$.i]
          inc     $.i
          push    $.arr[$.i]
          dec     $.i
          peek    $.arr[$.i]
          inc     $.i
          peek    $.arr[$.i]
          dec     $.i
    SortArray_IfSt1_End:
    gc
    inc     $.i
    bg      $.len, $.i
    jn      !SortArray_Loop2
    eq      0, $.cnterr
    jz      !SortArray_Loop
    rem    $.len
    rem    $.i
    rem    $.cnterr
    gc
endp


proc Main()
var .arr
    push   10
    gpm
    push   1
    gpm
    newa
    gc
    pop    $.arr
	
    push   2
    push   5
    push   1
    push   19
    push  -33
    push   4
    push   10
    push   200
    push   7
    push   4

    var .i = 10
    Main.Lp1:
      dec   $.i
      peek  $.arr[$.i]
      push  $.i
    jn    !Main.Lp1
	
    call  !PrintArray($.arr)
    call  !SortArray($.arr)
    call  !PrintArray($.arr)

    invoke !InputLn
endp
