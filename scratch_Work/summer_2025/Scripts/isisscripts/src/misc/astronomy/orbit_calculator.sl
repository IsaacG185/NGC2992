define AS() %{{{
%!%+
%\function{AS}
%\synopsis{Evaluate equations of motion, total energy, or circular velocity derived from a revised
%    Allen & Santillan potential}
%\usage{AS(Double_Types t, m[6,n]; qualifiers)}
%\qualifiers{
%\qualifier{coords}{[\code{="cyl"}] Use cylindrical ("cyl") or cartesian ("cart") coordinates.}
%\qualifier{eomecd}{[\code{="eom"}] Return equations of motion ("eom"), total energy ("energy"),
%      circular velocity ("circ"), or Sun-Galactic center distance ("sgcd").}
%\qualifier{Mb}{[\code{=409}] Mass of bulge in Galactic mass units, see Irrgang et al. 2013.}
%\qualifier{Md}{[\code{=2856}] Mass of disc in Galactic mass units, see Irrgang et al. 2013.}
%\qualifier{Mh}{[\code{=1018}] Mass scale factor of halo in Galactic mass units,
%               see Irrgang et al. 2013.}
%\qualifier{bb}{[\code{=0.23}] Bulge scale length, see Irrgang et al. 2013.}
%\qualifier{ad}{[\code{=4.22}] Disc scale length, see Irrgang et al. 2013.}
%\qualifier{bd}{[\code{=0.292}] Disc scale length, see Irrgang et al. 2013.}
%\qualifier{ah}{[\code{=2.562}] Halo scale length, see Irrgang et al. 2013.}
%\qualifier{exponent}{[\code{=2}] Exponent in the halo mass distribution, see Irrgang et al. 2013.}
%\qualifier{cutoff}{[\code{=200}] Halo cutoff, see Irrgang et al. 2013.}
%}
%\description
%    Evaluate the equations of motion, the total energy, or the circular velocity at time 't'
%    derived from the revised Galactic gravitational potential by Allen & Santillan (see Model I
%    in Irrgang et al., 2013, A&A, 549, A137) using either cylindrical coordinates (r [kpc],
%    phi [rad], z [kpc]) and their canonical momenta vr [kpc/Myr], Lz [kpc^2/Myr], vz [kpc/Myr])
%    or cartesian coordinates (x [kpc], y [kpc], z [kpc], vx [kpc/Myr], vy [kpc/Myr], vz [kpc/Myr]),
%    see qualifier 'coords'.  Conservation of angular momentum Lz is implemented in the equations
%    of motion for cylindrical coordinates only. The total energy E_total [kpc^2/Myr^2] is not
%    used to integrate the equations of motion although being a conserved quantity, too. Therefore,
%    conservation of energy, i.e., of E_total, is a measure for the precision of the numerical
%    methods applied.
%
%    For computing orbits with n different initial conditions, the input parameter m is
%    a [6,n]-matrix with (qualifier("coords")=="cyl")   or (qualifier("coords")=="cart")
%       m[0,*] = r;                                        m[0,*] = x;
%       m[1,*] = phi;                                      m[1,*] = y;
%       m[2,*] = z;                                        m[2,*] = z;
%       m[3,*] = vr;                                       m[3,*] = vx;
%       m[4,*] = Lz;                                       m[4,*] = vy;
%       m[5,*] = vz;                                       m[5,*] = vz;
%    If the qualifier 'eomecd' is set to "eom", the function returns a [6,n]-matrix delta with
%       delta[0,*] = vr;                                   delta[0,*] = vx;
%       delta[1,*] = Lz/r^2; % = vphi                      delta[1,*] = vy;
%       delta[2,*] = vz;                                   delta[2,*] = vz;
%       delta[3,*] = -d/dr (Potential(r,z) + Lz^2/r^2);    delta[3,*] = -d/dx Potential(x,y,z);
%       delta[4,*] = 0; % -d/dphi Potential(r,z)           delta[4,*] = -d/dy Potential(x,y,z);
%       delta[5,*] = -d/dz Potential(r,z);                 delta[5,*] = -d/dz Potential(x,y,z);
%    If the qualifier 'eomecd' is set to "energy", the function returns a [1,n]-array storing
%    the total energy for each orbit:
%       E_total(r,z,vr,vz,Lz) = Double_Type[n] = 0.5*(vr^2+vz^2+Lz^2/r^2) + Potential(r,z)
%    or
%       E_total(x,y,z,vx,vy,vz) = Double_Type[n] = 0.5*(vx^2+vy^2+vz^2) + Potential(x,y,z)
%    If the qualifier 'eomecd' is set to "circ", the function returns a [1,n]-array storing
%    the circular velocity for each orbit:
%       v_circ(r,z) = Double_Type[n] = sqrt( r * d/dr Potential(r,z) )
%    If the qualifier 'eomecd' is set to "sgcd", the function returns the Sun-Galactic center
%    distance found to fit best to this potential.
%\example
%    delta = AS(0, m);
%    energy = AS(0, m; eomecd="energy");
%    v_circ = AS(0, m; eomecd="circ");
%    sgcd = AS(; eomecd="sgcd");
%\seealso{orbit_calculator, MN_NFW, MN_TF, plummer_MW}
%!%-
{
  % equations of motion, energy, circular velocity or Sun-Galactic center distance:
  variable eomecd = qualifier("eomecd", "eom");
  if(eomecd == "sgcd")
  {
    return 8.4;
  }
  else if(_NARGS!=2)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  else
  {
    variable coords = qualifier("coords", "cyl");
    variable t, input;
    (t, input) = ();
    input *= 1.;
    variable r, z, vz;
    if(coords=="cart")
    {
      variable x, y, vx, vy;
      x = input[0,*];
      y = input[1,*];
      z = input[2,*];
      vx = input[3,*];
      vy = input[4,*];
      vz = input[5,*];
      r = sqrt(x^2+y^2);
    }
    else % coords=="cyl"
    {
      variable phi, vr, Lz;
      r = input[0,*];
      phi = input[1,*];
      z = input[2,*];
      vr = input[3,*];
      Lz = input[4,*];
      vz = input[5,*];
    }
    % definition of gravitational potential parameters:
    variable Mb = qualifier("Mb", 409.);  % mass of the bulge
    variable Md = qualifier("Md", 2856.); % mass of the disk
    variable Mh = qualifier("Mh", 1018.); % mass scale length of the halo
    variable bb = qualifier("bb", 0.23);  % scale length bulge
    variable ad = qualifier("ad", 4.22);  % scale length disk
    variable bd = qualifier("bd", 0.292); % scale length disk
    variable ah = qualifier("ah", 2.562); % scale length halo
    variable exponent = qualifier("exponent", 2.); % exponent in halo mass distribution
    variable cutoff = qualifier("cutoff", 200.); % halo cutoff

    % variable kpcmyr_to_kms = 977.7736364875057; % = conversion factor from kpc/myr to km/s = 3.0856775975*10^16 / (10^6 * 3.15582 * 10^7);
    variable constant = 1.0459799346702096e-04; % 100./kpcmyr_to_kms^2; factor 100 because potential is given in 100km^2/s^2
    % store frequently appearing expressions to save runtime:
    variable r2 = r^2;
    variable z2 = z^2;
    variable r2z2 = r2+z2;
    variable sr2z2 = sqrt(r2z2);
    variable sz2bd2 = sqrt(z2+bd^2);
    variable cutoff_ah = cutoff/ah;
    variable exp_minus_one = exponent-1.;
    variable ind1, ind11, ind12, ind2, ind3, ind4;
    ind1 = where( sr2z2 < cutoff, &ind2 );
    variable eps = 1e-5;
    ind11 = where( (sr2z2[ind1]) > eps, &ind12 ); % account for expressions with 1/sr2z2; e.g., right-hand side of equations of motion at origin are set to zero to solve singularity
    if(eomecd == "eom")
    {
      % store frequently appearing expressions to save runtime:
      variable dPot_bulge = -Mb/(r2z2+bb^2)^1.5;
      variable dPot_disc = -Md/(r2+(ad+sz2bd2)^2)^1.5;
      variable dPot_halo_inner = -Mh*(sr2z2/ah)^exp_minus_one/(r2z2)/(1.+(sr2z2/ah)^exp_minus_one)/ah;
      variable dPot_halo_outer = -Mh*(cutoff_ah)^exponent/(r2z2)^1.5/(1.+(cutoff_ah)^exp_minus_one);

      % calculate derivatives of the potential with respect to z (dPotdz):
      variable dPotdz = constant*( dPot_bulge*z + dPot_disc*(ad+sz2bd2)/sz2bd2*z );
      dPotdz[ind1[ind11]] += constant*dPot_halo_inner[ind1[ind11]]*z[ind1[ind11]];
      dPotdz[ind2] += constant*dPot_halo_outer[ind2]*z[ind2];

      variable ret = Double_Type[6,length(r)];

      if(coords=="cart")
      {
	% calculate derivatives of the potential with respect to x and y (dPotdx, dPotdy):
	variable dPotdx = constant*(dPot_bulge + dPot_disc)*x;
	variable dPotdy = constant*(dPot_bulge + dPot_disc)*y;
	dPotdx[ind1[ind11]] += constant*dPot_halo_inner[ind1[ind11]]*x[ind1[ind11]];
	dPotdy[ind1[ind11]] += constant*dPot_halo_inner[ind1[ind11]]*y[ind1[ind11]];
	dPotdx[ind2] += constant*dPot_halo_outer[ind2]*x[ind2];
	dPotdy[ind2] += constant*dPot_halo_outer[ind2]*y[ind2];

	ret[0,*] = vx;
	ret[1,*] = vy;
	ret[2,*] = vz;
	ret[3,*] = dPotdx;
	ret[4,*] = dPotdy;
	ret[5,*] = dPotdz;
	return ret;
      }
      else % coords=="cyl"
      {
	ind3 = where( Lz!=0, &ind4 );
	% calculate derivatives of the potential with respect to r (dPotdr):
	variable dPotdr = constant*(dPot_bulge + dPot_disc)*r;
	dPotdr[ind1[ind11]] += constant*dPot_halo_inner[ind1[ind11]]*r[ind1[ind11]];
	dPotdr[ind2] += constant*dPot_halo_outer[ind2]*r[ind2];
	dPotdr[ind3] += (Lz[ind3])^2/(r[ind3])^3;

	ret[0,*] = vr;
	ret[1,ind3] = (Lz[ind3])/(r2[ind3]);
	ret[1,ind4] = 0;
	ret[2,*] = vz;
	ret[3,*] = dPotdr;
	ret[4,*] = 0*Lz;
	ret[5,*] = dPotdz;
	return ret;
      }
    }
    else if(eomecd == "energy")
    {
      % calculate the kinetic and potential energies (Ekin, Epot):
      variable Ekin;
      if(coords=="cart")
      {
	Ekin = 0.5*(vx^2+vy^2+vz^2);
      }
      else % coords=="cyl"
      {
	Ekin = 0.5*(vr^2+vz^2);
	ind3 = where( Lz!=0 );
	Ekin[ind3] += 0.5*(Lz[ind3])^2/(r2[ind3]);
      }
      variable Epot = -Mb/sqrt(r2z2+bb^2)-Md/sqrt(r2+(ad+sz2bd2)^2);                                                 % phi_bulge + phi_disc
      Epot[ind1[ind11]] += Mh*log((1.+(sr2z2[ind1[ind11]]/ah)^(exp_minus_one))/(1.+cutoff_ah^(exp_minus_one)))/(exp_minus_one)/ah
                         - Mh*cutoff_ah^(exp_minus_one)/(1.+cutoff_ah^(exp_minus_one))/ah;                           % phi_bulge + phi_disc + phi_halo
      Epot[ind1[ind12]] += Mh*log((1.+(eps/ah)^(exp_minus_one))/(1.+cutoff_ah^(exp_minus_one)))/(exp_minus_one)/ah
                         - Mh*cutoff_ah^(exp_minus_one)/(1.+cutoff_ah^(exp_minus_one))/ah;                           % phi_bulge + phi_disc + phi_halo
      Epot[ind2] += -Mh*cutoff_ah^exponent/sr2z2[ind2]/(1.+cutoff_ah^exp_minus_one);                                 % phi_bulge + phi_disc + phi_halo
      return Ekin + constant*Epot;
    }
    else if(eomecd == "circ")
    {
      dPotdr = Mb/(r2z2+bb^2)^1.5*r + Md/(r2+(ad+sz2bd2)^2)^1.5*r;
      dPotdr[ind1[ind11]] += Mh*(sr2z2[ind1[ind11]]/ah)^exp_minus_one/(r2z2[ind1[ind11]])/(1.+(sr2z2[ind1[ind11]]/ah)^exp_minus_one)/ah*r[ind1[ind11]];
      dPotdr[ind2] += Mh*(cutoff_ah)^exponent/(r2z2[ind2])^1.5/(1.+(cutoff_ah)^exp_minus_one)*r[ind2];
      return 10.*sqrt(r*dPotdr);
    }
  }
}%}}}

