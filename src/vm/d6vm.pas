program d6vm;

uses
  SysUtils,
  dynlibs,
  variants,
  Classes;

{***** OP Codes ***************************************************************}
type
  TComand = (
    bcPH,     // [top] = [var]
    bcPK,     // [var] = [top]
    bcPP,     // pop
    bcSWP,    // [top] <-> [top-1]
    bcJP,     // jump [top]
    bcJZ,     // [top] == 0 ? jp [top-1]
    bcJN,     // [top] <> 0 ? jp [top-1]
    bcJC,     // jp [top] & push callback point as ip+1
    bcJR,     // jp to last callback point & rem last callback point

    bcEQ,     // [top] == [top-1] ? [top] = 1 : [top] = 0
    bcBG,     // [top] >  [top-1] ? [top] = 1 : [top] = 0
    bcBE,     // [top] >= [top-1] ? [top] = 1 : [top] = 0

    bcNOT,    // [top] = ![top]
    bcAND,    // [top] = [top] and [top-1]
    bcOR,     // [top] = [top] or  [top-1]
    bcXOR,    // [top] = [top] xor [top-1]
    bcSHR,    // [top] = [top] shr [top-1]
    bcSHL,    // [top] = [top] shl [top-1]

    bcNEG,    // [top] = -[top]
    bcINC,    // [top]++
    bcDEC,    // [top]--
    bcADD,    // [top] = [top] + [top-1]
    bcSUB,    // [top] = [top] - [top-1]
    bcMUL,    // [top] = [top] * [top-1]
    bcDIV,    // [top] = [top] / [top-1]
    bcMOD,    // [top] = [top] % [top-1]
    bcIDIV,   // [top] = [top] \ [top-1]

    bcMV,     // [top]^ = [top-1]^
    bcMVBP,   // [top]^^ = [top-1]^
    bcMVP,    // [top]^ = [top-1]
	
    bcMS,     // memory map size = [top]
    bcNW,     // [top] = @new
    bcMC,     // copy [top]
    bcMD,     // double [top]
    bcRM,     // rem @[top]
    bcNA,     // [top] = @new array[  [top]  ] of pointer
    bcSF,     // sizeof( [top] as object )
    bcAL,     // length( [top] as array )
    bcSL,     // setlength( [top] as array, {stack} )

    bcPA,     // push ([top] as array)[top-1]
    bcSA,     // peek [top-2] -> ([top] as array)[top-1]

    bcGPM,    // add pointer to TMem to grabber task-list
    bcGPA,    // add pointer to TMemArr to grabber task-list
    bcGC,     // run grabber

    bcPHC,    // push const

    bcPHEXMP, // push pointer to external method
    bcINV,    // call external method
    bcINVBP,  // call external method by pointer [top]

    bcPHN,    // push null
    bcCTHR,   // [top] = thread(method = [top], arg = [top+1]):id
    bcSTHR,   // suspendthread(id = [top])
    bcRTHR,   // resumethread(id = [top])
    bcTTHR,   // terminatethread(id = [top])

    bcTR,    // try @block_catch = [top], @block_end = [top+1]
    bcTRS,   // success exit from try/catch block
    bcTRR,   // raise exception, message = [top]

    bcPHS,   // [top]  --> [top2]
    bcPKS,   // [top2] --> [top]
    bcPPS    // [top2] --> X
    );

{***** Some consts ************************************************************}
  //const
  // null = '';

{***** Some types *************************************************************}
type
  TInstructionPointer = cardinal;
  //PInstructionPointer = ^TInstructionPointer;
  TMem = variant;
  PMem = ^TMem;
  TMemArr = array of pointer;
  PMemArr = ^TMemArr;
  TMemType = (mtNull, mtVar, mtArray, mtPointer);
  TMemory = array of pointer;
  PPointer = ^Pointer;
  TByteArr = array of byte;
  PByteArr = ^TByteArr;

