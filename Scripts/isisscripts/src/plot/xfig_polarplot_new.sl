require( "xfig" );

define xfig_polarplot_new()
%!%+
%\function{xfig_polarplot_new}
%\synopsis{creates a xfig_plot with polar axis}
%\usage{Struct_Type xfig_plot_new( Double_Type Size )}
%\altusage{Struct_Type xfig_plot_new()}
%\qualifiers{
%\qualifier{S}{[=10] Size of quadratic plot in width and height [cm].
%                      Is overwritten by argument size!}
%\qualifier{min}{[=0] Minimal angle of polar plot [degree]}
%\qualifier{max}{[=180] Maximal angle of polar plot [degree]}
%\qualifier{origin}{[=90] Origin of angular axis measured from x-axis [degree]}
%\qualifier{dir}{[=-1] Clockwise direction of polar plot axis (-1/1)}
%\qualifier{ticlabels}{[=.6] If 0 ticlabels are turned of. If not 0 it is used
%                       as relative justification}
%\qualifier{ticlabelsize}{[="small"] Size of ticlabels}
%\qualifier{ticlabelrotate}{[=1] Rotate polar ticlabels corresponding to their position (0/1)}
%\qualifier{ticthickness}{[=2] Thickness of tics}
%\qualifier{smallticinc}{[=2] Increment for small tics [degree]}
%\qualifier{medticinc}{[=10] Increment for medium tics [degree]}
%\qualifier{bigticinc}{[=20] Increment for big tics [degrees]}
%\qualifier{aticlables}{[=[min:max:bigticinc]] Ticlabels of angular axis}
%\qualifier{aticformat}{["$%d^\\circ$"] Format for the angular ticlabels}
%\qualifier{rlabel}{[=NULL] Label for the radial axis}
%\qualifier{rtics}{[=11] Number of radial tics}
%\qualifier{rticlabel}{[ =[0:1:#rtics/2] ] Radial tic labels. The 0th rtic label will not be drawn!}
%\qualifier{norticlabel}{If given, disabels radial tic labels.}
%\qualifier{rticlabelrotate}{[=0] Rotate polar ticlabels corresponding to their position (0/1)}
%\qualifier{padr}{[=0.05] Padding of radial axis}
%\qualifier{grid}{If given grid lines are plotted}
%\qualifier{gridcolor}{[="#BBBBBB"] Color of the grid lines}
%\qualifier{debug}{If given the x-y-axis of the underlying xfig_plot are shown}
%}
%\description
%   This function returns a xfig_plot_new structure but imprinted with polar axis.
%   This way one can use the functionality of xfig_plot_new. The polar axis
%   can be modified with the qualifiers above.
%
%   NOTE that when using %.(h)plot still requries 'x' and 'y' values, not 'radius'
%   and 'angle'. That means the user has to do the transformation manually accounting
%   for the 'origin', 'direction' and 'minimal'/'maximal' values (see examples).
%
%   TO BE IMPLEMENTED:
%   * functionality to us 'radius' and 'angle' for plotting!
%
%\example
%   % Plot coordinate transformation
%   variable min = 0,
%            max = 180,
%            dir = 1,
%            org = 45;
%   variable ang = [min:max:#100];
%   variable rad = 0.5+0.5*sin(ang*PI/180);
%   variable xf = xfig_polarplot_new(; min=min, max=max, origin=org, dir=dir, grid );
%   xf.plot( rad*cos( dir*(ang+org)*PI/180 ),
%            rad*sin( dir*(ang+org)*PI/180 ) ; color="red" );
%   xf.render("/tmp/test.pdf");
%
%\seealso{xfig_plot_new}
%
%!%-
{

  %%%%% QUALIFIERS & ARGUMENTS

  %% Plot Size
  variable S = qualifier("S",10);
  if(_NARGS){
    S = __pop_args(1);
    S = S[0].value;
    _pop_n(_NARGS-1); % get rid of all other arguments
  }

  %% Plot Limits & Orientation
  variable min = int(qualifier("min",0)) mod 360;
  variable max = int(qualifier("max",180)+.5) mod 360;
  if( min == max ) max += 360;
  variable origin = nint(qualifier("origin",90));
  variable dir  = sign(qualifier("dir",-1));
  
  variable ticlabels = qualifier("ticlabels",.6);
  variable ticlabelsize = qualifier("ticlabelsize","small");
  variable ticlabelrotate = qualifier("ticlabelrotate",1);
  variable ticthickness = qualifier("ticthickness",2);
  variable smallticinc  = int(qualifier("smallticinc",2));
  variable medticinc    = int(qualifier("medticinc",10));
  variable bigticinc    = int(qualifier("bigticinc",20));

  variable tlabels = qualifier("aticlabels", [min:max:bigticinc] );
  variable tlabelformat = qualifier("aticformat","$%d^\\circ$");
  
  variable rlabel = qualifier("rlabel");
  variable rtics = int(qualifier("rtics",11));
  variable rticlabelrotate = qualifier("rticlabelrotate",0);
  variable rticlabel = qualifier("rticlabel", array_map( String_Type, &sprintf, "$%.1f$",[0:1:#int(ceil(rtics/2.))]) );
  
  variable padr = qualifier("padr",0.05);
  padr = qualifier("padx",padr);
  padr = qualifier("pady",padr);

  variable gridlines = qualifier_exists("grid") ? 1 : 0;
  variable gridcolor = qualifier("gridcolor","#BBBBBB");
  
  %% ANGULAR & RADIAL TICSIZES
  variable
    rmax = .5*S,
    bigtic = rmax*.05,
    medtic = 0.6*bigtic,
    smalltic = 0.3*bigtic;

  variable rad = [0:rmax*(1-padr):#rtics];
  
  variable obj = xfig_new_compound_list ();
  variable tics = xfig_new_polyline_list ();
  variable grid = xfig_new_polyline_list ();

  %% ANGULAR AXIS, TICS & GRID
  variable theta, theta_rad, ticsize, draw_label, ii=-1;
  _for theta ( min, max, smallticinc ){
    theta_rad = (origin+dir*theta) * PI/180.0;
    draw_label = 0;
    ticsize = smalltic;
    if ((theta mod medticinc) == 0){
      ticsize = medtic;
    }
    if ((theta mod bigticinc) == 0){
      ++ii;
      ticsize = bigtic;
      draw_label = 1;
    }
    
    variable rmin = rmax - ticsize;
    variable
      xs = [rmin, rmax]*cos(theta_rad),
      ys = [rmin, rmax]*sin(theta_rad),
      zs = [0, 0];
    tics.insert (vector (xs, ys, zs));
    
    if (draw_label and ticlabels!=0 and not(theta==max and (max mod 360) == (min mod 360) ) ){
      variable label = xfig_new_text ( sprintf(tlabelformat,tlabels[ii mod ((max-min)/bigticinc+1)] ); size   = ticlabelsize );
      variable lheight = _diff(__push_array([label.get_bbox()][[2,3]]));
      
      label = xfig_new_text ( sprintf(tlabelformat,tlabels[ii mod ((max-min)/bigticinc+1)] );
			      size   = ticlabelsize,
			      rotate = ticlabelrotate*(theta_rad-PI/2)*180/PI,
			      x0 = xs[1] + ticlabelrotate*ticlabels*lheight*cos(theta_rad),
			      y0 = ys[1] + ticlabelrotate*ticlabels*lheight*sin(theta_rad),
			      just = -not(ticlabelrotate)*ticlabels*[cos(theta_rad),sin(theta_rad)],
			    );
      label.set_depth (0);
      obj.insert (label);
      
      %% ANGULAR GRID
      if( gridlines ){
	grid.insert( vector( [S*0.01,rmin], theta_rad*[1,1], PI/2*[1,1] ; sph ) );
      }
    }
  }
  tics.insert( vector( rmax*[1:1:#100], (origin+dir*[min:max:#100])*PI/180., PI/2*[1:1:#100] ; sph ) );
  
  
  %% RADIAL TICS
  variable r;
  foreach theta ( [min,max] ){
    theta_rad = (origin+dir*theta) * PI/180.0;
    tics.insert (vector ( [0,rmax], theta_rad*[1,1], PI/2*[1,1] ; sph));

    _for r ( 1, rtics-1 ){
      ticsize = smalltic;
      draw_label = 0;
    
      if ((r mod 2) == 0){
	ticsize = medtic;
	draw_label = 1;
      }
      tics.insert( vector_rotate(vector( (theta==min?-1:(max mod 360 == min?-1:1))*dir*ticsize*[0,1],
					 rad[[r,r]],
					 [0,0]),
				 vector(0,0,1),
				 theta_rad-PI/2 )
		 );
      if (draw_label and ticlabels!=0 and theta == min ){
	%label = xfig_new_text ( sprintf("$%.1f$",1.*r/(rtics-1)); size = ticlabelsize );
	ifnot( qualifier_exists("norticlabel") ){
	  lheight = _diff(__push_array([label.get_bbox()][[0,1]]));
	  label = xfig_new_text( rticlabel[r/2];%sprintf("$%.1f$",1.*r/(rtics-1));
				 size   = ticlabelsize,
				 rotate = rticlabelrotate*(theta_rad*180/PI - sign(sin(theta_rad))*90),
				 x0   = rad[r] * cos(theta_rad) + rticlabelrotate*dir*ticlabels*lheight * sin(theta_rad),
				 y0   = rad[r] * sin(theta_rad) - rticlabelrotate*dir*ticlabels*lheight * cos(theta_rad),
				 just = not(rticlabelrotate)*dir*ticlabels*[-sin(theta_rad),cos(theta_rad)],
			       );
	  obj.insert( label );
	}

	%% RADIAL GRID
	if( gridlines ){
	  grid.insert( vector( rad[r]*[1:1:#100], (origin+dir*[min:max:#100])*PI/180., PI/2*[1:1:#100] ; sph ) );
	}
      }
    }
  }
  if( qualifier_exists("rlabel") ){
    theta_rad = (origin+dir*max) * PI/180.0;
    
    label = xfig_new_text ( rlabel; size = ticlabelsize );
    lheight = _diff(__push_array([label.get_bbox()][[2,3]]));
    label = xfig_new_text ( rlabel;
			    size   = ticlabelsize,
			    rotate = theta_rad*180/PI - (sign(cos(theta_rad)) <= 0 ? 180 : 0),
			    x0 = .5*rmax*cos(theta_rad) - dir*ticlabels*lheight * sin(theta_rad),
			    y0 = .5*rmax*sin(theta_rad) + dir*ticlabels*lheight * cos(theta_rad),
			    just = [0,0]
			  );
    obj.insert( label );
  }
    
  tics.set_thickness (ticthickness);
  tics.set_depth (20);
  obj.insert (tics);

  grid.set_thickness( nint(_max(1,ticthickness-2)) );
  grid.set_depth (100);
  grid.set_pen_color (gridcolor);
  obj.insert (grid);
  
  %% MERGE TICS & AXIS into a xfig_plot object for further plotting
  variable xf = xfig_plot_new(S,S);
  xf.world(-1./(1-padr),1./(1-padr),-1./(1-padr),1./(1-padr);padx=0,pady=0);
  ifnot( qualifier_exists("debug") )
  {
    xf.axes(;off);
  }
  else{
    xf.plot(0,0);
  }
    
  
  %% Add circle at origin of both plots as marker of positioning
  variable circle = xfig_new_ellipse (S*0.01, S*0.01);
  obj.insert (@circle);
  xf.add_object(@circle, 0, 0 );

  %%% Positioning of xfig_plot_new and the polarplot object
  variable x0,y0;
  (x0,,y0,,,) = obj.get_bbox();
  xf.add_object( obj, 0.5+x0/S, 0.5+y0/S, -.5, -.5 ; world00 );

  return xf;
}
