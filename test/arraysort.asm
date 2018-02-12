import PrintLn "crt.lib" "PRINTLN"
import Print "crt.lib" "PRINT"

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

var a,b,c,d,e,f,g,h,i


PrintArray:              
    peek   $c
	alen
	peek   $d
	pop
	pushc  Zero
	peek   $e
	pop
	pushc  PrintArray_Loop
	peek   $f
	pop
	pushc  Print
	peek   $g
	pop
	pushc  ArrN
	gpm
	push   $g
	invoke
	gc
	PrintArray_Loop:
	  push    $e
	  push    $c
	  pushai
	  push    $g
	  invoke
	  pushc   Spc
	  gpm
	  push    $g
	  invoke
	  gc
	  push    $f
	  push    $e
	  inc
	  push    $d
	  bg
	  gpm
	  jn
	push   $d
	gpm
	pop
	push   $e
	gpm
	pop
	push   $f
	gpm
	pop
	push   $g
	gpm
	pop
	pushc  PrintLn
	gpm
	invoke
	gc
jr  
	  
	  
	  
SortArray:
    peek   $c
	alen
	peek   $d
	dec
	pop
	pushc  Zero
	peek   $e
	pop
	pushc  SortArray_Loop
	peek   $f
	pop
	pushc  SortArray_Loop2
	peek   $g
	pop
	pushc  Zero
	peek   $h
	pop
	pushc  Zero
	peek   $i
	pop
	SortArray_Loop:
	  push    $h
	  gpm
	  gc
	  pushc   Zero
	  peek    $h
	  pop
	  push    $e
	  gpm
	  gc
	  pushc   Zero
	  peek    $e
	  pop
	  SortArray_Loop2:
	    pushc   SortArray_IfSt1
		gpm
	    push    $e
	    push    $c
	    pushai
        push    $e
		inc
	    push    $c
	    pushai
		push    $e
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
		  push    $h
		  inc
		  pop
		  push    $e
	      push    $c
	      pushai
          push    $e
		  inc
	      push    $c
	      pushai
		  push    $e
		  dec
		  pop
		  push    $e
	      push    $c
	      peekai
          push    $e
		  inc
	      push    $c
	      peekai
		  push    $e
		  dec
		  pop
		SortArray_IfSt1_End:
	    gc
	    push    $g
	    push    $e
	    inc
	    push    $d
	    bg
		gpm
        jn
	  push    $f
	  push    $h
	  push    $i
	  eq
	  gpm
	  jz
	  
	push   $d
	gpm
	pop
	push   $e
	gpm
	pop
	push   $f
	gpm
	pop
	push   $g
	gpm
	pop
	push   $h
	gpm
	pop
	push   $i
	gpm
	pop
	gc
jr



Main:
	pushc  MemSz
	gpm
	msz
	gc
	
	pushc  ArrSz
	gpm
	pushc  ArrLvl
	gpm
	newa
	gc
	peek   $a
	pop
	
	pushc  Zero
	peek   $b
	pop
	
	pushc  a_0
	push   $b
	push   $a
	peekai
	push   $b
	inc
	pop
	pushc  a_1
	push   $b
	push   $a
	peekai
	push   $b
	inc
	pop
	pushc  a_2
	push   $b
	push   $a
	peekai
	push   $b
	inc
	pop
	pushc  a_3
	push   $b
	push   $a
	peekai
	push   $b
	inc
	pop
	pushc  a_4
	push   $b
	push   $a
	peekai
	push   $b
	inc
	pop
	pushc  a_5
	push   $b
	push   $a
	peekai
	push   $b
	inc
	pop
	pushc  a_6
	push   $b
	push   $a
	peekai
	push   $b
	inc
	pop
	pushc  a_7
	push   $b
	push   $a
	peekai
	push   $b
	inc
	pop
	pushc  a_8
	push   $b
	push   $a
	peekai
	push   $b
	inc
	pop
	pushc  a_9
	push   $b
	push   $a
	peekai
	push   $b
	inc
	pop
	
	push   $a
	pushc  PrintArray
	gpm
	jc
	gc
	
	push   $a
	pushc  SortArray
	gpm
	jc
	gc
	
	push   $a
	pushc  PrintArray
	gpm
	jc
	gc