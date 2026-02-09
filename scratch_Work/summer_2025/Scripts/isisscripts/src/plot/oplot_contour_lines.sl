%%%%%%%%%%%%%%%%%%%%%%%%%%
define oplot_contour_lines()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{oplot_contour_lines}
%\synopsis{overplots contour lines of a 2d array (image)}
%\usage{oplot_contour_lines(f, f0[, X, Y]);}
%\qualifiers{
%\qualifier{save}{=filename: saves/restores the contour lines in a FITS file}
%\qualifier{pgplot}{uses \code{_pgline} instead of \code{oplot}}
%}
%\description
%    \code{f} has to be a two-dimensional array (an image).
%    \code{f0} is the value of the contour lines \code{f[y,x] = f0}.
%    The arrays \code{X} and \code{Y}, if present, transform the array-indices \code{x} and \code{y}
%    to the coordinate system used for plotting.
%\seealso{get_contour_lines}
%!%-
{
  variable f, f0, X=NULL, Y=NULL;
  switch(_NARGS)
  { case 2: (f, f0) = (); }
  { case 4: (f, f0, X, Y) = (); }
  { help(_function_name()); return; }

  if(X==NULL)
  { X = [0:length(f[0,*])-1];
    Y = [0:length(f[*,0])-1];
  }

  variable filename = qualifier("save");
  variable pgplot = qualifier_exists("pgplot");

  variable col = get_plot_options.color;
  variable cline, data, F;
  if(filename==NULL || stat_file(filename)==NULL)
  {
    if(filename!=NULL)  F = fits_open_file(filename, "c");
    foreach cline (get_contour_lines(f, f0))
    {
      if(pgplot)
        ()=_pgline(length(cline.x), X[cline.x], Y[cline.y]);
      else
      { color(col); oplot(X[cline.x], Y[cline.y]); }

      if(filename!=NULL)
        fits_write_binary_table(F, "contour-line", struct { x=X[cline.x], y=Y[cline.y] });
    }
  }
  else
  {
    F = fits_open_file(filename, "r");
    while(_fits_movrel_hdu(F, 1)==0)
    { data = fits_read_table(F);
      if(pgplot)
        ()=_pgline(length(data.x), data.x, data.y);
      else
      { color(col); oplot(data.x, data.y); }
    }
  }
  if(filename!=NULL)  fits_close_file(F);
}
