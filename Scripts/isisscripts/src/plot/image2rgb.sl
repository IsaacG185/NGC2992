define image2rgb()
%!%+
%\function{image2rgb}
%\synopsis{converts an image (2d array) to a 24bit RGB image}
%\usage{Integer_Type rgb[] = image2rgb(Double_Type img[]);
%\altusage{Integer_Type rgb[] = image2rgb(Double_Type R[], G[], B[]);}
%}
%\description
%    \code{min(img)} will be mapped to black, \code{max(img)} to white,
%    and other values to their linear gray scale.\n
%    This function can be used for \code{png_write}(\code{_flipped}).
%\seealso{png_write}
%!%-
{
  variable R, G, B;

  switch(_NARGS)
  { case 1: G = (); }
  { case 3: (R, G, B) = (); }
  { help(_function_name()); return; }

  variable G_0_255 = int( 255.9999999999999 * (G - min(G)) / (max(G)-min(G)) );
  if(_NARGS==1)
    return typecast(G_0_255, Char_Type);
  else
  { variable R_0_255 = int( 255.9999999999999 * (R - min(R)) / (max(R)-min(R)) );
    variable B_0_255 = int( 255.9999999999999 * (B - min(B)) / (max(B)-min(B)) );
    return (R_0_255 << 16) | (G_0_255 << 8) | B_0_255;
  }
}
