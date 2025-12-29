% there is 'check_parameter_hit' but it is a: not documented and b: not very useful

define par_bounds ()
%!%+
%\function{par_bounds}
%\synopsis{Return parameter index of parameters hitting bounds}
%\usage{Int_Type[] par_bounds();}
%\qualifiers{
%  \qualifier{tolerance}{[=0.01] Boundary hit tolerance}
%}
%\description
%  This function returns the parameter index for every parameter with satisfies
%  (par.max-par.value)/(par.max-par.min) <= tolerance or
%  (par.value-par.min)/(par.max-par.min) <= tolerance.
%\seealso{list_par_bounds, list_free_bounds}
%!%-
{
  variable tol = _min(_max(qualifier("tolerance", 0.01), 1.), 0);

  variable par, p, r = {};

  par = get_params();
  if (NULL == par)
    return NULL;

  foreach p (par) {
    if (tol >= (p.max-p.value)/(p.max-p.min)
	|| tol >= (p.value-p.min)/(p.max-p.min))
      list_append(r, p.index);
  }

  return (length(r)) ? list_to_array(r) : Int_Type[0];
}

private variable __bounds_header = "%s\n idx%-*s          min             <bound>            max";
private variable __bounds_format = "%3u  %-*s  %10.7g %30s %-10.7g";
private variable __bounds_default = ('-')[[0:29]/30];

private define __bounds_lines (p, tol, max_name_len) {
  variable idicator;
  variable left, right;
  variable sector;
  variable factor;
  variable str;

  if (p.min == p.max) {
    left = '|'; right = '|';
    sector = 12;
    factor = 0.;
  } else if (tol >= (p.max-p.value)/(p.max-p.min)) {
    left = '<'; right = '|';
    factor = +.5;
    sector = 24;
  } else if (tol >= (p.value-p.min)/(p.max-p.min)) {
    left = '|'; right = '>';
    factor = -.5;
    sector = 0;
  } else {
    left = '<'; right = '>';
    factor = (p.value-.5*(p.max+p.min))/(p.max-p.min);
    sector = int(round((p.value-p.min)/(p.max-p.min)*24));
  }

  str = @__bounds_default;
  str[[sector:sector+5]] = string_to_wchars(sprintf("<%c.%02d>",
							(sign(factor)<0) ? '-' : '+',
							int(abs(factor*100))));
  str[0] = left; str[-1] = right;
  vmessage(__bounds_format, p.index, max_name_len, p.name, p.min, wchars_to_string(str), p.max);
}

define list_par_bounds ()
%!%+
%\function{list_par_bounds}
%\synopsis{List parameter range bounds}
%\usage{list_par_bounds();}
%\qualifiers{
%  \qualifier{tolerance}{[=0.01] Boundary hit tolerance}
%}
%\description
%  This function reports the values of the fit parameters relative to the
%  allowed parameter range. The value is indicated in a graphical indicator
%  where the parameter lies (from -0.5 to +0.5 around the center). If the
%  parameter value is within <tolerance> close to the range minimum or maximum
%  the indicator at the correspongind limit changes from '<' or '>' to '|'.
%  In the case of min == max both ends are displayed as '|'.
%\seealso{list_free_bounds, par_bounds}
%!%-
{
  variable tol = _min(_max(qualifier("tolerance", 0.01), 1.), 0);

  variable par,p;
  variable len = 0;

  par = get_params();
  if (NULL == par)
    return;

  foreach p (par)
    len = max([len, strlen(p.name)]);

  vmessage(__bounds_header, get_fit_fun(), len, "  param");

  variable idicator;
  variable left, right;
  variable sector;
  variable factor;
  foreach p (get_params)
    __bounds_lines (p, tol, len);
}

define list_free_bounds ()
%!%+
%\function{list_free_bounds}
%\synopsis{List parameter range bounds for free parameters}
%\usage{list_free_bounds();}
%\qualifiers{
%  \qualifier{tolerance}{[=0.01] Boundary hit tolerance}
%}
%\description
%  This function reports the parameter boundaries for all free parameters.
%  For more details see help for \code{list_par_bounds}.
%\seealso{list_par_bounds, par_bounds}
%!%-
{
  variable tol = _min(_max(qualifier("tolerance", 0.01), 1.), 0);

  variable par,p;
  variable len = 0;

  par = get_params();
  if (NULL == par)
    return;

  foreach p (par)
    len = max([len, strlen(p.name)]);

  vmessage(__bounds_header, get_fit_fun(), len, "  param");

  variable idicator;
  variable left, right;
  variable sector;
  variable factor;
  foreach p (get_params) {
    ifnot (p.freeze || p.tie != NULL || p.fun != NULL)
      __bounds_lines (p, tol, len);
  }
}
