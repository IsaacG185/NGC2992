define rebin_human2isis(reb)
%!%+
%\function{rebin_human2isis}
%\synopsis{create isis binning from str = rebin_human2isis}
%\usage{Array_Type binning = rebin_human2isis(String_Type str);}
%\description
%   This routine converts a binning string created with
%   rebin_isis2human back to the ISIS conform binning array
%   (see e.g. get_data_info(idx).rebin). It can be used to
%   restore the binning of data directly.
%   
%\seealso{fits_save_fit, get_data_info, rebin_isis2human}
%!%-
{

  variable tp = strtok(reb,",");
  
  variable s0 = Integer_Type[0];
  variable sg = 1;
  
  variable t,sub,is,i_lo,i_hi,n,i,j,del;
  foreach t(tp)
  {
    sub = strtok(t, ":");
    if (length(sub) == 1)
    {
      s0 = [s0, sg];
      sg *=-1;
    }
    else
    {
      is = strtok(sub[0],"-");
      i_lo = integer(is[0]);
      i_hi = integer(is[1]);
      del = i_hi-i_lo+1;
      n = integer(sub[1]);
            
      _for i(1,del,1)
      {
	s0 = [s0, sg];	  
	if (i mod n == 0) sg *=-1;
      }
      
    }
  }

  return s0;
}
