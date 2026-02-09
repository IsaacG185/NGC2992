%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define continued_fraction_expansion()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{continued_fraction_expansion}
%\synopsis{expands a floating point number as a continued fraction}
%\usage{UInteger_Type[] continued_fraction_expansion(Double_Type x)}
%\qualifiers{
%\qualifier{verbose}{}
%\qualifier{maxlen}{[\code{=64}]}
%}
%!%-
{
  variable x0;
  switch(_NARGS)
  { case 1: x0 = (); }
  { help(_function_name()); return; }

  if(x0<0)  x0 = -x0;
  variable verbose = qualifier_exists("verbose");
  if(verbose)  vmessage("continued fraction expansion of %S:", x0);
  variable N = qualifier("maxlen", 64);
  variable a = UInteger_Type[N], n = ULLong_Type[N+2], d = ULLong_Type[N+2];
  n[0] = 0; n[1] = 1;  d[0] = 1; d[1] = 0;
  variable i = 0, x = x0, cf = "[", fmt = "%d";
  do
  { variable a_i = int(x);
    a[i] = a_i;
    cf += sprintf(fmt, a_i);
    if(i<2)  { if(i==0)  fmt=";%d";  else  fmt=",%d"; }
    x = x-a_i;
    if(x>0) x = 1./x;
    n[i+2] = n[i] + a_i * n[i+1];
    d[i+2] = d[i] + a_i * d[i+1];
    variable frac = 1.*n[i+2] / d[i+2];
    variable diff = frac - x0;
    if(verbose)  vmessage("%s] = %lld/%lld = %S  (delta = %S)", cf, n[i+2], d[i+2], frac, diff);
    i++;
  } while(i<N && diff!=0.);
  return a[[:i-1]];
}
