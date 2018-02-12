program d6asm;
{$Apptype console}
{$Mode objfpc}
{$H+}

uses SysUtils, Classes;

{
  Code generation:
   1. Import section
   2. Constant section
   3. Code section
}

{** Methods **}

function CheckName(n:string):boolean;
var
  chars: set of char = ['a'..'z','0'..'9','_','.'];
begin
  result := false;
  if not (n[1] in ['0'..'9']) then
   begin
    delete(n,1,1);
    while Length(n)>0 do
     begin
       if not (n[1] in chars) then
        exit;
       delete(n,1,1);
     end;
    result := true;
   end;
end;

function TrimCodeStr(s:string):string;
var
  ConstStr: boolean;
begin
  s := Trim(s);
  ConstStr := false;
  Result := '';
  while Length(s)>0 do
   begin
     if s[1] = '"' then ConstStr := not ConstStr;
     if ConstStr then
      begin
        Result := Result+s[1];
        Delete(s,1,1);
      end
     else
      begin
        if s[1] = ';' then break;
        Result := Result+LowerCase(s[1]);
        Delete(s,1,1);
      end;
   end;
end;

function Tk(s:string; w:word):string;
begin
  result := '';
  while (length(s)>0)and(w>0) do
   begin
    if s[1] = '"' then
     begin
      delete(s,1,1);
      result := copy(s,1,pos('"',s)-1);
      delete(s,1,pos('"',s));
      s := trim(s);
     end
    else
    if Pos(' ',s)>0 then
     begin
      result := copy(s,1,pos(' ',s)-1);
      delete(s,1,pos(' ',s));
      s := trim(s);
     end
    else
     begin
      result := s;
      s := '';
     end;
    dec(w);
   end;
end;

procedure St_WriteWord(s:TStream; w:word);
begin
  s.WriteByte(PByte(@w+1)^);
  s.WriteByte(PByte(@w)^);
end;

procedure St_WriteCardinal(s:TStream; c:cardinal);
begin
  s.WriteByte(PByte(@c+3)^);
  s.WriteByte(PByte(@c+2)^);
  s.WriteByte(PByte(@c+1)^);
  s.WriteByte(PByte(@c)^);
end;

procedure St_WriteInt64(s:TStream; i:Int64);
begin
  s.WriteByte(PByte(@i+3)^);
  s.WriteByte(PByte(@i+2)^);
  s.WriteByte(PByte(@i+1)^);
  s.WriteByte(PByte(@i)^);
end;

procedure St_WriteDouble(s:TStream; d:double);
begin
  s.WriteByte(PByte(@d+7)^);
  s.WriteByte(PByte(@d+6)^);
  s.WriteByte(PByte(@d+5)^);
  s.WriteByte(PByte(@d+4)^);
  s.WriteByte(PByte(@d+3)^);
  s.WriteByte(PByte(@d+2)^);
  s.WriteByte(PByte(@d+1)^);
  s.WriteByte(PByte(@d)^);
end;

procedure AsmError(m:string);
begin
  writeln('Error: ',m);
  halt;
end;

procedure AsmWarn(m:string);
begin
  writeln('Warning: ',m);
end;

{** Types **}

type
  TBytes = array of byte;
  PBytes = ^TBytes;

  TImportLibrary = class(TObject)
    public
     LibraryPath: string;
     Imports,Methods:TStringList;
     constructor Create(lpath:string);
     destructor Destroy; override;
  end;

  TImportSection = class(TObject)
    public
     Libs:TList;
     Lines:TStringList;
     constructor Create(sl:TStringList);
     destructor Destroy; override;
     function GetLibIndx(l_path:string):integer;
     procedure AddMethod(l_path,m_name,exm_name:string);
     procedure ParseSection;
     procedure GenerateCode(Stream:TStream);
  end;

  TConstantType = (
   ctUnsigned64,
   ctInt64,
   ctDouble,
   ctString,
   ctStream
  );

  TConstant = class(TObject)
    public
     c_name: string;
     c_type: TConstantType;
     c_value: TMemoryStream;
     constructor Create;
     destructor Destroy; override;
     procedure GenerateCode(Stream:TStream);
  end;

  TConstantManager = class(TObject)
    public
     Constants: TList;
     Lines: TStringList;
     constructor Create(sl:TStringList);
     destructor Destroy; override;
     procedure AddConstCardinal(c_name:string; c:cardinal);
     function GetAddr(c_name:string):cardinal;
     procedure ParseSection;
     procedure CheckForDoubles;
     procedure AppendImports(ImportSection:TImportSection);
     procedure GenerateCode(Stream:TStream);
  end;

  TVarManager = class(TObject)
    public
     DefinedVars: TStringList;
     constructor Create;
     destructor Destroy; override;
     procedure DefVar(name:string);
     function Get(name:string):cardinal;
  end;

  TCodeSection = class(TObject)
    public
     Lines: TStringList;
     Constants: TConstantManager;
     Outp: TMemoryStream;
     constructor Create(sl:TStringList; cnsts:TConstantManager);
     destructor Destroy; override;
     procedure ParseSection;
     procedure GenerateCode(Stream:TStream);
  end;

