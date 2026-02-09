
define ohplot_with_err()
%!%+
%\function{ohplot_with_err}
%\synopsis{overplots histogram data points with errorbars}
%\description
%    This function passes all its arguments and qualifiers to the
%    \code{hplot_with_err} function, but adds the \code{overplot} qualifier.
%\seealso{[o][h]plot_with_err, [o][h]plot}
%!%-
{
  if(_NARGS)
  { variable args = __pop_list(_NARGS);
    hplot_with_err(__push_list(args);; struct_combine(__qualifiers(), "overplot"));
  }
  else
    help(_function_name());
}