{***** Some functions *********************************************************}
  procedure VMError(m: string);
  begin
    writeln(m);
    halt;
  end;

  procedure CutLeftBytes(pb: PByteArr; cnt: cardinal);
  var
    i: cardinal;
  begin
    for i := 0 to cardinal(length(pb^)) - cnt do
      pb^[i] := pb^[i + cnt];
    setlength(pb^, cardinal(length(pb^)) - cnt);
  end;

{***** Constant section *******************************************************}
type
  TConstType = (
    ctUnsigned64,
    ctInt64,
    ctDouble,
    ctString,
    ctStream
    );

type
  TConstSection = object
  private
    constants: array of variant;
    procedure SetSize(sz: cardinal);
    procedure SetConst(id: cardinal; v: variant);
  public
    procedure Parse(pb: PByteArr);
    function GetConst(id: cardinal): variant;
  end;

  PConstSection = ^TConstSection;

  procedure TConstSection.SetSize(sz: cardinal);
  begin
    setlength(self.constants, sz);
  end;

  procedure TConstSection.SetConst(id: cardinal; v: variant);
  begin
    self.constants[id] := v;
  end;

  procedure TConstSection.Parse(pb: PByteArr);
  var
    consts_count, bpos: cardinal;
    sl: word;
    s: string;
    stl: cardinal;
    st: TStream;
  begin
    consts_count := cardinal((pb^[0] shl 24) + (pb^[1] shl 16) +
      (pb^[2] shl 8) + pb^[3]);
    bpos := 4;
    self.SetSize(consts_count);
    while consts_count > 0 do
    begin
      case TConstType(pb^[bpos]) of
        ctUnsigned64:
        begin
          self.SetConst(
            cardinal(length(self.constants)) - consts_count,
            cardinal((pb^[bpos + 1] shl 24) + (pb^[bpos + 2] shl 16) +
            (pb^[bpos + 3] shl 8) + pb^[bpos + 4])
            );
          Inc(bpos, 5);
        end;

        ctInt64:
        begin
          self.SetConst(
            cardinal(length(self.constants)) - consts_count,
            int64((pb^[bpos + 1] shl 24) + (pb^[bpos + 2] shl 16) +
            (pb^[bpos + 3] shl 8) + pb^[bpos + 4])
            );
          Inc(bpos, 5);
        end;

        ctDouble:
        begin
          self.SetConst(
            cardinal(length(self.constants)) - consts_count,
            double((pb^[bpos + 1] shl 56) +
            (pb^[bpos + 2] shl 48) + (pb^[bpos + 3] shl 40) +
            (pb^[bpos + 4] shl 32) + (pb^[bpos + 5] shl 24) +
            (pb^[bpos + 6] shl 16) + (pb^[bpos + 7] shl 8) +
            pb^[bpos + 8])
            );
          Inc(bpos, 9);
        end;

        ctString:
        begin
          sl := (pb^[bpos + 1] shl 8) + pb^[bpos + 2];
          Inc(bpos, sl + 3);
          s := '';
          while sl > 0 do
          begin
            s := s + chr(pb^[bpos - sl]);
            Dec(sl);
          end;
          self.SetConst(cardinal(length(self.constants)) - consts_count, s);
        end;

        ctStream:
        begin
          stl := cardinal((pb^[bpos + 1] shl 24) +
            (pb^[bpos + 2] shl 16) + (pb^[bpos + 3] shl 8) +
            pb^[bpos + 4]);
          Inc(bpos, stl + 5);
          st := TStream.Create;
          while sl > 0 do
          begin
            st.WriteByte(pb^[bpos - stl]);
            Dec(stl);
          end;
          self.SetConst(cardinal(length(self.constants)) -
            consts_count, cardinal(Pointer(@st)));
        end;
        else
          VMError('Error: resource section format not supported.');
      end;
      Dec(consts_count);
    end;
    CutLeftBytes(pb, bpos);
  end;

  function TConstSection.GetConst(id: cardinal): variant;
  begin
    Result := self.constants[id];
  end;

