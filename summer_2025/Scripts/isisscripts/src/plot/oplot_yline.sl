%%%%%%%%%%%%%%%%%%
define oplot_yline()
%%%%%%%%%%%%%%%%%%
%!%+
%\function{oplot_yline}
%\synopsis{overplots one or more horizontal line(s)}
%\usage{oplot_yline(Double_Type y1[, y2, ...]);}
%\qualifiers{
%\qualifier{xmin}{[=<minimum of current \code{xrange}>]}
%\qualifier{xmax}{[=<maximum of current \code{xrange}>]}
%\qualifier{color}{number of the color to use}
%}
%\description
%    For each \code{y} of \code{y1}[, \code{y2}, ...] (which may be arrays, too),
%    a line is overplotted from \code{xmin} to \code{xmax} with the same \code{color}.
%!%-
{
  if(_NARGS<1) { help(_function_name()); return; }

  variable args = __pop_list(_NARGS);
  variable plot_opt = get_plot_options();
  variable col = qualifier("color", plot_opt.color);
  variable xmin = qualifier("xmin", plot_opt.xmin);
  variable xmax = qualifier("xmax", plot_opt.xmax);
  connect_points(-1);
  variable y;
  loop(_NARGS)
    foreach y ([list_pop(args)])
    { color(col);
      oplot([xmin, xmax], [y, y]);
    }
  set_plot_options(plot_opt);
}
