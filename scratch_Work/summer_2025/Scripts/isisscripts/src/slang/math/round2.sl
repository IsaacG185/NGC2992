define round2()
%!%+
%\function{round2}
%\synopsis{Round to the nearest integral value or to given digit}
%\usage{Double_Type[] = round2( Double_Type[] value);}
%\altusage{Double_Type[] = round2( Double_Type[] value, Integer_Type digit );}
%\description
%   This function rounds its argument to the nearest integral value and
%   returns it as a floating point result. If the argument is an array,
%   an array of the corresponding values will be returned.
%   If a 2nd argument is given it is used as digit the value is supposed
%   to be rounded to.
%\seealso{round, floor2, ceil2, nint}
%!%-
{
  variable val, dig = 0;
  switch (_NARGS)
  { case 1: val = (); }
  { case 2: (val,dig)=();}
  { help(_function_name); return; }

  dig = nint(dig);
  return round( val * 10^(-dig) )*10^dig;  
}

define ceil2()
  %!%+
  %\function{ceil2}
  %\synopsis{Round value up to the nearest integral value or to given digit}
  %\usage{Double_Type[] = ceil2( Double_Type[] value);}
  %\altusage{Double_Type[] = ceil2( Double_Type[] value, Integer_Type digit );}
  %\description
  %   This function rounds its argument up to the nearest integral value and
  %   returns it as a floating point result. If the argument is an array,
  %   an array of the corresponding values will be returned.
  %   If a 2nd argument is given it is used as digit the value is supposed
  %   to be rounded up to.
  %\seealso{ceil, floor2, round2, nint}
  %!%-
{
    variable val, dig = 0;
    switch (_NARGS)
  { case 1: val = (); }
  { case 2: (val,dig)=();}
  { help(_function_name); return; }

    dig = nint(dig);
    return ceil( val * 10^(-dig) )*10^dig;
}

define floor2()
  %!%+
  %\function{floor2}
  %\synopsis{Round value down to the nearest integral value or to given digit}
  %\usage{Double_Type[] = floor2( Double_Type[] value);}
  %\altusage{Double_Type[] = floor2( Double_Type[] value, Integer_Type digit );}
  %\description
  %   This function rounds its argument down to the nearest integral value and
  %   returns it as a floating point result. If the argument is an array,
  %   an array of the corresponding values will be returned.
  %   If a 2nd argument is given it is used as digit the value is supposed
  %   to be rounded down to.
  %\seealso{floor, ceil2, round2, nint}
  %!%-
{
    variable val, dig = 0;
    switch (_NARGS)
  { case 1: val = (); }
  { case 2: (val,dig)=();}
  { help(_function_name); return; }

    dig = nint(dig);
    return floor( val * 10^(-dig) )*10^dig;
}
