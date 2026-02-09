%%%%%%%%%%%%%%%%%%%%%%%%%%
define load_HETGS_datasets()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{load_HETGS_datasets}
%\synopsis{loads Chandra HETGS spectra from a type II pha file}
%\usage{Integer_Type ids[] = load_HETGS_datasets(String_Type specpath, RMFpath[, Integer_Type ms[]]);}
%\description
%    \code{ids} is an array containing negative/positive MEG/HEG spectra
%!%-
{
  variable specpath, RMFpath, ms = [1,2,3];
  switch(_NARGS)
  { case 2: (specpath, RMFpath) = (); }
  { case 3: (specpath, RMFpath, ms) = (); }
  { help(_function_name()); return;}
  specpath += "/";
  RMFpath += "/";

  % 1st index: [0, 1, 2, 3] = grating and +/- direction, see variable grat
  variable grat = ["MEG_-", "MEG_", "HEG_-", "HEG_"];
  % 2nd index: [1,2,3] = order
  variable row = Integer_Type[4,4];  % in pha2-file
  row[[0:3],1] = [9, 10, 3, 4];  % 1st order
  row[[0:3],2] = [8, 11, 2, 5];  % 2nd-order
  row[[0:3],3] = [7, 12, 1, 6];  % 3rd-order

  variable m, s, specs = Integer_Type[0];
  foreach m ([ms])
    _for s (0, 3, 1)
      specs = [specs, loadDataset(specpath + "pha2.fits",
                                  RMFpath + grat[s] + string(m) + ".rmf",
                                  specpath + grat[s] + string(m) + "_garf.fits",
                                  specpath+"bkg2.fits",
                                  row[s, m]
                                 )
               ];
  return specs;
}
