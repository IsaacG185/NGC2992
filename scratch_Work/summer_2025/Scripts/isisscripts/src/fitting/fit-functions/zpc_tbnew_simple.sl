
define zpc_tbnew_simple_fit(lo,hi,par)
%!%+
%\function{zpc_tbnew_simple (fit-function)}
%\synopsis{partial covering absorption}
%\description
%    This function describes two partial coverers with
%    covering fraction f, according to the formula:
%    \code{ (1-f) +  f*exp(-nH*sigma) }
%    This definition is equal to how, e.g., zpcfabs is defined.
%\seealso{tbnew_simple,tbnew,zpcfabs}
%!%-
{
   variable v1 = tbnew_simple_z_fit(lo,hi,[par[0],par[2]]);
   variable c=par[1];

   return  ((1-c) + c*v1);
}
add_slang_function("zpc_tbnew_simple", ["nH [10^22/cm^2]","C [Covering Fraction]","z [redshift]"]);

private define zpc_tbnew_simple_defaults(i)
{
   switch(i)
   {case 0:  return (1, 0, 0, 100); }
   {case 1:  return (0.5, 0, 0, 1); }   
   {case 2:  return (0, 1, 0, 10); }   
}
set_param_default_hook("zpc_tbnew_simple", &zpc_tbnew_simple_defaults);

