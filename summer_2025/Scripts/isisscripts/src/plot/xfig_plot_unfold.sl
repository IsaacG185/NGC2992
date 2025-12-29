require( "xfig" );

%  ===================  %
private define prepare_data_for_pp_plot(d)
%  ===================  %
{
  d = [d];

  variable len = length(d);

  variable dfieldnames,fn,f;
  variable pp = Struct_Type[len];
  variable pmin,pmax;

  variable i;
  _for i ( 0, len-1, 1 ){
    dfieldnames = get_struct_field_names(d[i]);

    pp[i] = struct_combine(dfieldnames);
    pmin = min(d[i].lo);
    pmax = max(d[i].hi);

    foreach fn(dfieldnames){
      f = get_struct_field( d[i], fn );

      if( fn=="lo" or fn=="hi" )
	set_struct_field( pp[i], fn, [f,f + pmax-pmin] - pmin );
      else
	set_struct_field( pp[i], fn, [f,f] );
    }
  }

  return len == 1 ? pp[0] : pp;
}

%  ===================  %
define xfig_plot_data(pl,d)
%  ===================  %
%!%+
%\function{xfig_plot_data}
%\synopsis{plots data which was loaded by "read_data_from_write_plot"}
%\usage{XFig_Plot_Type pl = xfig_plot_data(XFig_Plot_Type pl, Struct_Type dat)}
%\qualifiers{
%\qualifier{color}{specify the color}
%\qualifier{width}{line width}
%\qualifier{sym}{symbol}
%\qualifier{size}{size of the symbol}
%\qualifier{depth}{depth in plot}
%\qualifier{pp}{data are plotted twice (pulse profile)}
%}
%\seealso{xfig_plot_unfold,read_data_from_write_plot,read_col,write_plot}
%!%-
{
  if( qualifier_exists("pp") )
    d = prepare_data_for_pp_plot(d);

  pl.plot((d.lo+d.hi)*0.5, d.val,
	{d.lo, d.hi}, d.err;
	  sym=qualifier("sym","point"),
	  size=qualifier("size",0),
	  color=qualifier("color",1),
	  xminmax,
	  width=qualifier("width",3),
	  depth=qualifier("depth",50)
	 );

  return pl;
}

%  ===================  %
define xfig_plot_model(pl,d)
%  ===================  %
%!%+
%\function{xfig_plot_model}
%\synopsis{plots the model which was loaded by "read_data_from_write_plot"}
%\usage{XFig_Plot_Type pl = xfig_plot_model(XFig_Plot_Type pl, Struct_Type dat)}
%\qualifiers{
%\qualifier{color}{specify the color}
%\qualifier{width}{line width}
%\qualifier{depth}{depth in plot}
%\qualifier{hplot}{make it a histogram plot}
%\qualifier{pp}{model is plotted twice (pulse profile)}
%}
%\seealso{xfig_plot_data,read_data_from_write_plot,read_col,write_plot}
%!%-
{
  if( qualifier_exists("pp") )
    d = prepare_data_for_pp_plot(d);

   if (qualifier_exists("hplot")){
      pl.hplot([d.lo,d.hi[-1]], d.model;
	       color=qualifier("color","black"),
	       width=qualifier("width",3),
	       depth=qualifier("depth",50)
	      );
   } else {      
      pl.plot((d.lo+d.hi)*0.5, d.model;
	      color=qualifier("color","black"),
	      width=qualifier("width",3),
	      depth=qualifier("depth",50)
	     );
   }

  return pl;
}

%  ===================  %
define xfig_plot_res(pl,s)
%  ===================  %
%!%+
%\function{xfig_plot_res}
%\synopsis{plots the residuals which were loaded by "read_data_from_write_plot"}
%\usage{XFig_Plot_Type pl = xfig_plot_model(XFig_Plot_Type pl, Struct_Type dat)}
%\qualifiers{
%\qualifier{color}{specify the color}
%\qualifier{width}{line width}
%\qualifier{depth}{depth in plot}
%\qualifier{chi}{specifies that the residuals are in chi}
%\qualifier{ratio}{specifies that the residuals are a ratio}
%\qualifier{pp}{residuals are plotted twice (pulse profile)}
%}
%\seealso{xfig_plot_data,read_data_from_write_plot,read_col,write_plot}
%!%-
{
  if( qualifier_exists("pp") )
    s = prepare_data_for_pp_plot(s);

  pl.plot((s.lo+s.hi)*0.5, s.res,{s.lo, s.hi}, {s.res_min, s.res_max};
	  sym="point",
	  size=0,color=qualifier("color",1),
	  eb_factor=0,
	  minmax,
	  width=qualifier("width",3),
	  depth=qualifier("depth",50));

  pl.plot([0,1],[0,0];depth=90, width=3, line=0, world01);

  if (qualifier_exists("chi"))
  {
    pl.ylabel(`$\chi$`);
    pl.plot([0,1],[0,0];world01,width=3);
  }
  if (qualifier_exists("ratio"))
  {
    pl.ylabel(`Ratio`);
    pl.plot([0,1],[1,1];world01,width=3);
  }

  return pl;
}

