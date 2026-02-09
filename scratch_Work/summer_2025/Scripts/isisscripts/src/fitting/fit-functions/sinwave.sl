%%%%%%%%%%%%%%%%%%
define sinwave2_fit(bin_lo, bin_hi, pars)
%%%%%%%%%%%%%%%%%%
%!%+
%\function{sinwave2 (fit-function)}
%\description
%    a*sin(b*alpha+c)+d
%    (ISIS fit-function sinwave seems to be defined for keV space:
%    sinwave({a,b,c,d};alpha) = sinwave2({a,b,c,d};_A(alpha)))
%!%-
{
   variable a  = pars[0];
   variable b  = pars[1];
   variable c  = pars[2]; 
   variable d  = pars[3];
   
%   bin_hi -= bin_lo[0];
%   bin_lo -= bin_lo[0];
%   bin_lo *= 2*PI/bin_hi[-1];
%   bin_hi *= 2*PI/bin_hi[-1];
   
   variable alpha = 0.5*(bin_lo+bin_hi)*2*PI;
   
   return a*sin(b*alpha+c)+d;
}

%%%%%%%%%%%%%%%%%%%%%%
define sinwave2_default(i)
%%%%%%%%%%%%%%%%%%%%%%
{ switch(i)
  { case 0: return (1., 0, 1e-6, 1e6 ); }
  { case 1: return (1., 0, 1e-6, 1e6 ); }
  { case 2: return (0., 0, -2*PI, 2*PI ); }
  { case 3: return (0., 0, -1, 1 ); }
}

add_slang_function("sinwave2", ["a","b","c","d"]);
set_param_default_hook("sinwave2", "sinwave2_default");
