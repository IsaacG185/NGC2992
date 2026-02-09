require( "png" );

%%%%%%%%%%%%%%%%%%%%%
define png_read_curve()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{png_read_curve}
%\synopsis{reads a curve from a x-y plot in an image}
%\usage{(X, Y) = png_read_curve(filename, xpix1, xval1, xpix2, xval2, ypix1, yval1, ypix2, yval2);}
%\description
%   \code{filename} is a png file containing a color-defined curve.
%   Its \code{x} and \code{y} coordinates are calibrated by \code{pix}/\code{val} pairs
%   of pixel coordinate and corresponding value assuming a linear scale.
%   The pixel coordinates start with (0, 0) in the upper left corner.
%   The return values are calibrated x-values and y-values
%   averaged over all pixels of the curve in the corresponding column.
%\qualifiers{
%\qualifier{color}{[\code{=0x000000} (black)]: considered color of the curve}
%\qualifier{wherenot}{consider any color except the one specified above}
%}
%!%-
{
  variable filename, xpix1, xval1, xpix2, xval2, ypix1, yval1, ypix2, yval2;
  switch(_NARGS)
  { case 9: (filename, xpix1, xval1, xpix2, xval2, ypix1, yval1, ypix2, yval2) = (); }
  { help(_function_name()); return; }

  variable verbose = qualifier_exists("verbose");
  variable col = qualifier("color", 0x000000);
  variable use_wherenot = qualifier_exists("wherenot");

  variable img = png_read(filename);
  variable x, X = {}, Y = {};
  _for x (0, array_shape(img)[1]-1, 1)
  {
    variable iy = use_wherenot ? wherenot(img[*,x]==col) : where(img[*,x]==col);
    variable len = length(iy);
    if(len)
    {
      list_append(X, xval1 + 1.*(      x -xpix1)/(xpix2-xpix1)*(xval2-xval1));
      list_append(Y, yval1 + 1.*(mean(iy)-ypix1)/(ypix2-ypix1)*(yval2-yval1));
    }
    if(verbose)
      vmessage("xpix=%d, #{ypix}=%d" + (len ? " => x=%f, y=%f" : ""),
	       x, (len ? (len, X[-1], Y[-1]) : 0) );
  }

  return (list_to_array(X), list_to_array(Y));
}

