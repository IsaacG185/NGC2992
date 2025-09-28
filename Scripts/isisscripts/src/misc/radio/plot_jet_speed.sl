%%%%%%%%%%%%%%%%%%%%%%%%
define plot_jet_speed ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{plot_jet_speed}
%\synopsis{visualizes the jet_speed_struct used by init_jet_fit}
%\usage{plot_jet_speed (Struct_Type jet_speed_struct);}
%\qualifiers{
%\qualifier{xrange}{set the xrange (provide a list or array)}
%\qualifier{yrange}{set the yrange (provide a list or array)}
%}
%\seealso{init_jet_fit}
%!%-
%
{
  variable jss;
  switch(_NARGS)
  { case 1: jss = ();}
  { help(_function_name()); return; }
  variable one_day_in_years = 0.002737803091986241; % = 1./365.256363004; % sidereal year
  variable xmin,xmax;
  if (qualifier_exists("xrange"))
  { xmin = qualifier("xrange")[0];
    xmax = qualifier("xrange")[1];  }
  else
  { ( xmin, xmax ) = min_max( jss.time );
    xrange (xmin - 0.05*(xmax-xmin) , xmax + 0.05*(xmax-xmin) );  }
  variable ymin, ymax;
  if (qualifier_exists("yrange"))
  { ymin = qualifier("yrange")[0];
    ymax = qualifier("yrange")[1];  }
  else
  { ymin = min( jss.distance - jss.derr);
    ymax = max( jss.distance + jss.derr); }
  yrange (ymin - 0.05*(ymax-ymin) , ymax + 0.05*(ymax-ymin) );
  xlin; ylin;
  variable ci = unique(jss.component);
  variable i,k, counter = 0 , clr, pst;
  init_plot;
  variable pnt_styles = [1,2,4,8,10,11,12,14,15];
  variable colors     = [1:19];
  foreach i (ci)
  {
    k = where( jss.component == jss.component[i]);
    clr = pnt_styles[(counter mod 9)];
    pst = colors[(counter mod  19)];
    color (clr); point_style(pst);
    counter += 1;
    plot_with_err ( jss.time[k] , jss.distance[k]-jss.offset[k]
		    , jss.derr[k] ; overplot);
    connect_points(-1); color(clr);
    oplot([_max(xmin, jss.t0[i]), max(jss.time[k]) ],
    [(_max(xmin, jss.t0[i]) - jss.t0[i])*one_day_in_years*jss.speed[i],
     (max(jss.time[k]) - jss.t0[i])*one_day_in_years*jss.speed[i]
    ]);
  }
}
