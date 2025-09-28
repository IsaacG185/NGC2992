define alpha_ff() {
%!%+
%\function{alpha_ff}
%\synopsis{Calculate the absorption coefficient for free-free absorption}
%\usage{Double_Type alpha = alpha_ff(nu,T);}
%
%\qualifiers{
%\qualifier{Z}{average nuclear charge (default=1)}
%\qualifier{ne}{electron particle density (cm^-3; default: 1e10)}
%\qualifier{np}{proton particle density (cm^-3; default: 1e10)}
%}
%\description
%    This function returns the absorption coefficient for free-free radiation
%    (bremsstrahlung). The frequency, nu, is measured in Hz and can be an array,
%    the temperature T is measured in K.
%
%    For the moment this function assumes the Gauntt factor equals unity.
%
%    Note: per Kirchhoff's law the total bremsstrahlung spectrum from
%    a slab of size R is
%    B_nu(nu,T)*(1.-exp(-R*alpha_ff(nu,T)))
%
%\seealso{j_ff}
%!%-

    variable nu,T;
    (nu,T)=();
    
    variable h=6.62606885e-27; % erg s
    % variable c=2.99792457e10;  % cm/s
    variable k=1.3806504e-16;  % erg/K
    % variable qe=4.80320451e-10;% esu 
    % variable me=9.10938e-28;   % g

    variable Z=qualifier("Z",1.);
    variable ne=qualifier("ne",1e10);
    variable ni=qualifier("ni",1e10);
    
    variable gaunt_ff=1.; % for simplicity and until I've programmed it
    
    %    variable prefac=4*qe^6/(3.*me*h*c) * sqrt(2*PI/3/k/me);
    variable prefac=3.6923492876535404e+08;
    
    variable alpha=prefac*Z*Z*ne*ni/sqrt(T)/nu/nu/nu *(1.-exp(-h*nu/k/T)) *gaunt_ff;

    return alpha;
}
