require( "vector" );

%%%%%%%%%%%%%%%%%%%%%%%
define lorentz_trafo()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{lorentz_trafo}
%\synopsis{lorentz transformation for a boost in any direction}
%\usage{lorentz_trafo( Double_Type ct,
%                      Vector_Type x,
%                      Vector_Type B
%                    );
%}
%\description
%    This function performs a Lorentz transformation:
%      ( ct, x ) -> ( ct', x')
%      ct' = gamma ( ct - B*x )
%      x'  = x + ( (gamma-1)/B^2 * B*x - gamma * ct ) * B
%    where x is the spartial vector, gamma the Lorentz-factor
%    and B=v/c the velocity vector.
%    
%\seealso{Vector_Type}
%!%-
{
  variable ct, x, B;
  switch(_NARGS)
  { case 3: ( ct, x, B) = (); }
  { help(_function_name()); return; }

  variable BB = dotprod( B, B );
  variable xB = dotprod( x, B );

  variable g = 1. / sqrt( 1. - BB );
  
  
  variable ctp = g * ( ct - xB );
  variable xp = x + vector_mul( (g-1)/BB*xB - g*ct, B );

  return ( ctp, xp );
}
