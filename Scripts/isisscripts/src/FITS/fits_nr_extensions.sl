%%%%%%%%%%%%%%%%%%%%%%%%%
define fits_nr_extensions()
%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_nr_extensions}
%\synopsis{counts the extensions of a FITS file}
%\usage{Integer_Type fits_nr_extensions(String_Type filename)}
%\description
%    This function counts the number of extensions
%    in addition to the primary extension, i.e.,
%    returns \code{fits_num_hdus(filename)-1}.
%\seealso{_fits_get_num_hdus, fits_num_hdus}
%!%-
{
  variable filename;
  switch(_NARGS)
  { case 1: filename = (); }
  { help(_function_name()); return; }

  variable fp;
  if(_fits_open_file (&fp, filename, "r"))
    return -1;  % error
  variable nr = 0;
  while(_fits_movrel_hdu(fp, 1)==0)  nr++;
  fits_close_file(fp);

  return nr;
}