{** Public variables **}

var
  IncludedFiles: TStringList;

{** Preprocessor **}

function IsVar(s:string):boolean;
begin
  Result := false;
  if length(s)>0 then
  if s[1] = '$' then
   begin
     delete(s,1,1);
     Result := CheckName(s);
   end;
end;

function GetVar(s:string; varmgr:TVarManager):string;
begin
  if IsVar(s) then
   begin
    delete(s,1,1);
    Result := IntToStr(varmgr.Get(s));
   end
  else
   AsmError('Invalid variable call "'+s+'".');
end;

function IsConst(s:string):boolean;
begin
  Result := false;
  if length(s)>0 then
  if s[1] = '!' then
   begin
     delete(s,1,1);
     Result := CheckName(s);
   end;
end;

function GetConst(s:string):string;
begin
  if IsConst(s) then
   begin
    delete(s,1,1);
    Result := s;
   end
  else
   AsmError('Invalid constant call "'+s+'".');
end;

function IsArr(s:string):boolean;
var
  cnt:integer;
begin
  Result := false;
  if length(s)>0 then
  if (pos('[',s)>0) and (pos(']',s)>0) then
   begin
     Result := true;
     cnt := 0;
     while length(s)>0 do
      begin
        case s[1] of
         '[': inc(cnt);
         ']': dec(cnt);
        end;
        delete(s,1,1);
      end;
     Result := Result and (cnt = 0);
   end;
end;

function GetArrLvl(s:string):cardinal;
var
  cnt:integer;
begin
  Result := 0;
  if (pos('[',s)>0) and (pos(']',s)>0) then
   begin
     cnt := 0;
     while length(s)>0 do
      begin
        case s[1] of
         '[': inc(cnt);
         ']': dec(cnt);
        end;
        if (s[1] = ']') and (cnt = 0) then
         inc(Result);
        delete(s,1,1);
      end;
   end;
end;

function GetArrLvlVal(s:string; indx:cardinal):string;         //!!!!!
var
  cnt:integer;
  i:cardinal;
begin
  Result := '';
  i := 0;
  if indx < 1 then
   exit;
  if (pos('[',s)>0) and (pos(']',s)>0) then
   begin
     cnt := 0;
     while length(s)>0 do
      begin
        case s[1] of
         '[': inc(cnt);
         ']': dec(cnt);
        end;
        if (s[1] = ']') and (cnt = 0) then
         inc(i);
        delete(s,1,1);
        if i = indx-1 then
         begin
           while length(s)>0 do
            begin
              case s[1] of
               '[': inc(cnt);
               ']': dec(cnt);
              end;
              if (s[1] = ']') and (cnt = 0) then
               break;
              Result := Result + s[1];
              delete(s,1,1);
            end;
           break;
         end;
      end;
   end;
end;

function GetArrName(s:string):string;
begin
  Result := copy(s,1,pos('[',s)-1);
end;

function PreprocessVarAction(varexpr, action:string; varmgr:TVarManager):string;
begin
  Result := action + ' ' + GetVar(varexpr, varmgr);
end;

function PreprocessArrAction(arrexpr, action:string; varmgr:TVarManager):string;
var
  c,lvl:cardinal;
  s:string;
begin
  Result := '';
  lvl := GetArrLvl(arrexpr);
  for c := 1 to lvl+1 do
   begin
     s := GetArrLvlVal(arrexpr, c);
     if IsVar(s) then
      Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr);
     if IsConst(s) then
      Result := Result + sLineBreak + 'pushc '+GetConst(s);
     if IsArr(s) then
      Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr);
   end;
  for c := 0 to lvl do
   Result := Result + sLineBreak + 'push ' + GetVar(GetArrName(arrexpr),varmgr) + sLineBreak + action;
