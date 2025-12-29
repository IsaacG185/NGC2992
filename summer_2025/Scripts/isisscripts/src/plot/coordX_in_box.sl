define coordX_in_box()
%!%+
%\function{coordX_in_box}
%\synopsis{calculates a world x-coordinate from the relative x-coordinate in the plot box}
%\usage{Double_Type coordY_in_box(Double_Type x_rel)}
%\description
%    The left boundary of the plot box has \code{x_rel==0},
%    and the right boundary has \code{x_rel==1}.
%    Logarithmic world-coordinates are properly taken into account.
%    Note that the xrange has to be set in advance
%    in order to calculate the world x-coordinate with \code{coordX_in_box}.
%\seealso{coordY_in_box, coords_in_box}
%!%-
{
  variable x_rel;
  switch(_NARGS)
  { case 1: x_rel = (); }
  { help(_function_name()); return; }

  variable plot_opt = get_plot_options();
  if(plot_opt.logx)
    return plot_opt.xmin * (plot_opt.xmax / plot_opt.xmin)^x_rel;
  else
    return plot_opt.xmin + x_rel * (plot_opt.xmax - plot_opt.xmin);
}