define MN_NFW() %{{{
%!%+
%\function{MN_NFW}
%\synopsis{Evaluate equations of motion, total energy, or circular velocity derived from a
%    potential with a Miyamoto & Nagai bulge and disk component and a Navarro, Frenk,
%    & White dark matter halo}
%\usage{MN_NFW(Double_Types t, m[6,n]; qualifiers)}
%\qualifiers{
%\qualifier{coords}{[\code{="cyl"}] Use cylindrical ("cyl") or cartesian ("cart") coordinates.}
%\qualifier{eomecd}{[\code{="eom"}] Return equations of motion ("eom"), total energy ("energy"),
%      circular velocity ("circ"), or Sun-Galactic center distance ("sgcd").}
%\qualifier{Mb}{[\code{=439}] Mass of bulge in Galactic mass units, see Irrgang et al. 2013.}
%\qualifier{Md}{[\code{=3096}] Mass of disc in Galactic mass units, see Irrgang et al. 2013.}
%\qualifier{Mh}{[\code{=142200}] Mass scale factor of halo in Galactic mass units, see Irrgang et al. 2013.}
%\qualifier{bb}{[\code{=0.236}] Bulge scale length, see Irrgang et al. 2013.}
%\qualifier{ad}{[\code{=3.262}] Disc scale length, see Irrgang et al. 2013.}
%\qualifier{bd}{[\code{=0.289}] Disc scale length, see Irrgang et al. 2013.}
%\qualifier{ah}{[\code{=45.02}] Halo scale length, see Irrgang et al. 2013.}
%}
%\description
%    Evaluate the equations of motion, the total energy, or the circular velocity at time 't'
%    derived from a potential with a Miyamoto & Nagai bulge and disk component and a Navarro,
%    Frenk, & White dark matter halo (see Model III in Irrgang et al., 2013, A&A, 549, A137)
%    using either cylindrical coordinates (r [kpc], phi [rad], z [kpc]) and their canonical
%    momenta vr [kpc/Myr], Lz [kpc^2/Myr], vz [kpc/Myr]) or cartesian coordinates (x [kpc],
%    y [kpc], z [kpc], vx [kpc/Myr], vy [kpc/Myr], vz [kpc/Myr]), see qualifier 'coords'.
%    Conservation of angular momentum Lz is implemented in the equations of motion for
%    cylindrical coordinates only. The total energy E_total [kpc^2/Myr^2] is not used to
%    integrate the equations of motion although being a conserved quantity, too. Therefore,
%    conservation of energy, i.e., of E_total, is a measure for the precision of the numerical
%    methods applied.
%
%    For computing orbits with n different initial conditions, the input parameter m is
%    a [6,n]-matrix with (qualifier("coords")=="cyl")   or (qualifier("coords")=="cart")
%       m[0,*] = r;                                        m[0,*] = x;
%       m[1,*] = phi;                                      m[1,*] = y;
%       m[2,*] = z;                                        m[2,*] = z;
%       m[3,*] = vr;                                       m[3,*] = vx;
%       m[4,*] = Lz;                                       m[4,*] = vy;
%       m[5,*] = vz;                                       m[5,*] = vz;
%    If the qualifier 'eomecd' is set to "eom", the function returns a [6,n]-matrix delta with
%       delta[0,*] = vr;                                   delta[0,*] = vx;
%       delta[1,*] = Lz/r^2; % = vphi                      delta[1,*] = vy;
%       delta[2,*] = vz;                                   delta[2,*] = vz;
%       delta[3,*] = -d/dr (Potential(r,z) + Lz^2/r^2);    delta[3,*] = -d/dx Potential(x,y,z);
%       delta[4,*] = 0; % -d/dphi Potential(r,z)           delta[4,*] = -d/dy Potential(x,y,z);
%       delta[5,*] = -d/dz Potential(r,z);                 delta[5,*] = -d/dz Potential(x,y,z);
%    If the qualifier 'eomecd' is set to "energy", the function returns a [1,n]-array storing
%    the total energy for each orbit:
%       E_total(r,z,vr,vz,Lz) = Double_Type[n] = 0.5*(vr^2+vz^2+Lz^2/r^2) + Potential(r,z)
%    or
%       E_total(x,y,z,vx,vy,vz) = Double_Type[n] = 0.5*(vx^2+vy^2+vz^2) + Potential(x,y,z)
%    If the qualifier 'eomecd' is set to "circ", the function returns a [1,n]-array storing
%    the circular velocity for each orbit:
%       v_circ(r,z) = Double_Type[n] = sqrt( r * d/dr Potential(r,z) )
%    If the qualifier 'eomecd' is set to "sgcd", the function returns the Sun-Galactic center
%    distance found to fit best to this potential.
%\example
%    delta = MN_NFW(0, m);
%    energy = MN_NFW(0, m; eomecd="energy");
%    v_circ = MN_NFW(0, m; eomecd="circ");
%    sgcd = MN_NFW(; eomecd="sgcd");
%\seealso{orbit_calculator, AS, MN_TF, plummer_MW}
%!%-
{
  % equations of motion, energy, circular velocity or Sun-Galactic center distance:
  variable eomecd = qualifier("eomecd", "eom");
  if(eomecd == "sgcd")
  {
    return 8.33;
  }
  else if(_NARGS!=2)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  else
  {
    variable coords = qualifier("coords", "cyl");
    variable t, input;
    (t, input) = ();
    input *= 1.;
    variable r, z, vz;
    if(coords=="cart")
    {
      variable x, y, vx, vy;
      x = input[0,*];
      y = input[1,*];
      z = input[2,*];
      vx = input[3,*];
      vy = input[4,*];
      vz = input[5,*];
      r = sqrt(x^2+y^2);
    }
    else % coords=="cyl"
    {
      variable phi, vr, Lz;
      r = input[0,*];
      phi = input[1,*];
      z = input[2,*];
      vr = input[3,*];
      Lz = input[4,*];
      vz = input[5,*];
    }
    % definition of gravitational potential parameters:
    variable Mb = qualifier("Mb", 439.);    % mass of the bulge
    variable Md = qualifier("Md", 3096.);   % mass of the disk
    variable Mh = qualifier("Mh", 142200.); % mass scale factor of the halo
    variable bb = qualifier("bb", 0.236);   % scale length bulge
    variable ad = qualifier("ad", 3.262);   % scale length disk
    variable bd = qualifier("bd", 0.289);   % scale length disk
    variable ah = qualifier("ah", 45.02);   % scale length halo

    % variable kpcmyr_to_kms = 977.7736364875057; % = conversion factor from kpc/myr to km/s = 3.0856775975*10^16 / (10^6 * 3.15582 * 10^7);
    variable constant = 1.0459799346702096e-04; % 100./kpcmyr_to_kms^2; factor 100 because potential is given in 100km^2/s^2
    % store frequently appearing expressions to save runtime:
    variable r2 = r^2;
    variable z2 = z^2;
    variable r2z2 = r2+z2;
    variable sr2z2 = sqrt(r2z2);
    variable sz2bd2 = sqrt(z2+bd^2);
    variable ind1, ind2, ind3, ind4;
    ind1 = where(sr2z2 < 1e-5, &ind2); % ind1 to avoid singularities when falling into the Galactic Center
    if(eomecd == "eom")
    {
      % store frequently appearing expressions to save runtime:
      variable dPot_bulge = -Mb/(r2z2+bb^2)^1.5;
      variable dPot_disc = -Md/(r2+(ad+sz2bd2)^2)^1.5;
      variable dPot_halo = Mh/r2z2/ah/(1.+sr2z2/ah)-Mh*log(1.+sr2z2/ah)/(r2z2)^1.5;

      % calculate derivatives of the potential with respect to z (dPotdz):
      variable dPotdz = constant*(dPot_bulge*z+dPot_disc*(ad+sz2bd2)/sz2bd2*z);
      dPotdz[ind2] += constant*dPot_halo[ind2]*z[ind2];

      variable ret = Double_Type[6,length(r)];

      if(coords=="cart")
      {
	% calculate derivatives of the potential with respect to x and y (dPotdx, dPotdy):
	variable dPotdx = constant*(dPot_bulge + dPot_disc)*x;
	variable dPotdy = constant*(dPot_bulge + dPot_disc)*y;
	dPotdx[ind2] += constant*dPot_halo[ind2]*x[ind2];
	dPotdy[ind2] += constant*dPot_halo[ind2]*y[ind2];

	ret[0,*] = vx;
	ret[1,*] = vy;
	ret[2,*] = vz;
	ret[3,*] = dPotdx;
	ret[4,*] = dPotdy;
	ret[5,*] = dPotdz;
	return ret;
      }
      else % coords=="cyl"
      {
	ind3 = where( Lz!=0, &ind4 );
	% calculate derivatives of the potential with respect to r (dPotdr):
	variable dPotdr = constant*(dPot_bulge+dPot_disc)*r;
	dPotdr[ind2] += constant*dPot_halo[ind2]*r[ind2];
	dPotdr[ind3] += (Lz[ind3])^2/(r[ind3])^3;

	ret[0,*] = vr;
	ret[1,ind3] = (Lz[ind3])/(r2[ind3]);
	ret[1,ind4] = 0;
	ret[2,*] = vz;
	ret[3,*] = dPotdr;
	ret[4,*] = 0*Lz;
	ret[5,*] = dPotdz;
	return ret;
      }
    }
    else if(eomecd == "energy")
    {
      % calculate the kinetic and potential energies (Ekin, Epot):
      variable Ekin;
      if(coords=="cart")
      {
	Ekin = 0.5*(vx^2+vy^2+vz^2);
      }
      else % coords=="cyl"
      {
	Ekin = 0.5*(vr^2+vz^2);
	ind3 = where( Lz!=0 );
	Ekin[ind3] += 0.5*(Lz[ind3])^2/(r2[ind3]);
      }
      variable Epot = -Mb/sqrt(r2z2+bb^2)-Md/sqrt(r2+(ad+sz2bd2)^2); % phi_bulge + phi_disc
      Epot[ind1] += -Mh/ah;                                          % phi_bulge + phi_disc + phi_halo
      Epot[ind2] += -Mh*log(1.+sr2z2[ind2]/ah)/sr2z2[ind2];          % phi_bulge + phi_disc + phi_halo
      return Ekin + constant*Epot;
    }
    else if(eomecd == "circ")
    {
      dPotdr = Mb/(r2z2+bb^2)^(1.5)*r+Md/(r2+(ad+sz2bd2)^2)^(1.5)*r;
      dPotdr[ind2] += -Mh/(r2z2[ind2])/ah*r[ind2]/(1.+sr2z2[ind2]/ah)+Mh*log(1.+sr2z2[ind2]/ah)/(r2z2[ind2])^(1.5)*r[ind2];
      return 10.*sqrt(r*dPotdr);
    }
  }
}%}}}

