define solarAbund()
%!%+
%\function{solarAbund}
%\synopsis{returns the solar abundance of an element}
%\usage{Double_Type solarAbund(Integer_Type Z)}
%\description
%    \code{Z} is the element's proton number.
%\seealso{Grevesse et al., 1996: Standard Abundances}
%!%-
{
  variable Z;
  switch(_NARGS)
  { case 1: Z = (); }
  { help(_function_name()); return; }

  switch(Z)
  { case  1: return 10^(12.00-12); }
  { case  2: return 10^(10.99-12); }
  { case  6: return 10^( 8.55-12); }
  { case  7: return 10^( 7.97-12); }
  { case  8: return 10^( 8.87-12); }
  { case 10: return 10^( 8.08-12); }
  { case 12: return 10^( 7.58-12); }
  { case 13: return 10^( 6.47-12); }
  { case 14: return 10^( 7.55-12); }
  { case 16: return 10^( 7.33-12); }
  { case 18: return 10^( 6.52-12); }
  { case 20: return 10^( 6.36-12); }
  { case 26: return 10^( 7.50-12); }
  "Don't know, please tell me.";
}
