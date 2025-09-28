define continued_fraction()
%!%+
%\function{continued_fraction}
%\synopsis{computes a continued fraction}
%\usage{Double_Type continued_fraction(UInteger_Type a[])}
%\description
%    \code{                                  1 |      1 |}\n
%    \code{continued_fraction(a) = a[0] + ------ + ------ + ...}\n
%    \code{                               | a[1]   | a[2]}
%!%-
{
  variable a;
  switch(_NARGS)
  { case 1: a = (); }
  { help(_function_name()); return; }

  variable n_ = 0,  n = 1,  d_ = 1,  d = 0;
  variable i=0;
  _for i (0, length(a)-1, 1)
    (n_, d_, n, d) = (n, d, n_+a[i]*n, d_+a[i]*d);
  return 1.*n/d;
}
