%%%%%%%%%%%%%%%%%%%%%%%%%
public define gridmapping()
%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{gridmapping}
%\synopsis{computes a table of a 2d mapping}
%\usage{Struct_Type data = gridmapping(&getxy, X, Xfine, Y, Yfine);}
%!%-
{
  variable getxy, X, Xfine, Y, Yfine;
  switch(_NARGS)
  { case 3: (getxy, X, Y) = (); Xfine = X; Yfine = Y; }
  { case 5: (getxy, X, Xfine, Y, Yfine) = (); }
  { help(_function_name()); return; }

  variable n = length(X) * length(Yfine) + length(Y) * length(Xfine);
  variable dat = struct { x=Double_Type[n], y=Double_Type[n], x_=Double_Type[n], y_=Double_Type[n] };
  variable i = 0, x, y;
  foreach x (X)
    foreach y (Yfine)
    {
      (dat.x[i], dat.y[i], dat.x_[i], dat.y_[i]) = (x, y, @getxy(x, y));
      i++;
    }
  foreach y (Y)
    foreach x (Xfine)
    {
      (dat.x[i], dat.y[i], dat.x_[i], dat.y_[i]) = (x, y, @getxy(x, y));
      i++;
    }
  return dat;
}
