% ================= %
define notice_human2isis(sl)
% ================= %
%!%+
%\function{notice_human2isis}
%\synopsis{create isis notice_list from str = notice_isis2human}
%\usage{Array_Type notice_list = notice_human2isis(String_Type str);}
%\description
%   This routine converts a notice_list string created with
%   notice_isis2human back to the ISIS conform binning array
%   (see e.g. get_data_info(idx).notice_list). It can be used to
%   restore the otcing of data directly, by using it as argument
%   in the function notice_list(...).
%   
%\seealso{fits_save_fit, get_data_info, notice_isis2human}
%!%-
{
  
  variable nl = Integer_Type[0];
  
  variable tk = strtok(sl,",");

  variable i,j;
  _for i(0, length(tk)-1, 1)
  {
    variable ttk = strtok(tk[i],"-");
    if (length(ttk) == 1)
    {
      nl = [nl, integer(ttk)];
    }
    else
    {
      variable tlo = integer(ttk[0]);
      variable thi = integer(ttk[1]);
      
      _for j(tlo,thi,1)
      {
	nl = [nl, j];	
      }

    }
  }
   
  return nl;
}