end;

function CountVarDefs(s:string):cardinal;
begin
  s := Trim(s);
  Result := 0;
  if Length(s)>0 then
   Result := 1
  else
   Exit;
  while Length(s)>0 do
   begin
     if s[1] = ',' then
      inc(Result);
     delete(s,1,1);
   end;
end;

function GetVarDef(s:string; indx:integer):string;
begin
  s := Trim(s);
  Result := '';
  while Length(s)>0 do
   begin
     if (s[1] = ',') and (indx = 0) then
      break;
     if s[1] = ',' then
      begin
        dec(indx);
        delete(s,1,1);
      end;
     if (indx = 0) and (Length(s)>0) then
      Result := Result + s[1];
     if Length(s)>0 then
      delete(s,1,1);
   end;
end;

function PreprocessVarDefine(s:string; varmgr:TVarManager):string;
var
  v:string;
begin
  Result := '';
  s := Trim(s);
  if s = '' then
   exit;
  if pos('=',s)>0 then
   begin
    v := Trim(copy(s,1,pos('=',s)-1));
    delete(s,1,pos('=',s));
    s := Trim(s);
    if IsVar(s) then
     Result := PreprocessVarAction(s,'push',varmgr);
    if IsConst(s) then
      Result := Result + sLineBreak + 'pushc '+GetConst(s);
    if IsArr(s) then
     Result := PreprocessArrAction(s,'pushai',varmgr);
    varmgr.DefVar(v);
    Result := Result + sLineBreak + 'peek ' + GetVar('$'+v,varmgr) + sLineBreak + 'pop';
   end
  else
   varmgr.DefVar(s);
end;

function PreprocessVarDefines(s:string; varmgr:TVarManager):string;
var
  c,cnt: cardinal;
  df: string;
begin
  Result := '';
  cnt := CountVarDefs(s);
  for c := 0 to cnt-1 do
   begin
     df := GetVarDef(s,c);
     Result := Result + sLineBreak + PreprocessVarDefine(df,varmgr);
   end;
end;

function PreprocessStr(s:string; varmgr:TVarManager):string;
var
  sl:TStringList;
  c:cardinal;
begin
  Result := '';
  {** Include **}
  if Tk(s,1) = 'include' then
   begin
     delete(s,1,length('include'));
     s := Trim(s);
     case s[1] of
      '"':begin
            delete(s,1,1);
            if pos('"',s)<>Length(s) then
             AsmError('Invalid construction: "import "'+s+'".');
            delete(s,length(s),1);
            if not FileExists(s) then
             AsmError('File "'+s+'" not found.');
            sl := TStringList.Create;
            sl.LoadFromFile(s);
            if sl.Count>0 then
             begin
               for c := 0 to sl.Count-1 do
                sl[c] := TrimCodeStr(sl[c]);
               for c:=sl.count-1 downto 0 do
                if trim(sl[c])='' then sl.delete(c);
             end;
            Result := sl.Text + sLineBreak;
            FreeAndNil(sl);
          end;
      '<':begin
            delete(s,1,1);
            if pos('<',s)<>Length(s) then
             AsmError('Invalid construction: "import <'+s+'".');
            delete(s,length(s),1);
            if not FileExists(s) then
             AsmError('File "'+s+'" not found.');
            if IncludedFiles.IndexOf(s) = -1 then
             begin
               IncludedFiles.Add(s);
               sl := TStringList.Create;
               sl.LoadFromFile(s);
               if sl.Count>0 then
                begin
                  for c := 0 to sl.Count-1 do
                   sl[c] := TrimCodeStr(sl[c]);
                  for c:=sl.count-1 downto 0 do
                   if trim(sl[c])='' then sl.delete(c);
                end;
               Result := sl.Text + sLineBreak;
               FreeAndNil(sl);
             end;
          end;
      else
        AsmError('Invalid construction: "import '+s+'".');
     end;
   end
  else
  {** Var **}
  if Tk(s,1) = 'var' then
   begin
     delete(s,1,length('var'));
     s := Trim(s);
     Result := PreprocessVarDefines(s,varmgr);
   end
  else
  {** Anything **}
  if (pos('$',s)>0) or (pos('!',s)>0) then
   begin
     // push $a
     // push $a[expr 1][expr 2]..[expr n]
     if Tk(s,1) = 'push' then
      begin
        delete(s,1,length('push'));
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr);
        if IsConst(s) then
         Result := Result + sLineBreak + 'pushc '+GetConst(s);
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr);
      end
     else
     if Tk(s,1) = 'peek' then
      begin
        delete(s,1,length('peek'));
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'peek',varmgr);
        if IsConst(s) then
         AsmError('Peek in constant value "'+s+'"');
        if IsArr(s) then
         Result := PreprocessArrAction(s,'peekai',varmgr);
      end
     else
     Result := s;
   end
  else
   Result := s;
