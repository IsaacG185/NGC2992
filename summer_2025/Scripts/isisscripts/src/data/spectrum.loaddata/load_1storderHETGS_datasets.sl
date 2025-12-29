%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define load_1storderHETGS_datasets()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{load_1storderHETGS_datasets}
%\synopsis{loads MEG+-1 & HEG+-1 Chandra HETGS spectra}
%\usage{Integer_Type ids[] = load_1storderHETGS_datasets(String_Type specpath, RMFpath);}
%!%-
{
  variable specpath, RMFpath;
  switch(_NARGS)
  { case 2: (specpath, RMFpath) = (); }
  { help(_function_name());  return;}
  return load_HETGS_datasets(specpath, RMFpath, 1);
}
