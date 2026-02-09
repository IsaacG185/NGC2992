%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define fits_read_key_int_frac()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_read_key_int_frac}
%\synopsis{reads a keyword from a FITS file, which may be split in integer and fractional part}
%\usage{fits_read_key_int_frac(String_Type filename, key);}
%\seealso{fits_read_key}
%!%-
{
  variable filename, key;
  switch(_NARGS)
  { case 2: (filename, key) = (); }
  { help(_function_name()); return; }

  variable value;
  if(fits_key_exists(filename, key))
  {
    value = fits_read_key(filename, key);
    if(typeof(value)==String_Type)  value = atof(value);
    return value;
  }
% else
  if(fits_key_exists(filename, key+"I"))
  {
    value = fits_read_key(filename, key+"I");
    if(typeof(value)==String_Type)  value = atof(value);
    if(fits_key_exists(filename, key+"F"))
    {
      variable value2 = fits_read_key(filename, key+"F");
      if(typeof(value2)==String_Type)  value2 = atof(value2);
      value += value2;
    }
    return value;
  }
  return NULL;
}
