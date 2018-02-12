import PrintLn "crt.lib" "PRINTLN"


int Zero    0
int FbLoops 40
int I 3
int V1 1

var a,b,c,d,e,println,lp1

Main:
  push !I
  peek $a
  pop
  pushc FbLoops
  peek $b
  pop
  push !Lp1
  peek $Lp1
  pop
  push !PRINTLN
  peek $println
  pop
  pushc Zero
  peek $c  
  gpm
  push $println
  invoke
  pushc V1
  peek $d
  gpm
  push $println
  invoke
  new
  gpm
  peek $e 
  pop
  Lp1:
    push $d
    push $e
    mov
	  
	push $c
	push $d
	add
	 
	push $e
	push $c
	mov
	  
	push $d
	push $println
	invoke
	 
	push $Lp1
	push $b
	push $a
	inc
	bg
  jz