require("../src/slang/strings/TeX_value_pm_error.sl");
%require("isisscripts");

variable val_min_max;
foreach val_min_max (
[
 {4, 3, 6},
 {4, 3, 60},
 {4, 3, 600},
 {0, 0, 1},
 {0, -1, 9},
 {0, -100, 9000},
 {10, 0, 9000},
 {100, 0, 9000},
 {1000, 0, 9000},
 {1e-16, 0, 9e-16},
])
  vmessage("val=%S, min=%S, max=%S => %s", __push_list(val_min_max), TeX_value_pm_error(__push_list(val_min_max)));
