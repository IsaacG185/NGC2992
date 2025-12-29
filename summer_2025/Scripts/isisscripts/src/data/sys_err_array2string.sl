define sys_err_array2string(arr)
%!%+
%\function{sys_err_array2string}
%\synopsis{creates a string from an Array returned by "get_sys_err_frac"}
%\usage{String_Type str = sys_err_array2string(Array_Type sys_err);}
%\description
%
%    This routine creates a String from the Array of systematic errors
%    apllied to the data. Such an array is returned by the function
%    "get_sys_err_frac".
%   
%\seealso{fits_save_fit, set/get_sys_err_frac, string2sys_err_array}
%!%- 
{
   variable delim = "";
   variable str_sys = "";
   
   variable i_beg = 0;
   variable i_end = 0;
   
   variable n = length(arr), i;
   if(n) {
   _for i(0,n-1,1)
   {

      
      if (i > 0)
      {
	 if (abs(arr[i] - arr[i-1]) > 1e-8)
	 {
	    str_sys += delim+string(i_beg)+"-"+string(i_end)+":"+string(arr[i_beg]);
	    delim = qualifier("delim",",");   
	    i_beg = i; i_end=i;
	 }
	 else
	 {
	    i_end++;
	 }
	 
      }
   }
   % write the last line, too
   str_sys += delim+string(i_beg)+"-"+string(i_end)+":"+string(arr[i_beg]);   
   } else {
    % if length(arr) is zero, there are no systematic errors defined. This
    % string should result in zero systematic errors when run through
    % string2sys_err_array() and set_sys_err_frac().
    str_sys = "0-0:0";   
   }
   return str_sys;
}
