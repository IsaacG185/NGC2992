%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define fits_write_binary_table_extensions()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_write_binary_table_extensions}
%\synopsis{writes a binary FITS table with several extensions}
%\usage{fits_write_binary_table_extensions(filename, data1, data2, ...);}
%\description
%    \code{data1}, \code{data2}, ... are either just the data structures
%    or a list of the arguments 2, 3[, 4[, 5]] of \code{fits_write_binary_table}:
%    \code{{ extname, data[, keys[, hist]] }}
%
%    This function should usually not be used!
%    ISIS' cfitsio module allows to write several extensions
%    into a file after opening it with fits_open_file.
%\examples
%    \code{fits_write_binary_table_extensions("data.fits", struct { a1, b1 }, struct { a2, b2 });}\n
%    \code{fits_write_binary_table_extensions("data.fits",}
%    \code{                                   { "first", struct { a1, b1 } },}
%    \code{                                   { "second", struct { a2, b2 } });}\n
%    \code{fits_write_binary_table_extensions("data.fits",}
%    \code{                                   { "first", struct { a1, b1 }, struct { key11="value11"; key12="value12" } });}\n
%!%-
{
  if(_NARGS==0)  return help(_function_name());

  variable arg = __pop_list(_NARGS);
  variable FITSfilename = list_pop(arg);
  variable F = fits_open_file(FITSfilename, "c");
  variable i=1;
  foreach arg (arg)
  { switch(length(arg))
    { case 1: fits_write_binary_table(F, sprintf("ext%d", i), arg[0]); }
    { case 2: fits_write_binary_table(F, arg[0], arg[1]); }
    { case 3: fits_write_binary_table(F, arg[0], arg[1], arg[2]); }
    { case 4: fits_write_binary_table(F, arg[0], arg[1], arg[2], arg[3]); }
    i++;
  }
  fits_close_file(F);
}
