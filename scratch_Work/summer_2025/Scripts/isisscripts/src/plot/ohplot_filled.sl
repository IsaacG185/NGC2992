%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define ohplot_filled(lo,hi,val)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ohplot_filled}
%\synopsis{over-plot a filled histogram defined by slang arrays}
%\usage{ohplot_filled(Array_Type bin_lo, Array_Type bin_hi, Array_Type values)
%}
%\qualifiers{
%\qualifier{fill_style}{[\code{=1}] set the fill style:\n
%                       \code{FS = 1} \code{=>} solid (default)\n
%                       \code{FS = 2} \code{=>} outline\n
%                       \code{FS = 3} \code{=>} hatched (cannot be used with ylog;)\n
%                       \code{FS = 4} \code{=>} cross-hatched (cannot be used with ylog;)\n}
%\qualifier{ymin}{[\code{=min(values)}] set the lower y-value to which the areas are filled}
%\qualifier{angle}{[\code{=degrees}] sets the angle of the hatched lines for FS=3 [default = 45] }
%}
%\description
%    This function overplots a histogram described by three 1-D S-Lang arrays of size N.
%    The area below the histogram is filled. The fill style can be selected with a qualifier.
%\examples
%    \code{ohplot_filled([1:5],[2:6],[1:5]);}\n
%\seealso{hplot_filled, hplot}
%!%-
{
  ohplot(lo,hi,val);
  variable fs = qualifier("fill_style",1);

  %get hatching style and save it in order to reset it in the end
  variable hangle, hsep, hphase ;
  (hangle, hsep, hphase) = _pgqhs ;
  
  _pgsfs(fs);  
  if (fs == 3) { _pgshs(qualifier("angle",45), 1, 0);}
  
  variable i;
  if (get_plot_options.logx)
  {
    lo = log10(lo);
    hi = log10(hi);
  }
  if (get_plot_options.logy) val = log10(val);
  variable y_min = qualifier("ymin",max([min(val),get_plot_options.ymin ]));
  if (get_plot_options.logy) y_min = log10(y_min);
  if (get_plot_options.logy && (fs > 2)) 
  {
    printf("warning: hatched fill_style not allowed with ylog;\nfill_style was set to 1\n");
    _pgsfs(1);
  }
  _for i (0, length(lo)-1, 1) 
  {
    ()=_pgpoly(4,[lo[i],lo[i],hi[i],hi[i]],[y_min,val[i],val[i],y_min]);
  }

  %reset hatching style to default values:
  _pgshs(hangle, hsep, hphase);
}