end;

{** ImportLibrary **}

constructor TImportLibrary.Create(lpath:string);
begin
  LibraryPath := lpath;
  Imports := TStringList.Create;
  Methods := TStringList.Create;
  inherited Create;
end;

destructor TImportLibrary.Destroy;
begin
  Imports.Free;
  Methods.Free;
  inherited Destroy;
end;

{** ImportSection **}

constructor TImportSection.Create(sl:TStringList);
begin
  Self.Lines := sl;
  Libs := TList.Create;
  inherited Create;
end;

destructor TImportSection.Destroy;
var
  w:word;
begin
  if Libs.Count>0 then
   for w := 0 to Libs.Count-1 do
    TImportLibrary(Libs[w]).Free;
  FreeAndNil(Libs);
  inherited Destroy;
end;

function TImportSection.GetLibIndx(l_path:string):integer;
var
  w:word;
  c:cardinal;
begin
  Result := -1;
  c := 0;
  while c<Libs.Count do
   begin
     if TImportLibrary(Libs[c]).LibraryPath = l_path then
      begin
        Result := c;
        break;
      end;
     inc(c);
   end;
end;

procedure TImportSection.AddMethod(l_path,m_name,exm_name:string);
var
  lb_indx: integer;
begin
  lb_indx := GetLibIndx(l_path);
  if lb_indx<>-1 then
   begin
     with TImportLibrary(Libs[lb_indx]) do
      begin
        if Methods.IndexOf(m_name)<>-1 then
         AsmError('Dublicate import "'+m_name+'", from "'+l_path+'":"'+exm_name+'"');
        Methods.Add(m_name);
        Imports.Add(exm_name);
      end;
   end
  else
   begin
     Libs.Add(TImportLibrary.Create(l_path));
     with TImportLibrary(Libs[Libs.Count-1]) do
      begin
        Methods.Add(m_name);
        Imports.Add(exm_name);
      end;
   end;
end;

procedure TImportSection.ParseSection;
var
  c:cardinal;
begin
  c := 0;
  while c<Lines.Count do
   begin
     if Tk(Lines[c],1) = 'import' then
      begin
        AddMethod(Tk(Lines[c],3),Tk(Lines[c],2),Tk(Lines[c],4));
        Lines[c] := '';
      end;
     inc(c);
   end;
end;

procedure TImportSection.GenerateCode(Stream:TStream);
var
  w,w1:word;
  b:byte;
  c:cardinal;
begin
  w := Libs.Count;
  St_WriteWord(Stream,w);
  if w>0 then
   begin
     for w := 0 to Libs.Count-1 do
      with TImportLibrary(Libs[w]) do
       begin
         w1 := Length(LibraryPath);
         St_WriteWord(Stream,w1);
         Stream.WriteBuffer(LibraryPath[1],w1);
       end;
     c := 0;
     for w := 0 to Libs.Count-1 do
      with TImportLibrary(Libs[w]) do
       begin
         c := c+Imports.Count;
       end;
     St_WriteCardinal(Stream,c);
     for w := 0 to Libs.Count-1 do
      with TImportLibrary(Libs[w]) do
       begin
         if Imports.Count>0 then
          for w1 := 0 to Imports.Count-1 do
           begin
             b := Length(Imports[w1]);
             St_WriteWord(Stream,w);
             Stream.WriteByte(b);
             if b>0 then
              Stream.WriteBuffer(Imports[w1][1],b);
           end;
       end;
   end;
end;

{** Constant **}

constructor TConstant.Create;
begin
 c_value := TMemoryStream.Create;
 inherited Create;
