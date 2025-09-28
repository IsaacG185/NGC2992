require("./share/isisscripts.sl");

variable a1 = urand(10), a2 = urand(10);

define test_eval_equal(lhs, rhs) {
  variable l = eval(lhs), r = eval(rhs), equal = _eqs(l, r);
  ifnot (equal)
    vmessage("failed: %s != %s", lhs, rhs);
  return equal;
}

variable tests_passed = [
  test_eval_equal("CCF_1d(a1,+a1, 0)", "+1"),
  test_eval_equal("CCF_1d(a1,-a1, 0)", "-1"),
  test_eval_equal("CCF_1d(a1, a2, 0)", "CCF_1d(a1, a2, 0; notperiodic)"),
  test_eval_equal("CCF_1d(a1, a2, 1)", "CCF_1d(a1[[0:9]], a2[[0:9]-1],    0)"),
  test_eval_equal("CCF_1d(a1, a2,-1)", "CCF_1d(a1[[0:9]], a2[[0:9]+1-10], 0)"),
  test_eval_equal("CCF_1d(a1, a2, 5)", "CCF_1d(a1[[0:9]], a2[[0:9]-5],    0)"),
  test_eval_equal("CCF_1d(a1, a2,-5)", "CCF_1d(a1[[0:9]], a2[[0:9]+5-10], 0)"),
  test_eval_equal("CCF_1d(a1, a2, 1; notperiodic)", "CCF_1d(a1[[1:9]], a2[[0:8]], 0)"),
  test_eval_equal("CCF_1d(a1, a2,-1; notperiodic)", "CCF_1d(a1[[0:8]], a2[[1:9]], 0)"),
  test_eval_equal("CCF_1d(a1, a2, 5; notperiodic)", "CCF_1d(a1[[5:9]], a2[[0:4]], 0)"),
  test_eval_equal("CCF_1d(a1, a2,-5; notperiodic)", "CCF_1d(a1[[0:4]], a2[[5:9]], 0)"),
  test_eval_equal("CCF_1d(a1, a2)", "array_map(Double_Type, &CCF_1d, &a1, &a2, [0:9])"),
  test_eval_equal("CCF_1d(a1, a2, [-1:1]; notperiodic)", "[CCF_1d(a1, a2, -1; notperiodic), CCF_1d(a1, a2, 0), CCF_1d(a1, a2, 1; notperiodic)]"),
];
exit(all(tests_passed) ? 0 : 1);
