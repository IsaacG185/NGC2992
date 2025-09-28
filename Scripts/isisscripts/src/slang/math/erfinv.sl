require( "gsl","gsl" );

private define erfinv_kernel(z,eps) {
    %
    % newton method for inverse erf
    %
    variable start=z;
    variable stp;
    variable del=10.;
    while(abs(del)>eps) {
        variable dfdx=2.*exp(-start^2)/sqrt(PI);
        del=(gsl->erf(start)-z)/dfdx;
        start=start-del;
    }
    return start;
}

define erfinv(z)
%!%+
%\function{erfinv}
%\synopsis{Computes the inverse error function in abs(z)<1}
%\usage{Double_Type erfinv(Double_Type z);}
%\qualifiers{
%   \qualifier{eps}{See description. Typically not needed.}
%}    
%\description
%    This function computes the inverse error function, i.e.,
%    erf(erfinv(x))=x. This can be used to calculate a confidence level by
%    \code{sqrt(2)*erfinv(fraction)}
%
%    By default the function uses two fast polynomial approximations
%    by Mike Giles which have a relative accuracy of better than 1.2e-7
%    over the whole interval between 0 and 1.
%
%    If the eps qualifier is given, the method switches to a Newton-Raphson
%    method that terminates once the relative error of the function is
%    smaller than eps. This is significantly slower and only needed if
%    an extremely high precision is needed (pretty much never). On Joern's
%    laptop, this method needs on average 0.08ms per function evaluation
%    compared to 0.03 mus for the polynomial approximation. 
%
%    The function is array safe.
%
%\seealso{erf [in gsl],cerf,cerfc}
%!%-
{

    if (max(z)>=1. || min(z)<=-1.) { % z can be array
      vmessage("Valid range only abs(z)<1");
      return 0;
    }

    if (qualifier_exists("eps")) {
        variable eps=qualifier("eps",1e-10);

        if (typeof(z)==Array_Type) {
            return parallel_map(Double_Type,&erfinv_kernel,z,eps);
        }
        return erfinv_kernel(z,eps);
    }

    %
    % inverse erf based on GPU code by Mike Giles,
    % https://people.maths.ox.ac.uk/gilesm/files/gems_erfinv.pdf
    % 
    % The code is implemented as two Horner schemes. We use them
    % twice, once for arrays and once for scalars, avoiding a loop
    % for speed reasons.
    %
    
    variable w = -log((1.0-z)*(1.0+z));
    variable p;
    if (typeof(z)==Array_Type) {
        variable ndx,ndx2;
        p=Double_Type[length(w)];
        ndx=where(w<5.,&ndx2);
        if ( length(ndx)>0 ) {
            w[ndx] = w[ndx] - 2.500000;
            p[ndx] = 2.81022636e-08;
            p[ndx] = 3.43273939e-07 + p[ndx]*w[ndx];
            p[ndx] = -3.5233877e-06 + p[ndx]*w[ndx];
            p[ndx] = -4.39150654e-06 + p[ndx]*w[ndx];
            p[ndx] = 0.00021858087 + p[ndx]*w[ndx];
            p[ndx] = -0.00125372503 + p[ndx]*w[ndx];
            p[ndx] = -0.00417768164 + p[ndx]*w[ndx];
            p[ndx] = 0.246640727 + p[ndx]*w[ndx];
            p[ndx] = 1.50140941 + p[ndx]*w[ndx];
        }
        if (length(ndx2)>0) {
            w[ndx2] = sqrt(w[ndx2]) - 3.000000;
            p[ndx2] = -0.000200214257;
            p[ndx2] = 0.000100950558 + p[ndx2]*w[ndx2];
            p[ndx2] = 0.00134934322 + p[ndx2]*w[ndx2];
            p[ndx2] = -0.00367342844 + p[ndx2]*w[ndx2];
            p[ndx2] = 0.00573950773 + p[ndx2]*w[ndx2];
            p[ndx2] = -0.0076224613 + p[ndx2]*w[ndx2];
            p[ndx2] = 0.00943887047 + p[ndx2]*w[ndx2];
            p[ndx2] = 1.00167406 + p[ndx2]*w[ndx2];
            p[ndx2] = 2.83297682 + p[ndx2]*w[ndx2];
        }
        return p*z;
    } 

    if ( w < 5. ) {
        w = w - 2.500000;
        p = 2.81022636e-08;
        p = 3.43273939e-07 + p*w;
        p = -3.5233877e-06 + p*w;
        p = -4.39150654e-06 + p*w;
        p = 0.00021858087 + p*w;
        p = -0.00125372503 + p*w;
        p = -0.00417768164 + p*w;
        p = 0.246640727 + p*w;
        p = 1.50140941 + p*w;
    } else {
        w = sqrt(w) - 3.000000;
        p = -0.000200214257;
        p = 0.000100950558 + p*w;
        p = 0.00134934322 + p*w;
        p = -0.00367342844 + p*w;
        p = 0.00573950773 + p*w;
        p = -0.0076224613 + p*w;
        p = 0.00943887047 + p*w;
        p = 1.00167406 + p*w;
        p = 2.83297682 + p*w;
    }

    return p*z;
}
