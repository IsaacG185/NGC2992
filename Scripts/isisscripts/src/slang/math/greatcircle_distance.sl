
define greatcircle_distance()
%!%+
%\function{greatcircle_distance}
%\synopsis{calculates the angular distance between two points on a sphere in radians}
%\usage{Double_Type greatcircle_distance(alpha1, delta1, alpha2, delta2)}
%\qualifiers{
%\qualifier{unit}{[\code{="deg"}] unit of the input angular coordinates}
%\qualifier{alpha1_unit}{[\code{="deg"}] unit of the alpha1}
%\qualifier{alpha2_unit}{[\code{="deg"}] unit of the alpha2}
%\qualifier{delta1_unit}{[\code{="deg"}] unit of the delta1}
%\qualifier{delta2_unit}{[\code{="deg"}] unit of the delta2}
%}
%\description
%
%    DEPRECATED - please use angular_separation instead
%    (\code{alpha}i, \code{delta}i) are the spherical coordinates of point i.\n
%    \code{unit="deg"}: \code{alpha}i and \code{delta}i are in degrees.\n
%                They can be scalar values or arrays of the form
%                \code{[deg, arcmin]}, \code{[deg, arcmin, arcsec]} or \code{[sign, deg, arcmin, arcsec]}.
%    \code{unit="rad"}: \code{alpha}i and \code{delta}i are scalars in radian.\n
%    \code{unit="hms"}: \code{alpha}i are scalars hour angles (24h = 360deg)
%                or arrays in h:m:s format, i.e., \code{[h, m]} or \code{[h, m, s]}.
%                The \code{delta}i are in degrees as above.
%                The units of each coordinate can be set independently.
%    Note that independent of the unit setting, the returned great circle
%    distance will always be in radian.
%\seealso{greatcircle_coordinates}
%!%-
{
  variable x1, y1, x2, y2;
  switch(_NARGS)
  { case 4: (x1, y1, x2, y2) = (); }
  { help(_function_name()); return; }

  variable q = __qualifiers();
  variable new_q = struct{ unit = qualifier("alpha1_unit",qualifier("unit","deg")) };
  x1 = angle_to_rad(x1;; new_q);
  new_q.unit = qualifier("alpha2_unit",qualifier("unit","deg"));
  x2 = angle_to_rad(x2;; new_q);
  if(qualifier("unit", "deg")=="hms")  q.unit = "deg";  % if RA is in HMS, delta is still in deg
  new_q.unit = qualifier("delta1_unit",qualifier("unit","deg"));
  y1 = angle_to_rad(y1;; new_q);
  new_q.unit = qualifier("delta2_unit",qualifier("unit","deg"));
  y2 = angle_to_rad(y2;; new_q);
  
  variable Dx = x2 - x1;
  % return acos( cos(Dx)*cos(y1)*cos(y2) + sin(y1)*sin(y2) );
  % This arccosine formula above can have large rounding errors for the common case where the distance is small
  variable c = cos(Dx);
  variable s1,c1,s2,c2;
  (s1,c1)=sincos(y1);
  (s2,c2)=sincos(y2);
  return atan2(sqrt((c2*sin(Dx))^2 + (c1*s2 - s1*c2*c)^2), s1*s2 + c1*c2*c);
}

