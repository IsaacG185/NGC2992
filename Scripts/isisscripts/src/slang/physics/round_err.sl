%%%%%%%%%%%%%%%%%%%
define round_err()
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{round_err}
%\synopsis{rounds an error after DIN 1333 and gives the rounded decimal place}
%\usage{Struct_Type round_err(Double_Type x);}
%\qualifiers{
%    \qualifier{digits}{decimal place where rounding will be applied (suspends DIN 1333)}
%    \qualifier{sloppy}{Deactivates moving rounding decimal place if significant decimal place < 3 (suspends DIN 1333)}
%}
%\description
%    \code{x} is the error which will be rounded
%
%    The returned structure contains the fields
%    - \code{value} (the rounded error)
%    - \code{digit} (the rounded decimal place of the error)
%
% EXAMPLES
%     round_err(0.1278) will return value=0.13 and digit=-2
%     round_err(1278)   will return value=1300 and digit= 2
%     since after DIN 1333, the decimal point may only be right after the rounded digit or left of it,
%     the error should be in LaTeX assigned as $13.0\\times 10^{2}$
%     (? comment: in order to have the correct number of significant digits shouldn't it be:
%     $0.13\\times 10^{4}$, $1.3\\times 10^{3}$, or $13\\times 10^{2}$)
%\seealso{round_conf}
%!%-
{
  variable x;
  switch(_NARGS)
  { case 1: x = (); }
  { help(_function_name()); return; }
  variable digits = 0;
  ifnot (x==0)
  {
    if(qualifier_exists("digits"))
      digits = qualifier("digits");
    else
    {
      digits = floor(log10(x)); % first significant decimal place
      if( (round2( x/(10^digits),-14 ) < 3 ) and not qualifier_exists("sloppy")) % DIN 1333: if first significant decimal place is smaller than 3, then next decimal place is the one to be rounded; if qualifier sloppy is present this will be ignored
	digits--;
    }
    % account for numerical problems such as x=4.7-4.1 = 0.6000000000000005 causing ceil(x) = 7 instead of 6
    x = x*10^(-digits);
    if( x-int(x) > 10^(-15) ) % all decimal places beyond 15 are not trustworthy due to numerics
      x = ceil(x);
    x *= 10^digits;
    % account for numerical problems such as x=0.6, digits=-1 => ceil(x*10^(-digits))*10^digits = 0.6000000000000001 via fmt:
    variable fmt;
    if(digits<0)
      fmt = sprintf("%%.%df", nint(-digits));
    else
      fmt = "%.0f";
    x = atof(sprintf(fmt, x));
  }
  return struct{value=x, digit=digits};
}
