define atom_name()
%!%+
%\function{atom_name}
%\synopsis{DEPRECATED}
%\usage{String_Type atom_name(Integer_Type Z)}
%\description
% This function returns the symbol for atoms with proton number Z.
% This function is DEPRECATED, please use element_symbol.
%\seealso{element_symbol}
%!%-
{
    return element_symbol(();;__qualifiers);
}
