define refractive_index_air() {
%!%+
%\function{refractive_index_air}
%\synopsis{calculate the refractive index of dry and moist air}
%\usage{Double_Type refractive_index_air(lambda;qualifiers)}
%\qualifiers{
%    \qualifier{mum}{wavelength is in microns}
%    \qualifier{nm}{wavelength is in nanometers}
%    \qualifier{temperature}{temperature [K; default: 288.15K]}
%    \qualifier{centigrade}{temperature is given in C}
%    \qualifier{pressure}{ambient total pressure (Pa, default: 1013.25kPa)}
%    \qualifier{kPa}{all pressure arguments are in kPa}
%    \qualifier{hPa}{all pressure arguments are in hPa (or mbar)}
%    \qualifier{CO2_ppm}{CO2 fraction in ppm (default: 450)}
%    \qualifier{water_pressure}{partial water vapor pressure}
%    \qualifier{rel_humidity}{relative humidity}
%    \qualifier{silent}{do not emit warning messages}
%}
%\description
% This function calculates the phase refractive index of dry and moist air
% for light in the optical and IR following the standard paper by
% Ciddor (1996, Appl. Optics 35(9), 1566) and the discussion by Stone
% and Zimmerman (NIST Engineering Metrology Toolbox;
% http://emtoolbox.nist.gov/Wavelength/Documentation.asp) for a given
% wavelength (default A, but see the mum and nm qualifiers) and ambient
% conditions (temperature, pressure,  humidity or partial vapor pressure,
% and CO2 concentration). The function has been verified against the values 
% given by Ciddor and in the NIST Engineering Metrology Toolbox.
%
% The relative uncertainty of the approximations used here is claimed to be 
% around 2e-8. The range of validity is 3000 A<lambda<17000 A, temperatures
% between -40C and 100C (233-373K), and pressures between 10 and 140kPa.
% The CO2 fraction is allowed to vary between 0 and 2000ppm.
%
% This routine is array safe. If lambda is an array, the other qualifiers
% can be either arrays of the same length as lambda or single valued.
%
%!%-;
    variable lambda=(); % default: A

    if (qualifier_exists("mum") and qualifier_exists("nm")) {
	throw RunTimeError,sprintf("%s: only one of nm and mum qualifiers is allowed!",_function_name());
    }

    if (qualifier_exists("kPa") and qualifier_exists("hPa")) {
	throw RunTimeError,sprintf("%s: only one of kPa and hPa qualifiers is allowed!",_function_name());
    }

    if (qualifier_exists("mum")) {
	lambda*=10000.; % mum -> A
    }

    if (qualifier_exists("nm")) {
	lambda*=10.; % nm -> A
    }

    variable chatty=(qualifier_exists("silent")==1);
    
    if (chatty && length(lambda)!=length(where(3000<=lambda<=17000))) {
	()=printf("%s: WARNING: Wavelength outside of validity interval 3000-17000A\n",_function_name());
    }


    % convert lambda to mum
    lambda=lambda/10000.;
    
    variable T; % temperature in K (default: 15c [standard atmosphere]
    if (qualifier_exists("centigrade")) {
	T=qualifier("temperature",15.)+273.15;
    } else {
	T=qualifier("temperature",288.15);
    }

    if (chatty && length(T) !=length(where(233.15<=T<=373.15))) {
	()=printf("%s: WARNING: Temperature outside of validity interval 233-373K (-40-100C)\n",_function_name());
    }
 
    % pressure in P
    variable P;
    if (qualifier_exists("kPa")) {
	P=1000.*qualifier("pressure",101.325); % kPa -> Pa
    } else {
	if (qualifier_exists("hPa")) { % =mbar
	    P=100.*qualifier("pressure",1013.25); % hPa -> Pa
	} else {
	    P=qualifier("pressure",101325.); % default: Pa
	}
    }


    if (chatty && length(P)!=length(where(10e3<=P<=140e3))) {
	()=printf("%s: WARNING: Pressure outside of validity interval 10-140kPa\n",_function_name());
    }

    % CO2 content (ppm)
    variable xc=qualifier("CO2_ppm",450.);
    if (chatty && length(xc) != length(where(0.<=xc<=2000.))) {
	()=printf("%s: WARNING: CO2 fraction outside of validity interval 0-2000ppm\n",_function_name());
    }
    
    if (qualifier_exists("water_pressure") and qualifier_exists("rel_humidity")) {
	throw RunTimeError,sprintf("%s: only one of water_pressure and rel_humidity qualifiers is allowed!",_function_name());
    }

    
    % mole fraction of water vapor
    variable xw=0.;
    if (qualifier_exists("water_pressure") or qualifier_exists("rel_humidity")) {
	% enhancement factor of water vapor in air
	variable alpha=1.00062;
	variable beta=3.14e-8; % Pa^-1
	variable gamma=5.60e-7; % C^-2

	variable f=alpha+beta*P+gamma*(T-273.15)^2.;
	
	if (qualifier_exists("water_pressure")) {
	    %
	    % calculation for a given water partial pressure
	    %
	    variable Pv=qualifier("water_pressure");
	    if (qualifier_exists("kPa")) {
		Pv*=1000.; % kPa -> Pa
	    }
	    if (qualifier_exists("hPa")) {
		Pv*=100.; % hPa -> Pa
	    }
	    xw=f*Pv/P; % mole fraction
	    
	} else {
	    %
	    % relative humidity known
	    %
	    variable Rh=qualifier("rel_humidity",0.);
	    if (length(Rh)!=length(where(0<=Rh<=1.))) {
		throw RunTimeError, sprintf("%s: relative humidity is out of bounds\n",_function_name());
	    }

	    % saturation vapor pressure of water vapor in air
	    variable svp=SaturationVaporPressure(T;iapws);

	    % mole fraction 
	    xw=Rh*f*svp/P;
	}
    }

    %
    % from here on: T in K, lambda in mum, P in Pa
    %
    
    % wavenumber squared
    variable s2=1./(lambda*lambda);
    
    %
    % constants for standard phase and group refractivities
    % (Ciddor, Appendix A)
    %
    
    % dry air (mum^-2)
    variable k=[238.0185, 5792105., 57.362, 167917.];

    % water vapor (mum^-2)
    variable w=[295.235, 2.6422, -0.032380, 0.004028];

    % compressibility
    variable a=[1.58123e-6, -2.9331e-8, 1.1043e-10];
    variable b=[5.707e-6, -2.051e-8];
    variable c=[1.9898e-4, -2.376e-6];
    variable d=1.83e-11;
    variable e=-0.765e-8;


    % Gas constant
    variable R=8.314472; % J/mol/K

    variable Mv=0.018015; % 

    %
    % refractive index for standard air
    % (15C, 1013.25 hPa, 0% humidity)
    %
    variable Pr1=101325.; % Pa
    variable Tr1=288.15; % K
    
    % n_as-1 : dry standard air, 450ppm CO2
    variable nas=1e-8*(k[1]/(k[0]-s2) + k[3]/(k[2]-s2));

    variable nvs1=1.022e-8*(((w[3]*s2+w[2])*s2+w[1])*s2+w[0]);
    
    % molar mass of dry air
    variable Ma=0.0289635+1.2011e-8*(xc-400.);

    % n_axs-1: dry standard air, != 450ppm CO2
    variable naxs1=nas*(1.+5.34e-7*(xc-450.));
    
    % Celsius temperature
    variable TT=T-273.15;

    % Compressibility of dry air
    % (this is the equation for Zm below evaluated with
    % T=288.15, P=101325, xw=0)
    variable Za=0.9995922115;
    
    % Ciddor, eq 12 - compressibility of moist air
    variable Zm=1.-(P/T)*(a[0]+a[1]*TT+a[2]*TT^2.+(b[0]+b[1]*TT)*xw+
               (c[0]+c[1]*TT)*xw^2)+(P/T)^2.*(d+e*xw^2);

    variable rho_vs=0.00985938;
    % density of dry air at 15C, 131325 Pa w/xw=0
    variable rho_axs=Pr1*Ma/(Za*R*Tr1);
    % density of the vapor component
    variable rho_v=xw*P*Mv/(Zm*R*T);
    % density of the dry componnt
    variable rho_a=(1.-xw)*P*Ma/(Zm*R*T);

    % index of refraction
    variable n=1.+(rho_a/rho_axs)*naxs1+(rho_v/rho_vs)*nvs1;

    return n;
}
