define coords_in_box()
%!%+
%\function{coords_in_box}
%\synopsis{calculates world coordinates from the relative coordinates in the plot box}
%\usage{(Double_Type x, y) = coordY_in_box(Double_Type x_rel, y_rel);}
%\description
%    Note that the x- and yrange has to be set in advance
%    in order to calculate the world coordinates with \code{coords_in_box}.
%\seealso{coordX_in_box, coordY_in_box}
%!%-
{
  variable relX, relY;
  switch(_NARGS)
  { case 2: (relX, relY) = (); }
  { help(_function_name()); return; }

  return (coordX_in_box(relX), coordY_in_box(relY));
}