end;

destructor TConstant.Destroy;
begin
 c_value.Free;
 inherited Destroy;
end;

procedure TConstant.GenerateCode(Stream:TStream);
var
  w: word;
begin
  case c_type of
   ctUnsigned64:
     begin
       Stream.WriteByte(byte(ctUnsigned64));
       Stream.WriteBuffer(c_value.Memory^,c_value.size);
     end;
   ctInt64:
     begin
       Stream.WriteByte(byte(ctInt64));
       Stream.WriteBuffer(c_value.Memory^,c_value.size);
     end;
   ctDouble:
     begin
       Stream.WriteByte(byte(ctDouble));
       Stream.WriteBuffer(c_value.Memory^,c_value.size);
     end;
   ctString:
     begin
       Stream.WriteByte(byte(ctString));
       w := c_value.Size;
       St_WriteWord(Stream,w);
       Stream.WriteBuffer(c_value.Memory^,c_value.size);
     end;
  end;
end;

{** ConstantManager **}

constructor TConstantManager.Create(sl:TStringList);
begin
  Lines := sl;
  Constants := TList.Create;
  inherited Create;
end;

destructor TConstantManager.Destroy;
var
  c:cardinal;
begin
  if Constants.Count>0 then
   for c := 0 to Constants.Count-1 do
    TConstant(Constants[c]).Free;
  Constants.Free;
  inherited Destroy;
end;

procedure TConstantManager.AddConstCardinal(c_name:string; c:cardinal);
var
  Constant:TConstant;
begin
  Constant := TConstant.Create;
  Constant.c_name := c_name;
  Constant.c_type := ctUnsigned64;
  St_WriteCardinal(Constant.c_value,c);
  Constants.Add(Constant);
end;

function TConstantManager.GetAddr(c_name:string):cardinal;
var
  c:cardinal;
begin
  if pos(sLineBreak,c_name)>0 then
   c_name := copy(c_name,1,pos(slinebreak,c_name)-1);
  if Constants.Count = 0 then
   AsmError('Invalid constant call "'+c_name+'".');
  for c := 0 to Constants.Count-1 do
   begin
     if TConstant(Constants[c]).c_name = c_name then
      begin
        result := c;
        break;
      end
     else
      if c = Constants.Count-1 then
       AsmError('Invalid constant call "'+c_name+'"');
   end;
end;

procedure TConstantManager.ParseSection;
var
  c:cardinal;
  Constant:TConstant;
begin
  c := 0;
  while c<Lines.Count do
   begin
     if Tk(Lines[c],1) = 'word' then
      begin
        Constant := TConstant.Create;
        Constant.c_name := Tk(Lines[c],2);
        Constant.c_type := ctUnsigned64;
        St_WriteCardinal(Constant.c_value, StrToQWord(Tk(Lines[c],3)));
        Constants.Add(Constant);
        Lines[c] := '';
      end
     else
     if Tk(Lines[c],1) = 'int' then
      begin
        Constant := TConstant.Create;
        Constant.c_name := Tk(Lines[c],2);
        Constant.c_type := ctInt64;
        St_WriteInt64(Constant.c_value, StrToInt(Tk(Lines[c],3)));
        Constants.Add(Constant);
        Lines[c] := '';
      end
     else
     if Tk(Lines[c],1) = 'real' then
      begin
        Constant := TConstant.Create;
        Constant.c_name := Tk(Lines[c],2);
        Constant.c_type := ctDouble;
        St_WriteDouble(Constant.c_value, Double(StrToFloat(Tk(Lines[c],3))));
        Constants.Add(Constant);
        Lines[c] := '';
      end
     else
     if Tk(Lines[c],1) = 'str' then
      begin
        Constant := TConstant.Create;
        Constant.c_name := Tk(Lines[c],2);
        Constant.c_type := ctString;
        Constant.c_value.WriteBuffer(Tk(Lines[c],3)[1],Length(Tk(Lines[c],3)));
        Constants.Add(Constant);
        Lines[c] := '';
      end;
     inc(c);
   end;
end;

procedure TConstantManager.CheckForDoubles;
var
  s:string;
  c,c2:cardinal;
