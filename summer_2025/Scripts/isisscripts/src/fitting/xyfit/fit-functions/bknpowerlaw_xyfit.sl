%%%%%%%%%%%%%%%%%%%%%%%%%%%
define bknpowerlaw_xyfit()
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{bknpowerlaw_xyfit}
%\synopsis{linear xy fit function to be used with xyfit_fun}
%\usage{xyfit_fun ("bknpowerlaw");}
%\description
%    This function is not meant to be called directly!
%    
%    Calling \code{xyfit_fun ("bknpowerlaw");} sets up a powerlaw fit
%    function for xy-data. It has the form \code{y = norm*x^{-index}}
%\seealso{xyfit_fun, define_xydata, plot_xyfit, linear_regression}
%!%-
{
   variable xref, yref, par;
   switch(_NARGS)
   { case 0: return ["norm", "index1", "index2", "ebr"]; } % fit parameters
   { case 3: (xref, yref, par)=(); }
   { return help(_function_name); }
   
   variable ind  = where(@xref <= par[3]);
   variable ind2 = where(@xref > par[3]);

   (@yref)  = par[0] * ((@xref) /par[3])^(-par[1]);
   if (length(ind2)>0){
      (@yref)[ind2] = par[0] * ((@xref)[ind2]/par[3])^(-par[2]);
   }
}

define bknpowerlaw_xyfit_default(i)
{
  switch(i)
  { case 0: return (1, 0, -1e5, 1e5); }
  { case 1: return (1, 0, -1, 4); }
  { case 2: return (1, 0, -1, 4); }
  { case 3: return (1, 0, -1e5, 1e5); }
}
