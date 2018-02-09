import
  from "crt.lib"
   PrintLn "PRINTLN"
   InputLn "INPUTLN"
  end from
  from "bf.lib"
   StrToFloat "STRTOFLOAT"
  end from
end import


const
  str s_0 "Enter two digits:"
  str s_1 "Summ:"
  int MemSz 2
end const


code
  EntryPoint:
    pushc MemSz
	gpm
	memsz
	gc
	pushc s_0
	gpm
	pushc PrintLn
	gpm
	invoke
	pushc InputLn
	gpm
	invoke
	pushc StrToFloat
	gpm
	invoke
	peek 0
	pop
	pushc InputLn
	gpm
	invoke
	pushc StrToFloat
	gpm
	invoke
	peek 1
	gc
	pop
	push 0
	
	push 1
	add
	pushc s_1
	gpm
	pushc PrintLn
	gpm
	invoke
	pushc PrintLn
	gpm
	invoke
end code