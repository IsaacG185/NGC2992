define rebin_to_instrument(ni,no)
%!%+
%\function{rebin_to_instrument}
%\synopsis{rebin data from one instrument to another instrument}
%\usage{rebin_to_instrument(Dataset id_reference, Dataset id_to_be_rebinned);}
%\description
%   This routine tries its best to rebin the given dataset with the ID
%   "id_to_be_rebinned" to the dataset with id "id_reference".
%\seealso{rebin_to_energy_grid,rebin_data}
%!%-
{
   variable d = _A(get_data_counts(ni));
   rebin_to_energy_grid(no,d.bin_lo,d.bin_hi);
   
   return;
}
