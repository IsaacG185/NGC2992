%%%%%%%%%%%%%%%%
define get_all_data()
%%%%%%%%%%%%%%%%
%!%+
%\function{get_all_data}
%
%\synopsis{Get a list of all data-set indices}
%\usage{List_Type = get_all_data;}
%\description
%
%       This function returns a list of data indices, which have been obtained via all_data. 
%       The information is saved in a List, not an Array, which allows plotting of all datasets. 
%
%\example
%	isis>variable d = get_all_data;
%	isis>plot_data(d);
%
%\seealso{all_data}
%!%-

 { 
variable ad = all_data;
variable nl = {};

variable k;

_for k (0, length(ad)-1,1) {list_append(nl, ad[k]);}

if (nl[0]==NULL) {return NULL;}
else{

 return nl; }
     
}


