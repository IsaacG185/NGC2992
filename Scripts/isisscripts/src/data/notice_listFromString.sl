define notice_listFromString(str)
%!%+
%\function{notice_listFromString}
%\synopsis{creates a isis notice_list from a string containing the
%noticed bins separated with ",".}
%\usage{Array_Type notice = notice_listFromString(String_Type str);}                
%\seealso{notice_list, notice_listToString, get_data_info, fits_save_fit}       
%!%-
{
  
  variable sub = strtok(str,",");
  variable n = length(sub);
  variable nl = Integer_Type[n];
  
  variable i;
  _for i(0,n-1,1)
  {
    nl[i] = integer(sub[i]);
  }

  return nl;
}
