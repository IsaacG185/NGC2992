define notice_isis2human(nl)
%!%+
%\function{notice_isis2human}
%\synopsis{converts isis notice_list in a human readable string}
%\usage{String_Type str = notice_isis2human(Array_Type notice_list);}
%\description
%   This routine converts the notice_list as used by ISIS (see e.g. 
%   get_data_info(idx).notice_list) to a string which is easy to read.
%   
%   The routine fits_save_fit() uses this string to save the noticed
%   bins of the data. It can be converted back by using 
%   notice_human2isis().
%\seealso{fits_save_fit, get_data_info, notice_human2isis}
%!%-
{
  variable sl = "";
  variable comma = "";
  
  variable n = length(nl);
  variable i=0;
  
  % initialize
  variable rem = nl[0];
  
  _for i(1,n-1,1)
  {
    if (nl[i] != nl[i-1]+1)
    {
      if ( (nl[i] - rem) <= 1)
      {
	sl += comma+string(nl[i-1]);
      }
      else 
      {
	sl += comma+string(rem)+"-"+string(nl[i-1]);
      }
      comma = ",";
      rem = nl[i];
    }
    
  }

  % print what is on the "stack"
  if ( (nl[-1] - rem) < 1)
  {
    sl += comma+string(nl[i]);
  }
  else 
  {
    sl += comma+string(rem)+"-"+string(nl[-1]);
  }
  comma = ",";
  rem = nl[-1];    
  
  return sl;
}