define MN_TF() %{{{
%!%+
%\function{MN_TF}
%\synopsis{Evaluate equations of motion, total energy, or circular velocity derived from a
%    potential with a Miyamoto & Nagai bulge and disk component and a truncated, flat
%    rotation curve halo model}
%\usage{MN_TF(Double_Types t, m[6,n]; qualifiers)}
%\qualifiers{
%\qualifier{coords}{[\code{="cyl"}] Use cylindrical ("cyl") or cartesian ("cart") coordinates.}
%\qualifier{eomecd}{[\code{="eom"}] Return equations of motion ("eom"), total energy ("energy"),
%      circular velocity ("circ"), or Sun-Galactic center distance ("sgcd").}
%\qualifier{Mb}{[\code{=175}] Mass of bulge in Galactic mass units, see Irrgang et al. 2013.}
%\qualifier{Md}{[\code{=2829}] Mass of disc in Galactic mass units, see Irrgang et al. 2013.}
%\qualifier{Mh}{[\code{=69725}] Mass of halo in Galactic mass units, see Irrgang et al. 2013.}
%\qualifier{bb}{[\code{=0.184}] Bulge scale length, see Irrgang et al. 2013.}
%\qualifier{ad}{[\code{=4.85}] Disc scale length, see Irrgang et al. 2013.}
%\qualifier{bd}{[\code{=0.305}] Disc scale length, see Irrgang et al. 2013.}
%\qualifier{ah}{[\code{=200}] Halo scale length, see Irrgang et al. 2013.}
%}
%\description
%    Evaluate the equations of motion, the total energy, or the circular velocity at time 't'
%    derived from a potential with a Miyamoto & Nagai bulge and disk component and a truncated,
%    flat rotation curve dark matter halo model (see Model II in Irrgang et al., 2013, A&A,
%    549, A137) using either cylindrical coordinates (r [kpc], phi [rad], z [kpc]) and their
%    canonical momenta vr [kpc/Myr], Lz [kpc^2/Myr], vz [kpc/Myr]) or cartesian coordinates
%    (x [kpc], y [kpc], z [kpc], vx [kpc/Myr], vy [kpc/Myr], vz [kpc/Myr]), see qualifier
%    'coords'. Conservation of angular momentum Lz is implemented in the equations of motion
%    for cylindrical coordinates only. The total energy E_total [kpc^2/Myr^2] is not used to
%    integrate the equations of motion although being a conserved quantity, too. Therefore,
%    conservation of energy, i.e., of E_total, is a measure for the precision of the numerical
%    methods applied.
%
%    For computing orbits with n different initial conditions, the input parameter m is
%    a [6,n]-matrix with (qualifier("coords")=="cyl")   or (qualifier("coords")=="cart")
%       m[0,*] = r;                                        m[0,*] = x;
%       m[1,*] = phi;                                      m[1,*] = y;
%       m[2,*] = z;                                        m[2,*] = z;
%       m[3,*] = vr;                                       m[3,*] = vx;
%       m[4,*] = Lz;                                       m[4,*] = vy;
%       m[5,*] = vz;                                       m[5,*] = vz;
%    If the qualifier 'eomecd' is set to "eom", the function returns a [6,n]-matrix delta with
%       delta[0,*] = vr;                                   delta[0,*] = vx;
%       delta[1,*] = Lz/r^2; % = vphi                      delta[1,*] = vy;
%       delta[2,*] = vz;                                   delta[2,*] = vz;
%       delta[3,*] = -d/dr (Potential(r,z) + Lz^2/r^2);    delta[3,*] = -d/dx Potential(x,y,z);
%       delta[4,*] = 0; % -d/dphi Potential(r,z)           delta[4,*] = -d/dy Potential(x,y,z);
%       delta[5,*] = -d/dz Potential(r,z);                 delta[5,*] = -d/dz Potential(x,y,z);
%    If the qualifier 'eomecd' is set to "energy", the function returns a [1,n]-array storing
%    the total energy for each orbit:
%       E_total(r,z,vr,vz,Lz) = Double_Type[n] = 0.5*(vr^2+vz^2+Lz^2/r^2) + Potential(r,z)
%    or
%       E_total(x,y,z,vx,vy,vz) = Double_Type[n] = 0.5*(vx^2+vy^2+vz^2) + Potential(x,y,z)
%    If the qualifier 'eomecd' is set to "circ", the function returns a [1,n]-array storing
%    the circular velocity for each orbit:
%       v_circ(r,z) = Double_Type[n] = sqrt( r * d/dr Potential(r,z) )
%    If the qualifier 'eomecd' is set to "sgcd", the function returns the Sun-Galactic center
%    distance found to fit best to this potential.
%\example
%    delta = MN_TF(0, m);
%    energy = MN_TF(0, m; eomecd="energy");
%    v_circ = MN_TF(0, m; eomecd="circ");
%    sgcd = MN_TF(; eomecd="sgcd");
%\seealso{orbit_calculator, AS, MN_NFW, plummer_MW}
%!%-
{
  % equations of motion, energy, circular velocity or Sun-Galactic center distance:
  variable eomecd = qualifier("eomecd", "eom");
  if(eomecd == "sgcd")
  {
    return 8.35;
  }
  else if(_NARGS!=2)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  else
  {
    variable coords = qualifier("coords", "cyl");
    variable t, input;
    (t, input) = ();
    input *= 1.;
    variable r, z, vz;
    if(coords=="cart")
    {
      variable x, y, vx, vy;
      x = input[0,*];
      y = input[1,*];
      z = input[2,*];
      vx = input[3,*];
      vy = input[4,*];
      vz = input[5,*];
      r = sqrt(x^2+y^2);
    }
    else % coords=="cyl"
    {
      variable phi, vr, Lz;
      r = input[0,*];
      phi = input[1,*];
      z = input[2,*];
      vr = input[3,*];
      Lz = input[4,*];
      vz = input[5,*];
    }
    % definition of gravitational potential parameters:
    variable Mb = qualifier("Mb", 175.);   % mass of the bulge
    variable Md = qualifier("Md", 2829.);  % mass of the disk
    variable Mh = qualifier("Mh", 69725.); % mass of the halo
    variable bb = qualifier("bb", 0.184);  % scale length bulge
    variable ad = qualifier("ad", 4.85);   % scale length disk
    variable bd = qualifier("bd", 0.305);  % scale length disk
    variable ah = qualifier("ah", 200.);   % scale length halo

    % variable kpcmyr_to_kms = 977.7736364875057; % = conversion factor from kpc/myr to km/s = 3.0856775975*10^16 / (10^6 * 3.15582 * 10^7);
    variable constant = 1.0459799346702096e-04; % 100./kpcmyr_to_kms^2; factor 100 because potential is given in 100km^2/s^2
    % store frequently appearing expressions to save runtime:
    variable r2 = r^2;
    variable z2 = z^2;
    variable r2z2 = r2+z2;
    variable sr2z2 = sqrt(r2z2);
    variable sz2bd2 = sqrt(z2+bd^2);
    variable sr2z2ah2 = sqrt(r2z2+ah^2);
    variable ind1, ind2, ind3, ind4;
    variable eps = 1e-5;
    ind1 = where(sr2z2 < eps, &ind2); % ind1 to avoid singularities when falling into the Galactic center
    if(eomecd == "eom")
    {
      % store frequently appearing expressions to save runtime:
      variable dPot_bulge = -Mb/(r2z2+bb^2)^1.5;
      variable dPot_disc = -Md/(r2+(ad+sz2bd2)^2)^1.5;
      variable dPot_halo = -Mh/sr2z2ah2/r2z2;

      % calculate derivatives of the potential with respect to z (dPotdz):
      variable dPotdz = constant*(dPot_bulge*z+dPot_disc*(ad+sz2bd2)/sz2bd2*z);
      dPotdz[ind2] += constant*dPot_halo[ind2]*z[ind2];

      variable ret = Double_Type[6,length(r)];

      if(coords=="cart")
      {
	% calculate derivatives of the potential with respect to x and y (dPotdx, dPotdy):
	variable dPotdx = constant*(dPot_bulge + dPot_disc)*x;
	variable dPotdy = constant*(dPot_bulge + dPot_disc)*y;
	dPotdx[ind2] += constant*dPot_halo[ind2]*x[ind2];
	dPotdy[ind2] += constant*dPot_halo[ind2]*y[ind2];

	ret[0,*] = vx;
	ret[1,*] = vy;
	ret[2,*] = vz;
	ret[3,*] = dPotdx;
	ret[4,*] = dPotdy;
	ret[5,*] = dPotdz;
	return ret;
      }
      else % coords=="cyl"
      {
	ind3 = where( Lz!=0, &ind4 );
	% calculate derivatives of the potential with respect to r (dPotdr):
	variable dPotdr = constant*(dPot_bulge+dPot_disc)*r;
	dPotdr[ind2] += constant*dPot_halo[ind2]*r[ind2];
	dPotdr[ind3] += (Lz[ind3])^2/(r[ind3])^3;

	ret[0,*] = vr;
	ret[1,ind3] = (Lz[ind3])/(r2[ind3]);
	ret[1,ind4] = 0;
	ret[2,*] = vz;
	ret[3,*] = dPotdr;
	ret[4,*] = 0*Lz;
	ret[5,*] = dPotdz;
	return ret;
      }
    }
    else if(eomecd == "energy")
    {
      % calculate the kinetic and potential energies (Ekin, Epot):
      variable Ekin;
      if(coords=="cart")
      {
	Ekin = 0.5*(vx^2+vy^2+vz^2);
      }
      else % coords=="cyl"
      {
	Ekin = 0.5*(vr^2+vz^2);
	ind3 = where( Lz!=0 );
	Ekin[ind3] += 0.5*(Lz[ind3])^2/(r2[ind3]);
      }
      variable Epot = -Mb/sqrt(r2z2+bb^2)-Md/sqrt(r2+(ad+sz2bd2)^2); % phi_bulge + phi_disc
      Epot[ind1] += -Mh/ah*log((sqrt(eps^2+ah^2)+ah)/eps);           % phi_bulge + phi_disc + phi_halo
      Epot[ind2] += -Mh/ah*log((sr2z2ah2[ind2]+ah)/sr2z2[ind2]);     % phi_bulge + phi_disc + phi_halo
      return Ekin + constant*Epot;
    }
    else if(eomecd == "circ")
    {
      dPotdr = Mb/(r2z2+bb^2)^(1.5)*r+Md/(r2+(ad+sz2bd2)^2)^(1.5)*r;
      dPotdr[ind2] += Mh/sr2z2ah2[ind2]/r2z2[ind2]*r[ind2];
      return 10.*sqrt(r*dPotdr);
    }
  }
}%}}}

