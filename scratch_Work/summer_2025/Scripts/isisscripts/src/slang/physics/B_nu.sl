define B_nu() {
%!%+
%\function{B_nu}
%\synopsis{Calculates the spectral density for black body radiation (frequency space)}
%\usage{Double_Type Bnu = B_nu(nu,T);}
%
%\qualifiers{
%\qualifier{keV}{1st argument is energy in keV,
%                  T argument is kT in keV}
%\qualifier{MHz}{Frequency is given in MHz}
%\qualifier{GHz}{Frequency is given in GHz}
%}
%\description
%    This function returns the spectral energy density of a black body,
%    in units erg/cm^2/s/Hz/sr 
%    Either nu or T can be an array.
%    
%!%-
    variable par1,par2;

    switch(_NARGS)
    { case 2: (par1,par2)=(); }
    { help(_function_name()); return; }
    
    variable h=6.62606885e-27;% erg s
    variable c=2.99792457e10; % cm/s
    variable k=1.3806504e-16; % erg/K

    variable keV2erg=1.60218e-9; % keV -> erg
    variable MHz2Hz=1e6;      % MHz -> Hz
    variable GHz2Hz=1e9;      % GHz -> Hz
    variable A2cm  =1e-8;

    variable kT=par2;
    variable nu=par1;
    if (qualifier_exists("keV")) {
	% temperature argument is in keV; convert to erg
	kT*=keV2erg;
	% frequency argument is in keV -> convert to Hz
	nu*=keV2erg/h;
    } else {
	kT=k*kT;
	if (qualifier_exists("MHz")) {
	    nu*=MHz2Hz;
	} else {
	    if (qualifier_exists("GHz")) {
		nu*=GHz2Hz;
	    }
	}
    }
	
    variable Bnu=2*h*(nu/c)*(nu/c)*nu/(exp(h*nu/kT)-1.);

    return Bnu;
}
