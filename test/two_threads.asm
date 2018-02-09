import
  from "crt.lib"
   PrintLn "PRINTLN"
  end from
end import


const
  str Thr1Message "I'm thread #1!"
  str Thr2Message "I'm thread #2!"
  int MemSize 3
  int Thread2MemSize 3
end const


code
  EntryPoint:
    pushc MemSize
	gpm
	memsz
	gc
	pushc Thr1Message
	peek 0                       ; [0] = "I'm thread #1!"
	pop
	pushc PrintLn                ; [2] = @println
	peek 1
	pop
	pushc OutputFunction
	peek 2                       ; [3] = @Thread1Method
	pop
	pnull
	pushc Thread2Method         
	cthr                         ; [top] = createthread(@Thread2Method, null)
	rthr                         ; runthread([top])
	
  OutputFunction:
    push 0
	push 1
	invoke
	push 2
	jp

  Thread2Method:
    pushc Thread2MemSize
	gpm
	memsz
	gc
	pushc Thr2Message
	peek 0                       ; [0] = "I'm thread #2!"
	pop
	pushc PrintLn                ; [2] = @println
	peek 1
	pop
	pushc OutputFunction
	peek 2                       ; [3] = @Thread1Method
	pop
	push 2
	jp
end code