define hardnessratio_error_prop()
%!%+
%\function{hardnessratio_error_prop}
%\synopsis{calculates a ratio and error propagation}
%\usage{(hr, err) = hardnessratio_error_prop(h, h_err, s, s_err);}
%\description
%    \code{hr  = (h-s) / (h+s)}\n
%    \code{err = sqrt[ (2s/(h+s)^2 * h_err)^2  + (2h/(h+s)^2 * s_err)^2 ]}
%\seealso{ratio_error_prop}
%!%-
{
  variable h, h_err, s, s_err;
  switch(_NARGS)
  { case 4: (h, h_err, s, s_err) = (); }
  { help(_function_name()); return; }

  return 1.*(h-s)/(h+s),  2.*sqrt( 1.*(s*h_err)^2  + (h*s_err)^2 ) / (h+s)^2;
}
