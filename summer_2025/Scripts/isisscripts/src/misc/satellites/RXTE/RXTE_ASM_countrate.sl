%%%%%%%%%%%%%%%%%%%%%%%%%
define RXTE_ASM_countrate()
%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{RXTE_ASM_countrate}
%\synopsis{estimates the RXTE-ASM countrate from the current model}
%\usage{(A, B, C) = RXTE_ASM_countrate();}
%\description
%     Zdziarski et al. (http://adsabs.harvard.edu/abs/2002ApJ...578..357Z)
%     provide a "response matrix" for the RXTE-ASM.
%     The inverse of this matrix is applied to the energy flux
%     derived from the current fit-function and its parameters,
%     in order to estimate the RXTE-ASM count rates \code{A}, \code{B} and \code{C} (cps).
%
%     Note that these numbers may only give a rough estimate!
%\seealso{energyflux}
%!%-
{
  variable Fa = energyflux(1.5, 3);
  variable Fb = energyflux(3,   5);
  variable Fc = energyflux(5,  12);
  return  62675e2/1570549.   * Fa +     81e4/1570549.    * Fb,
           8925e2/1570549.   * Fa +    638e4/1570549.    * Fb,
         226525e2/268563879. * Fa + 340054e4/5639841459. * Fb + 1e4/3591. * Fc;
}
