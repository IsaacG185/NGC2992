require("xspec");
%%%%%%%%%%%%%%%%%%%%
define doublehump_fit(bin_lo,bin_hi,par)
%%%%%%%%%%%%%%%%%%%%
{
	variable k1=par[0];
	variable alpha=par[1];
	variable E1=par[2];
	variable E2=par[3];
	variable Eintersect=par[4];
 
	% calculate k2
	variable k2=k1*Eintersect^(-alpha-2)*exp(Eintersect*(1./E2-1./E1));
 
	if(qualifier_exists("cutoffpl"))
		return cutoffpl_fit(bin_lo,bin_hi,[k1,alpha,E1]);
 
	if(qualifier_exists("wienhump"))
		return cutoffpl_fit(bin_lo,bin_hi,[k2,-2,E2]);
 
	return cutoffpl_fit(bin_lo,bin_hi,[k1,alpha,E1])+cutoffpl_fit(bin_lo,bin_hi,[k2,-2,E2]);
}

add_slang_function("doublehump",["norm","alpha","cutoff [keV]","WienkT [keV]","intersect [keV]"]);

%%%%%%%%%%%%%%%%%%%%
define doublehump_default(i)
%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
  { case 0: return ( 1, 0,  0, 1e10); }
  { case 1: return ( 1, 0, -2,  9); }
  { case 2: return ( 2, 0, 1e-2, 30); }
  { case 3: return ( 10, 0, 1e-2, 100); }
  { case 4: return ( 10, 0, 1e-2, 50); }
}

set_param_default_hook("doublehump", &doublehump_default);
