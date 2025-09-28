
private define atmosphere_hohenkerk(h) {

    variable r=qualifier("rrefract");
   
    variable rr=r.Rearth+h;
    
    variable mu;
    variable T,Pw,P;
    
    if (rr<=r.Rtropo) {
	T=r.T0-r.alpha*(rr-r.R0);
	variable trat=(T/r.T0);
	Pw=r.Pw0*trat^r.delta;
	P=(r.P0+r.pfac*r.Pw0)*trat^r.gamma - r.pfac*Pw;
    } else {
	% Troposphere
	T=r.Ttropo;
	Pw=0.;
	P=r.Ptropo*exp(-r.tropscal/T * (rr-r.Rtropo));
    }

    return (T,P,Pw);
}

private define refract_mu(h) {
    variable r=qualifier("rrefract");

    variable T,P,Pw;
    (T,P,Pw)=atmosphere_hohenkerk(h;rrefract=r);

    return refractive_index_air(r.lambda;mum,pressure=P,pressure_water=Pw,temperature=T,hPa);
}

private define refract_integrand(psi)
{
    variable r=qualifier("rrefract");
    
    %
    % for a given angle psi [rad],
    % return the value of the integrand
    % (equation 3 of Auer and Standish)
    
    variable rtry=1.001*r.Rearth;
    variable sinpsi=sin(psi);
    
    %
    % newton raphson to find the correct height
    % We limit this to 8 steps (necessary since sometimes newton
    % raphson goes into oscillations and does not converge;
    % typically convergence happens after 4 steps)
    %
    variable maxnum=10;
    do {
	variable h=rtry-r.Rearth;
	variable mu=refract_mu(h;rrefract=r);

	variable dh=2.; % meter
	variable mu1,dmudr;

	% make sure that we are not crossing the
	% tropospheric boundary when calculating the
	% derivative
	if (rtry < r.Rtropo && rtry+dh > r.Rtropo) {
	    mu1=refract_mu(h-dh;rrefract=r);
	    dmudr=(mu-mu1)/dh;
	} else {
	    mu1=refract_mu(h+dh;rrefract=r);
	    dmudr=(mu1-mu)/dh;
	}
	variable fr=mu*rtry-r.mu0*r.R0*r.sinz0/sinpsi;
	variable dfr=dmudr*rtry+mu;
	variable ddr=fr/dfr;
	
	rtry-=ddr;
	maxnum--;
    } while (abs(ddr)>1e-10 && (maxnum>0));

    
    % d ln(mu(r))/dr = d mu(r)/dr * 1/mu(r)
    % dr / d ln r = r
    % therefore
    % dln(mu(r))/d(ln(r)) = d ln(mu(r))/dr * dr/d(ln r)
    %                     = d mu(r)/dr * r/mu(r)
    % and this then allows us to
    % rewrite the integrand of Auer as
    % r dmu/dr/(mu+r*dmu/dr)
    %
    
    return rtry*dmudr/(mu+rtry*dmudr);
}

