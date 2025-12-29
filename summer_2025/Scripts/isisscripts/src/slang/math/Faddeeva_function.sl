% Implementation of the Faddeeva function as described in
% https://dl.acm.org/citation.cfm?doid=3132683.3119904.
%
% Other routines use this to compute erf, erfc, real and imaginary voigt functions
%

private define __Faddeeva (z)
%{{{%
{
  % takes real or complex array returns Faddeyeva function w(z) = exp((-iz)^2)erfc(-iz)

  % often used numbers
  variable spi = 0.5641895835477563; % 1/sqrt(pi)
  variable ispi   = 1i*spi;     % i/sqrt(pi)
  variable zabs2 = (Real(z)^2 + Imag(z)^2);

  variable t; % integration variable
  variable t2;
  variable wz = @Complex_Type[length(z)]*_NaN; % return value, initialize as NaN
  variable wis;
  % Region 1 approximation
  variable ir1 = (zabs2 >= 38000.0);
  if (any(ir1)) {
    wis = where(ir1);
    t = z[wis];
    wz[wis] = ispi/t;
  }
  % Region 2
  variable ir2 = ( (38000.0>zabs2) and (zabs2>=256.0) );
  if (any(ir2)) {
    wis = where(ir2);
    t = z[wis];
    wz[wis] = ispi*t/(t*t-.5);
  }
  % Region 3
  variable ir3 = ( (256.0>zabs2) and (zabs2>=62.0) );
  if (any(ir3)) {
    wis = where(ir3);
    t=z[wis];
    wz[wis] = (ispi/t)*(1+.5/(t*t-1.5));
  }
  % Region 4
  variable ir4 = ( (62.0>zabs2) and (zabs2>=30.0) and (Imag(z)^2>=1e-13) );
  if (any(ir4)) {
    wis = where(ir4);
    t = z[wis];
    t2 = t*t;
    wz[wis] = ispi*t*(t2-2.5)/(t2*(t2-3.0)+.75);
  }
  % Region 5
  variable ir5 = ( (62.0>zabs2) and (not ir4) and ( (zabs2>2.5) and (Imag(z)^2<.072) ) );
  if (any(ir5)) {
    wis = where(ir5);
    t = z[wis];
    t2 = -t*t;
    wz[wis] = exp(t2)+1i*t*(36183.31-t2*(3321.99-t2*(1540.787-t2*(219.031-t2*(35.7668-t2*(
                    1.320522-t2*spi))))))/
                    (32066.6-t2*(24322.84-t2*(9022.228-t2*(2186.181-t2*(364.2191-t2*(
		    61.57037-t2*(1.841439-t2)))))));
  }
  % Region 6
  variable ir6 = ( (30.0>zabs2) and (not ir5) );
  if (any(ir6)) {
    wis = where(ir6);
    t = -1i*z[wis];
    wz[wis] = (122.60793+t*(214.38239+t*(181.92853+t*(93.15558+t*(30.180142+t*(
		   spi*t+5.9126262))))))/
                   (122.60793+t*(352.73063+t*(457.33448+t*(348.70392+t*(170.35400+t*(
		   53.992907+t*(t+10.479857)))))));
  }

  return wz;
}
%}}}%

%%%%%%%%%%%%%%%%%%%
define Faddeeva (z)
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{Faddeeva}
%\synopsis{Compute w(z) = exp((-iz)^2 erfc(-iz) for complex z}
%\usage{Complex_Type[] Faddeeva(Complex_Type[]);}
%#c%{{{%
%\description
%    This function uses continued fraction expansion and the algorithms described by
%    Humlicek () and Hui () to compute an approximation to the Faddeeva function
%
%    The algorithm used only allows to compute w(z) for Im(z)>=0, but using the relation
%    w(-z) = 2*exp(-z^2)-w(-z) gives the remaining half.
%
%    The derivative is given via dw/dz = 2i/sqrt(pi) - 2*z*w(z)
%    \seealso{Faddeeva_dz}
%
%    It is claimed that the algorithm has an accuracy of <4e-4.
%!%-
{
  variable ini = Imag(z)<0; % Is Negative Imaginary
  variable w = Complex_Type[length(z)]; % Where Is Negative Imaginary
  variable wini = where(ini);
  variable wipi = where(not ini); % Where Is Positive Imaginary
  w[wini] = 2*exp(-z[wini]^2)-__Faddeeva(-z[wini]);
  w[wipi] = __Faddeeva(z[wipi]);
  return (length(w)>1) ? w : w[0];
}
%}}}%

%%%%%%%%%%%%%%%%%%%%%%
define Faddeeva_dz (z)
%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{Faddeeva_dz}
%\synopsis{Compute derivative of Faddeeva function}
%\usage{Complex_Type[] Faddeeva_dz (Complex_Type[]);}
%\description
%    Computes complex derivative of Faddeeva function
%    \seealso{Faddeeva}
%!%-
{
  return 1.12837916709551*1i-2*z*Faddeeva(z);
}

%%%%%%%%%%%%%%%%
define cerfc (z)
%%%%%%%%%%%%%%%%
%!%+
%\function{cerfc}
%\synopsis{Complex error function complement}
%\usage{Complex_Type[] = cerfc(Complex_Type[]);}
%\description
%    Compute complex error function complement. Only useful in a region
%    with abs(z)<10.
%\seealso{Faddeeva, cerf}
%!%-
{
  return exp(-z^2)*Faddeeva(1i*z);
}

%%%%%%%%%%%%%%%
define cerf (z)
%%%%%%%%%%%%%%%
%!%+
%\function{cerf}
%\synopsis{Complex error function}
%\usage{Complex_Type[] = cerf(Complex_Type[]);}
%\description
%    Compute complex error function. Only useful in a region
%    with abs(z)<10.
%\seealso{Faddeeva, cerfc}
%!%-
{
  return 1-cerfc(z);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define Lorentz_complex (z, z0, gamma)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{Lorentz_complex}
%\synopsis{Compute complex Lorentz profile}
%\usage{Complex_Type[] = Lorentz_complex(z, z0, gamma);}
%!%-
{
  variable g2 = gamma^2;
  return 1./(PI*gamma)*(g2/((z-z0)^2+g2));
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define Gauss_complex (z, z0, sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{Gauss_complex}
%\synopsis{Compute complex Gauss profile}
%\usage{Complex_Type = Gauss_complex(z, z0, sigma);}
%!%-
{
  variable s2 = sig^2;
  return 1./sqrt(2*PI*s2)*exp(-.5*(z-z0)^2/s2);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define Voigt_complex (z, z0, sig, gamma)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{Voigt_complex}
%\synopsis{Compute complex Voigt profile}
%\usage{Complex_Type[] = Voigt_complex(z, z0, sigma, gamma);}
%!%-
{
  if (sig<0 || gamma<0) return z*0;
  else if (sig==0 && gamma==0) return z*0;
  else if (sig==0 && gamma>0) return Lorentz_complex(z,z0,gamma);
  else if (sig>0 && gamma==0) return Gauss_complex(z,z0,sig);
  variable zz = (z-z0+1i*gamma)/(sig*sqrt(2));
  return Faddeeva(zz)/(sig*sqrt(2*PI));
}
