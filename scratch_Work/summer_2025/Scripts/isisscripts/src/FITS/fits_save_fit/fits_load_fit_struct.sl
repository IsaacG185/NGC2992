define fits_load_fit_struct(name)
%!%+
%\function{fits_load_fit_struct}
%\synopsis{loads a FITS file written by 'fits_save_fit'}
%\usage{Struct_Type str = fits_load_fit_struct(String_Type filename);}
%\seealso{fits_save_fit}
%!%-
{
  variable l = fits_get_num_hdus(name);

   if (l <= 1)
   {
      message(" *** Warning: No extension contained in the FITS file!");return "";
   }
   
  variable strs = Struct_Type[l-1];
  
  variable i;
  variable str = fits_read_table(name+"[1]";casesen);
  _for i(1,l-2,1)
  {
    str = struct_combine(str, fits_read_table(name+"["+string(i+1)+"]";casesen));
  }
  
  return str;
}
