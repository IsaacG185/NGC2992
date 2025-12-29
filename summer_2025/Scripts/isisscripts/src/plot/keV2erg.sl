define keV2erg(value)
%!%+
%\function{keV2erg}
%\synopsis{convert flux to erg}
%\usage{Double_Type new_value = kev2erg(Double_Type old_value)}
%\qualifiers{
% \qualifier{y_fac}{: divide the value by 10^{y_fac} }
%}
%\seealso{plot_unfold}
%!%- 
{
   variable y_fac = qualifier("y_fac",0);

   variable fac0 = 1./624150647.996;

   return value*fac0/(10^y_fac);
}