%  ===================  %
define xfig_plot_unfold(d)
%  ===================  %
%!%+
%\function{xfig_plot_unfold}
%\synopsis{tries to plot the complete plot loaded by "read_data_from_write_plot"}
%\usage{XFig_Plot_Type pl = xfig_plot_unfold(Struct_Type dat)}
%\qualifiers{
%\qualifier{size}{[dx,dy,dr] size of the xfig-plot}
%\qualifier{dcol}{color of the data}
%\qualifier{mcol}{color of the model}
%\qualifier{xrng}{[xmin,xmax]}
%\qualifier{yrng}{[ymin,ymax]}
%\qualifier{rrng}{[rmin,rmax]}
%\qualifier{ranges}{[xmin,xmax,ymin,ymax,rmin,rmax]}
%\qualifier{chi}{specifies that the residuals are chi}
%\qualifier{ratio}{specifies that the residuals are ratio}
%\qualifier{y_label}{set a y-label for the data/model plot}
%\qualifier{keV2erg_fac}{if given, the y-label is given in units of
%                          ergs/s/cm^2 x 10^keV2erg_fac }
%\qualifier{pp}{data is plotted twice (pulse profile)}
%}
%\description
%    With "read_data_from_write_plot", previously stored data can be
%    loaded into a structure. This structure ("dat" in the example
%    above) can now be plotted with "xfig_plot_unfold".
%
%    The routines xfig_plot_data, xfig_plot_model, and
%    xfig_plot_res do the single steps on its own.
%\seealso{xfig_plot_data,xfig_plot_model,xfig_plot_res,read_data_from_write_plot,write_plot}
%!%-
{
  % make it always an array
  d = [d];
  variable n = length(d);
  
  variable size = qualifier("size",[14,8,4]);
  variable pl = xfig_plot_new(size[0],size[1]);
  variable pl_res = xfig_plot_new(size[0],size[2]);

  variable xlabel = qualifier("xlabel",`Energy [keV]`);
  variable pp = d;
  if( qualifier_exists("pp") ){
    pp = prepare_data_for_pp_plot(d);
    xlabel = qualifier("xlabel","pulse phase");
  }

  % Ranges
  variable xrng = [1,-1] * DOUBLE_MAX;
  variable yrng = [1,-1] * DOUBLE_MAX;
  variable rrng = [1,-1] * DOUBLE_MAX;

  variable i;
  _for i ( 0, n-1, 1 ){
    xrng[0] = min( [ xrng[0], pp[i].lo ] );
    xrng[1] = max( [ xrng[1], pp[i].hi ] );
    yrng[0] = min( [ yrng[0], pp[i].val-pp[i].err ] );
    yrng[1] = max( [ yrng[1], pp[i].val+pp[i].err ] );
    rrng[0] = min( [ rrng[0], pp[i].res_min ] );
    rrng[1] = max( [ rrng[1], pp[i].res_max ] );
  }
  xrng = qualifier("xrng",xrng);
  yrng = qualifier("yrng",yrng);
  rrng = qualifier("rrng",rrng);
  variable ranges = qualifier("ranges",[xrng,yrng,rrng]);

  variable quali = struct_combine( struct{ padx=0.01, pady=0.05 }, __qualifiers );
  
  if (qualifier_exists("pp")){
    pl.world(ranges[0],ranges[1],ranges[2],ranges[3];; quali );
    pl_res.world(ranges[0],ranges[1],ranges[4],ranges[5];; quali );
  }
  else{
    pl.world(ranges[0],ranges[1],ranges[2],ranges[3];;
	     struct_combine( struct{loglog}, quali ) );
    pl_res.world(ranges[0],ranges[1],ranges[4],ranges[5];;
		 struct_combine( struct{xlog}, quali) ) ;
  }

  variable dcol = [qualifier("dcol",[1:n])];
  variable mcol = [qualifier("mcol",n==1? ["black"] : dcol )];
  
  _for i(0,n-1,1){
    quali = struct_combine(__qualifiers,struct{col=dcol[i]});
    pl = xfig_plot_data(pl,d[i];;quali);
    pl_res = xfig_plot_res(pl_res,d[i];;quali);
    
    quali.col = mcol[i];
    pl = xfig_plot_model(pl,d[i];;quali);
  }
  
  variable y_fac = qualifier("keV2erg_fac",NULL);
  if (y_fac != NULL) {   pl.ylabel(sprintf(`$ \nu F_\nu \; [10^{%d} \times$ ergs\;\;s$^{-1}$\;cm$^{-2}]$`,y_fac)); }
  
  variable y_label = qualifier("y_label",NULL);
  if (y_label!=NULL) pl.ylabel(y_label);

  return xfig_multiplot(pl,pl_res;;
			struct_combine(struct{xlabel=xlabel},__qualifiers));
}