define plummer_MW() %{{{
%!%+
%\function{plummer_MW}
%\synopsis{Alternative model potential for the function 'orbit_calculator'}
%\usage{plummer_MW(Double_Types t, m[6,n]; qualifiers)}
%\qualifiers{
%\qualifier{plummer_spheres}{Structure whose fields are again structures with fields 't' [Myr],
%      'x' [kpc], 'y' [kpc], 'z' [kpc], 'psa' [Msun/Mgal*constant] (see notes), and 'psb'
%      [kpc^2] describing the orbits and shapes of the Plummer spheres.
%      Always make sure that the tabulated times 't[*]' are in monotonic increasing order
%      if 't[-1]' is positive or in monotonic decreasing order if 't[-1]' is negative.}
%\qualifier{MW_potential}{[\code{="AS"}]: Function ("AS", "MN_NFW", or "MN_TF"), which evaluates the
%      equations of motion that result from a model for the gravitational potential of
%      the Milky Way.}
%\qualifier{All qualifiers from the Milky Way model potential (see qualifier 'MW_potential').}{}
%\qualifier{All qualifiers from the function 'plummer_interaction_kernel'.}{}
%}
%\description
%    This function provides an alternative model for the gravitational potential of the
%    Milky Way which can be used by the function 'orbit_calculator'. The gravitational
%    forces of a standard Milky Way potential (see qualifier 'model') are combined with
%    those arising from the interaction with a number of moving Plummer spheres (see
%    function 'plummer_interaction_kernel' and qualifier 'plummer_spheres') to determine
%    the acceleration of n independent test particles at time 't'.
%\notes
%    Because of the unit convention used for the potentials of the Milky Way, the field
%    'psa' of the qualifier 'plummer_spheres', which is assumed to be the mass of the
%    respective Plummer sphere in solar masses, has to be converted to Galactic mass units
%    and then multiplied with a constant accounting for the remaining unit conversions
%    (see example below). The units of 'psb' have to be kpc^2.
%\example
%    % Test particle affected by the Milky Way and satellite galaxies:
%    t_end = -100; % integration time in Myr
%    model = "AS"; % Milky Way mass model
%    s = properties_satellite_galaxies();
%    i = struct{ x, y, z, vx, vy, vz, psa, psb };
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
%    ps = N_body_simulation(i, t_end; kernel="N_body_simulation_MW_kernel", psa=i.psa, psb=i.psb, model=model);
%    % ps contains time-dependent coordinates of Plummer spheres
%    % add information about shape of the Plummer spheres:
%    j = 0;
%    foreach field (get_struct_field_names(ps))
%    {
%      temp = struct{ psa=i.psa[j], psb=i.psb[j] };
%      set_struct_field(ps, field, struct_combine(get_struct_field(ps, field), temp));
%      j++;
%    };
%    % compute trajectories of test particles:
%    s = orbit_calculator(4,38,12.8,-54,33,12,61,723,0.86,0.57,t_end; set, model="plummer_MW", MW_potential=model, plummer_spheres=ps);
%    plot(s.tr.o0.x,s.tr.o0.y);
%    % without satellite galaxies:
%    s = orbit_calculator(4,38,12.8,-54,33,12,61,723,0.86,0.57,t_end; set, model=model);
%    oplot(s.tr.o0.x,s.tr.o0.y);
%\seealso{orbit_calculator, plummer_interaction_kernel, AS, MN_NFW, MN_TF}
%!%-
{
  variable MW_potential = qualifier("MW_potential", "AS"); % function evaluating the equations of motions of the Milky Way potential
  if(__get_reference(MW_potential)==NULL or (MW_potential!="AS" and MW_potential!="MN_NFW" and MW_potential!="MN_TF"))
  {
    _pop_n(_NARGS); % remove function arguments from stack
    throw UsageError, sprintf("Usage error in '%s': Invalid input for qualifier 'MW_potential'.", _function_name());
  }
  MW_potential = __get_reference(MW_potential);
  if(qualifier("eomecd")=="sgcd")
    return (@MW_potential)(;; __qualifiers);
  else if(_NARGS!=2)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': Wrong number of arguments.", _function_name());
  }
  variable ps;
  if(qualifier_exists("plummer_spheres"))
    ps = qualifier("plummer_spheres");
  else % create structure with no fields
  {
    ps = @Struct_Type(String_Type[0]);
  }
  variable t, m;
  (t, m) = ();
  variable r = (@MW_potential)(t,m;; __qualifiers); % [6,n]-matrix with velocities and forces
  if(qualifier("eomecd")=="circ")
    return r;
  variable r2 = plummer_interaction_kernel(t,m,ps;; __qualifiers); % [3,n]-matrix with forces only
  if(qualifier("eomecd")=="eom")
  {
    r[3,*] += r2[0,*]; % sum forces for first coordinate
    r[4,*] += r2[1,*]; % sum forces for second coordinate
    r[5,*] += r2[2,*]; % sum forces for third coordinate
  }
  else if(qualifier("eomecd")=="energy")
    r += r2; % sum energies
  return r;
}%}}}