{***** Library list section ***************************************************}
type
  TLibraryListSection = object
  private
    libs: array of THandle;
    procedure SetSize(sz: word);
    procedure SetLibH(id: word; h: THandle);
  public
    procedure Parse(pb: PByteArr; mainclasspath: string);
    function GetLibH(id: word): THandle;
  end;

  procedure TLibraryListSection.SetSize(sz: word);
  begin
    setlength(self.libs, sz);
  end;

  procedure TLibraryListSection.SetLibH(id: word; h: THandle);
  begin
    self.libs[id] := h;
  end;

  procedure TLibraryListSection.Parse(pb: PByteArr; mainclasspath: string);
  var
    bpos: cardinal;
    lib_count, sl: word;
    s: string;
  begin
    lib_count := cardinal((pb^[0] shl 8) + pb^[1]);
    bpos := 2;
    self.SetSize(lib_count);
    while lib_count > 0 do
    begin
      sl := (pb^[bpos] shl 8) + pb^[bpos + 1];
      Inc(bpos, sl + 2);
      s := '';
      while sl > 0 do
      begin
        s := s + chr(pb^[bpos - sl]);
        Dec(sl);
      end;
      if FileExists(ExtractFilePath(mainclasspath) + s) then
        s := ExtractFilePath(mainclasspath) + s
      else if FileExists(ExtractFilePath(ParamStr(0)) + 'lib\' + s) then
        s := ExtractFilePath(ParamStr(0)) + 'lib\' + s
      else if FileExists(ExtractFilePath(ParamStr(0)) + s) then
        s := ExtractFilePath(ParamStr(0)) + s
      else
        VMError('Error: can''t find library "' + s + '".');
      self.SetLibH(cardinal(length(self.libs)) - lib_count, LoadLibrary(s));
      Dec(lib_count);
    end;
    CutLeftBytes(pb, bpos);
  end;

  function TLibraryListSection.GetLibH(id: word): THandle;
  begin
    Result := self.libs[id];
  end;

{***** Import section *********************************************************}
type
  TExternalFunction = procedure(st: pointer); cdecl;
  PExternalFunction = ^TExternalFunction;

type
  TImportSection = object
  private
    methods: array of PExternalFunction;
    procedure SetSize(sz: cardinal);
    procedure SetFunc(id: cardinal; p: PExternalFunction);
  public
    libs: TLibraryListSection;
    procedure Parse(pb: PByteArr; mainclasspath: string);
    function GetFunc(id: cardinal): PExternalFunction;
  end;

  PImportSection = ^TImportSection;

  procedure TImportSection.SetSize(sz: cardinal);
  begin
    setlength(self.methods, sz);
  end;

  procedure TImportSection.SetFunc(id: cardinal; p: PExternalFunction);
  begin
    self.methods[id] := p;
  end;

  procedure TImportSection.Parse(pb: PByteArr; mainclasspath: string);
  var
    methods_count, bpos: cardinal;
    lb: word;
    sl: byte;
    s: string;
  begin
    libs.Parse(pb, mainclasspath);
    if length(libs.libs) > 0 then
    begin
      methods_count := cardinal((pb^[0] shl 24) + (pb^[1] shl 16) +
        (pb^[2] shl 8) + pb^[3]);
      bpos := 4;
      self.SetSize(methods_count);
      while methods_count > 0 do
      begin
        lb := (pb^[bpos] shl 8) + pb^[bpos + 1];
        sl := pb^[bpos + 2];
        Inc(bpos, sl + 3);
        s := '';
        while sl > 0 do
        begin
          s := s + chr(pb^[bpos - sl]);
          Dec(sl);
        end;
        self.SetFunc(cardinal(length(self.methods)) - methods_count,
          GetProcAddress(libs.GetLibH(lb), s));
        Dec(methods_count);
      end;
      CutLeftBytes(pb, bpos);
    end;
  end;

  function TImportSection.GetFunc(id: cardinal): PExternalFunction;
  begin
    Result := self.methods[id];
  end;

{***** Memory ops *************************************************************}
  function NewMemV(v: variant): PMem;
  begin
    new(Result);
    Result^ := v;
  end;

  function NewMem: PMem;
  begin
    new(Result);
  end;

  procedure RemMem(p: PMem);
  begin
    dispose(p);
  end;

{***** Stack ******************************************************************}
type
  TStack = object
  public
    items: array of pointer;
    procedure push(p: pointer);
    function peek: pointer;
    procedure pop;
    function popv: pointer;
    procedure swp;
  end;

type
  PStack = ^TStack;

  procedure TStack.push(p: pointer);
  begin
    setlength(self.items, length(self.items) + 1);
    self.items[length(self.items) - 1] := p;
  end;

  function TStack.peek: pointer;
  begin
    Result := self.items[length(self.items) - 1];
  end;

  procedure TStack.pop;
  begin
    setlength(self.items, length(self.items) - 1);
  end;

  function TStack.popv: pointer;
  begin
    Result := self.items[length(self.items) - 1];
    setlength(self.items, length(self.items) - 1);
  end;

  procedure TStack.swp;
  var
    p: pointer;
  begin
    p := self.items[length(self.items) - 2];
    self.items[length(self.items) - 2] := self.items[length(self.items) - 1];
    self.items[length(self.items) - 1] := p;
  end;

{***** New array **************************************************************}

type
  TSizeArr = array of cardinal;
  PSizeArr = ^TSizeArr;

  function NewArr_Sub(size_arr: PSizeArr; lvl: word): PMemArr;
  var
    i: cardinal;
  begin
    if lvl > 0 then
    begin
      new(Result);
      setlength(Result^, size_arr^[length(size_arr^) - lvl]);
      for i := 0 to size_arr^[length(size_arr^) - lvl] do
      begin
        Result^[i] := NewArr_Sub(size_arr, lvl - 1);
      end;
    end
    else
      Result := nil;
  end;

  function NewArr(stk: PStack; lvl: word): PMemArr;
  var
    size_arr: TSizeArr;
    i: word;
  begin
    SetLength(size_arr, lvl);
    for i := 0 to lvl - 1 do
      size_arr[i] := PMem(stk^.popv)^;
    Result := NewArr_Sub(@size_arr, lvl);
  end;

{***** CallBack stack *********************************************************}
type
  TCallBackStack = object
  public
    items: array of TInstructionPointer;
    procedure push(ip: TInstructionPointer);
    function peek: TInstructionPointer;
    function popv: TInstructionPointer;
    procedure pop;
  end;

  procedure TCallBackStack.push(ip: TInstructionPointer);
  begin
    setlength(self.items, length(self.items) + 1);
    self.items[length(self.items) - 1] := ip;
  end;

  function TCallBackStack.popv: TInstructionPointer;
  begin
    Result := self.items[length(items) - 1];
    setlength(self.items, length(self.items) - 1);
  end;

  function TCallBackStack.peek: TInstructionPointer;
  begin
    Result := self.items[length(self.items) - 1];
  end;

  procedure TCallBackStack.pop;
  begin
    setlength(self.items, length(self.items) - 1);
  end;

{***** Try/Catch block manager ************************************************}
type
  TTRBlock = record
    CatchPoint, EndPoint: TInstructionPointer;
  end;

  TTRBlocks = object
  public
    trblocks: array of TTRBlock;
    procedure add(CP, EP: TInstructionPointer);
    function TR_Catch(E: Exception): TInstructionPointer;
    function TR_Finally: TInstructionPointer;
  end;

  procedure TTRBlocks.add(CP, EP: TInstructionPointer);
  begin
    setlength(self.trblocks, length(self.trblocks) + 1);
    with self.trblocks[length(self.trblocks) - 1] do
    begin
      CatchPoint := CP;
      EndPoint := EP;
    end;
  end;

  function TTRBlocks.TR_Catch(E: Exception): TInstructionPointer;
  begin
    if Length(self.trblocks) > 0 then
    begin
      Result := self.trblocks[length(self.trblocks) - 1].CatchPoint;
      setlength(self.trblocks, length(self.trblocks) - 1);
    end
    else
      raise E;
  end;

  function TTRBlocks.TR_Finally: TInstructionPointer;
  begin
    Result := self.trblocks[length(self.trblocks) - 1].CatchPoint;
    setlength(self.trblocks, length(self.trblocks) - 1);
  end;

{***** Grabber ****************************************************************}
type
  TGrabberTask = record
    obj_p: pointer;
    obj_t: TMemType;
  end;

type
  TGrabber = object
  private
    tasks: array of TGrabberTask;
  public
    procedure AddTask(p: Pointer; t: TMemType);
    procedure Grab;
  end;

  procedure TGrabber.AddTask(p: Pointer; t: TMemType);
  begin
    SetLength(self.tasks, length(self.tasks) + 1);
    with self.tasks[length(self.tasks) - 1] do
    begin
      obj_p := p;
      obj_t := t;
    end;
  end;

  procedure TGrabber.Grab;
  var
    i: cardinal;
  begin
    if Length(self.tasks) > 0 then
    begin
      for i := 0 to length(self.tasks) - 1 do
        case self.tasks[i].obj_t of
          mtVar: Dispose(PMem(self.tasks[i].obj_p));
          mtArray: Dispose(PMemArr(self.tasks[i].obj_p));
          else
            Error(reInvalidCast);
        end;
      SetLength(self.tasks, 0);
    end;
  end;

{***** VM *********************************************************************}
type
  TVM = object
  public
    mainclasspath: string;
    mem: TMemory;
    stack, stack2: TStack;
    cbstack: TCallBackStack;
    bytes: PByteArr;
    ip,end_ip: TInstructionPointer;
    grabber: TGrabber;
    consts: PConstSection;
    extern_methods: PImportSection;
    try_blocks: TTRBlocks;
    procedure Run;
    procedure RunThread;
    procedure LoadByteCodeFromFile(fn: string);
    procedure LoadByteCodeFromArray(b: TByteArr);
  end;

  TVMThread = class(TThread)
  public
    vm: TVM;
    constructor Create(bytes: PByteArr; consts: PConstSection;
      extern_methods: PImportSection; method: TInstructionPointer;
      arg: pointer);
    procedure Execute; override;
  end;

  constructor TVMThread.Create(bytes: PByteArr; consts: PConstSection;
    extern_methods: PImportSection; method: TInstructionPointer;
    arg: pointer);
  begin
    FreeOnTerminate := True;
    vm.bytes := bytes;
    vm.end_ip := length(bytes^);
    vm.consts := consts;
    vm.extern_methods := extern_methods;
    vm.stack.push(arg);
    vm.stack.push(self);
    vm.ip := method;
    inherited Create(True);
  end;

  procedure TVMThread.Execute;
  begin
    vm.RunThread;
  end;

  procedure TVM.RunThread;
  var
    p: pointer;
  begin
    repeat
      try
        while self.ip < self.end_ip do
          case TComand(self.bytes^[self.ip]) of
            bcPH:
            begin
              self.stack.push(self.mem[cardinal(
                (self.bytes^[self.ip + 1] shl 24) + (self.bytes^[self.ip + 2] shl 16) +
                (self.bytes^[self.ip + 3] shl 8) +
                self.bytes^[self.ip + 4])]);
              Inc(self.ip, 5);
            end;

            bcPK:
            begin
              self.mem[
                cardinal((self.bytes^[self.ip + 1] shl 24) +
                (self.bytes^[self.ip + 2] shl 14) + (self.bytes^[self.ip + 3] shl 8) +
                self.bytes^[self.ip + 4])
                ] := self.stack.peek;
              Inc(self.ip, 5);
            end;

            bcPP:
            begin
              self.stack.pop;
              Inc(self.ip);
            end;

            bcSWP:
            begin
              self.stack.swp;
              Inc(self.ip);
            end;

            bcJP:
            begin
              self.ip := PMem(self.stack.popv)^;
            end;

            bcJZ:
            begin
              if PMem(self.stack.popv)^ = 0 then
                self.ip := PMem(self.stack.popv)^
              else
                Inc(self.ip);
            end;

            bcJN:
            begin
              if PMem(self.stack.popv)^ <> 0 then
                self.ip := PMem(self.stack.popv)^
              else
                Inc(self.ip);
            end;

            bcJC:
            begin
              self.cbstack.push(self.ip + 1);
              self.ip := PMem(self.stack.popv)^;
            end;

            bcJR:
            begin
              self.ip := Self.cbstack.popv;
            end;

            bcEQ:
            begin
              p := self.stack.popv;
              if PMem(p)^ = PMem(self.stack.popv)^ then
                self.stack.push(NewMemV(1))
              else
                self.stack.push(NewMemV(0));
              Inc(self.ip);
            end;

            bcBG:
            begin
              p := self.stack.popv;
              if PMem(p)^ > PMem(self.stack.popv)^ then
                self.stack.push(NewMemV(1))
              else
                self.stack.push(NewMemV(0));
              Inc(self.ip);
            end;

            bcBE:
            begin
              p := self.stack.popv;
              if PMem(p)^ >= PMem(self.stack.popv)^ then
                self.stack.push(NewMemV(1))
              else
                self.stack.push(NewMemV(0));
              Inc(self.ip);
            end;

            bcNOT:
            begin
              PMem(self.stack.peek)^ := not PMem(self.stack.peek)^;
              Inc(self.ip);
            end;

            bcAND:
            begin
              p := self.stack.popv;
              PMem(p)^ := PMem(p)^ and PMem(self.stack.popv)^;
              self.stack.push(p);
              Inc(self.ip);
            end;

            bcOR:
            begin
              p := self.stack.popv;
              PMem(p)^ := PMem(p)^ or PMem(self.stack.popv)^;
              self.stack.push(p);
              Inc(self.ip);
            end;

            bcXOR:
            begin
              p := self.stack.popv;
              PMem(p)^ := PMem(p)^ xor PMem(self.stack.popv)^;
              self.stack.push(p);
              Inc(self.ip);
            end;

            bcSHR:
            begin
              p := self.stack.popv;
              PMem(p)^ := PMem(p)^ shr PMem(self.stack.popv)^;
              self.stack.push(p);
              Inc(self.ip);
            end;

            bcSHL:
            begin
              p := self.stack.popv;
              PMem(p)^ := PMem(p)^ shl PMem(self.stack.popv)^;
              self.stack.push(p);
              Inc(self.ip);
            end;

            bcNEG:
            begin
              p := self.stack.peek;
              PMem(p)^ := -PMem(p)^;
              Inc(self.ip);
            end;

            bcINC:
            begin
              p := self.stack.peek;
              PMem(p)^ := PMem(p)^ + 1;
              Inc(self.ip);
            end;

            bcDEC:
            begin
              p := self.stack.peek;
              PMem(p)^ := PMem(p)^ - 1;
              Inc(self.ip);
            end;

            bcADD:
            begin
              p := self.stack.popv;
              PMem(p)^ := PMem(p)^ + PMem(self.stack.popv)^;
              self.stack.push(p);
              Inc(self.ip);
            end;

            bcSUB:
            begin
              p := self.stack.popv;
              PMem(p)^ := PMem(p)^ - PMem(self.stack.popv)^;
              self.stack.push(p);
              Inc(self.ip);
            end;

            bcMUL:
            begin
              p := self.stack.popv;
              PMem(p)^ := PMem(p)^ * PMem(self.stack.popv)^;
              self.stack.push(p);
              Inc(self.ip);
            end;

            bcDIV:
            begin
              p := self.stack.popv;
              PMem(p)^ := PMem(p)^ / PMem(self.stack.popv)^;
              self.stack.push(p);
              Inc(self.ip);
            end;

            bcMOD:
            begin
              p := self.stack.popv;
              PMem(p)^ := PMem(p)^ mod PMem(self.stack.popv)^;
              self.stack.push(p);
              Inc(self.ip);
            end;

            bcIDIV:
            begin
              p := self.stack.popv;
              PMem(p)^ := PMem(p)^ div PMem(self.stack.popv)^;
              self.stack.push(p);
              Inc(self.ip);
            end;
			
	    bcMV:
	    begin
              p := self.stack.popv;
	      PMem(p)^ := PMem(self.stack.popv)^;
	      Inc(self.ip);
	    end;
			
	    bcMVBP:
	    begin
              p := self.stack.popv;
	      PMem(Pointer(Cardinal(PMem(p)^)))^ := PMem(self.stack.popv)^;
	      Inc(self.ip);
	    end;
			
	    bcMVP:
	    begin
              p := self.stack.popv;
	      PMem(p)^ := Cardinal(PMem(self.stack.popv)^);
	      Inc(self.ip);
	    end;

            bcMS:
            begin
              SetLength(self.mem, PMem(self.stack.popv)^);
              Inc(self.ip);
            end;

            bcNW:
            begin
              self.stack.push(NewMem);
              Inc(self.ip);
            end;

            bcMC:
            begin
              self.stack.push(NewMemV(PMem(self.stack.peek)^));
              Inc(self.ip);
            end;

            bcMD:
            begin
              self.stack.push(self.stack.peek);
            end;

            bcRM:
            begin
              RemMem(PMem(self.stack.popv));
              Inc(self.ip);
            end;

            bcNA:
            begin
              self.stack.push(NewArr(@self.stack, PMem(self.stack.popv)^));
              Inc(self.ip);
            end;

            bcSF:
            begin
              self.stack.push(NewMemV(SizeOf(PMem(self.stack.popv)^)));
              Inc(self.ip);
            end;

            bcAL:
            begin
              self.stack.push(NewMemV(Length(PMemArr(self.stack.popv)^)));
              Inc(self.ip);
            end;

            bcSL:
            begin
              p := self.stack.popv;
              SetLength(PMemArr(self.stack.peek)^, cardinal(PMem(p)^));
              Inc(self.ip);
            end;

            bcPA:
            begin
              p := self.stack.popv;
              self.stack.push(PMemArr(p)^[cardinal(PMem(self.stack.popv)^)]);
              Inc(self.ip);
            end;

            bcSA:
            begin
              p := self.stack.popv;
              p := @(PMemArr(p)^[cardinal(PMem(self.stack.popv)^)]);
              PPointer(p)^ := self.stack.popv;
              Inc(self.ip);
            end;

            bcGPM:
            begin
              self.grabber.AddTask(self.stack.peek, mtVar);
              Inc(self.ip);
            end;

            bcGPA:
            begin
              self.grabber.AddTask(self.stack.peek, mtArray);
              Inc(self.ip);
            end;

            bcGC:
            begin
              self.grabber.Grab;
              Inc(self.ip);
            end;

            bcPHC:
            begin
              self.stack.push(NewMemV(self.consts^.GetConst(
                cardinal((self.bytes^[self.ip + 1] shl 24) +
                (self.bytes^[self.ip + 2] shl 16) + (self.bytes^[self.ip + 3] shl 8) +
                self.bytes^[self.ip + 4]))));
              Inc(self.ip, 5);
            end;

            bcPHEXMP:
            begin
              self.stack.push(self.extern_methods^.GetFunc(
                cardinal((self.bytes^[self.ip + 1] shl 24) +
                (self.bytes^[self.ip + 2] shl 16) + (self.bytes^[self.ip + 3] shl 8) +
                self.bytes^[self.ip + 4])));
              Inc(self.ip, 5);
            end;

            bcINV:
            begin
              TExternalFunction(self.extern_methods^.GetFunc(PMem(self.stack.popv)^))(
                @self.stack);
              Inc(self.ip);
            end;

            bcINVBP:
            begin
              TExternalFunction(self.stack.popv)(@self.stack);
              Inc(self.ip);
            end;

            bcPHN:
            begin
              self.stack.push(nil);
              Inc(self.ip);
            end;

            bcCTHR:
            begin
              self.stack.push(TVMThread.Create(self.bytes, self.consts,
                self.extern_methods, PMem(self.stack.popv)^,
                self.stack.popv));
              Inc(self.ip);
            end;

            bcSTHR:
            begin
              TVMThread(self.stack.popv).Suspend;
              Inc(self.ip);
            end;

            bcRTHR:
            begin
              TVMThread(self.stack.popv).Resume;
              Inc(self.ip);
            end;

            bcTTHR:
            begin
              TVMThread(self.stack.popv).Terminate;
              Inc(self.ip);
            end;

            bcTR:
            begin
              p := self.stack.popv;
              try_blocks.add(PMem(p)^, PMem(self.stack.popv)^);
              Inc(self.ip);
            end;

            bcTRS:
            begin
              self.ip := try_blocks.TR_Finally;
            end;

            bcTRR:
            begin
              self.ip := try_blocks.TR_Catch(Exception.Create(PMem(self.stack.popv)^));
            end;

            bcPHS:
            begin
              stack2.push(stack.popv);
              Inc(self.ip);
            end;

            bcPKS:
            begin
              stack.push(stack2.popv);
              Inc(self.ip);
            end;

            bcPPS:
            begin
              stack2.pop;
              Inc(self.ip);
            end;

            else
              VMError('Error: not supported operation, byte 0x' + IntToHex(self.bytes^[self.ip], 2) +
                ', at #' + IntToStr(self.ip));
          end;
      except
        on E: Exception do
        begin
          self.stack.push(NewMemV(E.Message));
          try
            self.ip := self.try_blocks.TR_Catch(E);
          except
            on E2: Exception do
              raise E2;
          end;
        end;
      end;
    until self.ip >= self.end_ip;
  end;

  procedure TVM.Run;
  begin
    new(consts);
    new(extern_methods);
    extern_methods^.Parse(self.bytes, mainclasspath);
    consts^.Parse(self.bytes);
    self.ip := 0;
    self.end_ip := length(self.bytes^);
    self.RunThread;
  end;

  procedure TVM.LoadByteCodeFromFile(fn: string);
  var
    f: file of byte;
  begin
    Self.MainClassPath := fn;
    AssignFile(f, fn);
    Reset(f);
    new(self.bytes);
    SetLength(self.bytes^, 0);
    while not EOF(f) do
    begin
      SetLength(self.bytes^, Length(self.bytes^) + 1);
      Read(f, self.bytes^[Length(self.bytes^) - 1]);
    end;
    CloseFile(f);
  end;

  procedure TVM.LoadByteCodeFromArray(b: TByteArr);
  var
    i: cardinal;
  begin
    Self.mainclasspath := ParamStr(1);
    new(self.bytes);
    setlength(self.bytes^, length(b));
    for i := 0 to length(b) - 1 do
      self.bytes^[i] := b[i];
  end;

{***** Main *******************************************************************}
var
  vm: TVM;
begin
  if ParamCount = 0 then
  begin
    writeln('Use: ', ExtractFileName(ParamStr(0)), ' <file>');
    halt;
  end;
  vm.LoadByteCodeFromFile(ParamStr(1));
  vm.Run;
end.
