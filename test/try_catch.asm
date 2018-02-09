import
  from "crt.lib"
   PrintLn "PRINTLN"
  end from
end import


const
  str Msg  "The exception 'division by zero' catched!"
  str Msg2 "CSVM exception message:"
  str Msg3 ":)"
  int a 10
  int b 0
end const


code
  EntryPoint:
    pushc Finally
	gpm
	pushc Catch
	gpm
	tr
	pushc b
	gpm
	pushc a
	gpm
	div
	trs
  Catch:
    pushc Msg
    gpm
	pushc PrintLn
    gpm
	invoke
	pushc Msg2
    gpm
	pushc PrintLn
    gpm
	invoke
	pushc PrintLn
	gpm
    invoke
  Finally:
    pushc Msg3
	gpm
    pushc PrintLn
    gpm
	invoke
	gc
end code