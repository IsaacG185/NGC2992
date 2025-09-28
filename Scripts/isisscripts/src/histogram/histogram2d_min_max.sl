%%%%%%%%%%%%%%%%%%%%%%%%
define histogram2d_min_max()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{histogram2d_min_max}
%\synopsis{computes a 2d histogram between minimum and maximum data values}
%\usage{h2 = histogram2d_min_max(Double_Type Y, X);}
%\qualifiers{
%\qualifier{xmin}{[\code{=min(X)}]: first value of \code{Xlo}-grid}
%\qualifier{xmax}{[\code{=max(X)}]: last value of \code{Xhi}-grid}
%\qualifier{ymin}{[\code{=min(Y)}]: first value of \code{Ylo}-grid}
%\qualifier{ymax}{[\code{=max(Y)}]: last value of \code{Yhi}-grid}
%\qualifier{Nx}{[=50]: number of bins of (linear) \code{Xlo}-grid}
%\qualifier{Ny}{[=50]: number of bins of (linear) \code{Ylo}-grid}
%\qualifier{Xlo}{reference to a variable to store the \code{Xlo} array}
%\qualifier{Ylo}{reference to a variable to store the \code{Ylo} array}
%}
%\description
%    For 2d arrays, the order of the indices matters.
%    Almost all ISIS and related functions use \code{h2[iy, ix]}
%    with the first index corresponding to y, and the second to x.
%    For this reason, \code{histogram2d_min_max} -- just as
%    \code{histogram2d} (though not explicitly documented) --
%    needs to get the array \code{Y} of y-coordinates as first argument
%    and the array \code{X} of x-coordinates only as second argument,
%    if the resulting 2d array \code{h2} shall be used with functions
%    like \code{plot_image}, \code{png_write}, \code{ds9_view}, etc..
%
%    The x-grid \code{Xlo} starts at \code{xmin}, but ends before xmax,
%    such that \code{Xhi = make_hi_grid(Xlo)} would end at \code{xmax}.
%    The same is true for the y-grid \code{Ylo} with \code{ymin} and \code{ymax}.
%
%    Unlike \code{histogram2d(Y, X, Ylo, Xlo)}, \code{h2} will not contain
%    overflow bins in the last column and the last row, i.e.,
%    \code{h2[iy,ix]} corresponds to the number of pairs (\code{X}, \code{Y})
%    where \code{Xlo[ix] <= X < Xhi[ix]} and \code{Ylo[iy] <= Y < Xhi[iy]}.
%\example
%    variable n=10000; x=2*grand(n), y=grand(n), Xlo, Ylo;
%    variable h2 = histogram2d_min_max(y, x; Xlo=&Xlo, Ylo=&Ylo);
%    plot_image(h2, 0, Xlo+(Xlo[1]-Xlo[0])/2., Ylo+(Ylo[1]-Ylo[0])/2.);
%\seealso{histogram2d}
%!%-
{
  variable X, Y;
  switch(_NARGS)
  { case 2: (Y, X) = (); }
  { help(_function_name()); return; }

  variable Xlo = [qualifier("xmin", min(X)) : qualifier("xmax", max(X)) : #(qualifier("Nx", 50)+1)];
  variable Ylo = [qualifier("ymin", min(Y)) : qualifier("ymax", max(Y)) : #(qualifier("Ny", 50)+1)];
  variable XloRef = qualifier("Xlo");  if(typeof(XloRef)==Ref_Type)  @XloRef = Xlo[[:-2]];
  variable YloRef = qualifier("Ylo");  if(typeof(YloRef)==Ref_Type)  @YloRef = Ylo[[:-2]];
  return histogram2d(Y, X, Ylo, Xlo)[[:-2],[:-2]];
}
