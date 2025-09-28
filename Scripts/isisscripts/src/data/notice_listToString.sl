define notice_listToString(nl)
%!%+
%\function{notice_listToString}
%\synopsis{converts an isis notice_list to a string}
%\usage{String_Type str = notice_listToString(Array_Type notice_list);}                
%\seealso{notice_list, notice_listFromString, get_data_info, fits_save_fit}       
%!%-
{
  variable result = "";
  variable comma = "";
  
  variable i;
  _for i(0,length(nl)-1,1)
  {
    result += comma+string(nl[i]);
    comma = ",";    
  }
  return result;
}
