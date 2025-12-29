%%%%%%%%%%%%%%%%%%%
define round_conf()
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{round_conf}
%\synopsis{converts confidence intervals after DIN 1333 and gives the rounded decimal place.}
%\usage{Struct_Type round_conf(Double_Type conf_lo, conf_val, conf_hi);}
%\altusage{Struct_Type round_conf(Double_Type val, sym_err);}
%\description
%    \code{conf_lo} is the lower confidence limit
%    \code{conf_val} is the best fit
%    \code{conf_hi} is the upper confidence limit
%    The alternative usage with two arguemts allows to specify a
%    value \code{val} with a symmetric uncertainty \code{sym_err}.
%
%    The returned structure contains the fields
%    - \code{err_lo} (the rounded lower error)
%    - \code{value_val} (the rounded best fit)
%    - \code{err_hi} (the rounded upper error)
%    - \code{digit} (the rounded decimal place of the error)
%
%\seealso{round_err, TeX_value_pm_error}
%!%-
{
  variable val_lo, val, val_hi, err, min_digit;
  variable err_lo, err_hi;
  switch(_NARGS)
  { case 3: (val_lo,val,val_hi) = ();
    if(val-val_lo<0 or val_hi-val<0)
    { vmessage("error in %s: value has to be within confidence limits (check order of arguments)",_function_name());
      return;
    }
     err_lo = round_err(val-val_lo;;__qualifiers);
     err_hi = round_err(val_hi-val;;__qualifiers);
    
    variable digit1 = err_lo.digit;
    variable digit2 = err_hi.digit;
    min_digit = _min(digit1,digit2);
    
    if (digit1!=digit2) {
      err_lo = round_err(val-val_lo; digits=min_digit);
      err_hi = round_err(val_hi-val; digits=min_digit);
    }

  }
  { case 2: (val,err) = ();
    err_lo = round_err(abs(err));
    err_hi = err_lo;
    min_digit = err_lo.digit;
  }
  { help(_function_name()); return; }
  
  val = round(val*10^(-min_digit))*10^min_digit;
  % account for numerical problems such as val=4.145, digits=-1 => round(val*10^(-min_digit))*10^min_digit = 4.1000000000000005 via fmt:
  variable fmt;
  if(min_digit<0)
    fmt = sprintf("%%.%df", nint(-min_digit));
  else
    fmt = "%.0f";
  val = atof(sprintf(fmt, val));
  return struct{err_lo=err_lo.value,value=val,err_hi=err_hi.value,digit=min_digit};
}
