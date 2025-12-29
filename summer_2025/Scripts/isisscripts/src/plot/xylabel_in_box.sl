define xylabel_in_box()
%!%+
%\function{xylabel_in_box}
%\synopsis{places a text label at a relative position in the plot box}
%\usage{xylabel_in_box(Double_Type x_rel, y_rel, String_Type label[, angle[, justify]]);}
%\description
%    \code{xylabel_in_box} uses relative coordinates \code{x_rel} and \code{y_rel}:
%    the plot box corresponds to \code{0<=x_rel<=1} and \code{0<=y_rel<=1},
%    but the \code{label} can also be placed outside of this area.
%    In order to calculate the world coordinates (with \code{coords_in_box}),
%    the \code{x}- and \code{yrange} has to be set before the first plot command.
%
%    The world coordinates and the optional parameters are passed to
%    \code{xylabel}, so see \code{xylabel} for a description of \code{angle} and \code{justify}.
%\seealso{coords_in_box, xylabel}
%!%-
{
  variable relX, relY, s, angle=0, justify=0;
  switch(_NARGS)
  { case 3: (relX, relY, s                ) = (); }
  { case 4: (relX, relY, s, angle         ) = (); }
  { case 5: (relX, relY, s, angle, justify) = (); }
  { help(_function_name()); return; }

  xylabel(coords_in_box(relX, relY), s, angle, justify);
}
