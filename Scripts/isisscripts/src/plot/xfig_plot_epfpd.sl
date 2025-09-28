require( "xfig" );
require("png"); 
require("gcontour");

define xfig_plot_epfpd (ep, lc)
%!%+
%\function{xfig_plot_epfpd}
%\synopsis{plot the results of epfoldpdot with Xfig, including the
%pulse profile of the stronges P/P-dot values}
%\usage{xfig_plot_epfpd(Struct_Type eppd, Struct_Type lc)
%}
%\qualifiers{
%\qualifier{W}{width of resulting plot (default=12)}
%\qualifier{H}{height of resulting plot (default=W)}
%\qualifier{pdstart}{start of P-dot axis (default read from eppd)}
%\qualifier{pdstop}{end of P-dot axis (default read from eppd)}
%\qualifier{pstart}{start of P axis (default read from eppd)}
%\qualifier{pstop}{end of P axis (default read from eppd)}
%\qualifier{p0}{center of P  axis (default mean of periods in eppd)}
%\qualifier{cmap}{[\code{="iceandfire"}] Color-map of Chi^2 landscape }
%\qualifier{cont}{switch to plot FWHM contour on map }
%\qualifier{pp}{switch to plot pulse profile below map }
%\qualifier{t0}{[\code{="0"}] t0 for pulse profile }
%\qualifier{nbins}{[\code{="12"}] number of phase bins for pulse profile }
%}
%           
%\description
%    This function plots the results for "epfoldpdot" into a nice
%    colorful xfig image, with the cuts in P and P-dot over the most
%    significant period as well as (if desired) the pulse profile of
%    that period. This style of plot is inspired by the results plots
%    of PRESTO.
%
%    This code is still under development and not very flexible yet.
%    Feel free to improve it.       
%
%  \seealso{epfoldpdot}
%!%-
{
   variable W = qualifier("W", 12) ;
   variable H = qualifier("H", W) ;
   
   variable xf = xfig_plot_new(W,H) ;

   variable pdstart = qualifier("pdstart", min(ep.pd)) ;
   variable pdstop =  qualifier("pdstop", max(ep.pd)) ;
   variable pstart = qualifier("pstart", min(ep.p)) ;
   variable pstop =  qualifier("pstop", max(ep.p)) ;

   variable p0 = qualifier("p0", mean(ep.p)) ;

   xf.world(pdstart, pdstop,pstart-p0,pstop-p0) ;
   xf.xlabel("$\\dot{P}$ [s/s]") ;
   xf.ylabel(sprintf("$P$ [s] - %.5f", p0)) ;

   xf.plot_png(ep.stat ; cmap=qualifier("cmap","iceandfire")) ;

#ifexists gcontour_compute
   if (qualifier_exists("cont"))
     {
	variable fwhm = gcontour_compute(ep.stat, [max(ep.stat)/2.]) ;

	xf.plot(fwhm[0].x_list[0]*(ep.pd[1]-ep.pd[0]) + ep.pd[0],
		(fwhm[0].y_list[0]*(ep.p[1]-ep.p[0]) + ep.p[0] - p0) ;
		line=0, width=2 , color="green2") ;

	xf.plot(min(fwhm[0].x_list[0]*(ep.pd[1]-ep.pd[0]) + ep.pd[0])[[0,0]], [-1,1] ; color="red") ;
     }
#endif

   variable pdmaxn = where_max(max(ep.stat,0)) ;
   variable pmaxn = where_max(max(ep.stat,1)) ;


   xf.plot(ep.pd[pdmaxn], ep.p[pmaxn] ; sym="+") ;

   variable x = ep.stat[pmaxn,*] ;
   variable y = ep.stat[*,pdmaxn] ;

   variable xx = xfig_plot_new(W, H/4.) ;
   xx.world(pdstart,pdstop,min(ep.stat), max(ep.stat) );
   xx.plot(ep.pd, x) ;
   xx.xaxis(;ticlabels=0) ;
   xx.ylabel("$\\chi^2$") ;

   variable xy = xfig_plot_new(W/4., H) ;
   xy.world(min(ep.stat), max(ep.stat),pstart,pstop) ;
   xy.plot(y, ep.p) ;
   xy.yaxis(;ticlabels=0) ;
   xy.xlabel("$\\chi^2$") ;

   variable xf1 = xfig_new_vbox_compound(xx,xf);
   variable xf2= xfig_new_hbox_compound(xf1,xy ; just=-0.93) ;
    
      
   if (qualifier_exists("pp"))
     {
	variable pp = pfold(lc.time, lc.rate, ep.p[pmaxn], lc.error ; pdot=ep.pd[pdmaxn],  nbins=qualifier("nbins", 12),
			    t0=qualifier("t0", 0), dt=lc.fracexp) ;

	variable xpp=xfig_plot_new(W, H/4.);
	xpp.xlabel("Phase") ;
	xpp.ylabel("cts/s") ;
   
	xpp.hplot([pp.bin_lo, pp.bin_lo+1],[pp.value, pp.value],[pp.error,pp.error]) ;
   
	return xfig_new_vbox_compound(xf2,xpp) ;
     }

   else
     return xf2 ;

}
