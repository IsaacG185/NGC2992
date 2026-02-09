define TeX_value_pm_error()
%!%+
%\function{TeX_value_pm_error}
%\synopsis{formats a \code{(value, min, max)} triple as TeX string}
%\usage{String_Type TeX_value_pm_error(Double_Type value, Double_Type min, Double_Type max)}
%\altusage{String_Type TeX_value_pm_error(Struct_Type output_of__round_conf)}
%\qualifiers{
%\qualifier{factor}{[=\code{1}]: factor to multiply \code{value, min, max}, will not be shown,
%                   works only if the function is called with three arguments}
%\qualifier{neg}{factorize overall minus sign}
%\qualifier{sci}{[=\code{2}]: exponent to switch to scienficic notation}
%\qualifier{scismall}{[=\code{-sci}]: exponent for small numbers}
%\qualifier{scilarge}{[=\code{+sci}]: exponent for large numbers}
%}
%\description
%    \code{TeX_value_pm_error} tries to produce a reasonable TeX output
%    from a \code{(value, min, max)} tripel or the output of the function
%    \code{round_conf}.
%    Rounding and obtaining the number of digits is done with the
%    function \code{round_conf}.
%\seealso{round_conf,round_err}
%!%-
{
  variable s,val, mn, mx;
  switch(_NARGS)
  { case 3: (val, mn, mx) = ();
    variable factor = qualifier("factor", 1);
    val *= factor;
    mn  *= factor;
    mx  *= factor;
    s = round_conf(mn,val,mx;;__qualifiers);}
  { case 1: s = (); }
  { help(_function_name()); return; }

  val    = s.value;
  mn     = val-s.err_lo;
  mx     = val+s.err_hi;
  variable dig = s.digit;
  
  variable neg = qualifier_exists("neg") && (val<0);
  if(neg)
    (val, mn, mx) = (-val, -mx, -mn);

  variable max_abs = maxabs([mn, mx, val]);
  if(max_abs==0)  % mn == val == mx == 0
    return `$\equiv0$`;

  variable sci      = qualifier("sci",         2);
  variable scismall = qualifier("scismall", -sci);
  variable scilarge = qualifier("scilarge",  sci);

  variable power_str = "";
  variable power = 0;
  variable pow10 = 0;
  variable val4power = (val != 0 ? abs(val) : max_abs); % avoid problems with upper limits
  ifnot(10^scismall <= val4power < 10^scilarge)
  { power = int(log10(val4power)); % leading value >= 1
    if(power<0)
      power--;
    pow10 = 10^(-power);
    val *= pow10;
    mn  *= pow10;
    mx  *= pow10;
    power_str = sprintf(`\times10^{%d}`, power);
  }

  variable n = nint(power - dig);
  if (n<0)
  {
    pow10 = 10^(n);
    val *= pow10;
    mn  *= pow10;
    mx  *= pow10;
    power_str = sprintf(`\times10^{%d}`, power-n);
    n = 0;
  }
  
  variable fmt = "%.${n}f"$;
  variable m_err = sprintf(fmt, val - mn);
  variable p_err = sprintf(fmt, mx - val);
  variable err = (p_err==m_err ? `\pm`+p_err : "^{+$p_err}_{-$m_err}"$);
  val = sprintf(fmt, val);
  variable null = sprintf(fmt, 0);

  if(mn>=0 && val==null && m_err==null) % only upper limit found
    return sprintf(`$\le`+fmt+`%s$`, mx, power_str);
  else
  {
    variable paren = neg || power_str!="";
    return "$" + (neg ? "-" : "") + (paren ? `\left(` : "") + val + err + (paren ? `\right)` : "" ) + power_str + "$";
  }
}
