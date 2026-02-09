define interpol_polynomial()
%!%+
%\function{interpol_polynomial}
%\synopsis{interpolates a polynomial function between data points}
%\usage{Double_Type y = interpol_polynomial(Double_Type x, Double_Type X[], Double_Type Y[]);}
%\description
%    \code{X} and \code{Y} are arrays of same length \code{n}.
%    \code{y} is the Lagrange polynomial (of degree \code{n-1}) interpolating
%    the data points (\code{X[i]}, \code{Y[i]}), evaluated at \code{x}:\n
%      \code{     n-1           n-1      x - X[j]  }\n
%      \code{y =  sum  Y[i] * product  ----------- }\n
%      \code{     i=0        j=0,j!=i   X[i]-X[j]  }
%
%    If \code{x} is an array (which doesn't need to be ordered), \code{y} will also be an array.
%\seealso{interpol_points}
%!%-
{
  variable x, X, Y;
  switch(_NARGS)
  { case 3: (x, X, Y) = (); }
  { help(_function_name()); return; }

  variable n = length(X);
  if(length(Y) != n)
  { vmessage("error (%s): the arrays X and Y must have the same size."); return; }

  variable y = Double_Type[0];
  if(length(x)>1)
  { variable x1;
    foreach x1 (x) { y = [y, interpol_polynomial(x1, X, Y)]; }
  }
  else
  { variable i, j;
    for(y=0,i=0; i<n; i++)
    { variable prod = Y[i];
      for(j=0; j<n; j++)
      { if(i!=j) { prod *= (x-X[j])/(X[i]-X[j]); }
      }
      y += prod;
    }
  }
  return y;
}
