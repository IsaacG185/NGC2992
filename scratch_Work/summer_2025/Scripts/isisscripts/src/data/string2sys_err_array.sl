% =================== %
define string2sys_err_array(str)
% =================== %
%!%+
%\function{string2sys_err_array}
%\synopsis{create sys_err_array from str = sys_err_array2string}
%\usage{Array_Type sys_err = string2sys_err_array(String_Type str);}
%\description
%
%   This routines converts a string created by the function
%   "sys_err_array2string" back to an array, which can then be applied
%   to the data by the function set_sys_err_frac.
%   
%\seealso{fits_save_fit, set/get_sys_err_frac, sys_err_array2string}
%!%- 
{
   variable delim = qualifier("delim",",");   

   variable arr = Double_Type[0];

   variable tp = strtok(str,delim);

   variable t,sub,is,i_lo,i_hi,fac,del,i;
   foreach t(tp)
   {
      sub = strtok(t, ":");
      if (length(sub) != 2)
      {
	 vmessage("sys_err_array_to_string: String %s not compatible with the function!",str);
	 return NULL;
      }
      is = strtok(sub[0],"-");
      i_lo = integer(is[0]);
      i_hi = integer(is[1]);
      fac = atof(sub[1]);

      del = i_hi-i_lo+1;
      _for i(0,del-1,1)
      {
	 arr = [arr, fac];
      }
   }

   return arr;
}
