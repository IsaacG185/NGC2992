define load_par_from_FITS_header()
%!%+
%\function{load_par_from_FITS_header}
%\synopsis{loads the fit-function and parameters from a FITS file}
%\usage{load_par_from_FITS_header(String_Type filename);}
%\description
%    This function reads keywords from a FITS header
%    created with \code{save_par_to_FITS_header_struct}.
%\seealso{save_par_to_FITS_header_struct, save_par, load_par}
%!%-
{
  variable file;
  if(_NARGS==1)  file = ();
  else { help(_function_name()); return; }

  fit_fun( fits_read_key(file, "fit_fun") );
  variable i;
  _for i (1, fits_read_key(file, "num_pars"), 1)
  {
    variable istr = string(i);

    variable par_fun = fits_read_key(file, "par"+istr+"_fun");
    set_par_fun(i, (__is_numeric(par_fun) ? NULL : par_fun));

    variable par_min = fits_read_key(file, "par"+istr+"_min");  ifnot(__is_numeric(par_min))  par_min = -DOUBLE_MAX;
    variable par_max = fits_read_key(file, "par"+istr+"_max");  ifnot(__is_numeric(par_max))  par_max =  DOUBLE_MAX;
    set_par(i, fits_read_key(file, "par"+istr, "par"+istr+"_frz"), par_min, par_max);

    variable par_tie = fits_read_key(file, "par"+istr+"_tie");
    if(__is_numeric(par_tie))  untie(i);  else  tie(par_tie, i);
  }
}
