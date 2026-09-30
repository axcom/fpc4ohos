#
#   This file is part of the Free Pascal run time library.
#   Copyright (c) 2024 by the Free Pascal development team
#
#   See the file COPYING.FPC, included in this distribution,
#   for details about the copyright.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#**********************************************************************}
#
# Shared library startup code for Free Pascal. HarmonyOS target.
#
# The OHOS loader executes constructors registered in .init_array when a
# shared library is dlopen()ed.  DT_INIT (set by the compiler as
# "-init FPC_LIB_START_HARMONYOS") is NOT called for dlopen()ed
# libraries, so the FPC runtime/unit initialization must be registered
# here.  Otherwise System.InitCriticalSection dereferences a NIL
# CurrentTM function pointer (SIGSEGV @ pc=0) at the first
# TCriticalSection.Create.
#
/* --------------------------------------------------------- */
  .section .init_array, "aw"

.ifdef CPU64
  .quad FPC_LIB_START_HARMONYOS
.else
  .long FPC_LIB_START_HARMONYOS
.endif