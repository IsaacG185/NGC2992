define find_function_value()
%!%+
%\function{find_function_value}
%\synopsis{computes an inverse function}
%\usage{Double_Type x0 = find_function_value(Ref_Type &f, Double_Type val, x1, x2);}
%\qualifiers{
%\qualifier{qualifiers}{structure of qualifiers to be passed to f}
%\qualifier{eps}{[=1e-12]}
%\qualifier{quiet}{do not show error message}
%}
%\description
%    \code{f} has to be a real function with one argument.
%    A binary search is performed to find \code{x0} such that\n
%       \code{f(x0)  =  val} .\n
%    If \code{f} is not strictly monotonic in \code{[x1:x2]}, the algorithm does not
%    need to succeed. Otherwise, the accuracy of \code{x0} is \code{(x2-x1)*eps}.
%\seealso{find_multiargumentfunction_value, find_function_maximum}
%!%-
{
  variable f, val, x1, x2;
  switch(_NARGS)
  { case 4: (f, val, x1, x2) = (); }
  { help(_function_name()); return; }

  if(x2<x1)  (x1, x2) = (x2, x1);
  variable qualifiers =  qualifier("qualifiers", NULL);
  variable f_x1 = @f(x1;; qualifiers);
  variable f_x2 = @f(x2;; qualifiers);
  ifnot( (f_x1 <= val <= f_x2) or (f_x1 >= val >= f_x2) )
  { ifnot(qualifier_exists("quiet"))
      vmessage("error (" + _function_name() + "): value %g is not enclosed by f(x1=%g)=%g and f(x2=%g)=%g.", val, x1, f_x1, x2, f_x2);
    return NULL;
  }
  variable eps = (x2-x1)*qualifier("eps", 1e-12);
  while(x2-x1>eps)
  { variable x = (x1+x2)/2.;
    variable f_x = @f(x;; qualifiers);
    if( (val-f_x1)*(val-f_x) > 0)
      (x1, f_x1) = (x, f_x);
    else
      (x2, f_x2) = (x, f_x);
  }
  return (x1+x2)/2.;
}
