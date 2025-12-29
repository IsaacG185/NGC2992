define SaturationVaporPressure() {
%!%+
%\function{SaturationVaporPressure}
%\synopsis{calculate the saturation vapor pressure of water in air}
%\usage{Double_Type[] SaturationWaterPressure(T;qualifiers)}
%\qualifiers{
%    \qualifier{centigrade}{temperature argument is in centigrade (default: K)}
%    \qualifier{kPa}{Return saturation vapor pressure in kilopascals}
%    \qualifier{hPa}{Return saturation vapor pressure in hectopascals (=mbar)}
%    \qualifier{water}{Calculate saturation vapor pressure over water}
%    \qualifier{ice}{Calculate saturation vapor pressure over ice}
%    \qualifier{iapws}{Use the more precise IAPWS prescription (see below)}
%}
%\description
% This function calculates the saturation vapor pressure (svp) of water over
% ice and water for a given temperature (default: K, but see the
% centigrade qualifier), the routine returns the svp in Pa unless
% the kPa or hPa keywords are given. By default, for T>0C (273.15K)
% the svp over water is returned, for smaller temperatures that for
% ice. Use the "water" and "ice" qualifiers if this is not what you want.
%
% As a default, for the svp over water the equation of
% Davis (1992), Metrologia 29, 67-70 is used, while for ice the
% prescription given by Marti and Mauersberger (1993), Geophys. Res.
% Lett. 20, 363-366 (1993) is applied. For the default settings,
% the relative deviation between these equations and the IAPWS recommended
% procedure is very small. It does not exceed 0.03% in the 0-100C range,
% and is <1.5% in the -50-0C range and less than 2.5% between -100 and -50C,
% while the absolute difference in the range below 50C does not exceed
% 1 Pa.
%
% If the iapws qualifier is given, the routine uses the recommendations
% of the International Association for the Properties of Water and Steam
% (IAPWS), which was originally given by Peter H. Huang, "New equations
% for water vapor pressure in the temperature range -100 deg C to 100 deg C
% for use with the 1997 NIST/ASME steam tables," in: Papers and abstracts
% from the third international symposium on humidity and moisture, Vol. 1,
% p. 69-76, National Physical Laboratory, Teddington, Middlesex, UK,
% April 1998. The algorithm used here is as described by 
% http://emtoolbox.nist.gov/Wavelength/Documentation.asp
% The uncertainty is 20kPa at 100 C, less than 2 kPa at 45 C and
% 0.7 kPa at 20C. 
%
% Note that formally the calculation is only valid in the range from
% -100 to +100 centigrade. The function returns "NaN" for T>100C and
% extrapolates formalism smoothly to lower temperatures (the values
% are very small in this regime anyway).
%
%
% This function is array safe. 
%
%!%-

variable T; % temperature in K

switch(_NARGS)
{ case 1: T=(); }
{ help(_function_name()); return; }

if (qualifier_exists("centigrade")) {
    T+=273.15;
}

if (qualifier_exists("water") && qualifier_exists("ice")) {
    throw RunTimeError,printf("%s: only one of the water and ice qualifiers is allowed!",_function_name());
}

% force array type
variable tarray=0;
if (Array_Type!=typeof(T)) {
    tarray=1;
    T=[T];
}

%
% calculate saturation water pressure over water or over ice
% default if no qualifier is set: over water for T>0C, over ice below that

variable waterndx=Int_Type[0];
variable icendx=Int_Type[0];

if (qualifier_exists("ice")) {
    icendx=[0:length(T)-1:1];
} else {
    if (qualifier_exists("water")) {
	waterndx=[0:length(T)-1:1];
    } else {
	waterndx=where(T>=273.15);
	icendx=where(T<273.15);
    }
}

variable Psv=Double_Type[length(T)];

if (qualifier_exists("iapws")) {
    % IAPWS  formula (see Stone and Zimmerman, NIST www pages and
    % Peter H. Huang, "New equations for water vapor pressure in the
    % temperature range -100 °C to 100 °C for use with the 1997 NIST/ASME
    % steam tables," in Papers and abstracts from the third international
    % symposium on humidity and moisture, Vol. 1, p. 69-76, National Physical
    % Laboratory, Teddington, Middlesex, UK, April 1998.)1
    %
    if (length(waterndx)>0) {
	variable K=[0.,1.16705214528E+03,-7.24213167032E+05,
 	           -1.70738469401E+01, 1.20208247025E+04,-3.23255503223E+06,
	            1.49151086135E+01,-4.82326573616E+03, 4.05113405421E+05,
	           -2.38555575678E-01, 6.50175348448E+02];

	variable omega=T[waterndx]+K[9]/(T[waterndx]-K[10]);
	variable A=(     omega+K[1])*omega+K[2];
	variable B=(K[3]*omega+K[4])*omega+K[5];
	variable C=(K[6]*omega+K[7])*omega+K[8];
	variable X=-B+sqrt(B*B-4.*A*C);
	Psv[waterndx]=1e6*(2.*C/X)^4.;
    }

    if (length(icendx)>0) {
	%
	% saturation over ice
	%
	variable A1=-13.927169;
	variable A2= 34.7078238;
	variable Theta=T[icendx]/273.16;
	variable Y=A1*(1.-Theta^-1.5)+A2*(1.-Theta^-1.25);
	Psv[icendx]=611.657*exp(Y);
    }
} else {
    if (length(waterndx)>0) {
	% equation of Davis, quoted by Ciddor (
	variable AA=1.2378847e-5;
	variable BB=-1.9121316e-2;
	variable CC=33.93711047;
	variable DD=-6.3431645e3;
	Psv[waterndx]=exp(((AA*T[waterndx]+BB)*T[waterndx])+CC+DD/T[waterndx]);
    }
    
    if (length(icendx)>0) {
	% equation of Marti and Mauersberger, quoted by
	% Ciddor (1996; appendix C);
	Psv[icendx]=10.^(-2663.5/T[icendx] + 12.537);
    }
} 

variable ndx=where(T>373.15);
if (length(ndx)>0) {
    Psv[ndx]=_NaN;
}


if (qualifier_exists("kPa")) {
    Psv=Psv/1000.;
}
if (qualifier_exists("hPa")) {
    Psv=Psv/100.;
}

if (tarray==1) {
    return Psv[0];
}
return Psv;
}
