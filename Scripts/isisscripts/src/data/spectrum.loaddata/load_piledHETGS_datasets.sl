%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define load_piledHETGS_datasets()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{load_piledHETGS_datasets}
%\synopsis{loads Chandra HETGS spectral and sets up the simple_gpile model}
%\usage{Integer_Type ids[] = load_1storderHETGS_dataset(specpath, RMFpath);}
%\seealso{load_HETGS_datasets, use_simple_gpile}
%!%-
{
  variable specpath, RMFpath;
  switch(_NARGS)
  { case 2: (specpath, RMFpath) = (); }
  { help(_function_name()); return;}

  variable s = load_HETGS_datasets(specpath, RMFpath);
  reshape(s, [3,4]);
  variable s1 = s[0,*];
  variable a2 = Integer_Type[4];
  variable a3 = Integer_Type[4];
  variable i;
  _for i (0, 3, 1)
  { a2[i] = get_data_info(s[1,i]).arfs[0];
    a3[i] = get_data_info(s[2,i]).arfs[0];
  }
  if(get_fit_fun() == "")  fit_fun("1");
  use_simple_gpile(s1, a2, a3);
  reshape(s, [12]);
  return s;
}
