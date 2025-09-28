define find_function_maximum()
%!%+
%\function{find_function_maximum}
%\synopsis{looks for the position of a function's maximum value}
%\usage{Double_Type x0 = find_function_maximum(Ref_Type &f, Double_Type x1, Double_Type x2);
%\altusage{Double_Type x0 = find_function_maximum(Ref_Type &f, Double_Type x1, Double_Type x2, &f_x0);}
%}
%\qualifiers{
%\qualifier{qualifiers}{structure of qualifiers to be passed to f}
%\qualifier{eps}{[=1e-12]}
%}
%\description
%    \code{f} has to be a real function with one argument.
%    A binary search is performed to find \code{x0} such that\n
%       \code{f(x0)  =  max( f([x1:x2]) )}.\n
%    If \code{f} is not convex in \code{[x1:x2]}, the algorithm does not need
%    to succeed. Otherwise, the accuracy of \code{x0} is \code{(x2-x1)*eps}.
%\seealso{find_function_value}
%!%-
{
  variable f, x1, x2, valref=NULL;
  switch(_NARGS)
  { case 3: (f, x1, x2) = (); }
  { case 4: (f, x1, x2, valref) = (); }
  { help(_function_name()); return; }

  if(x2<x1)  (x1, x2) = (x2, x1);
  variable qualifiers = qualifier("qualifiers", NULL);
  variable eps = (x2-x1)*qualifier("eps", 1e-12);
  while(x2-x1>eps)
  { variable xn1 = (2*x1+x2)/3., xn2 = (x1+2*x2)/3.;
    if(@f(xn1;; qualifiers) > @f(xn2;; qualifiers))
      x2 = xn2;
    else
      x1 = xn1;
  }
  variable x = (x1+x2)/2.;
  if(valref!=NULL)  @valref = @f(x;; qualifiers);
  return x;
}
