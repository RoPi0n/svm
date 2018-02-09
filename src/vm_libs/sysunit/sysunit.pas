library SysUNIT;

uses SysUtils,Classes;

{$I ..\adp.inc}

{FUNCTIONS}
procedure DHalt(Stack:PStack); cdecl;
begin
 halt;
end;

procedure DStrToInt(Stack:PStack); cdecl;
var s:string;
begin
 s:=PMem(Stack^.popv)^;
 Stack^.push(new_d6v(strtoint(s)));
end;

procedure DStrToFloat(Stack:PStack); cdecl;
var s:string;
begin
 s:=PMem(Stack^.popv)^;
 Stack^.push(new_d6v(strtofloat(s)));
end;

procedure DCHRUpper(Stack:PStack); cdecl;
var s:char;
begin
 s:=PMem(Stack^.popv)^;
 Stack^.push(new_d6v(upcase(s)));
end;

procedure DChrLower(Stack:PStack); cdecl;
var s:char;
begin
 s:=PMem(Stack^.popv)^;
 Stack^.push(new_d6v(ord(s)));
end;

procedure DStrUpper(Stack:PStack); cdecl;
var s:string;
begin
 s:=PMem(Stack^.popv)^;
 Stack^.push(new_d6v(uppercase(s)));
end;

procedure DStrLower(Stack:PStack); cdecl;
var s:string;
begin
 s:=PMem(Stack^.popv)^;
 Stack^.push(new_d6v(lowercase(s)));
end;

procedure DIntToStr(Stack:PStack); cdecl;
var s:longint;
begin
 s:=PMem(Stack^.popv)^;
 Stack^.push(new_d6v(inttostr(s)));
end;

procedure DFloatToStr(Stack:PStack); cdecl;
var s:double;
begin
 s:=PMem(Stack^.popv)^;
 Stack^.push(new_d6v(floattostr(s)));
end;

procedure DSleep(Stack:PStack); cdecl;
begin
 sleep(PMem(Stack^.popv)^);
end;

//DateTime
procedure DNow(Stack:PStack); cdecl;
begin
 Stack^.push(new_d6v(now));
end;


{EXPORTS DB}
exports DINTTOSTR           name 'INTTOSTR';
exports DFLOATTOSTR         name 'FLOATTOSTR';
exports DSTRTOINT           name 'STRTOINT';
exports DSTRTOFLOAT         name 'STRTOFLOAT';
exports DHALT               name 'EXITPROCESS';
exports DSLEEP              name 'SLEEP';
exports DSTRUPPER           name 'STRUPPER';
exports DSTRLOWER           name 'STRLOWER';
exports DCHRUPPER           name 'CHRUPPER';
exports DCHRLOWER           name 'CHRLOWER';
exports DNOW                name 'CURRENTDATETIME';

begin
end.
