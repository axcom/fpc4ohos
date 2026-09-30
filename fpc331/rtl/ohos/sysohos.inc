{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2024 by Free Pascal development team

    Interface part of HarmonyOS-specific System unit declarations.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 **********************************************************************}

var
  __stkptr : Pointer; public name '__stkptr';
  operatingsystem_parameter_envp : Pointer; public name 'operatingsystem_parameter_envp';
  operatingsystem_parameter_argc : LongInt; public name 'operatingsystem_parameter_argc';
  operatingsystem_parameter_argv : Pointer; public name 'operatingsystem_parameter_argv';

  _environ: pointer external name 'environ';

  HarmonyOSLibStarted: Boolean;
