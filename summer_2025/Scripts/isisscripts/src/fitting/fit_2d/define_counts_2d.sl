define define_counts_2d()
%!%+
%\function{define_counts_2d}
%\synopsis{defines a pseudo-spectrum from two-dimensional data}
%\usage{Integer_Type define_counts_2d(value[, err][, X, Y])}
%\description
%    \code{value} and \code{err} are 2d arrays of Double_Type.
%    ISIS usually deals with 1d spectra. For fitting 2d data, \code{define_counts_2d}
%    can be used to define a pseudo 1d spectrum by reshaping arrays,
%    to which ISIS' internal fit routines can be applied.\n
%    User defined fit-functions should not use the bin_lo, bin_hi arguments,
%    but the actual data-grid which can be set / obtained with \code{set}/\code{get_2d_data_grid},
%    if the user doesn't prefer to take care of the data grid on his own.
%    If the optional 1d Double_Type arrays \code{X} and \code{Y} are specified,
%    \code{set_2d_data_grid} is already called by \code{define_counts_2d}.
%\seealso{gauss_2d}
%!%-
{
  variable value, err=NULL, X=NULL, Y;
  switch(_NARGS)
  { case 1:  value             = (); }
  { case 2: (value, err)       = (); }
  { case 3: (value,      X, Y) = (); }
  { case 4: (value, err, X, Y) = (); }
  { help(_function_name()); return; }

  if(err==NULL)  err = 0*value+1;
  if(X!=NULL)  set_2d_data_grid(X, Y);

  variable value_1d = @value;
  variable err_1d = @err;
  reshape(value_1d, [length(value)]);
  reshape(err_1d, [length(err)]);

  variable bin_lo = _A([1:length(value)]);
  return define_counts(bin_lo, make_hi_grid(bin_lo), value_1d, err_1d;;__qualifiers());
}
