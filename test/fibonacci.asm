import
  from "crt.lib"
   PrintLn "PRINTLN"
  end from
end import


const
  int Zero    0
  int FbLoops 40
  int MemSize 7
  int I 3
  int V1 1
end const


code
  EntryPoint:
    pushc MemSize
	gpm
	memsz
	gc
	pushc I
	peek 0
	pop
	pushc FbLoops
	peek 1
	pop
	pushc Lp1
	peek 2
	pop
	pushc PRINTLN
	peek 3
	pop
	pushc Zero
	peek 4  
	gpm
	push 3
	invoke
	pushc V1
	peek 5 
	gpm
	push 3
	invoke
	new
	gpm
	peek 6 
	pop
	Lp1:
	  push 5
	  push 6
      mov
	  
	  push 4
	  push 5
	  add
	  
	  push 6
	  push 4
	  mov
	  
	  push 5
	  push 3
	  invoke
	  
	  push 2
	  push 1
	  push 0
	  inc
	  bg
	jz
  pushc EndPoint
  jp
  
  EndPoint:
end code