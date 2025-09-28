%%%%%%%%%%%%%%%%%
define ionabs_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%%
%!%+
%\function{ionabs (fit-function)}
%\synopsis{multiplicative fit-function for ionized photoabsorption}
%\description
%    Currently, the cross section is only evaluated at the center of each bin!
%
%    The first fit parameter, \code{ionabs.N_H}, is a dummy parameter,
%    which is not taken into account for the model. One can, however, use it
%    to relate the ionized column densities to an equivalent hydrogen column density.
%\seealso{ionized_phabs_sigma}
%!%-
{
  %
  % USE A FINER GRID
  %
  variable energy = _A(1) / ((bin_lo+bin_hi)/2);
  variable tau = Double_Type[length(energy)];
  variable i=1, Z, nEl;
  for(Z=1, nEl=1; Z<=28; i++)
  {
    if(par[i]!=0)
      tau += ionized_phabs_sigma(energy; Z=Z, Nel=nEl) * par[i];
    if(nEl>1) nEl--; else { Z++; nEl = Z; }
  }
  return exp(-tau);
}
% a = ["\"N_H[cm^-2 (dummy)]\""]; for(Z=1,nEl=1; Z<=28; nEl--) { a = [a, sprintf("\"N_%s%d[cm^-2]\"", atom_name(Z), 1+Z-nEl)]; if(nEl==1) { Z++; nEl=Z+1; } }; strjoin_wrap(a, ","; maxlen=128, initial="add_slang_function(\"ionabs\", [", final="]);");
add_slang_function("ionabs", ["N_H[cm^-2 (dummy)]","N_H1[cm^-2]","N_He1[cm^-2]","N_He2[cm^-2]","N_Li1[cm^-2]","N_Li2[cm^-2]",
 "N_Li3[cm^-2]","N_Be1[cm^-2]","N_Be2[cm^-2]","N_Be3[cm^-2]","N_Be4[cm^-2]","N_B1[cm^-2]","N_B2[cm^-2]","N_B3[cm^-2]",
 "N_B4[cm^-2]","N_B5[cm^-2]","N_C1[cm^-2]","N_C2[cm^-2]","N_C3[cm^-2]","N_C4[cm^-2]","N_C5[cm^-2]","N_C6[cm^-2]","N_N1[cm^-2]",
 "N_N2[cm^-2]","N_N3[cm^-2]","N_N4[cm^-2]","N_N5[cm^-2]","N_N6[cm^-2]","N_N7[cm^-2]","N_O1[cm^-2]","N_O2[cm^-2]","N_O3[cm^-2]",
 "N_O4[cm^-2]","N_O5[cm^-2]","N_O6[cm^-2]","N_O7[cm^-2]","N_O8[cm^-2]","N_F1[cm^-2]","N_F2[cm^-2]","N_F3[cm^-2]","N_F4[cm^-2]",
 "N_F5[cm^-2]","N_F6[cm^-2]","N_F7[cm^-2]","N_F8[cm^-2]","N_F9[cm^-2]","N_Ne1[cm^-2]","N_Ne2[cm^-2]","N_Ne3[cm^-2]",
 "N_Ne4[cm^-2]","N_Ne5[cm^-2]","N_Ne6[cm^-2]","N_Ne7[cm^-2]","N_Ne8[cm^-2]","N_Ne9[cm^-2]","N_Ne10[cm^-2]","N_Na1[cm^-2]",
 "N_Na2[cm^-2]","N_Na3[cm^-2]","N_Na4[cm^-2]","N_Na5[cm^-2]","N_Na6[cm^-2]","N_Na7[cm^-2]","N_Na8[cm^-2]","N_Na9[cm^-2]",
 "N_Na10[cm^-2]","N_Na11[cm^-2]","N_Mg1[cm^-2]","N_Mg2[cm^-2]","N_Mg3[cm^-2]","N_Mg4[cm^-2]","N_Mg5[cm^-2]","N_Mg6[cm^-2]",
 "N_Mg7[cm^-2]","N_Mg8[cm^-2]","N_Mg9[cm^-2]","N_Mg10[cm^-2]","N_Mg11[cm^-2]","N_Mg12[cm^-2]","N_Al1[cm^-2]","N_Al2[cm^-2]",
 "N_Al3[cm^-2]","N_Al4[cm^-2]","N_Al5[cm^-2]","N_Al6[cm^-2]","N_Al7[cm^-2]","N_Al8[cm^-2]","N_Al9[cm^-2]","N_Al10[cm^-2]",
 "N_Al11[cm^-2]","N_Al12[cm^-2]","N_Al13[cm^-2]","N_Si1[cm^-2]","N_Si2[cm^-2]","N_Si3[cm^-2]","N_Si4[cm^-2]","N_Si5[cm^-2]",
 "N_Si6[cm^-2]","N_Si7[cm^-2]","N_Si8[cm^-2]","N_Si9[cm^-2]","N_Si10[cm^-2]","N_Si11[cm^-2]","N_Si12[cm^-2]","N_Si13[cm^-2]",
 "N_Si14[cm^-2]","N_P1[cm^-2]","N_P2[cm^-2]","N_P3[cm^-2]","N_P4[cm^-2]","N_P5[cm^-2]","N_P6[cm^-2]","N_P7[cm^-2]",
 "N_P8[cm^-2]","N_P9[cm^-2]","N_P10[cm^-2]","N_P11[cm^-2]","N_P12[cm^-2]","N_P13[cm^-2]","N_P14[cm^-2]","N_P15[cm^-2]",
 "N_S1[cm^-2]","N_S2[cm^-2]","N_S3[cm^-2]","N_S4[cm^-2]","N_S5[cm^-2]","N_S6[cm^-2]","N_S7[cm^-2]","N_S8[cm^-2]","N_S9[cm^-2]",
 "N_S10[cm^-2]","N_S11[cm^-2]","N_S12[cm^-2]","N_S13[cm^-2]","N_S14[cm^-2]","N_S15[cm^-2]","N_S16[cm^-2]","N_Cl1[cm^-2]",
 "N_Cl2[cm^-2]","N_Cl3[cm^-2]","N_Cl4[cm^-2]","N_Cl5[cm^-2]","N_Cl6[cm^-2]","N_Cl7[cm^-2]","N_Cl8[cm^-2]","N_Cl9[cm^-2]",
 "N_Cl10[cm^-2]","N_Cl11[cm^-2]","N_Cl12[cm^-2]","N_Cl13[cm^-2]","N_Cl14[cm^-2]","N_Cl15[cm^-2]","N_Cl16[cm^-2]",
 "N_Cl17[cm^-2]","N_Ar1[cm^-2]","N_Ar2[cm^-2]","N_Ar3[cm^-2]","N_Ar4[cm^-2]","N_Ar5[cm^-2]","N_Ar6[cm^-2]","N_Ar7[cm^-2]",
 "N_Ar8[cm^-2]","N_Ar9[cm^-2]","N_Ar10[cm^-2]","N_Ar11[cm^-2]","N_Ar12[cm^-2]","N_Ar13[cm^-2]","N_Ar14[cm^-2]","N_Ar15[cm^-2]",
 "N_Ar16[cm^-2]","N_Ar17[cm^-2]","N_Ar18[cm^-2]","N_K1[cm^-2]","N_K2[cm^-2]","N_K3[cm^-2]","N_K4[cm^-2]","N_K5[cm^-2]",
 "N_K6[cm^-2]","N_K7[cm^-2]","N_K8[cm^-2]","N_K9[cm^-2]","N_K10[cm^-2]","N_K11[cm^-2]","N_K12[cm^-2]","N_K13[cm^-2]",
 "N_K14[cm^-2]","N_K15[cm^-2]","N_K16[cm^-2]","N_K17[cm^-2]","N_K18[cm^-2]","N_K19[cm^-2]","N_Ca1[cm^-2]","N_Ca2[cm^-2]",
 "N_Ca3[cm^-2]","N_Ca4[cm^-2]","N_Ca5[cm^-2]","N_Ca6[cm^-2]","N_Ca7[cm^-2]","N_Ca8[cm^-2]","N_Ca9[cm^-2]","N_Ca10[cm^-2]",
 "N_Ca11[cm^-2]","N_Ca12[cm^-2]","N_Ca13[cm^-2]","N_Ca14[cm^-2]","N_Ca15[cm^-2]","N_Ca16[cm^-2]","N_Ca17[cm^-2]",
 "N_Ca18[cm^-2]","N_Ca19[cm^-2]","N_Ca20[cm^-2]","N_Sc1[cm^-2]","N_Sc2[cm^-2]","N_Sc3[cm^-2]","N_Sc4[cm^-2]","N_Sc5[cm^-2]",
 "N_Sc6[cm^-2]","N_Sc7[cm^-2]","N_Sc8[cm^-2]","N_Sc9[cm^-2]","N_Sc10[cm^-2]","N_Sc11[cm^-2]","N_Sc12[cm^-2]","N_Sc13[cm^-2]",
 "N_Sc14[cm^-2]","N_Sc15[cm^-2]","N_Sc16[cm^-2]","N_Sc17[cm^-2]","N_Sc18[cm^-2]","N_Sc19[cm^-2]","N_Sc20[cm^-2]",
 "N_Sc21[cm^-2]","N_Ti1[cm^-2]","N_Ti2[cm^-2]","N_Ti3[cm^-2]","N_Ti4[cm^-2]","N_Ti5[cm^-2]","N_Ti6[cm^-2]","N_Ti7[cm^-2]",
 "N_Ti8[cm^-2]","N_Ti9[cm^-2]","N_Ti10[cm^-2]","N_Ti11[cm^-2]","N_Ti12[cm^-2]","N_Ti13[cm^-2]","N_Ti14[cm^-2]","N_Ti15[cm^-2]",
 "N_Ti16[cm^-2]","N_Ti17[cm^-2]","N_Ti18[cm^-2]","N_Ti19[cm^-2]","N_Ti20[cm^-2]","N_Ti21[cm^-2]","N_Ti22[cm^-2]","N_V1[cm^-2]",
 "N_V2[cm^-2]","N_V3[cm^-2]","N_V4[cm^-2]","N_V5[cm^-2]","N_V6[cm^-2]","N_V7[cm^-2]","N_V8[cm^-2]","N_V9[cm^-2]","N_V10[cm^-2]",
 "N_V11[cm^-2]","N_V12[cm^-2]","N_V13[cm^-2]","N_V14[cm^-2]","N_V15[cm^-2]","N_V16[cm^-2]","N_V17[cm^-2]","N_V18[cm^-2]",
 "N_V19[cm^-2]","N_V20[cm^-2]","N_V21[cm^-2]","N_V22[cm^-2]","N_V23[cm^-2]","N_Cr1[cm^-2]","N_Cr2[cm^-2]","N_Cr3[cm^-2]",
 "N_Cr4[cm^-2]","N_Cr5[cm^-2]","N_Cr6[cm^-2]","N_Cr7[cm^-2]","N_Cr8[cm^-2]","N_Cr9[cm^-2]","N_Cr10[cm^-2]","N_Cr11[cm^-2]",
 "N_Cr12[cm^-2]","N_Cr13[cm^-2]","N_Cr14[cm^-2]","N_Cr15[cm^-2]","N_Cr16[cm^-2]","N_Cr17[cm^-2]","N_Cr18[cm^-2]",
 "N_Cr19[cm^-2]","N_Cr20[cm^-2]","N_Cr21[cm^-2]","N_Cr22[cm^-2]","N_Cr23[cm^-2]","N_Cr24[cm^-2]","N_Mn1[cm^-2]","N_Mn2[cm^-2]",
 "N_Mn3[cm^-2]","N_Mn4[cm^-2]","N_Mn5[cm^-2]","N_Mn6[cm^-2]","N_Mn7[cm^-2]","N_Mn8[cm^-2]","N_Mn9[cm^-2]","N_Mn10[cm^-2]",
 "N_Mn11[cm^-2]","N_Mn12[cm^-2]","N_Mn13[cm^-2]","N_Mn14[cm^-2]","N_Mn15[cm^-2]","N_Mn16[cm^-2]","N_Mn17[cm^-2]",
 "N_Mn18[cm^-2]","N_Mn19[cm^-2]","N_Mn20[cm^-2]","N_Mn21[cm^-2]","N_Mn22[cm^-2]","N_Mn23[cm^-2]","N_Mn24[cm^-2]",
 "N_Mn25[cm^-2]","N_Fe1[cm^-2]","N_Fe2[cm^-2]","N_Fe3[cm^-2]","N_Fe4[cm^-2]","N_Fe5[cm^-2]","N_Fe6[cm^-2]","N_Fe7[cm^-2]",
 "N_Fe8[cm^-2]","N_Fe9[cm^-2]","N_Fe10[cm^-2]","N_Fe11[cm^-2]","N_Fe12[cm^-2]","N_Fe13[cm^-2]","N_Fe14[cm^-2]","N_Fe15[cm^-2]",
 "N_Fe16[cm^-2]","N_Fe17[cm^-2]","N_Fe18[cm^-2]","N_Fe19[cm^-2]","N_Fe20[cm^-2]","N_Fe21[cm^-2]","N_Fe22[cm^-2]",
 "N_Fe23[cm^-2]","N_Fe24[cm^-2]","N_Fe25[cm^-2]","N_Fe26[cm^-2]","N_Co1[cm^-2]","N_Co2[cm^-2]","N_Co3[cm^-2]","N_Co4[cm^-2]",
 "N_Co5[cm^-2]","N_Co6[cm^-2]","N_Co7[cm^-2]","N_Co8[cm^-2]","N_Co9[cm^-2]","N_Co10[cm^-2]","N_Co11[cm^-2]","N_Co12[cm^-2]",
 "N_Co13[cm^-2]","N_Co14[cm^-2]","N_Co15[cm^-2]","N_Co16[cm^-2]","N_Co17[cm^-2]","N_Co18[cm^-2]","N_Co19[cm^-2]",
 "N_Co20[cm^-2]","N_Co21[cm^-2]","N_Co22[cm^-2]","N_Co23[cm^-2]","N_Co24[cm^-2]","N_Co25[cm^-2]","N_Co26[cm^-2]",
 "N_Co27[cm^-2]","N_Ni1[cm^-2]","N_Ni2[cm^-2]","N_Ni3[cm^-2]","N_Ni4[cm^-2]","N_Ni5[cm^-2]","N_Ni6[cm^-2]","N_Ni7[cm^-2]",
 "N_Ni8[cm^-2]","N_Ni9[cm^-2]","N_Ni10[cm^-2]","N_Ni11[cm^-2]","N_Ni12[cm^-2]","N_Ni13[cm^-2]","N_Ni14[cm^-2]","N_Ni15[cm^-2]",
 "N_Ni16[cm^-2]","N_Ni17[cm^-2]","N_Ni18[cm^-2]","N_Ni19[cm^-2]","N_Ni20[cm^-2]","N_Ni21[cm^-2]","N_Ni22[cm^-2]",
 "N_Ni23[cm^-2]","N_Ni24[cm^-2]","N_Ni25[cm^-2]","N_Ni26[cm^-2]","N_Ni27[cm^-2]","N_Ni28[cm^-2]"]);

%%%%%%%%%%%%%%%%%%%%%
define ionabs_default(i)
%%%%%%%%%%%%%%%%%%%%%
{
  return (0, 1, 0, 1e24);
}
set_param_default_hook("ionabs", &ionabs_default);
