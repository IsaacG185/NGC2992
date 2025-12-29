define r_in_from_disk(norm, distance, inclination){
%!%+
%\function{r_in_from_disk}
%\synopsis{Calculate inner disk radius from a continuum fitting disk model}
%\usage{Struct_Type r_in_from_disk(norm, distance, inclination)}
%\qualifiers{
%    \qualifier{f}{Color-correction factor [default: 1.0]}
%    \qualifier{norm_err}{Error on normalization [default: 0]}
%    \qualifier{distance_err}{Error on distance in units of kpc [default: 0]}
%    \qualifier{inclination_err}{Error on inclination in degree [default: 0]}
%    \qualifier{mass}{Mass of the black hole in units of solar mass [default: 0]}
%    \qualifier{mass_err}{Error on mass in units of solar mass [default: 0]}
%}
%\description
%    This function can be used to calculate the values and errors of
%    the inner radius (in units of km) from a continuum fitting model
%    such as diskbb or ezdiskbb. See Mitsuda et al. (1984), Makishima
%    et al. (1986), and, e.g., Zimmerman et al. (2005) and Kubota et
%    al. (1998) on the color-correction. See also the HEASARC model
%    description of diskbb and ezdiskbb.
%    
%    The distance is given in units of kpc and the inclination in
%    degrees. If a mass is given (units of solar mass), the struct
%    will also contain the radius in units of r_g as well as the size
%    of the gravitational radius in km.
%\usage{r_in_from_disk(norm, distance, inclination)}
%\example
%    r_in_from_disk(1000, 8, 30; f=1.7, mass=10);
%\seealso{gravitational_radius}
%!%-
  variable f = qualifier("f", 1.0);
  variable norm_err = qualifier("norm_err", 0.0);
  variable distance_err = qualifier("distance_err", 0.0);
  variable incl_err = qualifier("inclination_err", 0.0);
  
  variable i_rad = inclination * PI/180.;
  variable i_rad_err = incl_err * PI/180.;
  variable r_in_km = sqrt(f^4 * norm * (distance/10.)^2 / cos(i_rad));
  
  variable arg = r_in_km^2;
  variable d_dn = 0.5 * arg^(-0.5) * f^4 * (distance/10.)^2 / cos(i_rad);
  variable d_dd = 0.5 * arg^(-0.5) * f^4 * norm * 2*(distance/10.) / cos(i_rad);
  variable d_di = 0.5 * arg^(-0.5) * f^4 * norm * (distance/10.)^2 * sin(i_rad)/(cos(i_rad))^2;
    
  variable dr_in_km = sqrt(d_dn^2 * norm_err^2 + d_dd^2 * distance_err^2 + d_di^2 * i_rad_err^2);

  variable ret = struct{
    r_in_km = r_in_km,
    r_in_km_err = dr_in_km
  };
  
  if (qualifier_exists("mass")){
    variable mass = qualifier("mass", 0.0);
    variable mass_err = qualifier("mass_err", 0.0);

    variable r_g_km = gravitational_radius(mass) / 1000.;
    variable dr_g_km = gravitational_radius(mass_err) / 1000.;
  
    variable r_in_rg = r_in_km / r_g_km;
    variable dr_in_rg = sqrt(1/r_g_km^2 * dr_in_km^2 + (r_in_km/r_g_km^2)^2 * dr_g_km^2);
    
    ret = struct_combine(ret, struct{
      r_in_rg = r_in_rg,
      r_in_rg_err = dr_in_rg,
      r_g_km = r_g_km,
      r_g_km_err = dr_g_km
    });
  }
  
  return ret;
}
