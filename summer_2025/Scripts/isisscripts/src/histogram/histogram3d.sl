define histogram3d()
%!%+
%\function{histogram3d}
%\synopsis{bins scatter data into a 3d histogram}
%\usage{Integer_Type[,,] histogram3d(Double_Type x[], y[], z[], Xgrid[], Ygrid[], Zgrid[])}
%\description
%    \code{histogram3d} computes the number \code{N[i,j,k]} of points \code{(x[m], y[m], z[m])}
%    that fall into the 3d-cell with \code{Xgrid[i] <= x < Xgrid[i+1]},
%    \code{Ygrid[j] <= y < Ygrid[j+1]} and \code{Zgrid[k] <= z < Xgrid[k+1]}.
%    The last bin in each dimension is an overflow bin,
%    such that its upper limit is at infinity.
%\seealso{histogram, histogram2d}
%!%-
{
  variable x, y, z, Xgrid, Ygrid, Zgrid;
  switch(_NARGS)
  { case 6: (x, y, z, Xgrid, Ygrid, Zgrid) = (); }
  { return help(_function_name()); }

  if(length(x)!=length(y) || length(y)!=length(z))
    return vmessage("error (%s): arrays x, y, z have to have the same length", _function_name());

  variable h3 = Integer_Type[length(Xgrid),length(Ygrid),length(Zgrid)];
  variable i, iz;
  _for iz (0, length(Zgrid)-2, 1)
  {
    i = where(Zgrid[iz] <= z < Zgrid[iz+1]);
    if(length(i))
      h3[*,*,iz] = histogram2d(x[i], y[i], Xgrid, Ygrid);
  }
  i = where(z >= Zgrid[-1]);  % overflow bin
  if(length(i))
    h3[*,*,-1] = histogram2d(x[i], y[i], Xgrid, Ygrid);

  return h3;
}
