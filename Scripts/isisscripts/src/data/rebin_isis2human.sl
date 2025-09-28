define rebin_isis2human(reb)
%!%+
%\function{rebin_isis2human}
%\synopsis{converts isis binning in a human readable string}
%\usage{String_Type str = rebin_isis2human(Array_Type binning);}
%\description
%   This routine converts the binning as used by ISIS (see e.g. 
%   get_data_info(idx).rebin) to a string which is easy to read.
%   
%   The routine fits_save_fit() uses this string to save the binning
%   of the data. It can be converted back by using rebin_human2isis().
%\seealso{fits_save_fit, get_data_info, rebin_human2isis}
%!%-
{
  variable ind = 0;
  variable ind_0 = ind;  
  variable comma = "";
  variable result = "";
  variable str;
  variable ct = 0;
  variable diff=-1;
  variable diff_0 = -1;
  variable sg = sign(reb[0]);
  
  variable i;
  _for i(1,length(reb),1)
  {
    if (i == length(reb) || sign(reb[i]) != sg )
    {
      
      ct++;
      diff = i-ind;
      if ((diff != diff_0))
      {
	if ( diff_0 != -1) 
	{
	  if (ct == 1 and diff_0 == 1)
	  {
	    str = comma+string(ind-1);
	  }
	  else
	  {
	    str= comma+string(ind_0)+"-"+string(ind-1)+":"+string(diff_0);
	  }
	  result +=str;
	  comma = ",";
	}
	if (i < (length(reb)-1)) ct = 0;
	ind_0 = ind;
	diff_0 = diff;	  
      }
      
      ind = i;
      if (i < length(reb)) sg = sign(reb[i]);
      
    }
  }
  
  if (ct == 1 and diff_0 == 1)
  {
    str = comma+string(ind-1);
  }
  else
  {
    str= comma+string(ind_0)+"-"+string(ind-1)+":"+string(diff_0);
  }
  result +=str;
  
  return result;
}
