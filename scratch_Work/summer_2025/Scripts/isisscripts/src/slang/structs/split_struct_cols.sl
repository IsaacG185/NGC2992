define split_struct_cols(str,num)
%!%+
%\function{split_struct_cols}
%\synopsis{split structure in an array of structures with maximal num
%columns}
%\usage{Struct_Type str_array = split_struct_cols(Struct_Type str,
%Integer_Type num);}
%\description
%
%     This function splits a structure in an array of structures,
%     with maximal 'num' columns in each structure.
%
%     This can be useful, as fits-tables only allow 999 colums to
%     be written in the same extension. With split_struct_cols these
%     can be splitted an written into different extensions. Afterwards
%     they can be easily combined with struct_combine().
%     
%\seealso{fits_save_fit, struct_combine}
%!%-
{  
  
  variable names = get_struct_field_names(str);
  
  variable n = int((length(names)-1)/num)+1;
  
  variable strs = Struct_Type[n];
  variable i;
  _for i(0,n-1,1)
  {
    variable ind,ss;
    ind = (i < n-1) ? (names[[0:num-1]+num*i]) : (names[[num*i:]]);
    
    strs[i] = @Struct_Type(ind);
    foreach ss(ind)
    {
      set_struct_field(strs[i],ss,get_struct_field(str,ss));
    }
  }

  return strs;
}
