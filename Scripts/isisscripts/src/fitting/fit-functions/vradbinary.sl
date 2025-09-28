%%%%%%%%%%%%%%%%%%%%%
define vradbinary_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vradbinary (fit-function)}
%\synopsis{describes the radial velocity in a binary system}
%\description
%    Note that only bin_lo is taken into account.
%\seealso{radial_velocity_binary}
%!%-
{
  return radial_velocity_binary(bin_lo; v0=par[0], K=par[1], P=par[2], T0=par[3], e=par[4], omega=par[5], degrees);
}

%%%%%%%%%%%%%%%%%%%%%%%%%
define vradbinary_default(i)
%%%%%%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
  { case 0: return (    0, 0, -1000,    1000); }  % v0
  { case 1: return (   10, 0,     0,    1000); }  % K
  { case 2: return (   10, 0,  0.01,    1000); }  % P
  { case 3: return (51544, 0,     0, 2500000); }  % T0
  { case 4: return (    0, 0,     0,       1); }  % e
  { case 5: return (    0, 1,     0,     360); }  % omega
}

add_slang_function("vradbinary", ["v0 [km/s]", "K [km/s]", "P [days]", "T0 [days]", "e", "omega [degrees]"]);
set_param_default_hook("vradbinary", &vradbinary_default);
