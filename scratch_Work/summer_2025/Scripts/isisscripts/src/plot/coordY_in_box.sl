define coordY_in_box()
%!%+
%\function{coordY_in_box}
%\synopsis{calculates a world y-coordinate from the relative y-coordinate in the plot box}
%\usage{Double_Type coordY_in_box(Double_Type y_rel)}
%\description
%    The lower boundary of the plot box has \code{y_rel==0},
%    and the upper boundary has \code{y_rel==1}.
%    Logarithmic world-coordinates are properly taken into account.
%    Note that the yrange has to be set in advance
%    in order to calculate the world y-coordinate with \code{coordY_in_box}.
%\seealso{coordX_in_box, coords_in_box}
%!%-
{
  variable y_rel;
  switch(_NARGS)
  { case 1: y_rel = (); }
  { help(_function_name()); return; }

  variable plot_opt = get_plot_options();
  if(plot_opt.logy)
    return plot_opt.ymin * (plot_opt.ymax / plot_opt.ymin)^y_rel;
  else
    return plot_opt.ymin + y_rel * (plot_opt.ymax - plot_opt.ymin);
}
