private variable fit_2d_data_grid = struct { X, Y, X_hi, Y_hi, nx, ny, XX, YY, XX_1d, YY_1d };

%%%%%%%%%%%%%%%%%%%%%%%
define set_2d_data_grid()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{set_2d_data_grid}
%\usage{set_2d_data_grid(Double_Type X[], Double_Type Y[]);}
%\altusage{set_2d_data_grid(Double_Type X_lo[], Double_Type X_hi[], Double_Type Y_lo[], Double_Type Y_hi[]);}
%\synopsis{define a two dimensional data grid required for 2D fits}
%\description
%    For fitting 2d data the corresponding grid is set with this function.
%    If \code{set_2d_data_grid} is not called, the function \code{define_counts_2d}
%    uses the indices of the image as grid.
%    For binned fit functions bin_lo and bin_hi have to be provided.
%    If only single X and Y arrays are provided, only fit functions
%    which are evaluated on these grid points can be used.
%\seealso{define_counts_2d, gauss_2d_integrated, gauss_2d}
%!%-
{
  variable X, Y, X_hi, Y_hi;
  switch(_NARGS)
  { case 2: (X, Y) = (); }
  { case 4: (X, X_hi, Y, Y_hi) = ();
            fit_2d_data_grid.X_hi  = X_hi; fit_2d_data_grid.Y_hi  = Y_hi; }

  variable nx = length(X);
  variable ny = length(Y);
  variable XX, YY;  (XX, YY) = get_grid(X, Y);
  fit_2d_data_grid.X  = X;      fit_2d_data_grid.Y  = Y;
  fit_2d_data_grid.nx = nx;     fit_2d_data_grid.ny = ny;
  fit_2d_data_grid.XX = @XX;    fit_2d_data_grid.YY = @YY;
  reshape(XX, length(XX));      reshape(YY, length(YY));
  fit_2d_data_grid.XX_1d = XX;  fit_2d_data_grid.YY_1d = YY;
}

%%%%%%%%%%%%%%%%%%%%%%%
define get_2d_data_grid()
%%%%%%%%%%%%%%%%%%%%%%%
{
  if(qualifier_exists("bins"))
    return (fit_2d_data_grid.X, fit_2d_data_grid.X_hi, fit_2d_data_grid.Y, fit_2d_data_grid.Y_hi);

  if(qualifier_exists("oned"))
    return (fit_2d_data_grid.XX_1d, fit_2d_data_grid.YY_1d);

  if(qualifier_exists("dim"))
    return (fit_2d_data_grid.nx, fit_2d_data_grid.ny);

  return (fit_2d_data_grid.XX, fit_2d_data_grid.YY);
}
