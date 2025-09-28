define fits_get_hdu_names()
%!%+
%\function{fits_get_hdu_names}
%\synopsis{returns the names of all extensions within a FITS-file}
%\usage{String_Type[] fits_get_hdu_names(Fits_File_Type fp);}
%\description
%  Moves to the first extension of a FITS-file using
%  `_fits_movabs_hdu' and then iterates over all extensions
%  using `_fits_movrel_hdu' to read the 'EXTNAME' keyword.
%  The string array of all extension names is returned.
%  
%  Note that the file-pointer is located at the last
%  extension in the end. Furthermore the first extension
%  has the index 1 (at least for `_fits_movabs_hdu'), which
%  has to be taken into account if the indices of the name-
%  array are used to find specific extensions.
%\seealso{fits_open_file, fits_read_key}
%!%-
{
  variable fp;
  switch (_NARGS)
    { case 1: fp = (); }
    { help(_function_name); return; }

  % move to first extension
  if (_fits_movabs_hdu(fp, 1) > 0) {
    vmessage("error (%s): cannot move to first extension, is the file opened?", _function_name);
    return;
  }

  % read extension names
  variable names = String_Type[0];
  do {
    names = [names, fits_read_key(fp, "extname")];
  } while (_fits_movrel_hdu(fp, 1) == 0);

  return names;
}