begin
 if Constants.Count>0 then
   begin
    for c := 0 to Constants.Count-1 do
     begin
      s := TConstant(Constants[c]).c_name;
      if not CheckName(s) then
       AsmError('Invalid name of "'+s+'"');
      c2 := c+1;
      while c2<Constants.Count do
       begin
        if TConstant(Constants[c2]).c_name = s then
         AsmError('Dublicate declaration of "'+s+'"');
        inc(c2);
       end;
     end
   end;
end;

procedure TConstantManager.AppendImports(ImportSection:TImportSection);
var
  w:word;
  c,c2:cardinal;
  Constant:TConstant;
begin
  if ImportSection.Libs.Count>0 then
   begin
     c := 0;
     for w := 0 to ImportSection.Libs.Count-1 do
      begin
        with TImportLibrary(ImportSection.Libs[w]) do
         begin
           if Methods.Count>0 then
             begin
               for c2 := 0 to Methods.Count-1 do
                begin
                  Constant := TConstant.Create;
                  Constant.c_name := Methods[c2];
                  Constant.c_type := ctUnsigned64;
                  St_WriteCardinal(Constant.c_value,c);
                  Constants.Add(Constant);
                  inc(c);
                end;
             end;
         end;
      end;
   end;
end;

procedure TConstantManager.GenerateCode(Stream:TStream);
var
  c:cardinal;
begin
 St_WriteCardinal(Stream,Constants.Count);
 if Constants.Count>0 then
  for c := 0 to Constants.Count-1 do
   TConstant(Constants[c]).GenerateCode(Stream);
end;

{** Variables **}

constructor TVarManager.Create;
begin
 DefinedVars := TStringList.Create;
 inherited Create;
end;

destructor TVarManager.Destroy;
begin
 FreeAndNil(DefinedVars);
 inherited Destroy;
end;

procedure TVarManager.DefVar(name:string);
begin
 if not CheckName(name) then
  AsmError('Invalid variable name "'+name+'".');
 if DefinedVars.IndexOf(name) = -1 then
  DefinedVars.Add(name)
 else
  AsmError('Trying to redefine variable "'+name+'".');
end;

function TVarManager.Get(name:string):cardinal;
begin
 Result := DefinedVars.IndexOf(name);
 if Result = -1 then
  AsmError('Invalid variable call "'+name+'".');
end;

{** Code section **}

constructor TCodeSection.Create(sl:TStringList; cnsts:TConstantManager);
begin
  Outp := TMemoryStream.Create;
  Lines := sl;
  Constants := cnsts;
  inherited Create;
end;

destructor TCodeSection.Destroy;
begin
  Outp.Free;
  inherited Destroy;
end;

