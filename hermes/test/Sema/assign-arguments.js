/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// RUN: (! %shermes %s -dump-ir 2>&1 ) | %FileCheck --match-full-lines %s

// Sloppy arguments assignment is valid; strict assignment remains an error.
function loose() {
    arguments = 0;
}

let arguments = 0;
function strict() {
    "use strict";
    ++arguments;
//CHECK: {{.*}}:[[@LINE-1]]:7: error: invalid operand in update operation
}
