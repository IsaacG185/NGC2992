define narrowline_fit (bin_lo,bin_hi,par)
%!%+
%\function{narrowline (fit-function)}
%\synopsis{multiplicative model; implements unresolved absorption/emission line}
%\description
%   simple multiplicative line-function to efficiently model
%   unresolved absorption and emission lines. Allows to direclty fit
%   the equivalent width of the line.
%
%   Caution: the function does not check whether the line is
%   unresolved; user needs to take care of that before using the
%   function. In particular, for absorption lines the absolute value
%   of the equivalent width should be smaller than the resolution of
%   the data.
%
%   The fit parameters are
%
%      center [A]   line position
%      eqw    [A]   equivalent width of the line
%!%-
{

  %array that we will return in the end; 1 everywhere
  variable dd = Double_Type[length(bin_lo)];
  dd[*] = 1.0;
  
  variable idx;

  %only do stuff if your line is within the energy range of your data
  %at all
  if (par[0] > bin_lo[0] and par[0] < bin_hi[-1]) {
    
    %if emission line, do ...
    if (par[1] >= 0) {
      
      %%last entry where the lower limit of the bin is below the
      %%centroid energy of the lone
      idx = where(bin_lo < par[0])[-1];
      
      %determine the multiplicative factors representing the line
      dd[idx] = 1+par[1]/(bin_hi[idx]-bin_lo[idx]);
      
    }
    %if absorption line, do ...
    else{
      
      %maximal and minimal wavelength
      variable lmin = par[0]-abs(par[1])/2.;
      variable lmax = par[0]+abs(par[1])/2.;
      
      %use where and not fancy max/min logic which would be shorter code
      %but much less efficient
      
      %note that the inner where always have to be one that stars with
      %zero and counts up without interruption; otherwise we are getting
      %ugly stuff
      variable idx1 = where (bin_hi[where( bin_lo < lmin)] > lmin);
      variable idx2 = where (bin_hi[where( bin_lo < lmax)] > lmax);
      variable idx3 = where (bin_lo[where( bin_hi < lmax)] > lmin);
      
      %% next step: union function of the three idx
      idx = union(idx1,idx2,idx3);
      
      %determine the multiplicative factors representing the line
      variable i;
      _for i (0,length(idx)-1,1) {
	dd[idx[i]]=1-_max((_min(bin_hi[idx[i]],lmax) -
			   _max(bin_lo[idx[i]],lmin)),0)/
	  (bin_hi[idx[i]]-bin_lo[idx[i]]);
      }
      
    }
    
  }
  
  return dd;
}

%%%%%%%%%%%%%%%%%%%%%%%%
add_slang_function("narrowline", ["center [A]", "eqw [A]"]);
%%%%%%%%%%%%%%%%%%%%%%%%

define narrowline_default(i)
{
  switch(i)
    { case 0: return ( 9.15, 0, 0.1, 100 ); }
    { case 1: return ( -0.004, 0, -1, 1); }
}
set_param_default_hook("narrowline", &narrowline_default);
