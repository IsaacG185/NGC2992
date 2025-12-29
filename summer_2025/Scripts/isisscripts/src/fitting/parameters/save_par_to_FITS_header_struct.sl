%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define save_par_to_FITS_header_struct()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{save_par_to_FITS_header_struct}
%\synopsis{saves fit-function and paramters to a FITS header structure}
%\usage{Struct_Type save_par_to_FITS_header_struct()}
%\description
%    The returned structure can be used as header keys
%    that are written to a FITS file.
%    This header can be read with \code{load_par_from_FITS_header}.
%\seealso{load_par_from_FITS_header, load_par, save_par, fits_write_binary_table}
%!%-
{
  variable p = get_params();
  variable s = struct { fit_fun = get_fit_fun(), num_pars=length(p) };
  variable i = 1;
  foreach p (p)
  {
    variable si = @Struct_Type( "par"+string(i)+["", "_min", "_max", "_frz", "_tie", "_fun"] );
    set_struct_fields(si,
		      p.value,
		      p.min == -DOUBLE_MAX ? "-inf" : p.min,
		      p.max ==  DOUBLE_MAX ? "+inf" : p.max,
		      p.freeze,
		      p.tie==NULL ? 0 : p.tie,
		      p.fun==NULL ? 0 : p.fun
		     );
    s = struct_combine(s, si);
    i++;
  }
  return s;
}
