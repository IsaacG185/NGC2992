%%%%%%%%%%%%%%%%%%%%%%
define fits_wcs_struct()
%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_wcs_struct}
%\synopsis{creates a structure with a WCS that can be written to FITS file}
%\usage{Struct_Type fits_wcs_struct(String_Type filename)
%\altusage{Struct_Type fits_wcs_struct(Double_Type X[], Y[] [, String_Type xtype, ytype[, xunit, yunit]])}
%}
%\qualifiers{
%\qualifier{arrays}{return a struct { ctype=[ctype1, ctype2], ... } with arrays
%              instead of struct { ctype1=ctype1, ctype2=ctype2, ... }.
%              This form is, e.g., required by ds9_put_wcs_struct.}
%}
%\description
%    The (linear) World Coordinate System (WCS) can be read from a FITS file,
%    or can be defined from an array of \code{X} and \code{Y} values.
%!%-
{
  variable X, Y, xtype="", ytype="", xunit="", yunit="";
  variable filename=NULL, xcol="1", ycol="2";
  switch(_NARGS)
  { case 2: (X, Y) = (); }
  { case 4: (X, Y, xtype, ytype) = (); }
  { case 6: (X, Y, xtype, ytype, xunit, yunit) = (); }
  { case 1: filename = (); }
  { case 3: (filename, xcol, ycol) = (); }
  { help(_function_name()); return; }

  variable Ikeys = ["ctype", "cunit", "crval", "cdelt", "crpix"], keys = Ikeys;
  variable Tkeys = ["tctyp", "tunit", "tcrvl", "tcdlt", "tcrpx"];
  variable           ctype1,  cunit1,  crval1,  cdelt1,  crpix1,
                     ctype2,  cunit2,  crval2,  cdelt2,  crpix2;
  if(filename==NULL)
  {
    ctype1 = xtype;  cunit1 = xunit;  crval1 = X[0];  cdelt1 = X[1]-X[0];  crpix1 = 1;
    ctype2 = ytype;  cunit2 = yunit;  crval2 = Y[0];  cdelt2 = Y[1]-Y[0];  crpix2 = 1;
  }
  else
  {
    ifnot(fits_key_exists(filename, keys[0]+xcol))
    {
      keys = Tkeys;
      ifnot(fits_key_exists(filename, keys[0]+xcol))
        return NULL;
    }
    (ctype1, cunit1, crval1, cdelt1, crpix1) = fits_read_key(filename, keys[0]+xcol, keys[1]+xcol, keys[2]+xcol, keys[3]+xcol, keys[4]+xcol);
    (ctype2, cunit2, crval2, cdelt2, crpix2) = fits_read_key(filename, keys[0]+ycol, keys[1]+ycol, keys[2]+ycol, keys[3]+ycol, keys[4]+ycol);
  }

  variable s;
  if( qualifier_exists("arrays") )
  {
    s = @Struct_Type(Ikeys);
    set_struct_fields(s, [ctype1, ctype2], [cunit1, cunit2], [crval1, crval2], [cdelt1, cdelt2], [crpix1, crpix2]);
  }
  else
  {
    s = @Struct_Type([Ikeys+"1", Ikeys+"2"]);
    set_struct_fields(s, ctype1, cunit1, crval1, cdelt1, crpix1,  ctype2, cunit2, crval2, cdelt2, crpix2);
  }
  return s;
}
