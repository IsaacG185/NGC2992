% -*- mode: slang; mode: fold -*-

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% integrate2d calculates 2-dimensional integrals of the form:
%%%
%%% I = int_x1^x2 int_y1(x)^y2(x) func(x,y) dx dy
%%%
%%% The solution is adopted from 'Numerical Recipes in C' Cap. 4.6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global variables:
private variable xsav;
private variable nrfunc;

%%% Inner function call: f2(y) = func(xsav,y)
private define f2(y){ %{{{
  return (@nrfunc)( xsav, y ;; __qualifiers );
}
%}}}

%%% Outer function call: f1(x) = func(x,&y(x));
private define f1(x){ %{{{
  xsav = x;
  return (@__qualifiers.intfun)( &f2,
				 (@__qualifiers.y1)(x;;__qualifiers),
				 (@__qualifiers.y2)(x;;__qualifiers)
				 ;;
				 __qualifiers
			       );
}
%}}}


define integrate2d( func, y1, y2, x1, x2 ) %{{{
%!%+
%\function{integrate2d}
%\synopsis{numerical computation of an 2-dim. integral}
%\usage{Double_Type I = integrate2d( Ref_Type func, y1, y2,
%                                    Double_Type x1, x2
%                                  );
%}
%\qualifiers{
%\qualifier{intfun[&qromb]:}{Reference to the integrator}
%\qualifier{NOTE}{Qualifiers are passed to all sub-functions!}
%}
%\description
%    This function numerically computes the 2-dimensional integral 'I' over the
%    integrant-function 'func' of the form:
%
%       I = int_x1^x2 int_y1(x)^y2(x) func(x,y) dx dy
%
%   The given limits 'x1' and 'x2' are the lower and upper integration limits
%   for the 'x' variable, respectively. 'y1' and 'y2', on the other hand, are
%   references to functions, which calculates the lower and upper limit y1(x)
%   and y2(x) for the 'y' variable depending on 'x'.
%
%   The implemented solution is adopted from the 'Numerical Recipes in C'
%   Chap. 4.6. !
%   
%   The integrator can be changed by the qualifier 'intfun', which is set to
%   'qromb' as default (see 'help qromb). Qualifiers given to 'integrate2d'
%   are passed to the 'intfun' function!
%
%\example
%   % Calculation of the area of an rectangle:
%   %    I = int_0^1 dx int_0^2 dy
%   %      = [ x ]_0^1 * [ y ]_0^2
%   %      = 2
%   
%   variable x1 = 0., x2 = 1.;
%   define y1(x){ return 0.; };
%   define y2(x){ return 2.; };
%   define func( x, y ){ return 1.; };
%   variable I = integrate2d( &func, &y1, &y2, x1, x2 );
%   vmessage("Area of rectangle is A = %g",I);
%
%   % Calculation of the area of the unit circle in cartesian coordinates:
%   %   I = int_-1^1 int_-sqrt(1-sqr(x))^sqrt(1-sqr(x)) dx dy
%   %     = int_-1^1 2 * sqrt(1-sqr(x)) dx
%   
%   define tfun( x, y ){ return 1; }
%   define y1(x){ return -sqrt(1-sqr(x)); }
%   define y2(x){ return  sqrt(1-sqr(x)); }
%   variable I = integrate2d( &tfun, &y1, &y2, -1., 1. ; qromb_max_iter=24, qromb_eps=1e-3 );
%   vmessage("Area of unite circle is A = %g, abs(A-PI)/PI = %g", I, abs(I-PI)/PI );
%   
%%\seealso{qromb, qsimp, integrate2d_test}
%!%-
{
  variable intfun = qualifier("intfun",&qromb);
  variable qualis = struct_combine(__qualifiers,struct{intfun=intfun,y1=y1,y2=y2} );
  nrfunc = func;
  return (@intfun)( &f1, x1, x2 ;; qualis );
}
%}}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% FUNCTION TEST:
%%%  %{{{
private define tfun( x, y ){
  return 1.;
}
private define y1(x){
  return -sqrt(1-sqr(x));
}
private define y2(x){
  return sqrt(1-sqr(x));
}
define integrate2d_test()

{
  variable lim = qualifier("lim",1e-3);
  variable Acirc = integrate2d( &tfun, &y1, &y2, -1., 1. ; intfun=&qromb, qromb_max_iter=24, qromb_eps=lim*1e-1 );
  variable reldif = abs( Acirc - PI )/PI;
  if( reldif < lim ){
    return 1;
  }
  else{
    return 0;
  }
}

%}}}
