%%%%%%%%%%%%%%%%%%%%
define fits_num_hdus()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_num_hdus}
%\usage{Integer_Type fits_num_hdus(String_Type filename)}
%\description
%    This function is just a wrapper around the
%    \code{_fits_get_num_hdus} function from ISIS' cfitsio module.
%\seealso{_fits_get_num_hdus}
%!%-
{
  variable filename;
  switch(_NARGS)
  { case 1: filename = (); }
  { help(_function_name()); return; }

  variable fp = fits_open_file(filename, "r");
  variable num; ()=_fits_get_num_hdus(fp, &num);
  fits_close_file(fp);
  return num;
}
