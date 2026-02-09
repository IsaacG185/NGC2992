require("../share/isisscripts");

define test()
{
  variable norm     = qualifier("norm", 1);
  variable PhoIndx1 = qualifier("PhoIndx1", 0);
  variable BreakE   = qualifier("BreakE",  10);
  variable PhoIndx2 = qualifier("PhoIndx2", 1);
  
  variable E1       = qualifier("E1",  5);
  variable E2       = qualifier("E2", 15);

  fit_fun("bknpower(1)");
  set_par("bknpower(1).norm",         norm);
  set_par("bknpower(1).PhoIndx1", PhoIndx1);
  set_par("bknpower(1).BreakE",     BreakE);
  set_par("bknpower(1).PhoIndx2", PhoIndx2);
  variable f1 = eval_fun(_A(E1, E2));

  fit_fun("multibknpower(1)");
  set_par("multibknpower(1).norm",         norm);
  set_par("multibknpower(1).PhoIndx0", PhoIndx1);
  set_par("multibknpower(1).BreakE1",     BreakE);
  set_par("multibknpower(1).PhoIndx1", PhoIndx2);
  variable f2 = eval_fun(_A(E1, E2));

  vmessage("%10f <-> %10f (diff=%10e, ratio=%10f)", f1, f2, f2-f1, f2/f1);
}

test(; E1= 5, E2= 8);
test(; E1= 5, E2=10);
test(; E1= 5, E2=15);
test(; E1=10, E2=15);
test(; E1=12, E2=15);
