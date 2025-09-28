define B_lambda() {
%!%+
%\function{B_lambda}
%\synopsis{Calculates the spectral density for black body radiation (wavelength space)}
%\usage{Double_Type Blambda = B_lambda(lambda,T);}
%
%\qualifiers{
%\qualifier{keV}{T argument is kT in keV}
%\qualifier{A}{Wavelength is given in Angstroms}
%\qualifier{Angstrom}{Wavelength is given in Angstroms}
%}
%\description
%    This function returns the spectral energy density of a black body,
%    in units erg/cm^2/s/cm/sr 
%    Either lambda or T can be an array.
%    
%!%-
    variable lambda,kT;

    switch(_NARGS)
    { case 2: (lambda,kT)=(); }
    { help(_function_name()); return; }

    variable h=6.62606885e-27;% erg s
    variable c=2.99792457e10; % cm/s
    variable k=1.3806504e-16; % erg/K

    variable keV2erg=1.60218e-9; % keV -> erg
    variable A2cm  =1e-8;

    if (qualifier_exists("Angstrom") or qualifier_exists("A")) {
	lambda*=A2cm;
    }
    if (qualifier_exists("keV")) {
	kT*=keV2erg;
    }
	    
    variable Blambda=2.*h*(c/lambda)*(c/lambda)/lambda/lambda/lambda/(exp(h*c/lambda/kT)-1.);

    return Blambda;
}
