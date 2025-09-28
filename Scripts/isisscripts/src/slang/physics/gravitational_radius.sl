%!%+
%\function{gravitational_radius}
%\synopsis{calculates the gravitational radius in Meters defined as r_g=GM/c^2,
%    for a mass given in units of M_sol.}
%\usage{gravitational_radius(mass_in_solar)}
%!%-
define gravitational_radius() {
   variable mass_in_solar;
   
   switch(_NARGS)
   { case 1: mass_in_solar = ();}
   { help(_function_name()); return; }

   variable G = 6.67430e-11;
   variable c = 299792458.0;
   variable Msol = 1.9884e30;  % in kg
   
   return    G*Msol*mass_in_solar / (c^2);
}
