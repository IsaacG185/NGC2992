%%%%%%%%%%%%%%%%%%%%%%
define e_bv()
%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{e_bv}
%\synopsis{Calculates the E(B_V) color excess after Predehl & Schmitt (1995)}
%\usage{Double_Type = e_bv(Double_Type N_H);}
%\qualifiers{
%    \qualifier{R_V}{Scalar specifying the ratio of total to selective extinction
%               R(V) = A(V) / E(B - V). If not specified, then R = 3.1
%               Extreme values of R(V) range from 2.3 to 5.3}
%}
%\description
%     From a given hydrogen absorption column density N_H in the diredtory
%     of the object, the color excess E(B-V) is calculated after
%     Predehl & Schmitt (1995): E(B-V) = N_H/(1.79e21*R_V).
%
% EXAMPLE
%     Calculate the color excess for Cen A (RA 13h25m27.6s DEC -43d01m09s) for
%     N_H = 8.09e20 and an "average" reddening of for the diffuse interstellar
%     medium (R(V) = 3.1).
%
%     isis> N_H = 8.09e20;
%     isis> ebv = e_bv(N_H);
%     isis> print(ebv);
%
%\seealso{fm_unred;}         
%!%-
{
   variable N_H;
   switch(_NARGS)
     { case 1: (N_H) = (); }
     { help(_function_name()); return; }

   variable R_V = qualifier("R_V", 3.1);
	
   variable ebv = N_H/(1.79e21*R_V);

   return ebv;
} %}}}
