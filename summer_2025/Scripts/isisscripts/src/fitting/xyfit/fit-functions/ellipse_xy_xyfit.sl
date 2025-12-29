%%%%%%%%%%%%%%%%%%%%%%
define ellipse_xy_xyfit()
%%%%%%%%%%%%%%%%%%%%%%
{
  variable xref, yref, par;
  switch(_NARGS)
  { case 0: return ["x0 [x center]", "y0 [y center]", "semi_major", "axis_ratio [minor/major]", "pos_angle [deg]"]; } % fit parameters
  { case 3: (xref, yref, par) = (); }
  { return help(_function_name); }

  variable phi = qualifier("curve_parameter");
  if(phi == NULL)
   throw UsageError, "error in ellipse xyfit function: please set_xyfit_qualifier(; curve_parameter=[0:2*PI:#steps]);";

  variable x, y;
  (x, y) = ellipse(par[2], par[2]*par[3], par[4]*PI/180, phi);
  (@xref, @yref) = (x+par[0], y+par[1]);
}

define ellipse_xy_xyfit_default(i)
{
  switch(i)
  { case 0: return (0   , 0   , -1e5 , 1e5 ); } % x-center 
  { case 1: return (0   , 0   , -1e5 , 1e5 ); } % y-center 
  { case 2: return (1   , 0   , 0    , 1e5 ); } % semi-major axis
  { case 3: return (1   , 0   , 1e-9 ,   1 ); } % axis ratio minor/major
  { case 4: return (1   , 0   , -360 , 360 ); } % position angle [deg]
}
