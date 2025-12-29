define erg2keV(value)
%!%+
%\function{erg2keV}
%\synopsis{converts energy from erg to keV}
%\usage{Double_Type new_value = erg2keV(Double_Type old_value)}
%\qualifiers{
%\qualifier{y_fac}{: divide the value by 10^{y_fac} }
%}
%\seealso{plot_unfold}
%!%- 
{
   variable y_fac = qualifier("y_fac",0);

   variable fac0 = 624150647.996;

   return value*fac0/(10^y_fac);
}
