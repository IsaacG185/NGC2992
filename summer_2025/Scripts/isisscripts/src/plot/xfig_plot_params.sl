% -*- mode:slang; mode:fold -*-
require( "xfig" ); 
require( "png" );

define xfig_plot_params()
%!%+
%\function{xfig_plot_params}
%\synopsis{Returns a xfig-plot of the given parameter (value, limits, [conf, chi2])}
%\usage{ Struct_Type xplot = xfig_plot_params( Struct_Type params1, params2, ... );}
%\qualifiers{
%\qualifier{tmpdir}{[='/tmp/'] Directory for temporar files}
%\qualifier{size}{[=[12,9]]: Dimension in cm of the (main) plot}
%\qualifier{space}{[=.05*size[0]]: Space between parameter columns.
%                    Dimension in cm of the (main) plot}
%\qualifier{xwidth}{[=.5]: Width of the parameter symbols (same units as x values).}
%\qualifier{x}{Alternative values for the x-axis (e.g., time in MJD)}
%\qualifier{xlabel}{Label for the alternative x-axis.}
%\qualifier{connect}{Connects the individual parameter values with a line.}
%\qualifier{conf}{Confidence level for the given parameters are plotted, if given.
%                 conf must be a Struct_Type[] with fields: the 'index' of the
%                 parameter and the corresponding confidence (absolut) limits
%                 'conf_min' and 'conf_max'.}
%\qualifier{steppar}{Steppar information (see 'steppar'). Either steppar filename
%                      which is loaded with steppar_load or a List_Type with two
%                      elemtents 1. stepparinformation and 2. the keys.}
%\qualifier{chi2log}{Logarithmic scales for chi2 plots}
%\qualifier{grid}{Enables gridlines on the chi2 plots}
%\qualifier{chi2max}{Custom max value for chi2 range}
%\qualifier{chi2min}{Custom min value for chi2 range}
%\qualifier{cmap}{[='ds9b'] Colormap for the colorcoded chi2 landscapes}
%\qualifier{ticmap}{[='rainbow'] Colormap for the ticlabels/chi2 landscapes}
%}
%\description
%     This function creates and returns a xfig-plot showing a compact overview
%     of the given parameter information.
%     The function takes a arbitrary number of arguments, which however are
%     expected to be all parameter struct arrays (see get_params)! For each
%     argument/parameter-array a individual xfig-plot will be created, which
%     in the end will be combined in an xfig_new_vbox_combound spaced by 'space'.
%
%     The main plot shows the parameter values
%     within its limits (y-axis). Its dimension are determined by the 'size'
%     qualifier. By default the x-axis is either the parameter index or the
%     number/dataset of the parameter, if the names of all given parameter are
%     the same.
%     The values are represented by horizontal lines, where their width
%     can be specified by the 'xwidth' qualifier (measured in x units). If
%     'xwidth' exceeds the minimal distant of adjacent x-values, 'xwidth' is set
%     to that value.
%     The 'x' qualifier allows to use custom x-values, e.g., the time at which
%     the parameters are valid. The corresponding label can be set with 'xlabel'.
%     If the 'x' qualifier is used, a second x-axis will be added to the plot,
%     which will be used to plot the parameter information, i.e., the spacing
%     is given be those 'x' values!
%     It is possible to give additional information about the parameters. Firstly
%     the 'conf' qualifier can be used to give confidence levels of the parameters.
%     'conf' must be a Struct_Type[] with fields 'index' (index of the parameter),
%     'conf_min' and 'conf_max' corresponding to the absolut values of the confidence
%     levels. The 'index' field is needed to find the corresponding parameter! Only
%     matches will be plotted!
%     Further information about the chi2 landscape can be given with the 'steppar'
%     qualifier, which expect filename(s) or filepattern(s) to load steppar
%     information produced with 'steppar'. The files are loaded using the
%     'steppar_load' function. Using 'steppar' qualifier creates a multiplot
%     with two additional plots besides main plot (caution, the return xfig-plot
%     will then be a xfit-multiplot!) showing the individual chi2 landscales
%     of the parameters, if existent and a mean chi2 of those landscapes.
%     With the 'chi2log' qualifier the chi2 landscapes are plotted logarithmic.
%     'grid' will extent the tics to a grid. To set custom limits for the chi2 range
%     use 'chi2min' and 'chi2max'! To easily visualize which chi2 landscape
%     belongs to which parameter, the parameter x-labels are colorized
%     accordingly using the colormap given by 'ticmap'.
%     Furthermore, color-coded chi2 landscapes are added to the main plot using
%     the colormap given with 'cmap'. The colormaps can be given by either a
%     name (String_Type) of an existing colormap (png_get_colormap_names) or
%     a colormap itself.
%\seealso{steppar, steppar_load, png_get_colormap_names}
%
%!%-
{
  %%% CAPTURE ARGUMENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  variable args = __pop_list(_NARGS);
  
  %%% PRELOAD QUALIFIERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  variable tmpdir = qualifier("tmpdir","/tmp/"+getenv("USER")+"/");
  if( tmpdir[-1] != '/' ){
    tmpdir += "/";
  }
  ()=mkdir_rec(tmpdir);
  
  variable size   = qualifier("size",[12,9]);
  variable space  = qualifier("space", 0.05*size[0] );
  variable xwidth = qualifier("xwidth",0.5);
  variable xlabel = qualifier("xlabel","time [MJD]");
  variable connect= qualifier_exists("connect") ? 1:0;
  variable conf   = qualifier("conf",[struct{index}]);

  variable steppar = qualifier("steppar");
  if( qualifier_exists("steppar") ){
    variable sp,sk;
    if( typeof(steppar) == String_Type ){
      % Read steppar information
      (sp,sk) = steppar_load( steppar ;; struct_combine(__qualifiers,struct{keys="pname"}) );
    }
    else if( typeof(steppar) == List_Type and length(steppar)==2 ){
      sp = steppar[0];
      sk = steppar[1];
    }
    else{
      help(_function_name);return;
    }
    variable spname = array_struct_field(sk, "pname");
  }

  variable chi2log= qualifier_exists("chi2log") ? 1:0;
  variable grid   = qualifier_exists("grid") ? 1:0;

  variable cmap = qualifier("cmap","ds9b");
  if( typeof(cmap) == String_Type ){
    cmap = png_get_colormap( cmap );
  }
  cmap = reverse(cmap);

  %%% ARGUMENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  variable xplot = {};
  variable params;
  foreach params( args ){
    % check if args
    
    ifnot( _typeof(params) == Struct_Type ){
      help(_function_name);return;
    }

    
    % Extracting parameter information from the parameter array
    variable nparams = length(params);
    variable pname = array_struct_field( params,"name");
    variable pname_lbl = array_map( String_Type, &strreplace, pname, "_", "-" ); 
    variable p     = array_struct_field( params,"value");
    variable pind  = array_struct_field( params,"index");
    variable pmin  = array_struct_field( params,"min");
    variable pmax  = array_struct_field( params,"max");

    % Obtain a overall parameter label 'plbl':
    % If all parameter names are matching plbl <model>*<parametername>
    % is set. Otherwise
    variable pname_tok = array_map( Array_Type, &strtok, pname_lbl, "()." );
    variable pmdl = array_flatten( pname_tok )[[0::length(pname_tok[0])]];
    variable pnum = array_flatten( pname_tok )[[1::length(pname_tok[0])]];
    variable pnick= array_flatten( pname_tok )[[2::length(pname_tok[0])]];
    variable punit = array_struct_field( params,"units");
    punit = array_map( String_Type, &strreplace, punit, "^", "" );     

    % get unique entries (attention unique returns unsorted arrays!)
    variable utmp;
    utmp = unique(pmdl);
    pmdl  = pmdl[ utmp[array_sort(utmp)] ];
    utmp = unique(pnum);
    pnum  = pnum[ utmp[array_sort(utmp)] ];
    utmp = unique(pnick);
    pnick = pnick[ utmp[array_sort(utmp)] ];
    utmp = unique(punit);
    punit = punit[ utmp[array_sort(utmp)] ];
    
    % determin x/y labels:
    % - if for all given parameter the model and the name are the same, than
    %   ylabel = <model>*<name> [unit] and x-axis/label is the parameter number/dataset
    % - otherwise the x-axis is the parameter index
    variable _x, xtics, x1label, plbl;
    if( length(pmdl) and length(pnick) and length(pnum)==nparams ){
      if( length(punit)==1 and punit[0] != "" ){
	punit = " ["+punit+"]";
      }
      
      plbl = [ strjoin( [pmdl,pnick], "*" ) + punit ][0];
      _x = atoi(pnum);
      xtics = "("+pnum+")";
      x1label = "dataset";
    }
    else{
      plbl = "parameter values";
      _x = [1:nparams];
      xtics = array_map( String_Type, &sprintf, "%d", pind );
      x1label = "parameter index";
    }
    _x = [1:nparams];

    %%% QUALIFIERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    variable x  = qualifier("x",_x);
    variable chi2max= qualifier("chi2max",-DOUBLE_MAX);
    variable chi2min= qualifier("chi2min",DOUBLE_MAX);

    variable ticmap = qualifier("ticmap","rainbow");
    if( typeof(ticmap) == String_Type ){
      ticmap = png_get_colormap( ticmap );
    }
    ticmap = ticmap[nint([0:length(ticmap)-1:#nparams])];

    %%% PLOT PREPARATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % check if xwidth is larger than distant of adjacent x and if need be set
    % xwidth to that minimal distant
    variable _xwidth = xwidth;
    if( nparams > 1 ){
      _xwidth = min( [shift(x,1)-x][[:-2]] );
    }
    if( xwidth > _xwidth ){
      xwidth = _xwidth;
    }

    % Colorize xticlabels, IF chi2 plots are plotted
    if( qualifier_exists("steppar") ){
      xtics = "\\color[rgb]{"+array_map(String_Type, &sprintf, "%0.3f,%03f,%03f", color2rgb(ticmap;float))+"}{"+xtics+"}";
    }

    % Set x/y plotting ranges
    variable xmin = min(x) - .5*xwidth;
    variable xmax = max(x) + .5*xwidth;
    variable ymin = min(pmin);
    variable ymax = max(pmax);
    variable padx = 0.05;
    variable pady = 0.05;

    variable cind = array_struct_field( conf, "index");
    variable _cind, cmin, cmax;

    % Initialize main plot 'xf':
    variable xf = xfig_plot_new( size[0], size[1] );
    xf.world( xmin, xmax, ymin, ymax ; padx=padx, pady=pady );
    xf.xlabel( x1label );
    xf.ylabel( plbl );

    % Axis management: If 'x' qualifier is not given only x1-axis is on
    xf.x1axis(;
	      major = x,
	      ticlabels = xtics,
	     );
    if( qualifier_exists("x") ){
      xf.x2axis(; on );
      xf.x2label( xlabel );
    }
    else{
      xf.x2axis(; major = x, ticlabels = 0 );
    }

    %%%%%%%%%%%%%%%%%%%
    %%% CREATE MAIN PLOT:
    variable i;
    foreach i ( [0:nparams-1] ){
      % parameter value
      xf.plot( x[i]+[-.5,.5]*xwidth, p[[i,i]] ; depth=10, width=3 );
      % confidence level (if given/existent)
      _cind = where(cind==pind[i]);
      if( length( _cind ) ){
	cmin = conf[_cind[0]].conf_min;
	cmax = conf[_cind[0]].conf_max;
	xf.plot( x[[i,i]], [cmin,cmax] ; depth=10, width=2, color="#000000", line=0 );
	xf.plot( x[i]+[-.25,.25]*xwidth, [cmax,cmax] ; depth=10, width=3, color="#000000" );
	xf.plot( x[i]+[-.25,.25]*xwidth, [cmin,cmin] ; depth=10, width=3, color="#000000" );
      }
      % parameter limits
      xf.plot( x[[i,i]], [pmin[i],pmax[i]] ; depth=40, width=1, color="#999999", line=1 );
      xf.plot( x[i]+[-.5,.5]*xwidth, pmax[[i,i]] ; depth=40,width=3, color="#999999" );
      xf.plot( x[i]+[-.5,.5]*xwidth, pmin[[i,i]] ; depth=40,width=3, color="#999999" );
    }
    if( connect ){
        xf.plot( x, p ; depth=15, width=1, color="#000000", line=0 );
    }

    
    %%%%%%%%%%%%%%%%%%%%%%%%
    %%% Adding Steppar plots
    if( qualifier_exists("steppar") ){

      % qualifiers for the worlds of both chi2 plots. The padding is neccessary to
      % ensure that the yranges are matching
      variable squal = struct{ padx=padx, pady=pady };
      if( chi2log ){
	squal = struct_combine( squal, struct{xlog} );
      }

      % Obtain steppar informations for the given parameters if available
      variable spinfo = Struct_Type[nparams];
      variable spidx  = Integer_Type[0];

      variable nsteps = Integer_Type[0];

      variable j;
      _for i ( 0, nparams-1 ){
	% for each given parameter check if steppar information is available in 'sp'
	j = where( pname[i] == spname );
	if( length(j) ){
	  j = j[0]; % array to single number
	  spidx = [ spidx, i ]; % remember the index of the corresponding parameter

	  % store the necessary information
	  spinfo[i] = struct{

	    pval = get_struct_field( sp[j], escapedParameterName( spname[j] ) ),
	    pval_min,
	    pval_max,

	    chi2 = sp[j].chi2

	  };
	  spinfo[i].pval_min = min(spinfo[i].pval);
	  spinfo[i].pval_max = max(spinfo[i].pval);

	  nsteps = nint(min([ nsteps, length(spinfo[i].pval)]));

	  ifnot( qualifier_exists("chi2min") ){
	    chi2min = min( [ chi2min, sp[j].chi2[where(0<sp[j].chi2<1e100)] ] );
	  }
	  ifnot( qualifier_exists("chi2max") ){
	    chi2max = max( [ chi2max, sp[j].chi2[where(0<sp[j].chi2<1e100)] ] );
	  }
	}
      }
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Overplot the Chi2 as colormap
      variable chi2map,chi2png;
      variable xcm, dx, dy;

      % individual chi2 colormaps
      foreach i (spidx){
	% create the colormap
	chi2map  = tmpdir+"tmp_";
	chi2map += strftime("%j%H%M_");
	chi2map += escapedParameterName(params[i].name);
	chi2map += ".png";
	chi2png = png_gray_to_rgb ( _reshape(spinfo[i].chi2, [length(spinfo[i].chi2),1]),
				    cmap
				    ; gmin=chi2min, gmax=chi2max );
	png_write_flipped ( chi2map, chi2png );

	% create a png of the colormap
	xcm = xfig_new_png( chi2map );
	% resize the png to fit the pmin,pmax range
	( dx, dy ) = xcm.get_pict_bbox();
	xcm.scale_pict( 1./(1+2*padx)*xwidth/(xmax-xmin) * xf.plot_data.plot_width/dx ,
			1./(1+2*pady)*(spinfo[i].pval_max-spinfo[i].pval_min)/(ymax-ymin) * xf.plot_data.plot_height/dy );
	% add the chi2 colormap to the main plot
	xf.add_object( xcm, x[i], spinfo[i].pval_min, 0, -.5 ; depth=30 );
      }

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Create plot with individual chi2 landscapes
      variable xs = xfig_plot_new( 2./3.*size[0], size[1] );
      xs.x1axis(;grid=grid);
      xs.y1axis(;grid=grid);
      xs.xlabel( "$\chi^2$"R );
      xs.ylabel( plbl );
      xs.world( chi2min, chi2max, ymin, ymax ;; squal );
      foreach i (spidx){
	% the color of the individual chi2 landscapes matches the color of the
	% ticlabels in the main plot
	xs.plot( spinfo[i].chi2, spinfo[i].pval ;
		 color = sprintf("#%06x", ticmap[i]),
		 depth = 25
	       );
      }

      % CREATE inplot scale
      chi2map  = tmpdir+"tmp_";
      chi2map += strftime("%j%H%M_");
      chi2map += string(length(xplot)+1)+"-"+string(_NARGS) + "_scale.png";
      i = [0:1:#length(cmap)];
      if( qualifier_exists("chi2log") ){
	i = 10^i;
      }
      chi2png = png_gray_to_rgb ( _reshape(i,[1,length(cmap)]) , cmap );
      png_write_flipped ( chi2map, chi2png );

      xcm = xfig_plot_new( 1/(1+2*padx) *xs.plot_data.plot_width,
			   0.85*pady*xs.plot_data.plot_height );
      xcm.world ( chi2min, chi2max , 0, 1 ;; reduce_struct(squal,"padx") );
      xcm.xaxis (;off);
      xcm.x2axis(;on,ticlabels=0);
      xcm.yaxis(;off);
      xcm.plot_png ( chi2map );

      xs.add_object( xcm, chi2min, 0, -.5, -.5 ; world10, depth=20 );

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Create plot of the mean summed chi2 landscape
      variable chi2sum = [0.:0.:#nsteps];
      variable _chi2sum;
      % To sum the individual chi2 landscapes a temporary grid between the minimal
      % and maximal occuring pvalue is defined with #bin='nsteps', which is the minimal
      % occuring amount of pvalues.
      variable p_lo, p_hi;
      (p_lo,p_hi) = linear_grid( ymin,ymax,nsteps);

      variable xm = xfig_plot_new( 1./3.*size[0], size[1] );
      xm.x1axis(;grid=grid);
      xm.y1axis(;grid=grid);
      xm.xlabel( "$\Sigma_n\chi^2/n$"R );
      xm.ylabel( plbl );
      foreach i (spidx){
	% rebin the individual chi2 landscapes to the new grid
	_chi2sum = rebin_mean( p_lo, p_hi,
			       spinfo[i].pval,
			       spinfo[i].pval + (spinfo[i].pval[-1]-spinfo[i].pval[-2]),
			       spinfo[i].chi2
			     );
	_chi2sum[where(_chi2sum==0)] = max(_chi2sum);
	chi2sum += _chi2sum;

      }
      chi2sum /= length(spidx);
      % ger rid of inf entries
      chi2sum[where(isinf(chi2sum))] = max(chi2sum[wherenot(isinf(chi2sum))]);
      
      xm.world( qualifier_exists("chi2min") ? chi2min : min(chi2sum),
		qualifier_exists("chi2max") ? chi2max : max(chi2sum),
		ymin, ymax ;; squal
	      );
      xm.plot( chi2sum, p_lo ; width = 3 );

      xf = xfig_multiplot( xf, xs, xm ; cols=3 );
    }
    list_append( xplot, xf );
  }

  variable xcomp = xfig_new_vbox_compound( __push_list(xplot), space ;; __qualifiers );
  return xcomp;
}
