define j_ff() {
%!%+
%\function{j_ff}
%\synopsis{Calculates the emission coefficient for free-free emission (bremsstrahlung)}
%\usage{Double_Type j = j_ff(nu,T);}
%
%\qualifiers{
%\qualifier{Z}{average nuclear charge (default=1)}
%\qualifier{ne}{electron particle density (cm^-3; default: 1e10)}
%\qualifier{np}{proton particle density (cm^-3; default: 1e10)}
%}
%\description
%    This function returns the emission coefficient for free-free radiation
%    (bremsstrahlung). The frequency, nu, is measured in Hz and can be an array,
%    the temperature T is measured in K.
%
%    Note: per Kirchhoff's law the total bremsstrahlung spectrum from
%    a slab of size R is
%    B_nu(nu,T)*(1.-exp(-R*alpha_ff(nu,T)))
%
%\seealso{alpha_ff}
%!%-

    variable nu,T;
    
    (nu,T)=();

    variable Z=qualifier("Z",1.);
    variable ne=qualifier("ne",1e10);
    variable ni=qualifier("ni",1e10);
    
    variable alpha=alpha_ff(nu,T;ne=ne,ni=ni,Z=Z);
    variable jnu=alpha*B_nu(nu,T);

}
