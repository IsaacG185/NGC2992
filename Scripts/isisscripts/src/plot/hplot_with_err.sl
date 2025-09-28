%%%%%%%%%%%%%%%%%%%%%
define hplot_with_err()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{hplot_with_err}
%\synopsis{plots histogram data points with errorbars}
%\description
%    This function passes all its arguments and qualifiers to the
%    \code{plot_with_err} function, but adds the \code{histogram} and \code{xminmax} qualifiers.
%\seealso{[o][h]plot_with_err, [o][h]plot}
%!%-
{
  if(_NARGS)
  { variable args = __pop_list(_NARGS);
    plot_with_err(__push_list(args);; struct_combine(__qualifiers(), "histogram", "xminmax"));
  }
  else
    help(_function_name());
}
