%!%+
%\function{kerr_rplus}
%\synopsis{calculates the event horizon of a black hole in units of GM/c^2}
%\usage{kerr_rplus(a)}
%!%-
define kerr_rplus() {
   variable a;
   
   switch(_NARGS)
   { case 1: a = ();}
   { help(_function_name()); return; }
   
   return 1. + sqrt((1.-a)*(1.+a));
}
