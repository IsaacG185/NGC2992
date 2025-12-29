define chebyshev_nodes (n)
%!%+
%\function{chebyshev_nodes}
%\synopsis{Get nodes of Chebyshev polynomial}
%\usage{Double_Type[] nodes = chebyshev_nodes(Int_Type n);}
%\qualifiers{
%  \qualifier{second}{if given, return nodes of second order polynomal.}
%  \qualifier{min}{[=-1] rescale to min}
%  \qualifier{max}{[=1] rescale to max}
%}
%\description
%  Given an integer \code{n} this function returns the nodes
%  of the Chebyshev polynomial of the first kind of order \code{n}.
%
%  Or, if the \code{second} qualifier is given, the corresponding nodes
%  of the second kind polynomial.
%
%  The nodes are distributed between -1 and 1 per default. If the \code{min}
%  and \code{max} qualifiers are given the nodes are rescaled accordingly.
%\seealso{chebyshev_lagrange_weights}
%!%-
{
  variable x, r;

  x = [0:n-1];
  if (qualifier_exists("second"))
    r = -cos(x*1./(n-1)*PI);
  else
    r = -cos((2.0*x+1.0)/n*PI/2);

  variable l = qualifier("min", -1.0);
  variable h = qualifier("max", 1.0);

  return 0.5*(l+h)+0.5*(h-l)*r;
}

define chebyshev_lagrange_weights (n)
%!%+
%\function{chebyshev_lagrange_weights}
%\synopsis{Get Lagrange weights for the chebyshev_nodes}
%\usage{Double_Type[] chebyshev_lagrange_weights(Int_Type n);}
%\qualifiers{
%  \qualifier{second}{if given, return weights of second order polynomal.}
%}
%\description
%  Given an integer \code{n} this function returns the weights for the
%  barycentric Lagrange polynomial for nodes placed the the Chebyshev nodes.
%
%  In case the \code{second} qualifier is given, the second kind Chebyshev
%  polynomial defines the weights, else the first kind.
%\seealso{chebyshev_nodes,lagrange_weights,lagrange_poly}
%!%-
{
  variable x, w;
  x = [0:n-1];
  if (qualifier_exists("second"))
    w = -(-1)^x*[0.5, 1.+Double_Type[n-2], 0.5];
  else
    w = -(-1)^x*sin((2.0*x+1)/n*PI/2);

  return w;
}

define lagrange_weights (x0)
%!%+
%\function{lagrange_weights}
%\synopsis{Get Lagrange polynomial weights}
%\usage{Double_Type[] lagrange_weights(Double_Type[] x0);}
%\description
%  Given an array of evaluation points \code{x0} this function
%  calculates the weights for the barycentric Lagrange polynomial.
%\seealso{lagrange_poly}
%!%-
{
  variable w = Double_Type[length(x0)]+1;
  variable i,j;
  _for i (0, length(x0)-1)
  {
    _for j (0,i-1)
      w[j] *= 1.0/(x0[i]-x0[j]);
    _for j (i+1,length(x0)-1)
      w[j] *= 1.0/(x0[i]-x0[j]);
  }

  return w;
}

define lagrange_poly (x, x0, y0)
%!%+
%\function{lagrange_poly}
%\synopsis{Interpolate points with Lagrange polynomial}
%\usage{Double_Type[] lagrange_poly(Double_Type[] x, x0, y0);}
%\qualifiers{
%  \qualifier{w}{calculated weights can be passed directly}
%}
%\description
%  Calculate the Lagrange interpolation at points \code{x} given
%  points \code{x0},\code{y0}.
%
%  If multiple invocations of the interpolation for the same pair
%  \code{x0},\code{y0} are required it is better to calculate the
%  weights beforehand (see \code{lagrange_weights}) and pass them
%  via the \code{w} qualifier.
%
%  The Lagrange interpolation is quite powerfull, however, as any
%  polynomial interpolation scheme it suffers from Runges phenomenon.
%  It can be shown that the interpolation of a function on a uniform
%  grid is close to the worst case, while the evaluation on a grid
%  given by the Chebyshev nodes is close to optimal. Therefore, when
%  interpolating a function not restircted to a specific grid you'd
%  be best advised to use \code{chebyshev_nodes} and
%  \code{chebyshev_lagrange_weights}.
%
%\example
%  variable x = chebyshev_nodes(20; min=-2, max=2);
%  variable w = chebyshev_lagrange_weights(20);
%  variable f = sin(x);
%  % we can extrapolate, but this will diverge quickly
%  variable p = lagrange_poly([-5:5:#100], x, f; w=w);
%
%\seealso{lagrange_weights,chebyshev_nodes,chebyshev_lagrange_weights}
%!%-
{
  variable r = Double_Type[length(x)];
  variable s, t;
  variable w;

  if (length(x0) != length(y0))
    throw UsageError, "Lengths of x0 and y0 do not match";

  w = qualifier("w", lagrange_weights(x0));

  variable i;
  _for i (0, length(x)-1)
  {
    s = w/(x[i]-x0);
    t = where(isinf(s));

    if (length(t))
      r[i] = 1.0*y0[t[0]];
    else
      r[i] = sum(s*y0)/sum(s);
  }

  return length(r)==1 ? r[0]: r;
}

define lagrange_poly_deriv (x, y)
%!%+
%\function{lagrange_poly_deriv}
%\synopsis{Calculate y values of the derivative of a Lagrange polynomial}
%\usage{dy = lagrange_poly_deriv(x, y);}
%\qualifiers{
%  \qualifier{w}{calculated weights can be passed directly}
%}
%\description
%  Returns the y values of the derivative of the lagrange polynomial at the
%  given points x according to Berrut & Trefethen 2004. Interpolating those
%  points with the same weights gives the full derivative function.
%
%\example
%  variable x = chebyshev_nodes(20; min=-2, max=2);
%  variable w = chebyshev_lagrange_weights(20);
%  variable f = sin(x);
%  variable p = lagrange_poly([-5:5:#100], x, f; w=w);
%  variable df = lagrange_poly_deriv(x, f);
%  variable dp = lagrange_poly([-5:5:#100], x, df; w=w);
%
%\seealso{lagrange_poly,lagrange_weights}
%!%-
{
  variable r = Double_Type[length(y)];
  variable t, w, i;

  w = qualifier("w", lagrange_weights(x));

  _for i (0, length(y)-1)
  {
    t = [[0:i-1],[i+1:length(y)-1]];
    r[i] = -sum(w[t]/w[i]*(y[t]-y[i])/(x[t]-x[i]));
  }

  return length(r)==1 ? r[0] : r;
}
