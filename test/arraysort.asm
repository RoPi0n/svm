import
  from "crt.lib"
   PrintLn "PRINTLN"
   Print   "PRINT"
  end from
end import


const
  int  MemSz  9
  int  Zero   0
  int  ArrSz  10
  int  ArrLvl 1
  int  a_0  7
  int  a_1  5
  int  a_2  93
  int  a_3  17
  int  a_4  23
  int  a_5  8
  int  a_6  13
  int  a_7  42
  int  a_8  3
  int  a_9  65
  str  ArrN "Array: "
  str  Spc  " "
end const


code
  EntryPoint:
	pushc  MemSz
	gpm
	memsz
	gc
	
	pushc  ArrSz
	gpm
	pushc  ArrLvl
	gpm
	newarr
	gc
	peek   0
	pop
	
	pushc  Zero
	peek   1
	pop
	
	pushc  a_0
	push   1
	push   0
	arritmpeek
	push   1
	inc
	pop
	pushc  a_1
	push   1
	push   0
	arritmpeek
	push   1
	inc
	pop
	pushc  a_2
	push   1
	push   0
	arritmpeek
	push   1
	inc
	pop
	pushc  a_3
	push   1
	push   0
	arritmpeek
	push   1
	inc
	pop
	pushc  a_4
	push   1
	push   0
	arritmpeek
	push   1
	inc
	pop
	pushc  a_5
	push   1
	push   0
	arritmpeek
	push   1
	inc
	pop
	pushc  a_6
	push   1
	push   0
	arritmpeek
	push   1
	inc
	pop
	pushc  a_7
	push   1
	push   0
	arritmpeek
	push   1
	inc
	pop
	pushc  a_8
	push   1
	push   0
	arritmpeek
	push   1
	inc
	pop
	pushc  a_9
	push   1
	push   0
	arritmpeek
	push   1
	inc
	pop
	
	push   0
	pushc  PrintArray
	gpm
	jc
	gc
	
	push   0
	pushc  SortArray
	gpm
	jc
	gc
	
	push   0
	pushc  PrintArray
	gpm
	jc
	gc
	
	pushc  EndPoint
	gpm
	jp
	
	

  PrintArray:              
    peek   2
	arrlen
	peek   3
	pop
	pushc  Zero
	peek   4
	pop
	pushc  PrintArray_Loop
	peek   5
	pop
	pushc  Print
	peek   6
	pop
	pushc  ArrN
	gpm
	push   6
	invoke
	gc
	PrintArray_Loop:
	  push    4
	  push    2
	  arritmpush
	  push    6
	  invoke
	  pushc   Spc
	  gpm
	  push    6
	  invoke
	  gc
	  push    5
	  push    4
	  inc
	  push    3
	  bg
	  gpm
	  jn
	push   3
	gpm
	pop
	push   4
	gpm
	pop
	push   5
	gpm
	pop
	push   6
	gpm
	pop
	pushc  PrintLn
	gpm
	invoke
	gc
  jr  
	  
	  
	  
  SortArray:
    peek   2
	arrlen
	peek   3
	dec
	pop
	pushc  Zero
	peek   4
	pop
	pushc  SortArray_Loop
	peek   5
	pop
	pushc  SortArray_Loop2
	peek   6
	pop
	pushc  Zero
	peek   7
	pop
	pushc  Zero
	peek   8
	pop
	SortArray_Loop:
	  push    7
	  gpm
	  gc
	  pushc   Zero
	  peek    7
	  pop
	  push    4
	  gpm
	  gc
	  pushc   Zero
	  peek    4
	  pop
	  SortArray_Loop2:
	    pushc   SortArray_IfSt1
		gpm
	    push    4
	    push    2
	    arritmpush
        push    4
		inc
	    push    2
	    arritmpush
		push    4
		dec
		pop
	    bg
		gpm
		jz
		pop
		pushc   SortArray_IfSt1_End
		gpm
		jp
		SortArray_IfSt1:
		  push    7
		  inc
		  pop
		  push    4
	      push    2
	      arritmpush
          push    4
		  inc
	      push    2
	      arritmpush
		  push    4
		  dec
		  pop
		  push    4
	      push    2
	      arritmpeek
          push    4
		  inc
	      push    2
	      arritmpeek
		  push    4
		  dec
		  pop
		SortArray_IfSt1_End:
	    gc
	    push    6
	    push    4
	    inc
	    push    3
	    bg
		gpm
        jn
	  push    5
	  push    7
	  push    8
	  eq
	  gpm
	  jz
	  
	push   3
	gpm
	pop
	push   4
	gpm
	pop
	push   5
	gpm
	pop
	push   6
	gpm
	pop
	push   7
	gpm
	pop
	push   8
	gpm
	pop
	gc
  jr
  
  
	  
  EndPoint:
    gc
end code