type TComand = (
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
   bcINVBP,  // call externam method by pointer [top]

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

procedure TCodeSection.ParseSection;
var
  p1,p2:cardinal;
  s:string;
begin
  p1 := 0;
  p2 := 0;
  while p2<Lines.Count do
   begin
     s := Lines[p2];
     if (s[length(s)] = ':') then
      begin
        Constants.AddConstCardinal(copy(s,1,length(s)-1),p1);
        Lines.Delete(p2);
        dec(p2);
        dec(p1);
      end;
     if (Tk(s,1) = 'push') or (Tk(s,1) = 'peek') or (Tk(s,1) = 'pushc') or (Tk(s,1) = 'pushm') then
      inc(p1,5)
     else
      if Length(s)>0 then
       inc(p1);
     inc(p2);
   end;
  while Lines.Count>0 do
   begin
    s := Lines[0];
    Lines.Delete(0);
    if Tk(s,1) = 'push' then
     begin
       Outp.WriteByte(byte(bcPH));
       St_WriteCardinal(Outp,StrToQWord(Tk(s,2)));
       s := '';
     end;
    if Tk(s,1) = 'peek' then
     begin
       Outp.WriteByte(byte(bcPK));
       St_WriteCardinal(Outp,StrToQWord(Tk(s,2)));
       s := '';
     end;
    if Tk(s,1) = 'pushc' then
     begin
       Outp.WriteByte(byte(bcPHC));
       St_WriteCardinal(Outp,Constants.GetAddr(Tk(s,2)));
       s := '';
     end;
    if Tk(s,1) = 'pushm' then
     begin
       Outp.WriteByte(byte(bcPHEXMP));
       St_WriteCardinal(Outp,Constants.GetAddr(Tk(s,2)));
       s := '';
     end;
    if Tk(s,1) = 'pop' then
     Outp.WriteByte(byte(bcPP))
    else
    if Tk(s,1) = 'swp' then
     Outp.WriteByte(byte(bcSWP))
    else
    if Tk(s,1) = 'jp' then
     Outp.WriteByte(byte(bcJP))
    else
    if Tk(s,1) = 'jz' then
     Outp.WriteByte(byte(bcJZ))
    else
    if Tk(s,1) = 'jn' then
     Outp.WriteByte(byte(bcJN))
    else
    if Tk(s,1) = 'jc' then
     Outp.WriteByte(byte(bcJC))
    else
    if Tk(s,1) = 'jr' then
     Outp.WriteByte(byte(bcJR))
    else
    if Tk(s,1) = 'eq' then
     Outp.WriteByte(byte(bcEQ))
    else
    if Tk(s,1) = 'bg' then
     Outp.WriteByte(byte(bcBG))
    else
    if Tk(s,1) = 'be' then
     Outp.WriteByte(byte(bcBE))
    else
    if Tk(s,1) = 'not' then
     Outp.WriteByte(byte(bcNOT))
    else
    if Tk(s,1) = 'and' then
     Outp.WriteByte(byte(bcAND))
    else
    if Tk(s,1) = 'or' then
     Outp.WriteByte(byte(bcOR))
    else
    if Tk(s,1) = 'xor' then
     Outp.WriteByte(byte(bcXOR))
    else
    if Tk(s,1) = 'shr' then
     Outp.WriteByte(byte(bcSHR))
    else
    if Tk(s,1) = 'shl' then
     Outp.WriteByte(byte(bcSHL))
    else
    if Tk(s,1) = 'neg' then
     Outp.WriteByte(byte(bcNEG))
    else
    if Tk(s,1) = 'inc' then
     Outp.WriteByte(byte(bcINC))
    else
    if Tk(s,1) = 'dec' then
     Outp.WriteByte(byte(bcDEC))
    else
    if Tk(s,1) = 'add' then
     Outp.WriteByte(byte(bcADD))
    else
    if Tk(s,1) = 'sub' then
     Outp.WriteByte(byte(bcSUB))
    else
    if Tk(s,1) = 'mul' then
     Outp.WriteByte(byte(bcMUL))
    else
    if Tk(s,1) = 'div' then
     Outp.WriteByte(byte(bcDIV))
    else
    if Tk(s,1) = 'mod' then
     Outp.WriteByte(byte(bcMOD))
    else
    if Tk(s,1) = 'idiv' then
     Outp.WriteByte(byte(bcIDIV))
    else
    if Tk(s,1) = 'mov' then
     Outp.WriteByte(byte(bcMV))
    else
    if Tk(s,1) = 'movbp' then
     Outp.WriteByte(byte(bcMVBP))
    else
    if Tk(s,1) = 'movp' then
     Outp.WriteByte(byte(bcMVP))
    else
    if Tk(s,1) = 'msz' then
     Outp.WriteByte(byte(bcMS))
    else
    if Tk(s,1) = 'new' then
     Outp.WriteByte(byte(bcNW))
    else
    if Tk(s,1) = 'copy' then
     Outp.WriteByte(byte(bcMC))
    else
    if Tk(s,1) = 'pcopy' then
     Outp.WriteByte(byte(bcMD))
    else
    if Tk(s,1) = 'rem' then
     Outp.WriteByte(byte(bcRM))
    else
    if Tk(s,1) = 'newa' then
     Outp.WriteByte(byte(bcNA))
    else
    if Tk(s,1) = 'sizeof' then
     Outp.WriteByte(byte(bcSF))
    else
    if Tk(s,1) = 'alen' then
     Outp.WriteByte(byte(bcAL))
    else
    if Tk(s,1) = 'salen' then
     Outp.WriteByte(byte(bcSL))
    else
    if Tk(s,1) = 'pushai' then
     Outp.WriteByte(byte(bcPA))
    else
    if Tk(s,1) = 'peekai' then
     Outp.WriteByte(byte(bcSA))
    else
    if Tk(s,1) = 'gpm' then
     Outp.WriteByte(byte(bcGPM))
    else
    if Tk(s,1) = 'gpa' then
     Outp.WriteByte(byte(bcGPA))
    else
    if Tk(s,1) = 'gc' then
     Outp.WriteByte(byte(bcGC))
    else
    if Tk(s,1) = 'invoke' then
     Outp.WriteByte(byte(bcINV))
    else
    if Tk(s,1) = 'invokebp' then
     Outp.WriteByte(byte(bcINVBP))
    else
    if Tk(s,1) = 'pushn' then
     Outp.WriteByte(byte(bcPHN))
    else
    if Tk(s,1) = 'cthr' then
     Outp.WriteByte(byte(bcCTHR))
    else
    if Tk(s,1) = 'sthr' then
     Outp.WriteByte(byte(bcSTHR))
    else
    if Tk(s,1) = 'rthr' then
     Outp.WriteByte(byte(bcRTHR))
    else
    if Tk(s,1) = 'tthr' then
     Outp.WriteByte(byte(bcTTHR))
    else
    if Tk(s,1) = 'tr' then
     Outp.WriteByte(byte(bcTR))
    else
    if Tk(s,1) = 'trs' then
     Outp.WriteByte(byte(bcTRS))
    else
    if Tk(s,1) = 'trr' then
     Outp.WriteByte(byte(bcTRR))
    else
    if Tk(s,1) = 'pushb' then
     Outp.WriteByte(byte(bcPHS))
    else
    if Tk(s,1) = 'peekb' then
     Outp.WriteByte(byte(bcPKS))
    else
    if Tk(s,1) = 'popb' then
     Outp.WriteByte(byte(bcPPS))
    else
     if Length(s)>0 then
      AsmError('Invalid token in line: "'+s+'"');
   end;
end;

procedure TCodeSection.GenerateCode(Stream:TStream);
begin
  Stream.WriteBuffer(Outp.Memory^,Outp.Size);
end;

{** Main **}
var
  Code: TStringList;
  c:cardinal;
  Output:TFileStream;
  varmgr:TVarManager;
  Imports:TImportSection;
  Constants:TConstantManager;
  CodeSection:TCodeSection;
begin
 if ParamCount=0 then
  begin
    writeln('Assembler for SVM.');
    writeln('Use: ',ExtractFileName(ParamStr(0)),' <file>');
    halt;
  end;
 IncludedFiles := TStringList.Create;
 Code := TStringList.Create;
 Code.LoadFromFile(ParamStr(1));
 if Code.Count>0 then
   for c := 0 to Code.Count-1 do
    Code[c] := TrimCodeStr(Code[c]);
 {for c:=code.count-1 downto 0 do
  if trim(code[c])='' then code.delete(c);}
 c := 0;
 varmgr := TVarManager.Create;
 while c<Code.Count do
  begin
    if Trim(Code[c]) <> '' then
     Code[c] := Trim(PreprocessStr(Code[c],varmgr));
    inc(c);
  end;
 code.text := 'word calculated_addr_table_size '+inttostr(varmgr.DefinedVars.Count)+sLineBreak+
              'pushc calculated_addr_table_size'+sLineBreak+
              'gpm'+sLineBreak+
              'msz'+sLineBreak+
              'gc'+sLineBreak+
              'pushc main'+slinebreak+
              'gpm'+slinebreak+
              'jp'+sLineBreak+code.text;
 code.SaveToFile('buf.tmp');      // Хз почему, но без этого не работает...
 code.LoadFromFile('buf.tmp');    //
 DeleteFile('buf.tmp');
 if Code.Count>0 then
  begin
    Output := TFileStream.Create(ChangeFileExt(ParamStr(1),'.vmc'),fmCreate);
    Imports := TImportSection.Create(Code);
    Imports.ParseSection;
    Imports.GenerateCode(Output);
    Constants := TConstantManager.Create(Code);
    Constants.ParseSection;
    Constants.AppendImports(Imports);
    for c:=code.count-1 downto 0 do
     if trim(code[c])='' then code.delete(c);
    CodeSection := TCodeSection.Create(Code, Constants);
    CodeSection.ParseSection;
    Constants.CheckForDoubles;
    Constants.GenerateCode(Output);
    CodeSection.GenerateCode(Output);
    writeln('Success.');
    writeln('Executable file size: ',Output.Size,' bytes.');
    FreeAndNil(Imports);
    FreeAndNil(Constants);
    FreeAndNil(CodeSection);
    FreeAndNil(Output);
  end;
 FreeAndNil(Code);
 FreeAndNil(IncludedFiles);
end.

