require("xfig");

% --------------------------------------------------------
% determine roll angle (kindly provided by Manfred Hanke):
private define projected_angle_for_eye(dist, theta, phi, roll, x, y, z)
{
  xfig_set_eye(dist, theta, phi, roll);
  variable v = vector([0,x], [0,y], [0,z]);
  variable px, py; (px, py) = xfig_project_to_xfig_plane(v);
  return atan2(py[0]-py[1], px[1]-px[0]) * 180/PI;  % Xfig's y increases downwards
}

private define computed_roll_angle(dist, theta, phi, v, expected_angle)
{
  variable roll = [0:360:#3601] [[:-2]];
  variable angle = array_map(Double_Type, &projected_angle_for_eye, dist, theta, phi, roll, v.x, v.y, v.z);
  variable delta = (angle - expected_angle) mod 360;
  delta[where(delta < -180)] += 360;
  delta[where(delta > +180)] -= 360;
  roll = roll[wherefirstmin(abs(delta))];
  return roll;
}
private define xfig_set_eye_with_computed_roll_angle(dist, theta, phi)
{
  xfig_set_eye(dist, theta, phi, computed_roll_angle(dist, theta, phi, vector(0,0,1), 90));
}
% --------------------------------------------------------

define xfig_3d_orbit_on_cube()
%!%+
%\function{xfig_3d_orbit_on_cube}
%\synopsis{Visualize 3d orbits by projecting them onto a cube}
%\usage{xfig = xfig_3d_orbit_on_cube(Struct_Type orbits [, Struct_Type text]; qualifiers)}
%\description
%    The orbits have to be given in cartesian coordinates (x,y,z) and are passed
%    to the function via a structure. Each individual orbit is itself a structure
%    with fields 'x', 'y', and 'z'. The orbits are then visualized by plotting the
%    projections to the xy-, xz-, and yz-plane on the surfaces of a cube. Use the
%    qualifiers to change the viewing angle, labels, or properties of the cube and
%    the background grid. The function's optional second argument can be used to
%    add text or symbols to the plot (see example section below).
%\notes
%    If one of the three coordinates is missing, the projection on the plane defined
%    by the remaining two coordinates is still plotted. This feature can be used to
%    add lines or text to one specific plane only.
%
%    The properties of the orbits (line style, color, ...) can be changed by adding the
%    field 'qualies' to the structure that decribes the orbit. The field 'qualies' is
%    again a structure whose fields are qualifiers of the function 'xfig_new_polyline'.
%\qualifiers{
%\qualifier{phi [=-45]}{Azimuthal angle in the x-y-plane in degrees (-90 < phi < 0).}
%\qualifier{theta [=60]}{Polar angle from the z-axis in degrees (0 < theta < 90).}
%\qualifier{dist [=1e6]}{Distance of the eye from the focus.}
%\qualifier{scale [=4]}{Factor to scale dimensions with respect to the character size (scale > 0).}
%\qualifier{x_label [="$x$\\,(kpc)"]}{x-label.}
%\qualifier{y_label [="$y$\\,(kpc)"]}{y-label.}
%\qualifier{z_label [="$z$\\,(kpc)"]}{z-label.}
%\qualifier{digits [=1]}{Digits for ticmarks (a non-negative integer).}
%\qualifier{cube}{Modify the cube by providing a structure whose fields are qualifiers of the function 'xfig_new_polyline'.}
%\qualifier{grid}{Modify the grid by providing a structure whose fields are qualifiers of the function 'xfig_new_polyline'.}
%\qualifier{center}{Center the cube at (0,0,0).}
%\qualifier{z_adjust}{Use separate scale for z-axis.}
%}
%\example
%   % basic example:
%   o = struct{ orbit1, orbit2, orbit3 };
%   o.orbit1 = struct{ x=[0,1], y=[0,1], z=[0,1] };
%   o.orbit2 = struct{ x=[1,1], y=[4,1], z=[-3,0], qualies=struct{color="blue"} };
%   o.orbit3 = struct{ x=[-1,0,1], y=[-1,1,-1], qualies=struct{closed, fillcolor="tomato", depth=5} }; % filled triangle in the xy-plane
%   xfig = xfig_3d_orbit_on_cube(o);
%   xfig.render("test.pdf");
%   xfig_set_eye(1e6,0,0,0); % restore the default position of the eye
%
%   % adding text to xy-plane:
%   t = struct{ triangle=struct{text="triangle", x0=0, y0=0, depth=4} };
%   xfig_3d_orbit_on_cube(o,t).render("test.pdf");
%   xfig_set_eye(1e6,0,0,0); % restore the default position of the eye
%
%   % example involving the function 'orbit_calculator':
%   o = orbit_calculator([12,12],[22,22],[29.6,29.6],[40,40],[49,49],[36,36],[3.078,4],[262,262],[-13.52,-13.52],[16.34,16.34],-1000; r_disk=50, set);
%   set_struct_field(o.tr, "o0", struct_combine(o.tr.o0, "qualies")); set_struct_field(o.tr.o0, "qualies", struct{ color="red", depth=2, backward_arrow });
%   set_struct_field(o.tr, "o1", struct_combine(o.tr.o1, "qualies")); set_struct_field(o.tr.o1, "qualies", struct{ color="blue", depth=1, backward_arrow });
%   xfig_3d_orbit_on_cube(o.tr).render("test.pdf");
%   xfig_set_eye(1e6,0,0,0); % restore the default position of the eye
%
%   % changing the appearance of the cube and grid:
%   xfig_3d_orbit_on_cube(o.tr; cube=struct{color="red",width=2}, grid=struct{line=0}).render("test.pdf");
%   xfig_set_eye(1e6,0,0,0); % restore the default position of the eye
%
%   % adding symbols:
%   t = struct{ sun, gc };
%   t.sun = struct{ text="$\\odot$", x0=-8.4, y0=0, z0=0, depth=3 };
%   t.gc = struct{ text="+", x0=0, y0=0, z0=0 };
%   xfig_3d_orbit_on_cube(o.tr, t).render("test.pdf");
%   xfig_set_eye(1e6,0,0,0); % restore the default position of the eye
%\seealso{orbit_calculator}
%!%-
{
  variable o, s;
  if(_NARGS==1)
    o = ();
  else if(_NARGS==2)
    (o, s)  = ();
  else
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  ifnot(is_struct_type(o))
    throw UsageError, sprintf("Usage error in '%s': first input parameter has to be a structure.", _function_name());
  % -----------
  % qualifiers:
  variable digits = qualifier("digits", 1);
  if(typeof(digits)!=Integer_Type or digits<0)
  {
    vmessage("Warning in '%s': Qualifier 'digits' needs to be a non-negative Integer_Type. Setting it to default value digits=1.", _function_name());
    digits = 1;
  }
  variable fmt = sprintf("%%.%df", digits);
  variable label_x = qualifier("x_label", "$x$\\,(kpc)");
  variable label_y = qualifier("y_label", "$y$\\,(kpc)");
  variable label_z = qualifier("z_label", "$z$\\,(kpc)");
  variable scale = qualifier("scale", 4);
  if(scale<=0)
  {
    vmessage("Warning in '%s': Qualifier 'scale' out of valid range scale>0. Setting it to default value scale=4.", _function_name());
    scale = 4;
  }
  % -----------------------
  % set eye and roll angle:
  variable phi = qualifier("phi", -45);
  ifnot(-90<phi<0)
  {
    vmessage("Warning in '%s': Qualifier 'phi' out of valid range -90<phi<0. Setting it to default value phi=-45.", _function_name());
    phi = -45;
  }
  variable theta = qualifier("theta", 60);
  ifnot(0<theta<90)
  {
    vmessage("Warning in '%s': Qualifier 'theta' out of valid range 0<theta<90. Setting it to default value theta=60.", _function_name());
    theta = 60;
  }
  xfig_set_focus(vector(0,0,0));
  xfig_set_eye_with_computed_roll_angle(qualifier("dist", 1e6), theta, phi);
  % -----------------------
  % -----------
  % -------------
  % preparations:
  variable xmin = +_Inf, xmax = -_Inf;
  variable ymin = +_Inf, ymax = -_Inf;
  variable zmin = +_Inf, zmax = -_Inf;
  % determine plot ranges:
  variable field;
  variable orbits = get_struct_field_names(o);
  foreach field (orbits)
  {
    % x:
    if(struct_field_exists( get_struct_field( o, field ), "x"))
    {
      xmin = _min(xmin,min(get_struct_field( get_struct_field( o, field ), "x")));
      xmax = _max(xmax,max(get_struct_field( get_struct_field( o, field ), "x")));
    }
    % y:
    if(struct_field_exists( get_struct_field( o, field ), "y"))
    {
      ymin = _min(ymin,min(get_struct_field( get_struct_field( o, field ), "y")));
      ymax = _max(ymax,max(get_struct_field( get_struct_field( o, field ), "y")));
    }
    % z:
    if(struct_field_exists( get_struct_field( o, field ), "z"))
    {
      zmin = _min(zmin,min(get_struct_field( get_struct_field( o, field ), "z")));
      zmax = _max(zmax,max(get_struct_field( get_struct_field( o, field ), "z")));
    }
  }
  if(is_struct_type(s))
  {
    variable symbols = get_struct_field_names(s);
    foreach field (symbols)
    {
      % x:
      if(struct_field_exists( get_struct_field( s, field ), "x0"))
      {
	xmin = _min(xmin, get_struct_field(get_struct_field( s, field ), "x0"));
	xmax = _max(xmax, get_struct_field(get_struct_field( s, field ), "x0"));
      }
      % y:
      if(struct_field_exists( get_struct_field( s, field ), "y0"))
      {
	ymin = _min(ymin, get_struct_field(get_struct_field( s, field ), "y0"));
	ymax = _max(ymax, get_struct_field(get_struct_field( s, field ), "y0"));
      }
      % z:
      if(struct_field_exists( get_struct_field( s, field ), "z0"))
      {
	zmin = _min(zmin, get_struct_field(get_struct_field( s, field ), "z0"));
	zmax = _max(zmax, get_struct_field(get_struct_field( s, field ), "z0"));
      }
    }
  }
  % -----------------------------
  % if no data are to be plotted:
  if(xmin==+_Inf)
    xmin = -1;
  if(ymin==+_Inf)
    ymin = -1;
  if(zmin==+_Inf)
    zmin = -1;
  if(xmax==-_Inf)
    xmax = 1;
  if(ymax==-_Inf)
    ymax = 1;
  if(zmax==-_Inf)
    zmax = 1;
  % -----------------------------
  variable buffer = 0.05;
  xmin -= buffer*(xmax-xmin);
  xmax += buffer*(xmax-xmin);
  ymin -= buffer*(ymax-ymin);
  ymax += buffer*(ymax-ymin);
  zmin -= buffer*(zmax-zmin);
  zmax += buffer*(zmax-zmin);
  %
  if(qualifier_exists("center")) % center at origin
  {
    variable xy_dim = _max(abs(xmin), abs(xmax), abs(ymin), abs(ymax));
    variable z_dim = _max(abs(zmin), abs(zmax));
    if(qualifier_exists("z_adjust"))
    {
      xmin = -xy_dim;
      xmax =  xy_dim;
      ymin = -xy_dim;
      ymax =  xy_dim;
      zmin = -z_dim;
      zmax =  z_dim;
    }
    else
    {
      variable dim = _max(xy_dim,z_dim);
      xmin = -dim;
      xmax =  dim;
      ymin = -dim;
      ymax =  dim;
      zmin = -dim;
      zmax =  dim;
    }
  }
  %
  variable xy_unit = _max( ceil((xmax-xmin)*10^digits/4.), ceil((ymax-ymin)*10^digits/4.) )*2./10^digits;
  variable z_unit = ceil((zmax-zmin)*10^digits/4.)*2./10^digits;
  ifnot(qualifier_exists("z_adjust"))
  {
    z_unit = _max(xy_unit,z_unit);
    xy_unit = z_unit;
  }
  variable x_center = round(0.5*(xmin+xmax)*10^digits)/10^digits;
  variable y_center = round(0.5*(ymin+ymax)*10^digits)/10^digits;
  variable z_center = round(0.5*(zmin+zmax)*10^digits)/10^digits;
  % -------------
  % -----
  % xfig:
  variable xfig = xfig_plot_new();
  xfig.axis(; off);
  % ----------------
  % reference system
  variable cube = struct{ depth=99 };
  if(qualifier_exists("cube") && is_struct_type(qualifier("cube")))
    cube = struct_combine(cube, qualifier("cube"));
  xfig.add_object( xfig_new_polyline( scale*vector([-1,1] ,[1,1]  ,[1,1]  );; cube) );
  xfig.add_object( xfig_new_polyline( scale*vector([-1,1] ,[-1,-1],[1,1]  );; cube) );
  xfig.add_object( xfig_new_polyline( scale*vector([-1,1] ,[-1,-1],[-1,-1]);; cube) );
  xfig.add_object( xfig_new_polyline( scale*vector([1,1]  ,[-1,1] ,[1,1]  );; cube) );
  xfig.add_object( xfig_new_polyline( scale*vector([-1,-1],[-1,1] ,[1,1]  );; cube) );
  xfig.add_object( xfig_new_polyline( scale*vector([1,1]  ,[-1,1] ,[-1,-1]);; cube) );
  xfig.add_object( xfig_new_polyline( scale*vector([-1,-1],[-1,-1],[-1,1] );; cube) );
  xfig.add_object( xfig_new_polyline( scale*vector([1,1]  ,[-1,-1],[-1,1] );; cube) );
  xfig.add_object( xfig_new_polyline( scale*vector([1,1]  ,[1,1]  ,[-1,1] );; cube) );
  variable i, tics = 2; % total number of ticmarks is 2*tics-1
  variable grid = struct{ line=1, color="gray", depth=100 };
  if(qualifier_exists("grid") && is_struct_type(qualifier("grid")))
    grid = struct_combine(grid, qualifier("grid"));
  _for i(-tics,tics,1)
  {
    xfig.add_object( xfig_new_polyline( scale*vector([-1,1],i/(1.*tics)*[1,1],[1,1]);;   grid) );
    xfig.add_object( xfig_new_polyline( scale*vector([-1,1],[-1,-1],i/(1.*tics)*[1,1]);; grid) );
    xfig.add_object( xfig_new_polyline( scale*vector([1,1],i/(1.*tics)*[1,1],[-1,1]);;   grid) );
    xfig.add_object( xfig_new_polyline( scale*vector(i/(1.*tics)*[1,1],[-1,-1],[-1,1]);; grid) );
    xfig.add_object( xfig_new_polyline( scale*vector([1,1],[-1,1],i/(1.*tics)*[1,1]);;   grid) );
    xfig.add_object( xfig_new_polyline( scale*vector(i/(1.*tics)*[1,1],[-1,1],[1,1]);;   grid) );
  }
  xfig.add_object( xfig_new_polyline( scale*vector([-.5,.5],[-1.1,-1.1],[-1,-1]);;     struct_combine( cube, struct{ forward_arrow }))); % Arrow parallel to x-axis
  xfig.add_object( xfig_new_polyline( scale*vector([1.1,1.1],[-.5,.5],[-1,-1]);;       struct_combine( cube, struct{ forward_arrow }))); % Arrow parallel to y-axis
  xfig.add_object( xfig_new_polyline( scale*vector([1.05,1.05],[1.05,1.05],[-.5,.5]);; struct_combine( cube, struct{ forward_arrow }))); % Arrow parallel to z-axis
  xfig.add_object( xfig_new_text(label_x;; struct_combine( cube, struct{ x0=0, y0=-1.15*scale, z0=-1*scale, just=[0,1.5] }))); % x-label
  xfig.add_object( xfig_new_text(label_y;; struct_combine( cube, struct{ x0=1.15*scale, y0=0, z0=-1*scale, just=[-0.5,0] }))); % y-label
  xfig.add_object( xfig_new_text(label_z;; struct_combine( cube, struct{ x0=1.12*scale, y0=1.12*scale, z0=0, just=[-0.1,-0.1], rotate=90 }))); % z-label
  xfig.add_object( xfig_new_text(sprintf(fmt, -0.5*xy_unit+x_center);; struct_combine( cube, struct{ x0=-.5*scale,    y0=1.05*scale, z0=1*scale,    just=[0,-1.]  }))); % x-ticmark
  xfig.add_object( xfig_new_text(sprintf(fmt,  0.0*xy_unit+x_center);; struct_combine( cube, struct{ x0=0,            y0=1.05*scale, z0=1*scale,    just=[0,-1.]  }))); % x-ticmark
  xfig.add_object( xfig_new_text(sprintf(fmt,  0.5*xy_unit+x_center);; struct_combine( cube, struct{ x0=.5*scale,     y0=1.05*scale, z0=1*scale,    just=[0,-1.]  }))); % x-ticmark
  xfig.add_object( xfig_new_text(sprintf(fmt, -0.5*xy_unit+y_center);; struct_combine( cube, struct{ x0=-1.075*scale, y0=-.5*scale,  z0=1*scale,    just=[0.5,0]  }))); % y-ticmark
  xfig.add_object( xfig_new_text(sprintf(fmt,  0.0*xy_unit+y_center);; struct_combine( cube, struct{ x0=-1.075*scale, y0=0,          z0=1*scale,    just=[0.5,0]  }))); % y-ticmark
  xfig.add_object( xfig_new_text(sprintf(fmt,  0.5*xy_unit+y_center);; struct_combine( cube, struct{ x0=-1.075*scale, y0=.5*scale,   z0=1*scale,    just=[0.5,0]  }))); % y-ticmark
  xfig.add_object( xfig_new_text(sprintf(fmt, -0.5*z_unit+z_center);;  struct_combine( cube, struct{ x0=-1*scale,     y0=-1*scale,   z0=-0.5*scale, just=[0.7,0.7]}))); % z-ticmark
  xfig.add_object( xfig_new_text(sprintf(fmt,  0.0*z_unit+z_center);;  struct_combine( cube, struct{ x0=-1*scale,     y0=-1*scale,   z0=0,          just=[0.7,0.7]}))); % z-ticmark
  xfig.add_object( xfig_new_text(sprintf(fmt,  0.5*z_unit+z_center);;  struct_combine( cube, struct{ x0=-1*scale,     y0=-1*scale,   z0=0.5*scale,  just=[0.7,0.7]}))); % z-ticmark
  % ----------------
  % -------
  % orbits:
  foreach field (orbits)
  {
    variable temp = get_struct_field(o, field);
    variable qualies = struct{ color="black" };
    if(struct_field_exists( temp, "qualies" ))
      qualies = struct_combine( qualies, get_struct_field(temp, "qualies") );
    if(struct_field_exists(temp, "x") and struct_field_exists(temp, "y"))
      xfig.add_object( xfig_new_polyline(vector( (temp.x-x_center)/xy_unit*scale, (temp.y-y_center)/xy_unit*scale, 0*temp.x+scale );; qualies) ); % xy-plane
    if(struct_field_exists(temp, "x") and struct_field_exists(temp, "z"))
      xfig.add_object( xfig_new_polyline(vector( (temp.x-x_center)/xy_unit*scale, 0*temp.x-scale, (temp.z-z_center)/z_unit*scale ) ;; qualies) ); % xz-plane
    if(struct_field_exists(temp, "y") and struct_field_exists(temp, "z"))
      xfig.add_object( xfig_new_polyline(vector( 0*temp.y+scale, (temp.y-y_center)/xy_unit*scale, (temp.z-z_center)/z_unit*scale)  ;; qualies) ); % yz-plane
  }
  % -------
  % --------
  % symbols:
  if(is_struct_type(s))
  {
    foreach field (symbols)
    {
      temp = get_struct_field(s, field);
      variable x0=0, y0=0, z0=0;
      if(struct_field_exists(temp, "x0"))
	x0 = (get_struct_field(temp, "x0")-x_center)/xy_unit*scale;
      if(struct_field_exists(temp, "y0"))
	y0 = (get_struct_field(temp, "y0")-y_center)/xy_unit*scale;
      if(struct_field_exists(temp, "z0"))
	z0 = (get_struct_field(temp, "z0")-z_center)/z_unit*scale;
      if(struct_field_exists(temp, "x0") and struct_field_exists(temp, "y0")) % xy-plane
	xfig.add_object(xfig_new_text(temp.text;; struct_combine(temp, struct{ x0=x0, y0=y0, z0=scale }) ));
      if(struct_field_exists(temp, "x0") and struct_field_exists(temp, "z0")) % xz-plane
	xfig.add_object(xfig_new_text(temp.text;; struct_combine(temp, struct{ x0=x0, y0=-scale, z0=z0 }) ));
      if(struct_field_exists(temp, "y0") and struct_field_exists(temp, "z0")) % yz-plane
	xfig.add_object(xfig_new_text(temp.text;; struct_combine(temp, struct{ x0=scale, y0=y0, z0=z0 }) ));
    }
  }
  % --------
  % -----
  return xfig;
}

