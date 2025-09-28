%!%+
%\function{kerr_lp_redshift}
%\synopsis{calculates the redshift from a Lamp Post source (point-like)
% on the rotational axis of a spining black hole (spin a) to the  observer}
%\usage{kerr_lp_redshift(height, a)}
%\description
%   z_obs = 1 / ( sqrt( 1 - 2*h/(h^2 + a^2) )  - 1 
%!%-
define kerr_lp_redshift(){
   variable height, a;
   
   switch(_NARGS)
   { case 2: (height, a) = ();}
   { help(_function_name()); return; }


   return 1.0 / sqrt( 1.0 - 2*height / (height^2 + a^2))-1.0;
}



%!%+
%\function{kerr_lp_energyshift_observer}
%\synopsis{calculates the energyshift from a Lamp Post source (point-like)
% on the rotational axis of a spining black hole (spin a) to the
% observer. It follows the relxill definition that if the height is in
% negative units, it is interpreted as given in units of the event
% horizon. }
%\usage{kerr_lp_energyshift_observer(height, a)}
%\description
%   g = E_obs / E_emit =  sqrt( 1 - 2*h/(h^2 + a^2)
%!%-
define kerr_lp_energyshift_observer(){
   variable height, a;
   
   switch(_NARGS)
   { case 2: (height, a) = ();}
   { help(_function_name()); return; }

   height = [height];

   variable ii, n = length(height);

   _for ii(0, n-1){         
      if (height[ii] < 0) {
	 height[ii] *= -1.0*kerr_rplus(a);
      }
   }

   variable g = sqrt( 1.0 - 2*height / (height^2 + a^2));
   
   if (n == 1) {
      return g[0];
   } else   {
      return g;
   }
   
}