define refraction() {
%!%+
%\function{refraction}
%\synopsis{calculate the correction for astronomical refraction}
%\usage{Double_Type refraction(z0;qualifiers)}
%\qualifiers{
%    \qualifier{lambda}{wavelength (in A, between 3000 and 17000 A)}
%    \qualifier{mum}{wavelength is in microns}
%    \qualifier{nm}{wavelength is in nanometers}
%    \qualifier{temperature}{temperature at observer [K; default: 288.15K=15C]}
%    \qualifier{lapse_rate}{temperature lapse rate [K/m; default: 0.0065K/m = 6.5K/km]}
%    \qualifier{centigrade}{temperature is given in C}
%    \qualifier{pressure}{ambient total pressure at observer (Pa, default: 1013.25kPa)}
%    \qualifier{kPa}{ambient pressure is in kPa}
%    \qualifier{hPa}{ambient pressure is in hPa (or mbar)}
%    \qualifier{rel_humidity}{relative humidity at observer (between 0 and 1)}
%    \qualifier{altitude}{altitude of observer above geoid (m; below 11000m)}
%    \qualifier{latitude}{geographical latitude of the observer (rad; default: 0)}
%    \qualifier{deg}{all angles are given in degrees, not radians}
%    \qualifier{exact}{use numerical integration also for z0 below 80deg}
%}
%\description
% For a given zenith distance z and local observing conditions, this function calculates
% the refraction angle, that is the difference R=z-z0 where z is the unrefracted zenith
% distance that would be measured if the Earth did not have an atmosphere, and z0 is the
% observed zenith distance.
%
% The most common use of this function will be to calculate z0 for a given topocentric
% zenith distance. For all practical purposes, R is so small and changes slowly enough,
% such that users can call the function with z and determine z0 from the return value.
% Note that the default arguments are in radians, use the deg qualifier to switch to
% degrees.
%
% The refraction depends very slightly on the atmospheric properties, i.e., its temperature
% profile. These can be set with the respective qualifiers. 
%
% The default settings of the routine are that for zenith distances smaller than 80 degrees
% the approximations given by Saastamoinen (1972, Bull. Geodesique 105, 279 and 1972, Bull.
% Geodesique 106, 383) are used. 
%
% For larger zenith distances, or if the "exact"-qualifier is set, a numerical approach
% is chosen, following the approach discussed by Auer & Standish (2000, AJ 119, 2472
% [first submitted in 1979!]), Hohenkerk and Sinclair (1985, HM Nautical Almanac Office,
% NAO Technical Note 63), and Mangum and Wallace (2015, PASP 127, 74). The function uses
% the atmospheric model discussed by Hohenkerk and Sinclair, but uses the exact refraction
% formula for air. This exact approach yields good results for zenith distances up to a
% few degrees larger than 90 degrees (i.e., observation of the horizon from a mountain
% top) and is the one on which the refraction formulae of the Astronomical Almanac are based.
%
% For large zenith angles, there are slight differences at the arcsecond or less level
% between the results discussed here and the numbers listed by Hohenkerk or Auer. These
% are due to the different treatment of numerical instabilities and the use of numerical
% differentiation formulae. Given that for large zenith angles the simplified atmospheric
% model of Hohenkerk (constant temperature lapse rate in the troposphere, constant temperature
% in the stratosphere) results in larger systematic errors anyway (see Nauenberg, 2017,
% PASP 129, 44503), this should not be seen as an error of the function.
%
% As a caveat, the calculations using the Saastamoinen formulae assume that all pressure
% terms there are in Pa, rather than in mbar. This reproduces the results with respect
% to the numerical simulations and values tabulated elsewhere to <1". But it is not
% what Saastamoinen claims. I (J. Wilms) am puzzled...
%
% If the exact qualifier is set or for large z, all input into the function MUST be
% scalars - in this case this routine is NOT array safe.
%
% For the Saastamoinen formulae, the routine is array safe in all relevant parameters.
%
%!%-;
    variable z0;
    switch (_NARGS)
    { case 1: z0=(); }
    { help(_function_name()); return; }

    if (qualifier_exists("deg")) {
	z0*=PI/180.;
    }

    % temperature at observer [K]
    variable T0;
    if (qualifier_exists("centigrade")) {
	T0=qualifier("temperature",0.)+273.15;
    } else {
	T0=qualifier("temperature",273.15);
    }
    % pressure at observer [Pa]
    variable P0;
    if (qualifier_exists("kPa")) {
	P0=1000.*qualifier("pressure",101.325); % kPa -> Pa
    } else {
	if (qualifier_exists("hPa")) { % =mbar
	    P0=100.*qualifier("pressure",1013.25); % hPa -> Pa
	} else {
	    P0=qualifier("pressure",101325.); % default: Pa
	}
    }
    variable h0=qualifier("altitude",0.);    % height of observer above geoid [m]

    variable lat=qualifier("latitude",0.);
    if (qualifier_exists("deg")) {
	lat*=PI/180.;
    }
    
    variable Rh=qualifier("rel_humidity",0.);
    if (Rh<0. or  Rh>1.) {
	throw RunTimeError, sprintf("%s: relative humidity is out of bounds\n",_function_name());
    }
    % partial pressure of water at observer (Pa)
    % see Mangum and Wallace (2015; appendix C)
    variable Pw0=Rh*(T0/247.1)^18.36;

    % wavelength for the observation 
    variable lambda=0.574; % mum
    if (qualifier_exists("lambda")) {
	if (qualifier_exists("mum")) {
	    lambda=qualifier("lambda");
	} else {
	    lambda=qualifier("lambda")/10000.; % A->Mum
	}
    }

    % atmospheric structure
    variable htropo=qualifier("Htropo",11000.);   % altitude of the tropopause above geoid [h]
    variable hstrato=qualifier("Hstrato",80000.);  % altitude of the stratosphere above geoid [h]

    if (h0>=htropo) {
	()=printf("%s: WARNING: altitude is above topopause. Returning 0!\n",_function_name());
	return 0.;
    }

    % WGS84 radius (for speed reasons we do not use geographic2vector)
    variable Rearth=6378137.*(1.-sin(lat)^2./298.257223563); 
    variable R0=Rearth+h0;
    
    variable Rstrato=hstrato+Rearth; % radius of the stratosphere
    variable Rtropo=Rearth+htropo;
    variable alpha=qualifier("lapse_rate",0.0065); % Temperature lapse rate [K/m]
    variable Ttropo=T0-alpha*(Rtropo-R0); % temperature at the tropopause
    
    % Saastamoinen 1972 standard formula
    % use if
    % a) qualifier "exact" is not set and
    % b) z0<80 degrees (1.4 rad)
    if (not qualifier_exists("exact") && z0<1.4) {
	variable tanz=tan(z0);
	variable tanz2=tanz*tanz;

	% note: Saastamoinen claims that the pressures should be
	% in mbar/hPa, but results agreeing with numerical calculations
	% agree only when using Pa here
	% I am confused...
	variable pterm=(P0-0.156*Pw0)/T0;
	
	% latitude term (Saastamoinen 72, equation above eq 37)
	% corrected by 1e3 to avoid a division below
	variable lterm=0.07485e-3*(1.+0.0060*cos(2.*lat)+0.00012e-3*h0);
	
	% basic equation (Saastamoinen, eq. 30a)
	variable dz=16.271*tanz*(1.+0.0000394*tanz2*pterm)*pterm-lterm*(tanz2+1.)*tanz*P0;

	% correction for z in65-80 deg
	% (this should be Saastamoinen, Table III, but I can't fully
	% reproduce his values)
	if (z0>1.13) {
	    variable T1=T0-alpha*(htropo-h0);
	    variable p1=P0*(T1/T0)^5.26;

	    variable tanz3=tanz2*tanz;
	    variable tanz5=tanz3*tanz2;
	    variable tanz7=tanz3*tanz2;
	    variable tanz9=tanz7*tanz2;

	    variable del=0.000288e-6*(3.*tanz5+5.*tanz3)*(p1*T1+0.190*P0*T0)
	                -0.013e-6*tanz5*(p1*p1/T1)
	                -0.014e-12*tanz7*(p1*T1*T1+0.64*P0*T0*T0)
	                +0.0003e-15*tanz9*(p1*T1*T1*T1+2.*P0+T0*T0*T0);
	    
	    dz+=del;
	}
	
	% wavelength correction (Saastamoinen, eq 38 [p388])
	dz*=170.2649/(173.3-1./lambda/lambda);

	
	if (qualifier_exists("deg")) {
	    return dz/3600.;
	}
	
	return dz/3600 * PI/180.;
    }


    % local acceleration
    variable g=g_earth(lat;mks,altitude=h0);


    % exponent of temperature dependency on water pressure,
    % between 18 and 21 (only by accident the same as the exponent
    % in the equation for Pw)
    variable delta=18.36;
    
    % Universal gas constant [J/Mole K]
    variable Runiv=8314.36; 
    
    % Molecular weight of dry air and of water vapor [g/mole]
    variable Md=28.9644; 
    variable Mw=18.0152;

    % atmospheric structure
    
    variable tropscal=g*Md/Runiv;
    variable gamma=tropscal/alpha;
    % pressure at the tropopause
    variable pfac=(1.-Mw/Md)*gamma/(delta-gamma);
    variable Ptropo=(P0+pfac*Pw0)*(Ttropo/T0)^gamma; 

    
    % structure containing all of the parameters
    % needed for the evaluation of the atmospheric
    % structure and other helpers for the
    % refraction
    variable r;
    r=struct
    {
	Rearth=Rearth, % Radius of the Earth, m
	Rtropo=Rtropo, % radius of the troposphere
	lambda=lambda,
	P0=P0,         % pressure at observer, mb
	T0=T0,         % Temperature at observer, K
	Pw0=Pw0,       % partial pressure of water vapor at observer, mb
	alpha=alpha,   % temperature lapse rate
	delta=delta,   % humidity exponent
	gamma=gamma,   %
	pfac=pfac,     % helper
	tropscal=tropscal, % helper for the pressure scaling in the troposphere
	Ttropo=Ttropo, % Temperature at tropopause, K
	Ptropo=Ptropo, % Pressure at tropopause, mb
	R0=R0,         % radius of observer from center of Earth, m
	z0=z0,         % zenith angle, rad
	sinz0=sin(z0), % 
	mu0=0.
    };
    r.mu0=refract_mu(h0;rrefract=r); % refract_mu does not need mu0!
    %
    % angle at the tropopause in the troposphere
    %
    variable mutropo=refract_mu(htropo;rrefract=r);
    variable sintropo=r.mu0*R0*r.sinz0/(mutropo*Rtropo);
    variable psitropo=asin(sintropo);
	
    %
    % angle at the end of the stratosphere
    %
    variable mustrato=refract_mu(hstrato;rrefract=r);
    variable sinstrato=r.mu0*r.R0*r.sinz0/(mustrato*Rstrato);
    variable psistrato=asin(sinstrato);

    variable refstrato=-qromb(&refract_integrand,psitropo,z0;rrefract=r);
    variable reftropo=-qromb(&refract_integrand,psistrato,psitropo;rrefract=r);

    variable reftot=refstrato+reftropo;

    if (qualifier_exists("deg")) {
	return reftot*180./PI;
    }
	
    return reftot;
}
