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
# NOTE: On OHOS, .init_array processing during dlopen has memory issues
# (BSS not fully mapped, heap not ready). We MUST NOT call
# FPC_LIB_START_HARMONYOS from .init_array. Instead, the library's
# main() function will explicitly call FPC_LIB_MAIN_HARMONYOS.
#

.section .note.GNU-stack,"",@progbits
