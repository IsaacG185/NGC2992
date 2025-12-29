define fits_append_binary_table()
%!%+
%\function{fits_append_binary_table}
%\synopsis{appends a binary table to the end of a FITS file}
%\usage{fits_append_binary_table(filename, [extname], data[, keys[, hist]]);}
%\description
%    This function employs functions from ISIS' cfitsio module
%    in order to open/create a FITS file,
%#c    find the number of HDUs,
%#c    move to the end of the file,
%    and append a binary table extension.
%#c\seealso{fits_open_file, _fits_get_num_hdus, _fits_movabs_hdu, fits_write_binary_table}
%\seealso{fits_open_file, fits_write_binary_table}
%!%-
{
  variable filename, extname=NULL, data, keys=NULL, hist=NULL;
  switch(_NARGS)
  { case 2: (filename,          data) = (); }
  { case 3: (filename, extname, data) = (); }
  { case 4: (filename, extname, data, keys) = (); }
  { case 5: (filename, extname, data, keys, hist) = (); }
  { help(_function_name()); return; }

  variable F = typeof(filename)==String_Type
               ? fits_open_file(filename, stat_file(filename)==NULL ? "c" : "w")
               : filename;
%  variable num_hdus; ()=_fits_get_num_hdus(F, &num_hdus);
%  ()=_fits_movabs_hdu(F, num_hdus);
  if(extname==NULL)  extname = "";
  fits_write_binary_table(F, extname, data, keys, hist);
  fits_close_file(F);
}
