%!%+
%\function{kerr_rms}
%\synopsis{calculates the radius of marginal stability of a black hole
%    in units of GM/c^2}
%\usage{kerr_rms(a)}
%!%-
define kerr_rms() {
   variable a;
   
   switch(_NARGS)
   { case 1: a = ();}
   { help(_function_name()); return; }
   
%   if (abs(a) > 1) {
%      message("Only values of -1 < a < 1 are reasonable!");  
%      return;
%   }
   
   variable z1 = 1+ (1 - a^2)^(1./3)*((1+a)^(1./3) + (1-a)^(1./3)  );
   variable z2 = sqrt(3.*a^2 + z1^2);
   
   return (3 + z2 - sign(a)*sqrt( (3-z1)*(3+z1+2*z2)));
}
