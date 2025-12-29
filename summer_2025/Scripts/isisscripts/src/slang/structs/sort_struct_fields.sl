define sort_struct_fields() {
%!%+
%\function{sort_struct_fields}
%\synopsis{sorts structure tags in a predefined order}
%\usage{ Struct_Type newstruc = empty_struct(Struct_Type s, String_Type taglist[]);}
%\description
% This function creates a new structure newstruc with the fiels given by the
% array taglist, and fills them with the values from structure s.
%
% The order in which the fields are added is given by taglist, fields not
% listed in taglist are ignored.
%
% The function is useful, e.g., when using fits_binary_table to create a FITS-file 
% from a structure. In this case the order in which the FITS columns are created
% corresponds to the order in which they are contained in the structure. One can then
% use this function to create a FITS-file with the desired order of columns.
%
%!%-
    variable s,fieldarr;
    (s,fieldarr)=();

    variable snew=@Struct_Type(fieldarr);
    variable i;
    _for i(0,length(fieldarr)-1,1) {
	set_struct_field(snew,fieldarr[i],get_struct_field(s,fieldarr[i]));
    }
    
    return snew;
}
