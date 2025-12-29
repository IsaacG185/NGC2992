require("gsl","gsl");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define fm_unred()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{fm_unred}
%\synopsis{Deredden a flux vector using the Fitzpatrick (1999) parameterization}
%\usage{Double_Type = fm_unred(Double_Type[] wave, Double_Type[] flux, Double_Type ebv);}
%\qualifiers{
%    \qualifier{N_H}{Hydrogen absorption column}
%    \qualifier{R_V}{Scalar specifying the ratio of total to selective extinction
%               R(V) = A(V) / E(B - V). If not specified, then R = 3.1
%               Extreme values of R(V) range from 2.3 to 5.3}
%    \qualifier{LMC2}{If set, then the fit parameters are set to the values determined
%               for the LMC2 field (including 30 Dor) by Misselt et al.
%               Note that neither 'AVGLMC' or 'LMC2' will alter the default
%               value of 'R_V' which is poorly known for the LMC.}
%    \qualifier{AVGLMC}{If set, then the default fit parameters c1,c2,c3,c4,gamma,x0
%               are set to the average values determined for reddening in the
%               general Large Magellanic Cloud (LMC) field by Misselt et al.
%               (1999, ApJ, 515, 128)}
%    \qualifier{extcurve}{If set to a variable as Ref_Type, the E(wave-V)/E(B-V)
%               extinction curve is returned, interpolated onto the input
%               wavelength vector}
%    \qualifier{gamma}{Width of 2200 A bump in microns (default = 0.99)}
%    \qualifier{x0}{Centroid of 2200 A bump in microns (default = 4.596)}
%    \qualifier{c1}{Intercept of the linear UV extinction component
%               (default = 2.030 - 3.007 * c2)}
%    \qualifier{c2}{Slope of the linear UV extinction component
%               (default = -0.824 + 4.717 / R_V)}
%    \qualifier{c3}{Strength of the 2200 A bump (default = 3.23)}
%    \qualifier{c4}{FUV curvature (default = 0.41)}
%    \qualifier{wilm}{If N_H value has been determined using wilm abundances and Verner 
%               cross-sections use this updated correlation (Nowak et al., 2012)}
%    \qualifier{ngc3227}{Use the reddening curve for NGC3227 after Crenshaw, D.~M.,
%               Kraemer, S.~B., Bruhweiler, F.~C., & Ruiz, J.~R. 2001, ApJ, 555, 633
%               provided locally in /home/beuchert/work/ngc3227/scripts/reddening/}
%
%}
%\description
%     The unreddened flux vector of the input 'flux' is calculated on the
%     wavelength vector 'wave' using the Fitzpatrick (1999) parameterization.
%     The scalar 'ebv' is the color excess E(B-V). If a negative EBV is supplied,
%     then fluxes will be reddened rather than dereddened. If the scalar is not
%     known the hydrogen absorption column in the directory of the object must be
%     given as a qualifier and E(B-V) is calculated by
%       E(B-V) = N_H/(1.79e21*R_V).
%     
%     The R-dependent Galactic extinction curve is that of Fitzpatrick & Massa 
%     (Fitzpatrick, 1999, PASP, 111, 63; astro-ph/9809387 ).    
%     Parameterization is valid from the IR to the far-UV (3.5 microns to 0.1 
%     microns). UV extinction curve is extrapolated down to 912 Angstroms.
%     This Function is adopted from the IDL-Function fm_unred.
%         
%     The five input qualifiers 'gamma', 'x0', 'c1', 'c2', 'c3' and 'c4' allow the
%     user to customize the adopted extinction curve. For example, see Clayton et al.
%     (2003, ApJ, 588, 871) for examples of these parameters in different interstellar
%     environments.           
%
% EXAMPLE
%     Determine how a flat spectrum (in wavelength) between 1200 A and 6500 A
%     is altered by a reddening of E(B-V) = 0.5. Assume an "average"
%     reddening for the diffuse interstellar medium (R(V) = 3.1)
%
%     isis> wave = [1200:6500:#500];                               %Create a wavelength vector from 1200 to 6500 Angstrom with 500 steps between
%     isis> flux = 1.*ones(500);                                   %Create a "flat" flux vector
%     isis> ebv = 0.5;                                             %Value for E(B-V)
%     isis> variable var;                                          %Referenz for extcurve 
%     isis> funred = fm_unred(wave, flux, ebv; extcurve=&var);     %Redden flux vector
%     isis> plot(wave,var);                                        %Plots the extinctioncurve versus the wavelength
%
%\seealso{e_bv;}
%!%-
{
 variable wave, flux, ebv = NULL;
 switch (_NARGS)
     { case 2: (wave, flux)      = (); }
     { case 3: (wave, flux, ebv) = (); }
     { help(_function_name()); return; }
	 
 variable R_V = qualifier("R_V", 3.1);
 variable N_H = qualifier("N_H", 1.e20);
 variable LMC2 = qualifier("LMC2");
 variable AVGLMC = qualifier("AVGLMC");
 variable x0 = qualifier("x0");
 variable gamma = qualifier("gamma");
 variable c1 = qualifier("c1");
 variable c2 = qualifier("c2");
 variable c3 = qualifier("c3");
 variable c4 = qualifier("c4");
 variable wilm = qualifier("wilm");
 variable ngc3227 = qualifier("ngc3227");

  
 variable x = 10000./ wave;                % Convert to inverse microns 
 variable curve = x*0.;

% Set default values of c1,c2,c3,c4,gamma and x0 parameters

 if (qualifier_exists("LMC2"))   
     {
	 ifnot (qualifier_exists("x0"))  {x0    =  4.626;};
         ifnot (qualifier_exists("gamma"))  {gamma =  1.05;};	
         ifnot (qualifier_exists("c4"))  {c4   =  0.42;};
         ifnot (qualifier_exists("c3"))  {c3    =  1.92;};	
         ifnot (qualifier_exists("c2"))  {c2    = 1.31;};
         ifnot (qualifier_exists("c1"))  {c1    =  -2.16;};
     }
 else if (qualifier_exists("AVGLMC")) 
     {
	 ifnot (qualifier_exists("x0"))  {x0 = 4.596;};
         ifnot (qualifier_exists("gamma"))  {gamma = 0.91;};
         ifnot (qualifier_exists("c4"))  {c4   =  0.64;};
         ifnot (qualifier_exists("c3"))  {c3    =  2.73;};
         ifnot (qualifier_exists("c2"))  {c2    = 1.11;};
         ifnot (qualifier_exists("c1"))  {c1    =  -1.28;};
     }
   
 else 
     {
	 ifnot (qualifier_exists("x0"))  {x0    =  4.596;};
         ifnot (qualifier_exists("gamma"))  {gamma =  0.99;};
         ifnot (qualifier_exists("c3"))  {c3    =  3.23;};
         ifnot (qualifier_exists("c4"))  {c4   =  0.41;};
         ifnot (qualifier_exists("c2"))  {c2    = -0.824 + 4.717/R_V;};
         ifnot (qualifier_exists("c1"))  {c1    =  2.030 - 3.007*c2;};
     }
   
 if (ebv == NULL)
 {
   if (qualifier_exists("N_H")) 
     { 
	 if (qualifier_exists("wilm")){
	     ebv = N_H/(2.69e21*R_V);
	 }
	 else {
	     ebv = N_H/(1.79e21*R_V);
	 }
     }
     else 
     {
	 message("Either 'ebv' or 'N_H' must be given!"); 
	 return; 
     }	  
     
 }

% Compute UV portion of A(lambda)/E(B-V) curve using FM fitting function and 
% R-dependent coefficients
 
 variable xcutuv = 10000.0/2700.0;
 variable xspluv = 10000.0/[2700.0,2600.0];
 variable iopir;
 variable iuv = where(x >= xcutuv, &iopir);
 variable N_UV = length(iuv);
 variable Nopir = length(iopir);
 if (length(N_UV) > 0)  {variable xuv = [xspluv,x[iuv]];}
   else  {xuv = xspluv;}

 variable yuv = c1  + c2*xuv;
    yuv += c3*xuv^2./((xuv^2.-x0^2.)^2. +(xuv*gamma)^2.);
    yuv += c4*(0.5392*((xuv-5.9)*(xuv>5.9))^2.+0.05644*((xuv-5.9)*(xuv>5.9))^3.);
    yuv += R_V;
  variable yspluv = yuv[[0:1]];                  % save spline points

 if (length(N_UV) > 0)  { curve[iuv] = yuv[[2:length(yuv)-1]];}      % remove spline points
 
% Compute optical portion of A(lambda)/E(B-V) curve
% using cubic_spline anchored in UV, optical, and IR

#ifexists gsl->interp_cspline
 variable xsplopir = [0.0,10000.0/[26500.0,12200.0,6000.0,5470.0,4670.0,4110.0]];
 variable ysplir   = [0.0,0.26469,0.82925]*R_V/3.1 ;
 variable ysplop   = [polynom([-4.22809e-01, 1.00270, 2.13572e-04], R_V ),
		      polynom([-5.13540e-02, 1.00216, -7.35778e-05], R_V ),
		      polynom([ 7.00127e-01, 1.00184, -3.32598e-05], R_V ),
		      polynom([ 1.19456, 1.01707, -5.46959e-03, 7.97809e-04,-4.45636e-05], R_V ) ];
  
 variable ysplopir = [ysplir,ysplop];

 if (Nopir > 0)  {
          curve[iopir] = gsl->interp_cspline(x[iopir],[xsplopir,xspluv],[ysplopir,yspluv]);
 }
#endif

  variable curve_cpy = @curve;
  
 % special case: reddening curve for NGC3227 after Crenshaw, D.~M.,
 % Kraemer, S.~B., Bruhweiler, F.~C., & Ruiz, J.~R. 2001, ApJ, 555, 633

  variable fname = "/home/beuchert/work/ngc3227/scripts/reddening/f3_1_edit_curve.dat";
  if (qualifier_exists("ngc3227") && (stat_file(fname)!=NULL)) {
    variable x_ngc3227,y_ngc3227;
    (x_ngc3227,y_ngc3227)=readcol(fname,1,2);
    variable unity_array = wave*0.+1.;
    variable id = where(x_ngc3227[0] < wave < x_ngc3227[-1]);
    curve = [unity_array[where(wave<x_ngc3227[0])],interpol(wave[id],x_ngc3227,y_ngc3227),curve_cpy[where(wave>x_ngc3227[-1])]];
  }

 % Now apply extinction correction to input flux vector

 curve *= ebv; % = A_lambda, before: curve == A_lambda / E(B-V)
   
 variable funred = flux * 10.^(0.4*curve);
    	   
%       variable funred = flux * 10.^(0.4*curve);       %Derive unreddened flux
 variable extcurve = qualifier("extcurve", NULL);
 ifnot (typeof(extcurve) == Ref_Type || typeof(extcurve) == Null_Type) { message("'extcurve' must be a reference!"); return; }
 else if (typeof(extcurve) == Ref_Type) @extcurve = 1.*curve/ebv - R_V; % == E(lambda-V)/E(B-V)

 return funred; 
}  %}}}
