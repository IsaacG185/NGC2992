define oplot_xline()
%!%+
%\function{oplot_xline}
%\synopsis{overplots one or more vertical line(s)}
%\usage{oplot_xline(Double_Type x1[, x2, ...]);}
%\qualifiers{
%\qualifier{ymin}{[=<minimum of current \code{yrange}>]}
%\qualifier{ymax}{[=<maximum of current \code{yrange}>]}
%\qualifier{color}{number of the color to use}
%}
%\description
%    For each \code{x} of \code{x1}[, \code{x2}, ...] (which may be arrays, too),
%    a line is overplotted from \code{ymin} to \code{ymax} with the same \code{color}.
%!%-
{
  if(_NARGS<1) { help(_function_name()); return; }

  variable args = __pop_list(_NARGS);
  variable plot_opt = get_plot_options();
  variable col = qualifier("color", plot_opt.color);
  variable ymin = qualifier("ymin", plot_opt.ymin);
  variable ymax = qualifier("ymax", plot_opt.ymax);
  connect_points(-1);
  variable x;
  loop(_NARGS)
    foreach x ([list_pop(args)])
    { color(col);
      oplot([x, x], [ymin, ymax]);
    }
  connect_points(plot_opt.connect_points);
}
