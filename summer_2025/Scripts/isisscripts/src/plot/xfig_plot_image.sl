require( "xfig" );
require( "png" );

define xfig_plot_image()
%!%+
%\function{xfig_plot_image}
%\synopsis{Plots an image (with x/y-grid)}
%\usage{Struct_Type xfig_plot_new( Double_Type[n,m] IMG, [Double/Struct_Type x, y] );}
%\altusage{xfig_plot_new( Double_Type[n,m] IMG, [Double/Struct_Type x, y [, Struct_Type xf]] );}
%\qualifiers{
%\qualifier{cmap}{[="ds9b"] Either a name (String_Type) of a colormap
%                     (see png_get_colormap_names), or a self defined
%                      colormap (Integer_Type[]).}
%\qualifier{gmin}{[=min(IMG)] Minimal value of image to be plotted}
%\qualifier{gmax}{[=max(IMG)] Maximal value of image to be plotted}
%\qualifier{xmin}{[=min(x)] Minimal value of x-axis}
%\qualifier{xmax}{[=max(x)] Maximal value of x-axis}
%\qualifier{ymin}{[=min(y)] Minimal value of y-axis}
%\qualifier{ymax}{[=max(y)] Maximal value of y-axis}
%\qualifier{dx}{[=0.] Relative justification of pixels in x-direction. Used if 'x' is no grid.}
%\qualifier{dy}{[=dx] Relative justification of pixels in y-direction. Used if 'y' is no grid.}
%\qualifier{fill}{[=20] global filling method (see %.shade_region) }
%\qualifier{fmap}{[=Integer_Type[n,m]+fill] individual filling method for each pixel}
%%\qualifier{nancol}{[="black"] Extra color for IMG pixel values, which are NAN.}
%\qualifier{ratio}{[=1] Desired ratio of x and y-axis scale}
%\qualifier{W}{[=14] Plot width [cm]. 'ratio' is overwritten if W & H are given!}
%\qualifier{H}{[=W/ratio] Plot height [cm]. 'ratio' is overwritten if W & H are given!}
%\qualifier{colorscale}{If given an inlay colorscale is plotted using xfig_plot_colorscale}
%\qualifier{format}{Format for colormap axis ticlabels, see 'help xfig_plot.axis'}
%\qualifier{just}{[=[.95,.05,-.5,.5]] Position (world00) & relative justification
%         of the colorscale.}
%\qualifier{scale}{[=[.33,.05]] : Relative size of the colorscale in respect to W & H.}
%\qualifier{xlabel}{Label of x-axis}
%\qualifier{ylabel}{Label of y-axis}
%\qualifier{depth}{[=150] xfig depth}
%}
%\description
%   Other than the %plot_png function of the xfig_plot structure this function
%   aims to plot images with a (given) ARBITRARY x/y-grid in a correct way
%   (NOTE that .plot_png does not care for x/y values!). This also allows to
%   plot images with logarithmic scales without any problems! In addition
%   it is easy to plot gabbed images by just giving the x and y grid as bin_lo
%   and bin_hi.
%
%   ARGUMENTS
%    IMG:
%    In any case a IMaGe has to be given, which can arbitrary dimensions n and m
%    (it even can be 1-dimensional).
%
%    x, y:
%    x and y-grids are optional arguments but cannot be given individually.
%    If no grid is given the grids are set to the pixel number assuming a linear
%    grid! The grids can be Array_Types either of length n and m, respectively, in
%    which case the bin_lo and bin_hi is created by assuming a linear grid.
%    Otherwise their length must be n+1, m+1!
%    It is also possible that x and y are Struct_Types already containing the bin_lo
%    and bin_hi (it is only required that the bin_lo filed has 'lo' in its name and
%    the bin_hi field 'hi', respectively). In that last case it is also possible to
%    plot images with gabs!
%    
%    xf:
%    Must be and xfig_plot structure. If given the image is plotted into xf and there
%    will be no return value. This way all automatic plot settings of this function will
%    be disregarded. Otherwise a new xfig_plot is created (qualifiers are
%    passed through).
%    
%\example
%   % Example 1: logscale
%   variable x = [PI:10*PI:#100];
%   variable y = [PI:5*PI:#80];
%   variable IMG = sin(x) # transpose(cos(y));
%   variable xf = xfig_plot_image( IMG, x*180/PI, y*180/PI;
%                                         padx=0.025, pady=0.025,
%      		                          dx=-.5,
%                                         xlog, ylog,
%				          fill=20
%				        );
%   xf.render("/tmp/test.pdf");
%
%   % Example 2: image of Example 1 but with gaps
%   variable tmp = [[1:30],[35:65],[75:115]];
%   variable x = struct{ lo = tmp/11.5*PI, hi = (tmp+1)/11.5*PI };
%   tmp = [[1:40],[50:90]];
%   variable y = struct{ lo = tmp/18.*PI, hi = (tmp+1)/18.*PI };
%   variable IMG = sin(x.lo) # transpose(cos(y.lo));
%   variable xf = xfig_plot_image( IMG, x, y ; cmap="drywet");
%   xf.render("/tmp/test.pdf");
%
%\seealso{xfig_plot_new, %.shade_region, xfig_plot_colormap}
%
%!%-
{
  %%%%% ARGUMENTS
  variable IMG,
    x  = NULL,
    y  = NULL,
    xf = NULL;
  
  switch(_NARGS)
  { case 1: IMG = (); }
  { case 3: ( IMG, x, y ) = (); }
  { case 2: ( IMG, xf ) = (); }
  { case 4: ( IMG, x, y, xf ) = (); }

  %%%%% QUALIFIERS

  %% LOAD ColorMap
  variable cmap = qualifier("cmap","ds9b");
  if( _typeof(cmap) == String_Type ){
    if( int(sum(cmap==png_get_colormap_names)) == 0 ){
      vmessage("EEROR(%s): Colormap '%s' does not exist!",
	       _function_name, cmap );
      return NULL;
    }
    cmap = png_get_colormap(cmap);
  }
  %% Scaling in z-direction
  variable gmin = qualifier("gmin",min(IMG));
  variable gmax = qualifier("gmax",max(IMG));
  % variable scalefun = qualifier("scalefun", NULL);
  % if (scalefun != NULL) {
  %   gmin = (@scalefun)(gmin);
  %   gmax = (@scalefun)(gmax);
  %   IMG = (@scalefun)(IMG);
  % }
  
  %% Fillmethod
  variable fmap = qualifier("fmap",NULL);
  variable fill = qualifier("fill",20);
  variable nancol = qualifier("nancol","black");
  
  %% Pixel positioning
  variable dx = qualifier("dx",0.);
  variable dy = qualifier("dy",dx);

  %% Plot size
  variable ratio = qualifier("ratio",1);
  variable W = qualifier("W",14);
  variable H = qualifier("H",NULL); 
  variable padx = qualifier("padx",0.);
  variable pady = qualifier("pady",0.);

  variable depth = qualifier("depth",150);

  %% Label
  variable xlabel = qualifier("xlabel");
  variable ylabel = qualifier("ylabel");
  
  %% COLORscale
  variable colorscale = qualifier("colorscale");
  variable just = qualifier("just", [.95,.05,.5,-.5] );
  variable scale = qualifier("scale", [.33,.05] );
  
  %%%%% LET THE MAGIC HAPPEN
  
  %% Obain Image dimensions
  variable dim = array_shape( IMG );
  if( length(dim) == 1 ){
    dim = [dim[0],1];
    reshape( IMG, dim );
  }
  variable len = int(prod(dim));

  %% Create FILLmap
  if( fmap == NULL ){
    fmap = Integer_Type[dim[0],dim[1]] + fill;
  }
  
  %% Obtain x grids
  variable xlo, xhi, ylo, yhi;
  variable fname, del;
  if( x == NULL ){
    xlo = [0:dim[0]-1];
    xhi = xlo + 1;
  }
  else if( typeof(x) == Struct_Type ){
    fname = get_struct_field_names(x);
    xlo = get_struct_field( x, fname[where(is_substr(fname,"lo"))][0] );
    xhi = get_struct_field( x, fname[where(is_substr(fname,"hi"))][0] );
  }
  else if( typeof(x) == Array_Type ){ 
    if( length(x) == dim[0]+1 ){
      xlo = x[[:-2]];
      xhi = x[[1:]];
    }
    else if( length(x) == dim[0] ){
      del = diff(x);
      xlo = x - (.5+dx) * [del,del[-1]];
      xhi = x + (.5-dx) * [del,del[-1]];
    }
    else{
      vmessage("ERROR(%s): Dimension of x-grid does not match IMG!",_function_name);
    }
  }
  %% Obtain y grids
  if( y == NULL ){
    ylo = [0:dim[1]-1];
    yhi = ylo + 1;
  }
  else if( typeof(y) == Struct_Type ){
    fname = get_struct_field_names(y);
    ylo = get_struct_field( y, fname[where(is_substr(fname,"lo"))][0] );
    yhi = get_struct_field( y, fname[where(is_substr(fname,"hi"))][0] );
  }
  else if( typeof(y) == Array_Type ){
    if( length(y) == dim[1]+1 ){
      ylo = y[[:-2]];
      yhi = y[[1:]];
    }
    else if( length(y) == dim[1] ){
      del = diff(y);
      ylo = y - (.5+dy) * [del,del[-1]];
      yhi = y + (.5-dy) * [del,del[-1]];
    }
    else{
      vmessage("ERROR(%s): Dimension of y-grid does not match IMG!",_function_name);
    }
  }

  variable xmin = qualifier("xmin",xlo[0]);
  variable xmax = qualifier("xmax",xhi[-1]);
  variable ymin = qualifier("ymin",ylo[0]);
  variable ymax = qualifier("ymax",yhi[-1]);
  
  %% If not given, initialize a xfig_plot
  variable ret = 0;
  if( xf == NULL ){
    if( H == NULL ){
      H = abs(1.*W / ( ratio*(xhi[-1]-xlo[0])/(yhi[-1]-ylo[0])*(1+padx)/(1+pady) ));
    }
    else if( qualifier_exists("H") and not(qualifier_exists("W")) ){
      W = abs(1.*H * ( ratio*(xhi[-1]-xlo[0])/(yhi[-1]-ylo[0])*(1+padx)/(1+pady) ));
    }
    xf = xfig_plot_new( W, H ;; struct_combine(__qualifiers,struct{padx=padx,pady=pady}) );
    xf.world( xmin, xmax, ymin, ymax ;; __qualifiers );
    xf.xlabel(xlabel);
    xf.ylabel(ylabel);
    ret = 1;
  }  

  %% Obtain colors from IMG & CMAP accounting for z-scaling
  variable col = png_gray_to_rgb ( IMG , cmap ; gmin=gmin, gmax=gmax );
  col = array_map(String_Type, &sprintf, "#%06X", col );
  col[ where(isnan(IMG) or isinf(IMG)) ] = nancol;
  
  if( qualifier_exists("group") ){ %% TODO
    %% Group pixel of same color to one shade region if possibile!
    variable U = unique(col);
    variable I, ix, iy, xa, ya;
    _for $1 ( 0, length(U)-1 ){
    }
  }else{
    %% Plot each pixel individually!
    _for $1 ( 0, length(xlo)-1 ){
      _for $2 ( 0, length(ylo)-1 ){
	xf.shade_region( xlo[$1], xhi[$1], ylo[$2], yhi[$2] ;;
			 struct_combine( struct{ width=0, depth=depth,
			   color=col[$1,$2],
			   fillcolor=col[$1,$2],
			   fill=fmap[$1,$2] },
					 __qualifiers
				       )
		       );
      }
    }
  }

  %% Add colorscale
  if( qualifier_exists("colorscale") ){
    variable quals = reduce_struct(__qualifiers,["colorscale","xlog","ylog","fill","fmap"]);
    quals = struct_combine(quals, struct{depth=depth-10,W=scale[0]*W,H=scale[1]*H});
    variable cs = xfig_plot_colormap( IMG ;; quals );
    xf.add_object( cs, __push_array(just) ; world00 );
  }
  
  if( ret ){
    return xf;
  }
}


define xfig_plot_colormap()
%!%+
%\function{xfig_plot_colormap}
%\synopsis{Plots a colormap/colorscale}
%\usage{Struct_Type xfig_plot_new( Double_Type[n,m] IMG );}
%\qualifiers{
%\qualifier{cmap}{[="ds9b"] Either a name (String_Type) of a colormap
%                     (see png_get_colormap_names), or a self defined
%                      colormap (Integer_Type[]).}
%\qualifier{gmin}{[=min(IMG)] Minimal value of image to be plotted}
%\qualifier{gmax}{[=max(IMG)] Maximal value of image to be plotted}
%\qualifier{W}{[=14] Plot width [cm]. 'ratio' is overwritten if W & H are given!}
%\qualifier{H}{[=W/ratio] Plot height [cm]. 'ratio' is overwritten if W & H are given!}
%\qualifier{orientation}{[=1] Horizontal if 1, vertical if 0. Set Horizontal if W/H > 1,
%             otherwise set to vertical.}
%\qualifier{label}{Label for the colormap}
%\qualifier{format}{Format for colormap axis ticlabels, see 'help xfig_plot.axis'}
%\qualifier{depth}{[=80] Depth of the colormap}
%\qualifier{fontsize}{[="scriptsize"] Font size of tic & axis label}
%\qualifier{ticlen}{[=.15] Length of major tic marks (minor tic are .5*ticlen).}
%\qualifier{maxtics}{[=5] Maximal number of labeled tics}
%\qualifier{box}{Draws a box behind the colormap}
%\qualifier{border}{[=.01] Relative size of box excess length}
%\qualifier{boxcolor}{[="#FFFFFF"] Color of the box}
%}
%\description
%   This function uses xfig_plot_image to create a colormap based on the given
%   IMaGe (with dimension n and m).
%   
%\example
%   variable x = [PI:10*PI:#100];
%   variable y = [PI:5*PI:#80];
%   variable IMG = sin(x) # transpose(cos(y));
%   variable xf = xfig_plot_colormap( IMG );
%   xf.render("/tmp/test.pdf");
%
%\seealso{xfig_plot_new, %.shade_region, xfig_plot_image}
%
%!%-
{
  %%%%% ARGUMENTS
  variable IMG,
    grid  = NULL;
  
  switch(_NARGS)
  { case 1: IMG = (); }

  %%%%% QUALIFIERS

  variable W = qualifier("W",4);
  variable H = qualifier("H",0.5);
  variable box = qualifier("box");
  variable border = qualifier("border",0.01);
  variable boxcolor = qualifier("boxcolor","#FFFFFF");
  variable fontsize = qualifier("fontsize","scriptsize");
  variable label = qualifier("label");
  variable depth = qualifier("depth",80);
  variable maxtics = qualifier("maxtics",5);
  variable tlen   = qualifier("ticlen",.15);
  variable format = qualifier("format","%g");
  variable orientation = qualifier("orientation", W/H > 1 ? 1 : 0 );

  if( typeof(orientation) == String_Type ){
    if( is_substr("horizontal",orientation) ){
      orientation = 1;
    }
    else{
      orientation = 0;
    }
  }
  
  %% LOAD ColorMap
  variable cmap = qualifier("cmap","ds9b");
  if( _typeof(cmap) == String_Type ){
    if( int(sum(cmap==png_get_colormap_names)) == 0 ){
      vmessage("EEROR(%s): Colormap '%s' does not exist!",
	       _function_name, cmap );
      return NULL;
    }
    cmap = png_get_colormap(cmap);
  }
  variable gmin = qualifier("gmin",min(IMG));
  variable gmax = qualifier("gmax",max(IMG));

  variable sm = [gmin:gmax:#length(cmap)];
  variable lohi = [gmin:gmax:#length(cmap)+1];
  
  variable axisquals = struct{
    ticlabel_size = fontsize,
    maxtics       = maxtics,
    major_len     = tlen,
    minor_len     =.5*tlen,
    depth         = depth-1,
    tic_depth     = depth-1,
    ticlabel_color="black",
    format        = format,
  };

  % color scale
  variable s = xfig_plot_new( W, H );
  
  %% Horizontal
  if( orientation == 1 ){
    s.world( gmin, gmax, 0, 1 );
    s.yaxis(; major = 0, minor = 0, depth=depth-1, tic_depth=depth-1 );
    s.x1axis(;;axisquals);
    s.x2axis(;;struct_combine(axisquals,struct{major_color = "white", minor_color = "white", ticlabels = 0}) );
    s.x2label( label ; size = fontsize , depth=depth-1 );
    
    xfig_plot_image( sm, lohi , [0,1], s ;; struct_combine(struct{depth=depth},reduce_struct(__qualifiers,"colorscale")) );
  }
  %% Vertical
  else{
    s.world( 0, 1, gmin, gmax );
    s.xaxis(; major = 0, minor = 0, depth=depth-1, tic_depth=depth-1);
    s.y2axis(;;axisquals);
    s.y1axis(;;struct_combine(axisquals,struct{major_color = "white", minor_color = "white", ticlabels = 0}) );
    s.ylabel( label ; size = fontsize , depth=depth-1);
    
    xfig_plot_image( transpose(sm), [0,1], lohi, s ;; struct_combine(struct{depth=depth},reduce_struct(__qualifiers,"colorscale")) );
  }

  % draw a white box behind the color scale
  if( qualifier_exists("box") ){
    variable bbox = [s.get_bbox()];
    variable bord = border*(bbox[1]-bbox[0]);
    variable b = xfig_new_rectangle( 2*bord + bbox[1]-bbox[0],
				     2*bord + bbox[3]-bbox[2]
				   );
    b.set_area_fill(20);
    b.set_fill_color(boxcolor);
    b.set_depth(depth+1);
    b.translate( vector( bbox[0]-bord,
			 bbox[2]-bord,
			 0.)
	       );
    s.add_object(b);
  }

  
  return s;
}
