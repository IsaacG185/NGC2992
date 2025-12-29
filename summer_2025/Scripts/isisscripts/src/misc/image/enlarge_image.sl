require("gsl","gsl");

%%%%%%%%%%%%%%%%%%%%
define enlarge_image()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{enlarge_image}
%\synopsis{enlarge an image to subpixel resolution by 2d interpolation}
%\usage{Double_Type IMG = enlarge_image(img, Integer_Type n);
%\altusage{Double_Type IMG = enlarge_image(img, Integer_Type nx, ny);}
%}
%\qualifiers{
%\qualifier{interp}{reference to interpolation function (see below)}
%\qualifier{y_first}{interpolate first in y-, then in x-direction}
%}
%\description
%    The pixels of \code{img} are mapped to every \code{nx}-th pixel
%    in x-direction and every \code{ny}-th pixel in y-direction
%    (in the first usage, nx = ny = n) of \code{IMG}:
%#v+
%       IMG[ [::ny], [::nx] ] = img;
%#v-
%    As no extrapolation is performed at the boundary,
%    width and height of \code{IMG} are smaller than \code{nx*w} and \code{ny*h},
%    where \code{w} and \code{h} are width and height of \code{img}.
%
%    Intermediate pixels are interpolated using the function
%    specified by the \code{interp} qualifier, which defaults to
%    \code{gsl->interpol_cspline} if the gsl module is available,
%    and otherwise to ISIS' \code{interpol} function. In general,
%    it can be a reference to any function of the form
%#v+
%       newy[] = interpol(newx[], oldx[], oldy[]);
%#v-
%    All qualifiers of \code{enlarge_image} are passed to \code{@interp}.
%
%    The interpolation is first performed in x-direction
%    and then in y-direction -- unless the \code{y_first} qualifier
%    is specified. For linear and cubic spline interpolation,
%    the final result is independent of the order.
%!%-
{
  variable img, nx, ny;
  switch(_NARGS)
  { case 2: (img, nx) = (); ny = nx; }
  { case 3: (img, nx, ny) = (); }
  { return help(_function_name()); }

  % dimensions of original image img
  variable dims = array_shape(img);
  variable y = [0 : dims[0]-1];
  variable x = [0 : dims[1]-1];

  % dimensions of final image IMG
  nx = nint(nx);
  ny = nint(ny);
  variable DIMS = [(dims[0]-1)*ny+1, (dims[1]-1)*nx+1];
  variable Y = [0 : DIMS[0]-1], Yval = Y * 1./ny;
  variable X = [0 : DIMS[1]-1], Xval = X * 1./nx;

  % interpolation routine
  variable interp = qualifier("interp",
#ifexists gsl->interp_cspline
			      &gsl->interp_cspline
#else
			      &interpol
#endif
			     );
  variable ix, iy, iX, iY;
  variable Img, IMG = Double_Type[DIMS[0], DIMS[1]];

  if(qualifier_exists("y_first"))
  {
    % message("interpolate first in y (1st index)");
    Img = Double_Type[DIMS[0], dims[1]];
    foreach ix (x)
      Img[*,ix] = (@interp)(Yval, y, img[*,ix];; __qualifiers);
    foreach iY (Y)
      IMG[iY,*] = (@interp)(Xval, x, Img[iY,*];; __qualifiers);
  }
  else
  {
    % message("% interpolate first in x (2nd index)");
    Img = Double_Type[dims[0], DIMS[1]];
    foreach iy (y)
      Img[iy,*] = (@interp)(Xval, x, img[iy,*];; __qualifiers);
    foreach iX (X)
      IMG[*,iX] = (@interp)(Yval, y, Img[*,iX];; __qualifiers);
  }

  return IMG;
}
