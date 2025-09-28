%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define load_piled1storderHETGS_datasets()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{load_piled1storderHETGS_datasets}
%\synopsis{loads 1st order Chandra-HETGS data and sets up the simple_gpile model}
%\usage{Integer_Type ids[] = load_1storderHETGS_dataset(specpath, RMFpath);}
%!%-
{
  variable specpath, RMFpath;
  switch(_NARGS)
  { case 2: (specpath, RMFpath) = (); }
  { help(_function_name()); return; }

  variable ids = load_piledHETGS_datasets(specpath, RMFpath);
  delete_data(ids[[4:11]]);
  return ids[[0:3]];
}
