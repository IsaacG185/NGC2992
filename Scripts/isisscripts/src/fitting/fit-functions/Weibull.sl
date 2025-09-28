%%%%%%%%%%%%%%%%%%
define Weibull_fit(bin_lo, bin_hi, pars)
%%%%%%%%%%%%%%%%%%
%!%+
%\function{Weibull (fit-function)}
%\description
%    \code{W(x) = norm * k/lambda * ((x-x0)/lam)^(k-1) * exp(-((x-x0)/lam)^k);}\n
%    \code{W( x0 + lambda * (1-1/k)^(1/k) )  =  max.}
%!%-
{
  variable x = (bin_lo + bin_hi) / 2. ;
  variable k      = pars[0];
  variable lambda = pars[1];
  variable x0     = pars[2];
  variable norm   = pars[3];
  variable y = norm * k/lambda * ((x-x0)/lambda)^(k-1) * exp(-((x-x0)/lambda)^k);
  y[where(x<=x0)] = 0;
  return y;
}

%%%%%%%%%%%%%%%%%%%%%%
define Weibull_default(i)
%%%%%%%%%%%%%%%%%%%%%%
{ switch(i)
  { case 0: return (4.9, 0, 0, 10 ); }
  { case 1: return (3.0, 0, 0, 20 ); }
  { case 2: return (1  , 0, 0, 0  ); }
  { case 3: return (1e3, 0, 0, 1e6); }
}

add_slang_function("Weibull", ["k", "lambda", "x0", "norm"]);
set_param_default_hook("Weibull", "Weibull_default");
