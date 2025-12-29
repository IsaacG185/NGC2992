define rebin_to_energy_grid(id,elo,ehi)
%!%+
%\function{rebin_to_energy_grid}
%\synopsis{rebin data to a given energy grid}
%\usage{rebin_to_energy_grid(Dataset ID, bin_lo, bin_hi);}
%\description
%   This routine bins the data to a given energy grid. Bins outside
%   the given energy grid are left unbinned.
%\seealso{rebin_data,rebin_satellite, rebin_human2isis}
%!%-
{
   variable info = get_data_info(id).rebin;
   % go to the original binning
   rebin_data(id,0);

   % get the (un-binned) grid 
   variable e = _A(get_data_counts(id)); % take care to be in energy space
   variable nelo = e.bin_lo;   variable nehi = e.bin_hi;

   variable n = length(nelo); variable m = length(elo);
   variable n_reb = Integer_Type[n];
   
   variable i,j;
   % initalize 
   variable val = +1;j=0;

   %  ====  LOOP  ====  %
   _for i(0,n-1,1)
   {
      % see if the bin has to be changed
      if (elo[j]<nelo[i])
      {
	 val*=-1;
	 if (j < m-1) j++;
      }
      if (elo[0]>nelo[i]) val*=-1; % leave it unbinned outside the energy range
      
      n_reb[i] = val;
   }
   %  ================  %
   
   % rebin spectrum
   rebin_data(id,n_reb);
      
   return reverse(n_reb);
}
