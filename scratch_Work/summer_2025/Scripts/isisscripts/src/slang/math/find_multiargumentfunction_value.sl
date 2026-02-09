%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define find_multiargumentfunction_value()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{find_multiargumentfunction_value}
%\synopsis{computes an inverse function}
%\usage{Double_Type xi0 = find_multiargumentfunction_value(Ref_Type &f, Double_Type val, x1, x2, ..., xn);}
%\qualifiers{
%\qualifier{qualifiers}{structure of qualifiers to be passed to f}
%\qualifier{eps}{[=1e-12]}
%}
%\description
%    \code{f} has to be a real function with n arguments.
%    While \code{xi = [xi_min, xi_max]} is an array, \code{xj} (for \code{j!=i}) are constants.
%    A binary search is performed to find \code{xi0} such that
%    \code{f(x1, x2, ...,  xn)  =  val} for \code{xi = xi0}.\n
%    If \code{f} is not strictly monotonic for \code{xi_min < xi < xi_max}, the algorithm does not
%    need to succeed. Otherwise, the accuracy of \code{xi0} is \code{(xi_max-xi_min)/1e12}.
%\seealso{find_function_value}
%!%-
{
  variable arg = __pop_args(_NARGS-2);
  variable val = ();
  variable f = ();

  variable i;
  _for i (0, length(arg)-1, 1)
    if(typeof(arg[i].value)==Array_Type)
      break;
  if(typeof(arg[i].value)!=Array_Type)
  { message("error (" + _function_name() + "): one argument has to be an array");
    return NULL;
  }
  variable x1 = min(arg[i].value);
  variable x2 = max(arg[i].value);
  variable qualifiers = qualifier("qualifiers", NULL);
  arg[i].value = x1;  variable f_x1 = @f( __push_args(arg) ;; qualifiers);
  arg[i].value = x2;  variable f_x2 = @f( __push_args(arg) ;; qualifiers);
  ifnot(f_x1 <= val <= f_x2 || f_x1 >= val >= f_x2)
    return vmessage("error (%s): value %g is not enclosed by f(x1=%g)=%g and f(x2=%g)=%g", _function_name(), val, x1, f_x1, x2, f_x2);
  variable eps = (x2-x1)*qualifier("eps", 1e-12);
  while(x2-x1>eps)
  { arg[i].value = (x1+x2)/2.;
    variable f_x = @f( __push_args(arg) ;; qualifiers);
    if( (val-f_x1)*(val-f_x) > 0)
      (x1, f_x1) = (arg[i].value, f_x);
    else
      (x2, f_x2) = (arg[i].value, f_x);
  }
  return (x1+x2)/2.;
}
