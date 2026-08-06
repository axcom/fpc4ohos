unit hilog;
{ writeln → HiLog 重定向单元（仅 ohos 目标生效）
  uses 中加入 hilog，引用一次，现有 writeln(...) 全部无需改动→重定向到 HiLog。

  原理：writeln 的输出最终由 RTL 通过 TextRec 的函数指针回调写入，
  本单元替换 Output/ErrOutput/StdOut/StdErr 的 InOutFunc/FlushFunc/CloseFunc，
  把所有 writeln(...) 内容组装成完整行后经 OH_LOG_Print 发往 HiLog。

  - ohos 目标：发往 HiLog（libhilog_ndk.z.so），tag 默认为 'fpc'
  - 其他目标：不安装 hook，writeln 保持系统默认行为；
    HiLogDebug/Info/... 在桌面打印带时间戳行，便于调试

  日志级别映射：stdout/Output → INFO，stderr/ErrOutput → ERROR
  长行跨 256 字节缓冲会自动重组为一行；HiLog 单条超 1000 字节截断。
  多线程同时 writeln 时行可能交错（HiLog 本身线程安全）。
}
{$mode objfpc}{$H+}
{$codepage utf8}

interface

procedure InstallWritelnToHiLog(const ATag: AnsiString);
procedure UninstallWritelnToHiLog;

// 打印日志（ohos 发 HiLog，桌面打印带时间戳行）
procedure HiLogDebug(const Msg: string); overload;
procedure HiLogInfo(const Msg: string); overload;
procedure HiLogWarn(const Msg: string); overload;
procedure HiLogError(const Msg: string); overload;
procedure HiLogFatal(const Msg: string); overload;

// 带格式化的版本（使用 SysUtils.Format）
procedure HiLogDebug(const Fmt: string; const Args: array of const); overload;
procedure HiLogInfo(const Fmt: string; const Args: array of const); overload;
procedure HiLogWarn(const Fmt: string; const Args: array of const); overload;
procedure HiLogError(const Fmt: string; const Args: array of const); overload;
procedure HiLogFatal(const Fmt: string; const Args: array of const); overload;

var
  // 全局默认服务域，ArkTS 模板默认为 0，C++ NDK 模板(napi_init.cpp)默认为 0xD002D00。用户可修改
  DefaultLogDomain: DWord = 0;

implementation

uses sysutils;

const
  // 日志类型
  LOG_APP     = 0;
  // 日志级别
  LOG_DEBUG = 3;
  LOG_INFO  = 4;
  LOG_WARN  = 5;
  LOG_ERROR = 6;
  LOG_FATAL = 7;
  // 全局默认日志标签，默认为 nil，用户可执行 InstallWritelnToHiLog 入参设置，如 'MyApp'
  DefaultLogTag = 'fpc';

{$ifdef ohos}

const
  HILOG_MAX = 1000;

procedure OH_LOG_Print(typ, level: LongInt; domain: DWord;
  tag, fmt: PAnsiChar); cdecl; varargs; external 'libhilog_ndk.z.so';

var
  LogTag: PAnsiChar;
  TagBuf: array[0..63] of AnsiChar;
  Pending: AnsiString;
  PendingSrc: TextRec;
  SavedInOut, SavedFlush, SavedClose: CodePointer;
  HookInstalled: Boolean = False;

procedure EmitLine(const S: AnsiString);
var
  L: AnsiString;
  level: Integer;
begin
  L := S;
  if Length(L) > HILOG_MAX then
    SetLength(L, HILOG_MAX);
  { 来源流映射日志级别：stderr/ErrOutput → ERROR，stdout/Output → INFO }
  if (PendingSrc.Handle = TextRec(ErrOutput).Handle) or
     (PendingSrc.Handle = TextRec(StdErr).Handle) then
    level := LOG_ERROR
  else
    level := LOG_INFO;
  OH_LOG_Print(LOG_APP, level, DefaultLogDomain, LogTag,
    PAnsiChar('%{public}s'), PAnsiChar(L));
end;

procedure FlushCompleteLines;
var
  p: SizeInt;
  line: AnsiString;
