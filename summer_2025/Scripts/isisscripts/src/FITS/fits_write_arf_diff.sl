%%%%%%%%%%%%%%%%%%%%%%%%%%
define fits_write_arf_diff()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_write_arf_diff}
%\synopsis{writes the difference of two ARFs in a corresponding FITS file}
%\usage{fits_write_arf_diff(String_Type arffile0, arffile1, arffile2);}
%\description
%    arf0  =  arf1 - arf2\n
%    The important header keywords are copied from arf1,
%    assuming that they are the are the same in arf2.
%!%-
{
  variable arffile0, arffile1, arffile2;
  switch(_NARGS)
  { case 3: (arffile0, arffile1, arffile2) = (); }
  { help(_function_name()); return; }

  if(qualifier_exists("verbose"))
    vmessage("ARF(%s) = ARF(%s) - ARF(%s)", arffile0, arffile1, arffile2);

  variable a = fits_read_table(arffile1);
  a.specresp -= fits_read_col(arffile2, "SPECRESP");
  variable keys = fits_read_key_struct(arffile1,
	"TUNIT1", "TUNIT2", "TUNIT3", "TELESCOP", "INSTRUME", "FILTER", "ARFVERSN",
	"HDUCLASS", "HDUCLAS1", "HDUCLAS2", "HDUVERS1", "HDUVERS2", "HDUVERS");

  fits_write_binary_table(arffile0, "SPECRESP", a, keys);
}
