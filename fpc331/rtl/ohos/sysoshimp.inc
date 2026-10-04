{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2024 by Free Pascal development team

    Implementation part of HarmonyOS-specific System unit procedures.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 **********************************************************************}

procedure CommonMainHarmonyOS;
const
  EmptyEnv: array[0..2] of PAnsiChar = (nil, nil, nil);
  EmptyCmdLine: array[0..0] of PAnsiChar = ( '' );
var
  i: cardinal;
  p: PPAnsiChar;
begin
  __stkptr:=pointer(ptruint(Sptr) or $FFFF);
  p:=_environ;
  if p = nil then
    operatingsystem_parameter_envp:=@EmptyEnv
  else
    begin
      operatingsystem_parameter_envp:=p;
      Dec(p);
      if p^ = nil then
        begin
          i:=0;
          while i < 200 do
            begin
              Dec(p);
              if ptruint(p^) = i then
                begin
                  operatingsystem_parameter_argc:=i;
                  operatingsystem_parameter_argv:=p + 1;
                  break;
                end;
              Inc(i);
            end;
        end;
    end;

  if operatingsystem_parameter_argc = 0 then
    begin
      operatingsystem_parameter_argc:=1;
      operatingsystem_parameter_argv:=@EmptyCmdLine;
    end;
end;

procedure ProgMainHarmonyOS; cdecl; [public, alias:'FPC_PROG_START_HARMONYOS'];
begin
  CommonMainHarmonyOS;
end;

procedure LibMainHarmonyOS; external name 'FPC_LIB_MAIN_HARMONYOS';

procedure fpc_lib_exit_intern; external name 'FPC_LIB_EXIT';

procedure atexit(p: pointer); cdecl; external;

procedure HarmonyOSLibStart; cdecl; [public, alias:'FPC_LIB_START_HARMONYOS'];
begin
  if HarmonyOSLibStarted then
    Exit;
  HarmonyOSLibStarted := True;
  CommonMainHarmonyOS;
  LibMainHarmonyOS;
  atexit(@fpc_lib_exit_intern);
end;

procedure _exit(e:longint); cdecl; external name 'exit';

procedure _haltproc(e:longint);cdecl; [public, alias: '_haltproc'];
begin
  _exit(e);
end;

procedure InitHarmonyOS;
begin
end;