begin
  if Length(Pending) > 8192 then
  begin
    EmitLine(Pending);
    Pending := '';
    Exit;
  end;
  p := Pos(#10, Pending);
  while p > 0 do
  begin
    line := Copy(Pending, 1, p - 1);
    while (line <> '') and (line[Length(line)] in [#10, #13]) do
      Delete(line, Length(line), 1);
    Delete(Pending, 1, p);
    EmitLine(line);
    p := Pos(#10, Pending);
  end;
end;

procedure HiLogInOut(var t: TextRec);
var
  n: SizeInt;
begin
  n := t.BufPos;
  if n = 0 then
    Exit;
  PendingSrc := t;
  SetLength(Pending, Length(Pending) + n);
  Move(t.BufPtr^[0], Pending[Length(Pending) - n + 1], n);
  t.BufPos := 0;
  FlushCompleteLines;
end;

procedure HiLogClose(var t: TextRec);
begin
  HiLogInOut(t);
  FlushCompleteLines;
  if Pending <> '' then
  begin
    EmitLine(Pending);
    Pending := '';
  end;
end;

{$endif ohos}

//==============================================================================

procedure DoLog(atype, level: Integer; domain: DWord; tag: PChar; const msg: string);
{$ifdef ohos}
var
  buf: array[0..1023] of Char;
{$endif ohos}
begin
  if msg = '' then Exit;
{$ifdef ohos}
  StrPLCopy(buf, msg, SizeOf(buf) - 1);
  OH_LOG_Print(atype, level, domain, tag, '%{public}s', buf);
{$else}
  Writeln(FormatDateTime('yyyy-mm-dd hh:mm:ss.zzz', now), ' ', level, ' ', tag, ' ', msg);
{$endif ohos}
end;

procedure HILogDebug(const Msg: string);
begin
  DoLog(LOG_APP, LOG_DEBUG, DefaultLogDomain, PChar(DefaultLogTag), Msg);
end;

procedure HILogInfo(const Msg: string);
begin
  DoLog(LOG_APP, LOG_INFO, DefaultLogDomain, PChar(DefaultLogTag), Msg);
end;

procedure HILogWarn(const Msg: string);
begin
  DoLog(LOG_APP, LOG_WARN, DefaultLogDomain, PChar(DefaultLogTag), Msg);
end;

procedure HILogError(const Msg: string);
begin
  DoLog(LOG_APP, LOG_ERROR, DefaultLogDomain, PChar(DefaultLogTag), Msg);
end;

procedure HILogFatal(const Msg: string);
begin
  DoLog(LOG_APP, LOG_FATAL, DefaultLogDomain, PChar(DefaultLogTag), Msg);
end;

procedure HILogDebug(const Fmt: string; const Args: array of const);
begin
  HILogDebug(Format(Fmt, Args));
end;

procedure HILogInfo(const Fmt: string; const Args: array of const);
begin
  HILogInfo(Format(Fmt, Args));
end;

procedure HILogWarn(const Fmt: string; const Args: array of const);
begin
  HILogWarn(Format(Fmt, Args));
end;

procedure HILogError(const Fmt: string; const Args: array of const);
begin
  HILogError(Format(Fmt, Args));
end;

procedure HILogFatal(const Fmt: string; const Args: array of const);
begin
  HILogFatal(Format(Fmt, Args));
end;

//==============================================================================

procedure InstallWritelnToHiLog(const ATag: AnsiString);
{$ifdef ohos}
var
  i, n: SizeInt;
begin
  n := Length(ATag);
  if n > 63 then
    n := 63;
  for i := 1 to n do
    TagBuf[i - 1] := ATag[i];
  TagBuf[n] := #0;
  LogTag := @TagBuf[0];

  if not HookInstalled then
  begin
    SavedInOut := TextRec(Output).InOutFunc;
    SavedFlush := TextRec(Output).FlushFunc;
    SavedClose := TextRec(Output).CloseFunc;
    TextRec(Output).InOutFunc := @HiLogInOut;
    TextRec(Output).FlushFunc := @HiLogInOut;
    TextRec(Output).CloseFunc := @HiLogClose;
    TextRec(ErrOutput).InOutFunc := @HiLogInOut;
    TextRec(ErrOutput).FlushFunc := @HiLogInOut;
    TextRec(ErrOutput).CloseFunc := @HiLogClose;
    TextRec(StdOut).InOutFunc := @HiLogInOut;
    TextRec(StdOut).FlushFunc := @HiLogInOut;
    TextRec(StdOut).CloseFunc := @HiLogClose;
    TextRec(StdErr).InOutFunc := @HiLogInOut;
    TextRec(StdErr).FlushFunc := @HiLogInOut;
    TextRec(StdErr).CloseFunc := @HiLogClose;
    HookInstalled := True;
  end;
end;
{$else}
begin
end;
{$endif}

procedure UninstallWritelnToHiLog;
begin
{$ifdef ohos}
  if HookInstalled then
  begin
    HiLogClose(TextRec(Output));
    TextRec(Output).InOutFunc := SavedInOut;
    TextRec(Output).FlushFunc := SavedFlush;
    TextRec(Output).CloseFunc := SavedClose;
    TextRec(ErrOutput).InOutFunc := SavedInOut;
    TextRec(ErrOutput).FlushFunc := SavedFlush;
    TextRec(ErrOutput).CloseFunc := SavedClose;
    TextRec(StdOut).InOutFunc := SavedInOut;
    TextRec(StdOut).FlushFunc := SavedFlush;
    TextRec(StdOut).CloseFunc := SavedClose;
    TextRec(StdErr).InOutFunc := SavedInOut;
    TextRec(StdErr).FlushFunc := SavedFlush;
    TextRec(StdErr).CloseFunc := SavedClose;
    HookInstalled := False;
  end;
{$endif}
end;

initialization
  InstallWritelnToHiLog(DefaultLogTag);

end.
