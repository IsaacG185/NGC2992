define angle_to_rad()
%!%+
%\function{angle_to_rad}
%\synopsis{converts an angle in degrees or h:m:s format into radian}
%\usage{Double_Type angle_to_rad(Double_Type x);}
%\qualifiers{
%\qualifier{unit}{[\code{="deg"}] unit of \code{x} (\code{"deg"}/\code{"hms"}/\code{"rad"})}
%}
%\description
%    \code{x} can be a scalar value or (unless \code{unit="rad"}) an array of the form\n
%    - \code{[deg, arcmin]} (respectively \code{[hour, min]} for \code{unit="hms"})\n
%    - \code{[deg, arcmin, arcsec]} (respectively \code{[hour, min, sec]} for \code{unit="hms"})\n
%    - \code{[sign, deg, arcmin, arcsec]} (respectively \code{[sign, hour, min, sec]}).\n
%    The latter representation is needed for \code{-1 < deg}/\code{hour < 0}.
%\seealso{hms2deg,dms2deg}
%!%-
{
  if(_NARGS==0)  { help(_function_name()); return; }
  variable unit = qualifier("unit", "deg");
  foreach (__pop_list(_NARGS))
  { variable x = ();
    variable s = 1;
    if(typeof(x)==Array_Type)
    { if(unit=="rad")
	vmessage(`error (%s): cannot convert array with unit="rad"`, _function_name());
      if(x[0]<0)  s = -1;
      switch(length(x))
      { case 2: x = s*(abs(x[0]) + x[1]/60.); }
      { case 3: x = s*(abs(x[0]) + x[1]/60. + x[2]/3600.); }
      { case 4: x = s*(x[1] + x[2]/60. + x[3]/3600.); }
    }
    switch(unit)
    { case "deg": x *= PI/180.; }
    { case "hms": x *= PI/12.; }
    { case "rad": ; }
    { vmessage(`error (%s): unknown unit="%s"`, _function_name(), unit); }
    x;  % left on stack
  }
}