define orbit_calculator() %{{{
%!%+
%\function{orbit_calculator}
%\synopsis{Calculate orbits of test particles in a Galactic gravitational potential}
%\usage{orbit_calculator(Double_Types ah[], am[], as[], dd[], dm[], ds[], dist[], vrad[], pma_cos_d[], pmd[], t_end; qualifiers)
%    % or (for error propagation)
%    orbit_calculator(Double_Types ah, am, as, dd, dm, ds, dist, dist_sigma[], vrad, vrad_sigma[], pma_cos_d, pma_cos_d_sigma[], pmd, pmd_sigma[], t_end; qualifiers)}
%\altusage{orbit_calculator(Double_Types x[], y[], z[], vx[], vy[], vz[], t_end; qualifiers)}
%\qualifiers{
%\qualifier{coords}{[\code{="cyl"}]: Use cylindrical ("cyl") or cartesian ("cart") coordinates for the internal
%      computations. Note that circular orbits like that of the Sun are computed faster in cylindrical
%      coordinates whereas cartesian coordinates are much more efficient for straight-line trajectories
%      or those that come very close to the z-axis where angular momentum terms slow down cylindrical
%      calculations.}
%\qualifier{dt}{Deactivate adaptive mode and use this fixed stepsize instead.}
%\qualifier{model}{[\code{="AS"}]: Function ("AS", "MN_NFW", "MN_TF", or "plummer_MW") evaluating the equations
%      of motion, circular velocity, and energy of the model potential.}
%\qualifier{MC_runs}{[\code{=nint(10^5)}]: Number of Monte Carlo realizations in the case that 1-sigma errors are given.}
%\qualifier{ODE_solver}{[\code{="RKCK"}]: Choose among three different Runge-Kutta (RK) integration methods:
%      "RKF": RK-Fehlberg, "RKCK": RK-Cash-Karp, "RKDP": RK-Dormand-Prince.}
%\qualifier{parallax_pma_corr}{[\code{=0}]: Correlation between parallax and proper motion in right ascension.}
%\qualifier{parallax_pmd_corr}{[\code{=0}]: Correlation between parallax and proper motion in declination.}
%\qualifier{pma_pmd_corr}{[\code{=0}]: Correlation between proper motion in right ascension and in declination.}
%\qualifier{disk}{[\code{=struct{radius = 0, height = 0.1, x = 0, y = 0, z = 0, crossings = 1}}]: If disk.radius > 0,
%      orbit integration will be stopped at the moment a trajectory has crossed a horizontal plane
%      located at z = disk.z + disk.height * Gaussian-random-number inside a circle of radius
%      disk.radius centered at (disk.x, disk.y) for the disk.crossings-th time.}
%\qualifier{seed}{[\code{=_time()}]: Seed the random number generator via the function 'seed_random'.}
%\qualifier{set}{[\code{=0}]: If present, trajectories will be saved ("Save entire trajectories"). As
%      this can be very memory-consuming for a large number of orbits, one can additionally
%      use the value of this qualifier to specify a lower limit on the time difference of
%      two consecutive moments of time that will be saved.}
%\qualifier{stff}{"Save to fits files": Prefix of fits files to which initial and final structures are written.}
%\qualifier{SunGCDist}{By default, the Sun-Galactic center distance is taken from the current model.
%      Use this qualifier to explicitly set a distance in kpc.}
%\qualifier{tolerance}{[\code{=1e-8}]: Absolute error control tolerance; lower limit: 1e-15.}
%\qualifier{verbose}{Show intermediate times t.}
%\qualifier{Any qualifiers from 'cel2gal' and the model potential function except 'vlsr' and 'eomecd'.}{
%      Important note: for consistency, the local standard of rest velocity vlsr is calculated from the
%      circular velocity of the current model potential evaluated at (r=SunGCDist, z=0).}
%}
%\description
%    Calculate orbits of test particles in a Galactic gravitational potential from given
%    initial conditions. The latter can be given either in celestial or Galactic cartesian
%    coordinates (see the help on the function 'cel2gal' for format and unit conventions).
%    Integration starts at time t=0 and ends at t=t_end [Myr], which is the last input
%    parameter. A negative t_end implies backward integration, which is e.g. useful to
%    trace back orbits in time. The potential and its equations of motion are outsourced
%    to a function specified by the qualifier 'model'. In this way, switching from one model
%    to another one is simply done by changing the before mentioned qualifier. Make always
%    use of cylindrical coordinates (r [kpc], phi [rad], z [kpc]) and their canonical momenta
%    (vr [kpc/Myr], Lz [kpc^2/Myr], vz [kpc/Myr]) as well as of cartesian coordinates (x [kpc],
%    y [kpc], z [kpc], vx [kpc/Myr], vy [kpc/Myr], vz [kpc/Myr]) to set up the equations of
%    motion (see the qualifier 'coords'). To numerically integrate the coupled differential
%    equations, an adaptive Runge-Kutta method of fourth/fifth order is used (see qualifier
%    'ODE_solver'). The stepsize is hereby controlled such that for each step an absolute
%    accuracy in coordinates (in units of kpc) and velocity components (in units of km/s) is
%    achieved that is smaller than given by the qualifier 'tolerance'. The function is optimized
%    for multi-orbit calculations, i.e., when the input parameters are either arrays or 1-sigma
%    uncertainties are given in addition. The latter are used to create Gaussian distributed
%    initial conditions to perform error propagation based on a number of Monte Carlo runs as
%    specified by the qualifier 'MC_runs'. To assign asymmetric uncertainties, use an array
%    of length two, i.e., [sigma_plus, sigma_minus], instead of a single number. The Gaussian
%    distribution is then split up into two Gaussian distributions, one with standard deviation
%    sigma_plus (for values larger than the respective input parameter) and one with sigma_minus
%    (else). To account for correlations between the distance (or alternatively the parallax,
%    see the qualifier 'parallax' in the function 'cel2gal'), proper motions in right ascension,
%    and proper motion in declination, make use of the qualifiers 'parallax_pma_corr',
%    'parallax_pmd_corr', and 'pma_pmd_corr'. Note that asymmetric uncertainties and
%    parameter correlations are mutually exclusive for individual parameters. All orbits are
%    computed simultaneously and on the same time grid. Stepsize control is hereby based on
%    the worst-offender principle. The function returns one structure with the two fields
%    "i" (initial) and "f" (final) (both again structures) containing the initial and final
%    Galactic cartesian coordinates (in kpc) and velocities (in km/s) as well as the z-component
%    of angular momentum Lz (in kpc^2/Myr) and total energy E_total = E_kin + E_pot (in kpc^2/Myr^2).
%    To see whether conservation of energy or conservation of angular momentum is implemented
%    in the equations of motion or not, have a look at the help of the outsourced potential
%    function. The final structure contains also the minimum and maximum Galactocentric distances
%    Rmin = min(R(t)) and Rmax = max(R(t)) with R(t) = sqrt(x(t)^2+y(t)^2+z(t)^2) and - if the
%    qualifier 'coords' is set to "cyl" - the number of revolutions about the Galactic z-axis
%    (negative values imply a motion in direction of Galactic rotation, i.e. prograde orbits,
%    while positive ones imply retrograde orbits). To save the initial and final structures to
%    fits files, set the qualifier 'stff' to the desired prefix of the filename. If not only
%    the initial and final situation is of interest, but rather the entire trajectories, use
%    the qualifier 'set'. In this case, the additional field "tr" (trajectory) (again a structure,
%    one field per orbit ("o1", "o2", ...)) is added to the returned structure containing all
%    orbits. For tracing back orbits to the Galactic disk, use the 'disk' qualifier to stop
%    individual calculations at the moment a trajectory has crossed the disk for a certain
%    number of times.
%\example
%    s = orbit_calculator(12,22,29.6,40,49,36,3.078,262,-13.52,16.34,-1000; disk = struct{radius=50, height=0.2, x=0, y=0, z=0, crossings=1});
%    s = orbit_calculator(12,22,29.6,40,49,36,3.078,[0.6,0.3],262,5,-13.52,1.31,16.34,1.37,-1000; disk = struct{radius=50, height=0.2, x=0, y=0, z=0, crossings=1}, stff="HIP60350", MC_runs=100);
%    s = orbit_calculator(-8.4,0,0,0,242,0,250; set, model="MN_TF");
%    plot(s.tr.o0.x, s.tr.o0.y);
%    s = orbit_calculator([8:10:#500], [0:1:#500], [4:5:#500], [0:0:#500], [210:230:#500], [-10:-50:#500], 1000);
%
%    % Example using parallax, proper motions, and correlation parameters from Gaia:
%    s = orbit_calculator(12,22,29.6,40,49,36,0.325,0.3,262,5,-13.52,1.31,16.34,1.37,-1; parallax, parallax_pma_corr=0.1, parallax_pmd_corr=0.2, pma_pmd_corr=0.75);
%
%    % Example using the spectroscopic distance and only proper motions from Gaia:
%    s = orbit_calculator(12,22,29.6,40,49,36,3.077,[0.6,0.3],262,5,-13.52,1.31,16.34,1.37,-1; pma_pmd_corr=0.75);
%\seealso{cel2gal, AS, MN_NFW, MN_TF, plummer_MW, xfig_3d_orbit_on_cube}
%!%-
{
  % =====================
  % processing the input:
  variable model = qualifier("model", "AS"); % function evaluating the equations of motions, circular velocity, energy of the model potential
  if(__get_reference(model)==NULL or (model!="AS" and model!="MN_NFW" and model!="MN_TF" and model!="plummer_MW"))
  {
    _pop_n(_NARGS); % remove function arguments from stack
    throw UsageError, sprintf("Usage error in '%s': wrong input for qualifier 'model'.", _function_name());
  }
  variable coords = qualifier("coords", "cyl");
  if(coords != "cyl" and coords != "cart")
  {
    _pop_n(_NARGS); % remove function arguments from stack
    throw UsageError, sprintf("Usage error in '%s': wrong input for qualifier 'coords'.", _function_name());
  }
  model = __get_reference(model); % function evaluating the equations of motions, circular velocity, energy of the model potential
  variable dt_fixed = qualifier_exists("dt"); % fixed stepsize for integrator
  variable eps = _max( qualifier("tolerance", 1e-8), 1e-15 ); % error control tolerance
  variable disk = qualifier("disk", struct{radius = 0, height = 0.1, x = 0, y = 0, z = 0, crossings = 1});
  % If disk.radius > 0, orbit integration will be stopped at the moment a trajectory has crossed a horizontal plane located at
  % z = disk.z + disk.height * Gaussian-random-number inside a circle of radius disk.radius centered at (disk.x, disk.y) for the disk.crossings-th time.
  if(typeof(disk)!=Struct_Type)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    throw UsageError, sprintf("Usage error in '%s': The qualifier 'disk' has to be a Struct_Type.", _function_name());
  }
  if(struct_field_exists(disk, "radius")==0 or struct_field_exists(disk, "height")==0 or struct_field_exists(disk, "x")==0 or struct_field_exists(disk, "y")==0 or struct_field_exists(disk, "z")==0 or struct_field_exists(disk, "crossings")==0)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    throw UsageError, sprintf("Usage error in '%s': The qualifier 'disk' has to be a Struct_Type with fields 'radius', 'height', 'x', 'y', 'z', and 'crossings'.", _function_name());
  }
  if(typeof(disk.crossings)!=Integer_Type || disk.crossings<1)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    throw UsageError, sprintf("Usage error in '%s': The qualifier 'disk.crossings' has to be a positive Integer_Type.", _function_name());
  }
  variable set = qualifier_exists("set"); % "save entire trajectory"
  variable set_threshold = qualifier("set", 0);
  if(typeof(set_threshold)==Null_Type) % to cover cases where the qualifier 'set' is present but without a specified value
    set_threshold = 0;
  variable verbose = qualifier_exists("verbose");
  % algorithm for solving the ordinary differential equations (ODEs): Runge-Kutta-Fehlberg ("RKF"), Runge-Kutta-Cash-Karp ("RKCK"), Runge-Kutta-Dormand-Prince ("RKDP"):
  variable method = qualifier("ODE_solver", "RKCK");
  % ============================================================================
  variable qualies = __qualifiers;
  qualies = struct_combine(qualies, "eomecd");
  qualies = struct_combine(qualies, "vlsr");
  qualies = struct_combine(qualies, "SunGCDist");
  variable SunGCDist = (@model)(; eomecd="sgcd"); % Sun-Galactic center distance from the model
  if(qualifier_exists("SunGCDist"))
    SunGCDist = qualifier("SunGCDist");
  set_struct_field(qualies, "SunGCDist", SunGCDist); % qualifier 'SunGCDist' in function cel2gal is set according to the current potential
  variable temp0 = 0*Double_Type[6,length(SunGCDist)]; temp0[0,*] = SunGCDist;
  set_struct_field(qualies, "eomecd", "circ"); % important for the following line
  set_struct_field(qualies, "vlsr", ((@model)(0, temp0;; qualies))[0] ); % qualifier 'vlsr' in function cel2gal is set according to the current potential
  set_struct_field(qualies, "eomecd", "eom"); % set back to default
  qualies = struct_combine(qualies, "coords");
  set_struct_field(qualies, "coords", coords);
  % ============================================================================
  if(qualifier_exists("stff")) % some keywords for fits-header to know what input parameters or qualifiers were used for this computation
    variable keys = struct{SunGCDist = string(median(SunGCDist))};
  variable x, y, z, vx, vy, vz, t_end; % t_end: maximum integration time in Myrs

  if(_NARGS==11)
  {
    variable ah, am, as, dd, dm, ds, dist, rv, pma, pmd;
    (ah, am, as, dd, dm, ds, dist, rv, pma, pmd, t_end) = ();
    ah = [1.*ah]; am = [1.*am]; as = [1.*as]; dd = [1.*dd]; dm = [1.*dm]; ds = [1.*ds]; dist = [1.*dist]; rv = [1.*rv]; pma = [1.*pma]; pmd = [1.*pmd];
    (x, y, z, vx, vy, vz) = cel2gal(ah, am, as, dd, dm, ds, dist, rv, pma, pmd;; qualies);
  }

  else if(_NARGS==15)
  {
    variable dist_sigma, rv_sigma, pma_sigma, pmd_sigma;
    (ah, am, as, dd, dm, ds, dist, dist_sigma, rv, rv_sigma, pma, pma_sigma, pmd, pmd_sigma, t_end) = ();
    variable MC_runs = nint(qualifier("MC_runs", nint(10^5)));
    variable parallax_pma_corr = qualifier("parallax_pma_corr", 0);
    if(abs(parallax_pma_corr)>1)
      throw UsageError, sprintf("Usage error in '%s': Qualifier 'parallax_pma_corr' has to be between -1 and 1.", _function_name());
    variable parallax_pmd_corr = qualifier("parallax_pmd_corr", 0);
    if(abs(parallax_pmd_corr)>1)
      throw UsageError, sprintf("Usage error in '%s': Qualifier 'parallax_pmd_corr' has to be between -1 and 1.", _function_name());
    variable pma_pmd_corr = qualifier("pma_pmd_corr", 0);
    if(abs(pma_pmd_corr)>1)
      throw UsageError, sprintf("Usage error in '%s': Qualifier 'pma_pmd_corr' has to be between -1 and 1.", _function_name());
    variable seed = nint(qualifier("seed", _time()));
    seed_random(seed); % initialize the seed according to qualifier or time
    variable rv_distr;
    if(length(rv_sigma)==2)
    {
      rv_distr = grand(MC_runs);
      rv_distr[where(rv_distr>0)] *= rv_sigma[0];
      rv_distr[where(rv_distr<0)] *= rv_sigma[1];
      rv_distr += rv;
    }
    else
      rv_distr = rv+grand(MC_runs)*rv_sigma[0];
    variable cov_mat = 0.*Double_Type[3,3]; % initialize covariance matrix between parallax (or distance), pma, and pmd with zeros
    variable distr = Double_Type[3,MC_runs];
    variable len = length(dist_sigma);
    if(len==2 and (parallax_pma_corr!=0 or parallax_pmd_corr!=0))
      throw UsageError, sprintf("Usage error in '%s': Asymmetric uncertainties and correlation parameters cannot be used together.", _function_name());
    if(parallax_pma_corr==0 and parallax_pmd_corr==0)
    {
      cov_mat[0,0] = 1; cov_mat[1,0] = 0; cov_mat[0,1] = 0; cov_mat[2,0] = 0; cov_mat[0,2] = 0;
      if(len==2)
      {
	distr[0,*] = grand(MC_runs);
	distr[0,where(distr[0,*]>0)] *= dist_sigma[0];
	distr[0,where(distr[0,*]<0)] *= dist_sigma[1];
      }
      else
	distr[0,*] = grand(MC_runs)*dist_sigma[0];
    }
    else
    {
      cov_mat[0,0] = (dist_sigma[0])^2; cov_mat[1,0] = parallax_pma_corr*dist_sigma[0]*pma_sigma[0]; cov_mat[0,1] = cov_mat[1,0];
      cov_mat[2,0] = parallax_pmd_corr*dist_sigma[0]*pmd_sigma[0]; cov_mat[0,2] = cov_mat[2,0];
      distr[0,*] = grand(MC_runs);
    }
    len = length(pma_sigma);
    if(len==2 and (parallax_pma_corr!=0 or pma_pmd_corr!=0))
      throw UsageError, sprintf("Usage error in '%s': Asymmetric uncertainties and correlation parameters cannot be used together.", _function_name());
    if(parallax_pma_corr==0 and pma_pmd_corr==0)
    {
      cov_mat[1,1] = 1; cov_mat[1,0] = 0; cov_mat[0,1] = 0; cov_mat[1,2] = 0; cov_mat[2,1] = 0;
      if(len==2)
      {
	distr[1,*] = grand(MC_runs);
	distr[1,where(distr[1,*]>0)] *= pma_sigma[0];
	distr[1,where(distr[1,*]<0)] *= pma_sigma[1];
      }
      else
	distr[1,*] = grand(MC_runs)*pma_sigma[0];
    }
    else
    {
      cov_mat[1,1] = (pma_sigma[0])^2; cov_mat[1,0] = parallax_pma_corr*dist_sigma[0]*pma_sigma[0]; cov_mat[0,1] = cov_mat[1,0];
      cov_mat[1,2] = pma_pmd_corr*pma_sigma[0]*pmd_sigma[0]; cov_mat[2,1] = cov_mat[1,2];
      distr[1,*] = grand(MC_runs);
    }
    len = length(pmd_sigma);
    if(len==2 and (parallax_pmd_corr!=0 or pma_pmd_corr!=0))
      throw UsageError, sprintf("Usage error in '%s': Asymmetric uncertainties and correlation parameters cannot be used together.", _function_name());
    if(parallax_pmd_corr==0 and pma_pmd_corr==0)
    {
      cov_mat[2,2] = 1; cov_mat[2,0] = 0; cov_mat[0,2] = 0; cov_mat[1,2] = 0; cov_mat[2,1] = 0;
      if(len==2)
      {
	distr[2,*] = grand(MC_runs);
	distr[2,where(distr[2,*]>0)] *= pmd_sigma[0];
	distr[2,where(distr[2,*]<0)] *= pmd_sigma[1];
      }
      else
	distr[2,*] = grand(MC_runs)*pmd_sigma[0];
    }
    else
    {
      cov_mat[2,2] = (pmd_sigma[0])^2; cov_mat[2,0] = parallax_pmd_corr*dist_sigma[0]*pmd_sigma[0]; cov_mat[0,2] = cov_mat[2,0];
      cov_mat[1,2] = pma_pmd_corr*pma_sigma[0]*pmd_sigma[0]; cov_mat[2,1] = cov_mat[1,2];
      distr[2,*] = grand(MC_runs);
    }
    variable e;
    try(e)
    {
      distr = cholesky_decomposition(cov_mat)#distr; % matrix product of the Cholesky decomposition of the covariance matrix and a vector containing random numbers, see the function 'cholesky_decomposition' for details
    }
    catch AnyError:
    {
      vmessage(e.message);
      throw UsageError, sprintf("Usage error in '%s': The given parameter correlations are not physical.", _function_name());
    }
    variable dist_distr = distr[0,*] + dist;
    variable pma_distr  = distr[1,*] + pma;
    variable pmd_distr  = distr[2,*] + pmd;
    (x, y, z, vx, vy, vz) = cel2gal(ah*ones(MC_runs), am*ones(MC_runs), as*ones(MC_runs), dd*ones(MC_runs), dm*ones(MC_runs), ds*ones(MC_runs), dist_distr, rv_distr, pma_distr, pmd_distr;; qualies);
    variable ind = where(dist_distr>0); len = length(ind); % omit negative distances or parallaxes
    if(len!=MC_runs)
    {
      vmessage("Warning in '%s': only %d out of %d Monte Carlo runs are performed because initial conditions with negative distances have been omitted.", _function_name(), len, MC_runs);
      x = x[ind]; y = y[ind]; z = z[ind]; vx = vx[ind]; vy = vy[ind]; vz = vz[ind];
    }
    if(qualifier_exists("stff")) % some keywords for fits-header to know what input parameters or qualifiers were used for this computation
    {
      keys = struct_combine( keys, struct{ maximum_integration_time = string(t_end), rah=string(ah), ras=string(am), ram=string(as), decd=string(dd), decm=string(dm), decs=string(ds),
	dist=string(dist), dist_sigma_plus=string(dist_sigma[0]), dist_sigma_minus=string(dist_sigma[-1]), rv=string(rv), rv_sigma_plus=string(rv_sigma[0]), rv_sigma_minus=string(rv_sigma[-1]),
	pma_cos_delta=string(pma), pma_cos_delta_sigma_plus=string(pma_sigma[0]), pma_cos_delta_sigma_minus=string(pma_sigma[-1]), pmd=string(pmd), pmd_sigma_plus=string(pmd_sigma[0]),
	pmd_sigma_minus=string(pmd_sigma[-1]) });
    }
  }

  else if(_NARGS==7)
  {
    (x, y, z, vx, vy, vz, t_end) = ();
  }

  else
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }

  variable s = sign(t_end);
  if(s==0) s=1; % to account for t_end==0
  t_end *= (1.*s); vx = [1.*s*vx]; vy = [1.*s*vy]; vz = [1.*s*vz]; % for backward integration, i.e. t_end < 0, reverse t_end and the sign of the velocity components
  x = [1.*x]; y = [1.*y]; z = [1.*z]; % cast to Double_Type[]
  % =====================

  variable ret;
  if(set) ret = struct{i, f, tr};
  else ret = struct{i, f};
  % ==============================================================================================================
  % preparations:
  variable kms_to_kpcMyr = 0.0010227316044154543; % km/s = 1 / (3.0856775975*10^16 / 10^6 / 3.15582 / 10^7) kpc/Myr;
  vx *= kms_to_kpcMyr; vy *= kms_to_kpcMyr; vz *= kms_to_kpcMyr;
  ret.i = struct{ t, x, y, z, vx, vy, vz, Lz, Energy };
  len = length(x);
  ret.i.t = 0.*Double_Type[len];
  ret.i.x = x;
  ret.i.y = y;
  ret.i.z = z;
  ret.i.vx = vx;
  ret.i.vy = vy;
  ret.i.vz = vz;
  variable disk_crossings = 0*Integer_Type[len];
  variable disk_positions = disk.z + disk.height*grand(len);
  variable Rmin = [sqrt(x^2+y^2+z^2)]; % initialize Rmin as Array_Type
  variable Rmax = [sqrt(x^2+y^2+z^2)]; % initialize Rmax as Array_Type
  variable m = Double_Type[6, len];
  if(coords=="cart")
  {
    m[0,*]=x, m[1,*]=y, m[2,*]=z, m[3,*]=vx, m[4,*]=vy, m[5,*]=vz;
    ret.i.Lz = @m[0,*]*@m[4,*] - @m[1,*]*@m[3,*]; % Lz = x*vy - y*vx
  }
  else % transform cartesian coordinates to cylindrical ones
  {
    (m[0,*], m[1,*], m[2,*], m[3,*], m[4,*], m[5,*]) = cart2cyl(x, y, z, vx, vy, vz); % r, phi, z, vr, vphi, vz = ...
    m[4,*] *= (m[0,*])^2; % conversion from vphi to Lz: Lz = vphi*r^2
    ret.i.Lz = @m[4,*];
    variable phi_start = m[1,*];
  }
  variable qualies_energy = @qualies;
  set_struct_field(qualies_energy, "eomecd", "energy"); % important for the following line
  ret.i.Energy = (@model)(0, m;; qualies_energy); % calculate initial total energy using the model-function -> function 'orbit_calculator' is model independent
  % ==============================================================================================================

  % ============================
  % initializing the ODE-solver:
  variable k1, k2, k3, k4, k5, k6, k7, dx_c, dx_e; % dx_c = dx continue, dx_e = dx error estimation
  variable coef = Double_Type[7,7]; % modified Butcher tableau
  if(method == "RKF")
  {
    coef[0,0]= 1./4;   coef[0,1]=  1./4;
    coef[1,0]= 3./8;   coef[1,1]=  3./32;      coef[1,2]=  9./32;
    coef[2,0]= 12./13; coef[2,1]=  1932./2197; coef[2,2]= -7200./2197;  coef[2,3]=  7296./2197;
    coef[3,0]= 1.;     coef[3,1]=  439./216;   coef[3,2]= -8.;          coef[3,3]=  3680./513;    coef[3,4]= -845./4104;
    coef[4,0]= 1./2;   coef[4,1]= -8./27;      coef[4,2]=  2.;          coef[4,3]= -3544./2565;   coef[4,4]=  1859./4104;   coef[4,5]= -11./40;
    coef[5,0]= 0;      coef[5,1]=  25./216;    coef[5,2]=  1408./2565;  coef[5,3]=  2197./4104;   coef[5,4]= -1./5;         coef[5,5]= 0; % fourth order solution
    coef[6,0]= 0;      coef[6,1]=  16./135;    coef[6,2]=  6656./12825; coef[6,3]=  28561./56430; coef[6,4]= -9./50;        coef[6,5]= 2./55; % fifth order solution
  }

  else if(method == "RKDP")
  {
    coef[0,0]= 1./5;  coef[0,1]= 1./5;
    coef[1,0]= 3./10; coef[1,1]= 3./40;       coef[1,2]=  9./40;
    coef[2,0]= 4./5;  coef[2,1]= 44./45;      coef[2,2]= -56./15;      coef[2,3]= 32./9;
    coef[3,0]= 8./9;  coef[3,1]= 19372./6561; coef[3,2]= -25360./2187; coef[3,3]= 64448./6561; coef[3,4]= -212./729;
    coef[4,0]= 1.;    coef[4,1]= 9017./3168;  coef[4,2]= -355./33;     coef[4,3]= 46732./5247; coef[4,4]=  49./176;       coef[4,5]= -5103./18656;
    coef[5,0]= 1.;    coef[5,1]= 35./384;     coef[5,2]= 500./1113;    coef[5,3]=  125./192;   coef[5,4]= -2187./6784;    coef[5,5]= 11./84; % fourth order solution
    coef[6,0]= 0;     coef[6,1]= 5179./57600; coef[6,2]= 7571./16695;  coef[6,3]=  393./640;   coef[6,4]= -92097./339200; coef[6,5]= 187./2100;    coef[6,6]= 1./40; % fitfh order solution
  }

  else % use RKCK if method is none of the two above methods
  {
    coef[0,0]= 1./5;  coef[0,1]= 1./5;
    coef[1,0]= 3./10; coef[1,1]= 3./40;       coef[1,2]= 9./40;
    coef[2,0]= 3./5;  coef[2,1]= 3./10;       coef[2,2]= -9./10;       coef[2,3]= 6./5;
    coef[3,0]= 1.;    coef[3,1]= -11./54;     coef[3,2]= 5./2;         coef[3,3]= -70./27;       coef[3,4]= 35./27;
    coef[4,0]= 7./8;  coef[4,1]= 1631./55296; coef[4,2]= 175./512;     coef[4,3]= 575./13824;    coef[4,4]= 44275./110592; coef[4,5]= 253./4096;
    coef[5,0]= 0;     coef[5,1]= 2825./27648; coef[5,2]= 18575./48384; coef[5,3]= 13525./55296;  coef[5,4]= 277./14336;    coef[5,5]= 1./4; % fourth order solution
    coef[6,0]= 0;     coef[6,1]= 37./378;     coef[6,2]= 250./621;     coef[6,3]= 125./594;      coef[6,4]= 0;             coef[6,5]= 512./1771; % fitfh order solution
  }
  % ============================

  % =======================================
  % solving the equations of motions:
  variable t = 0;
  variable dt = 0.001;
  if(dt_fixed) dt = qualifier("dt"); % use fixed stepsize when qualifier "dt" is present
  variable t_eoc = t_end + 0*Double_Type[len]; % t_eoc: time at the end or moment of crossing the disk
  ind = [0:len-1:1]; % array of indices, important for bookkeeping of which orbits already crossed the disk and thus for qualifier 'disk.radius'
  if(set)
  {
    variable t_last_save = 0;
    variable cols = String_Type[len];
    variable i, j;
    _for i(0, len-1, 1)
    {
      cols[i] = sprintf("o%d", i);
    }
    ret.tr = @Struct_Type(cols);
    variable temp1 = struct{ t, x, y, z, vx, vy, vz, Lz, Energy };
    _for i(0, len-1, 1)
    {
      temp1.t = {t};
      temp1.x = {m[0,i]};
      temp1.y = {m[1,i]};
      temp1.z = {m[2,i]};
      temp1.vx = {m[3,i]};
      temp1.vz = {m[5,i]};
      temp1.Lz = {m[4,i]};
      temp1.Energy = {ret.i.Energy[i]};
      set_struct_field(ret.tr, cols[i], @temp1);
    }
  }
  while(t < t+dt <= t_end and length(ind)>0)
  {
    k1 = dt * (@model)(s*t, m[*,ind];; qualies);
    k2 = dt * (@model)(s*(t + coef[0,0]*dt), m[*,ind] + coef[0,1]*k1;; qualies);
    k3 = dt * (@model)(s*(t + coef[1,0]*dt), m[*,ind] + coef[1,1]*k1 + coef[1,2]*k2;; qualies);
    k4 = dt * (@model)(s*(t + coef[2,0]*dt), m[*,ind] + coef[2,1]*k1 + coef[2,2]*k2 + coef[2,3]*k3;; qualies);
    k5 = dt * (@model)(s*(t + coef[3,0]*dt), m[*,ind] + coef[3,1]*k1 + coef[3,2]*k2 + coef[3,3]*k3 + coef[3,4]*k4;; qualies);
    k6 = dt * (@model)(s*(t + coef[4,0]*dt), m[*,ind] + coef[4,1]*k1 + coef[4,2]*k2 + coef[4,3]*k3 + coef[4,4]*k4 + coef[4,5]*k5;; qualies);
    if(method == "RKDP") % for RKPD use fifth order solution to continue integration
    {
      dx_e = coef[5,1]*k1 + coef[5,2]*k3 + coef[5,3]*k4 + coef[5,4]*k5 + coef[5,5]*k6; % fourth order solution
      k7 = dt * (@model)(s*(t + coef[5,0]*dt), m[*,ind] + dx_e;; qualies);
      dx_c = coef[6,1]*k1 + coef[6,2]*k3 + coef[6,3]*k4 + coef[6,4]*k5 + coef[6,5]*k6 + coef[6,6]*k7; % fifth order solution
    }
    else % for RKF, RKCK use fourth order solution to continue integration
    {
      dx_c = coef[5,1]*k1 + coef[5,2]*k3 + coef[5,3]*k4 + coef[5,4]*k5 + coef[5,5]*k6; % fourth order solution
      dx_e = coef[6,1]*k1 + coef[6,2]*k3 + coef[6,3]*k4 + coef[6,4]*k5 + coef[6,5]*k6; % fifth order solution
    }
    variable scale = 0.9*(eps/max(abs(dx_c-dx_e)))^(0.2); % 0.9 is safety factor; derivation see Numerical Recipes, Section "Adaptive Stepsize Control for Runge-Kutta"
    if(dt_fixed) scale = 1; % use fixed stepsize when qualifier "dt" is present
    % variable scale = ( 0.5*eps*dt/max(abs(dx_c-dx_e)) )^0.25;  % "derivation of this formula can be found in advanced books on numerical analysis"
    if(scale>=1 or dt<=1e-14*t) % scale>1: accept stepsize only if correction factor is equal/larger than 1
    {                           % dt<=abs(1e-14*t) in order to avoid infinite loops due to Double_Type precision limit at dt=1e-16*t
      if(disk.radius>0)
      {
	variable m_last = @(m[*,ind]);
	variable t_last = @t;
      }
      m[*,ind] += dx_c;
      t += dt;
      % ---------------------
      % update Rmin and Rmax:
      variable temp_R;
      if(coords=="cart")
	temp_R = sqrt((m[0,ind])^2+(m[1,ind])^2+(m[2,ind])^2); % temp_R = R = sqrt(x^2+y^2+z^2)
      else % coords = "cyl"
	temp_R = sqrt((m[0,ind])^2+(m[2,ind])^2); % temp_R = R = sqrt(r^2+z^2)
      temp0 = where(temp_R>Rmax[ind]);
      Rmax[ind[temp0]] = temp_R[temp0];
      temp0 = where(temp_R<Rmin[ind]);
      Rmin[ind[temp0]] = temp_R[temp0];
      % ---------------------
      if(disk.radius>0)
      {
	% identify orbits that have crossed the disk:
	variable ind_cro, ind_con; % indices of orbits which have crossed plane and of those for which calculation is continued
	if(coords=="cart") % (z-z_disk) * (z_last-z_disk) <= 0 but z!=z_last!=0 and r<=disk.radius -> orbit crossed disk inside radius of disk.radius during last step:
	  ind_cro = where((m[2,ind]-disk_positions[ind]) * (m_last[2,*]-disk_positions[ind]) <= 0 and m[2,ind]!=m_last[2,*] and
			  ( (m_last[0,*]-disk.x)^2 + (m_last[1,*]-disk.y)^2 <= disk.radius^2 or (m[0,ind]-disk.x)^2 + (m[1,ind]-disk.y)^2 <= disk.radius^2));
	else % coords = "cyl"
	  ind_cro = where((m[2,ind]-disk_positions[ind]) * (m_last[2,*]-disk_positions[ind]) <= 0 and m[2,ind]!=m_last[2,*] and ( (m_last[0,*]*cos(m_last[1,*])-disk.x)^2 + (m_last[0,*]*sin(m_last[1,*])-disk.y)^2 <= disk.radius^2 or
																  (m[0,ind]*cos(m[1,ind])-disk.x)^2 + (m[0,ind]*sin(m[1,ind])-disk.y)^2 <= disk.radius^2));
	disk_crossings[ind[ind_cro]] += 1;
	ind_cro = where(disk_crossings[ind]==disk.crossings, &ind_con);
	variable len_ind_cro = length(ind_cro);
	if(len_ind_cro>0)
	{
	  % =====================================================================
	  % interpolate to moment of crossing and save the result in m and t_end:
	  variable t_travel_last = (disk_positions[ind[ind_cro]]-m_last[2,ind_cro])/m_last[5,ind_cro]; % t_travel_last := t_cross - t_last = (disk_positions - z_last)/vz_last <=> t_travel_last*vz_last  = disk_positions - z_last <= linear interpolation
	  variable t_travel = (m[2,ind[ind_cro]]-disk_positions[ind[ind_cro]])/m[5,ind[ind_cro]]; % t_travel = t - t_cross = (z-disk_positions)/vz <=> vz*t_travel = z - disk_positions <= linear interpolation
	  % average with weights: the larger the estimated travel time, the worse the linear approximation
	  variable weight = t_travel / ( t_travel + t_travel_last );
	  t_eoc[ind[ind_cro]] = weight*t_last + (1.-weight)*t;
	  variable t_remaining = Double_Type[6,len_ind_cro];
	  t_remaining[0,*] = t_eoc[ind[ind_cro]] - t_last;
	  t_remaining[1,*] = t_remaining[0,*];
	  t_remaining[2,*] = t_remaining[0,*];
	  t_remaining[3,*] = t_remaining[0,*];
	  t_remaining[4,*] = t_remaining[0,*];
	  t_remaining[5,*] = t_remaining[0,*];
	  % re-calculate the last step but with adopted timestep t_remaining instead of dt
	  k1 = t_remaining * (@model)(s*t_last, m_last[*,ind_cro];; qualies);
	  k2 = t_remaining * (@model)(s*(t_last + coef[0,0]*t_remaining[0,*]), m_last[*,ind_cro] + coef[0,1]*k1;; qualies);
	  k3 = t_remaining * (@model)(s*(t_last + coef[1,0]*t_remaining[0,*]), m_last[*,ind_cro] + coef[1,1]*k1 + coef[1,2]*k2;; qualies);
	  k4 = t_remaining * (@model)(s*(t_last + coef[2,0]*t_remaining[0,*]), m_last[*,ind_cro] + coef[2,1]*k1 + coef[2,2]*k2 + coef[2,3]*k3;; qualies);
	  k5 = t_remaining * (@model)(s*(t_last + coef[3,0]*t_remaining[0,*]), m_last[*,ind_cro] + coef[3,1]*k1 + coef[3,2]*k2 + coef[3,3]*k3 + coef[3,4]*k4;; qualies);
	  k6 = t_remaining * (@model)(s*(t_last + coef[4,0]*t_remaining[0,*]), m_last[*,ind_cro] + coef[4,1]*k1 + coef[4,2]*k2 + coef[4,3]*k3 + coef[4,4]*k4 + coef[4,5]*k5;; qualies);
	  if(method == "RKDP") % for RKPD use fifth order solution to continue integration
	  {
	    dx_e = coef[5,1]*k1 + coef[5,2]*k3 + coef[5,3]*k4 + coef[5,4]*k5 + coef[5,5]*k6; % fourth order solution
	    k7 = t_remaining * (@model)(s*(t_last + coef[5,0]*t_remaining[0,*]), m_last[*,ind_cro] + dx_e;; qualies);
	    dx_c = coef[6,1]*k1 + coef[6,2]*k3 + coef[6,3]*k4 + coef[6,4]*k5 + coef[6,5]*k6 + coef[6,6]*k7; % fifth order solution
	  }
	  else % for RKF, RKCK use fourth order solution to continue integration
	  {
	    dx_c = coef[5,1]*k1 + coef[5,2]*k3 + coef[5,3]*k4 + coef[5,4]*k5 + coef[5,5]*k6; % fourth order solution
	    dx_e = coef[6,1]*k1 + coef[6,2]*k3 + coef[6,3]*k4 + coef[6,4]*k5 + coef[6,5]*k6; % fifth order solution
	  }
	  m[*,ind[ind_cro]] = m_last[*,ind_cro] + dx_c;
	  % =====================================================================
	}
      }
      if(set)
      {
	if(t-t_last_save > set_threshold or t==t_end)
	{
	  t_last_save = t;
	  variable temp_energy = (@model)(s*t, m[*,ind];; qualies_energy);
	  _for i(0, length(ind)-1, 1)
	  {
	    list_append((get_struct_field(ret.tr, cols[ind[i]])).t, t);
	    list_append((get_struct_field(ret.tr, cols[ind[i]])).x, m[0,ind[i]]);
	    list_append((get_struct_field(ret.tr, cols[ind[i]])).y, m[1,ind[i]]);
	    list_append((get_struct_field(ret.tr, cols[ind[i]])).z, m[2,ind[i]]);
	    list_append((get_struct_field(ret.tr, cols[ind[i]])).vx, m[3,ind[i]]);
	    list_append((get_struct_field(ret.tr, cols[ind[i]])).vz, m[5,ind[i]]);
	    list_append((get_struct_field(ret.tr, cols[ind[i]])).Lz, m[4,ind[i]]);
	    list_append((get_struct_field(ret.tr, cols[ind[i]])).Energy, temp_energy[i]);
	  }
	}
      }
      if(disk.radius>0)
      {
	if(len_ind_cro>0)
	{
	  % continue orbit calculation only for those orbits in m that did not cross the disk yet:
	  ind = ind[ind_con];
	}
      }
      if(verbose) vmessage("t=%g", s*t);
    }
    dt = _max(dt*scale, t*1e-15); % abs(1e-15*t) in order to avoid infinite loops due to Double_Type precision limit at dt=1e-16*t
    if(t+dt > t_end) dt = t_end-t;
  }
  % =======================================
  ret.i.vx /= (s*kms_to_kpcMyr); % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components
  ret.i.vy /= (s*kms_to_kpcMyr); % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components
  ret.i.vz /= (s*kms_to_kpcMyr); % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components
  ret.i.Lz *= s; % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components

  if(set)
  {
    _for i(0, len-1, 1)
    {
      temp1.t = list_to_array((get_struct_field(ret.tr, cols[i])).t, Double_Type);
      temp1.t[-1] = t_eoc[i];
      temp1.t *= s; % for backward integration, i.e. t_end < 0, re-reverse t_end
      temp1.Energy = list_to_array((get_struct_field(ret.tr, cols[i])).Energy, Double_Type);
      if(coords=="cart")
      {
	temp1.x = list_to_array((get_struct_field(ret.tr, cols[i])).x, Double_Type);
	temp1.y = list_to_array((get_struct_field(ret.tr, cols[i])).y, Double_Type);
	temp1.z = list_to_array((get_struct_field(ret.tr, cols[i])).z, Double_Type);
	temp1.vx = list_to_array((get_struct_field(ret.tr, cols[i])).vx, Double_Type);
	temp1.vy = list_to_array((get_struct_field(ret.tr, cols[i])).Lz, Double_Type);
	temp1.vz = list_to_array((get_struct_field(ret.tr, cols[i])).vz, Double_Type);
	temp1.Lz = temp1.x*temp1.vy - temp1.y*temp1.vx; % Lz = x*vy - y*vx
      }
      else % coords = "cyl"
      {
	variable temp2 = struct{ r, phi, z, vr, vphi, vz };
	temp2.r = list_to_array((get_struct_field(ret.tr, cols[i])).x, Double_Type);
	temp2.phi = list_to_array((get_struct_field(ret.tr, cols[i])).y, Double_Type);
	temp2.z = list_to_array((get_struct_field(ret.tr, cols[i])).z, Double_Type);
	temp2.vr = list_to_array((get_struct_field(ret.tr, cols[i])).vx, Double_Type);
	temp1.Lz = list_to_array((get_struct_field(ret.tr, cols[i])).Lz, Double_Type);
	temp2.vphi = @temp1.Lz; ind = where(temp2.r != 0); temp2.vphi[ind] /= ((temp2.r)^2)[ind];
	temp2.vz = list_to_array((get_struct_field(ret.tr, cols[i])).vz, Double_Type);
	(temp1.x, temp1.y, temp1.z, temp1.vx, temp1.vy, temp1.vz) =
	  cyl2cart(temp2.r, temp2.phi, temp2.z, temp2.vr, temp2.vphi, temp2.vz);
      }
      temp1.Lz *= s; % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components by multiplying s
      temp1.vx /= (s*kms_to_kpcMyr); % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components
      temp1.vy /= (s*kms_to_kpcMyr); % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components
      temp1.vz /= (s*kms_to_kpcMyr); % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components
      set_struct_field(ret.tr, cols[i], @temp1);
    }
  }

  ret.f = struct{ t, x, y, z, vx, vy, vz, Lz, Energy, Rmin, Rmax };
  ret.f.t = s*t_eoc; % for backward integration, i.e. t_end < 0, re-reverse t_end and the sign of the velocity components
  if(coords=="cart")
  {
    ret.f.x = m[0,*]; ret.f.y = m[1,*]; ret.f.z = m[2,*]; ret.f.vx = m[3,*]; ret.f.vy = m[4,*]; ret.f.vz = m[5,*];
    ret.f.Lz = s*(ret.f.x*ret.f.vy - ret.f.y*ret.f.vx); % Lz = x*vy - y*vx
  }
  else % coords = "cyl"
  {
    variable temp_vphi = @m[4,*]; ind = where( m[0,*] != 0 ); temp_vphi[ind] /= (m[0,ind])^2;
    (ret.f.x, ret.f.y, ret.f.z, ret.f.vx, ret.f.vy, ret.f.vz) = cyl2cart(m[0,*], m[1,*], m[2,*], m[3,*], temp_vphi, m[5,*]);
    ret.f.Lz = s*m[4,*]; % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components
    ret.f = struct_combine(ret.f, "Nrev");
    ret.f.Nrev = s*(m[1,*] - phi_start)/(2*PI);
  }
  ret.f.Energy = (@model)(s*t, m;; qualies_energy);
  ret.f.vx /= (s*kms_to_kpcMyr); % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components
  ret.f.vy /= (s*kms_to_kpcMyr); % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components
  ret.f.vz /= (s*kms_to_kpcMyr); % for backward integration, i.e. t_end < 0, re-reverse the sign of the velocity components
  ret.f.Rmin = Rmin;
  ret.f.Rmax = Rmax;

  if(qualifier_exists("stff")) % some keywords for fits-header to know what input parameters or qualifiers were used for this computation
  {
    keys = struct_combine( keys, struct{ vxs, vys, vzs, Mb, Md, Mh, bb, ad, bd, ah, exponent, cutoff, model, method, eps}, disk );
    variable field;
    foreach field (["vxs", "vys", "vzs", "Mb", "Md", "Mh", "bb", "ad", "bd", "ah", "exponent", "cutoff"])
    {
      if(qualifier_exists(field))
	set_struct_field(keys, field, string(median(qualifier(field))));
      else
	set_struct_field(keys, field, "Default value");
    }
    keys.model = string(model);
    keys.method = method;
    keys.eps = string(eps);
    if(__is_initialized(&seed))
      keys = struct_combine( keys, struct{ random_seed = string(seed) } );
    if(qualifier_exists("dt"))
      keys = struct_combine( keys, struct{ dt = string(qualifier("dt")) } );
    fits_write_binary_table(qualifier("stff")+"_initial.fits", "Initial_conditions", ret.i, keys);
    fits_write_binary_table(qualifier("stff")+"_final.fits", "Final_conditions", ret.f, keys);
  }

  return ret;
}%}}}
