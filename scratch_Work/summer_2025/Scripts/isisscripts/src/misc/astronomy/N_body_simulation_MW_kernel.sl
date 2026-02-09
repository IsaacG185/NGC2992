define N_body_simulation_MW_kernel()
%!%+
%\function{N_body_simulation_MW_kernel}
%\synopsis{Alternative interaction kernel for the function 'N_body_simulation'}
%\usage{Double_Type r[6,N] = N_body_simulation_MW_kernel(Double_Types t, m[6,N]; qualifiers)}
%\description
%    This function is an alternative interaction kernel for the function 'N_body_simulation'.
%    It combines the mutual N-nody interactions of the standard interaction kernel
%    'N_body_simulation_std_kernel' with the external forces stemming from an analytical
%    model for the gravitational potential of the Milky Way (see qualifier 'model').
%\notes
%    Because of the unit convention used for the potentials of the Milky Way, 'psa', which
%    is a qualifier of the function 'N_body_simulation_std_kernel' and which is assumed to
%    be the mass of the Plummer spheres in solar masses, has to be converted to Galactic
%    mass units and then multiplied with a constant accounting for the remaining unit
%    conversions (see example below). The units of 'psb' have to be kpc^2.
%\qualifiers{
%\qualifier{model}{[\code{="AS"}]: Function ("AS", "MN_NFW", or "MN_TF"), which evaluates the equations of
%      motion that result from a model for the gravitational potential of the Milky Way.}
%\qualifier{All qualifiers from the model potential function except 'coords'.}{}
%\qualifier{All qualifiers from the function 'N_body_simulation_std_kernel'.}{}
%}
%\example
%    % Interacting satellite galaxies in the Milky Way:
%    s = properties_satellite_galaxies();
%    i = struct{ x, y, z, vx, vy, vz, psa, psb };
%    model = "AS"; % Milky Way mass model
%    SunGCDist = (@(__get_reference(model)))(; eomecd="sgcd"); % Sun-GC distance of chosen mass model
%    temp = [SunGCDist,0,0,0,0,0]; reshape(temp, [6,1]);
%    vlsr = (@(__get_reference(model)))(0, temp; eomecd="circ")[0]; % Local standard of rest velocity of chosen mass model
%    (i.x, i.y, i.z, i.vx, i.vy, i.vz) = cel2gal(s.ah, s.am, s.as, s.dd, s.dm, s.ds, s.dist, s.vrad, s.pma_cos_d, s.pmd; SunGCDist=SunGCDist, vlsr=vlsr);
%    kpcmyr_to_kms = 977.7736364875057; % = conversion factor from kpc/myr to km/s = 3.0856775975*10^16 / (10^6 * 3.15582 * 10^7);
%    i.vx /= kpcmyr_to_kms;
%    i.vy /= kpcmyr_to_kms;
%    i.vz /= kpcmyr_to_kms;
%    i.psa = s.Pl_mass/2.325131802556774e+07; % conversion from solar masses to Galactic mass units Mgal to have G=1
%    % Mgal = 2.325131802556774e+07 = 1e8*3.0856775975*1e19/6.6742/1e-11/1.9884/1e30, see Irrgang et al., 2013, A&A, 549, A137
%    const = 100./kpcmyr_to_kms^2; % factor 100 because potential is given in 100 km^2/s^2, see Irrgang et al. 2013
%    i.psa *= const;
%    i.psb = (s.Pl_radius)^2;
%    r = N_body_simulation(i, -1000; kernel="N_body_simulation_MW_kernel", psa=i.psa, psb=i.psb, model=model);
%    xrange(min_max([r.o0.x,r.o1.x])); yrange(min_max([r.o0.y,r.o1.y]));
%    plot(r.o0.x,r.o0.y); oplot(r.o1.x,r.o1.y);
%\seealso{N_body_simulation, N_body_simulation_std_kernel, AS, MN_NFW, MN_TF}
%!%-
{
  if(_NARGS!=2)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': Wrong number of arguments.", _function_name());
  }
  variable model = qualifier("model", "AS"); % function evaluating the equations of motions of the Milky Way potential
  if(__get_reference(model)==NULL or (model!="AS" and model!="MN_NFW" and model!="MN_TF"))
  {
    _pop_n(_NARGS); % remove function arguments from stack
    throw UsageError, sprintf("Usage error in '%s': Invalid input for qualifier 'model'.", _function_name());
  }
  model = __get_reference(model);
  variable t, m;
  (t, m) = ();
  variable N = length(m[0,*]);
  variable forces_only = Double_Type[6,N]; % to avoid summing over velocities
  forces_only[3,*] += 1;
  forces_only[4,*] += 1;
  forces_only[5,*] += 1;
  variable qualies = __qualifiers;
  qualies = struct_combine(qualies, "coords");
  set_struct_field(qualies, "coords", "cart");
  return ( N_body_simulation_std_kernel(t,m;; __qualifiers) + forces_only * (@model)(t,m;; qualies) );
}
