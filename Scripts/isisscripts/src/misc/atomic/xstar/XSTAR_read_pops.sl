%%%%%%%%%%%%%%%%%%%%%%
define XSTAR_read_pops()
%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{XSTAR_read_pops}
%\synopsis{reads the ionization balances from an XSTAR population file}
%\usage{Struct_Type XSTAR_read_pops(String_Type filename)}
%\qualifiers{
%\qualifier{verbose}{}
%\qualifier{Z}{array of Z values of elements to include}
%\qualifier{ions}{array of ions to include (overrides Z qualifier)}
%}
%!%-
{
  variable filename;
  switch(_NARGS)
  { case 1: filename = (); }
  { help(_function_name()); return; }

  variable nr_shells = fits_get_num_hdus(filename)-2;
  variable F = fits_open_file(filename, "r");
  ()=fits_movrel_hdu(F, 1);  % skip primary extension
  variable parameters = fits_read_table(F);
  variable density = parameters.value[wherefirst(parameters.parameter=="density")];
  variable luminosty = 1e38 * parameters.value[wherefirst(parameters.parameter=="rlrad38")];

  variable ions = qualifier("ions");
  if(ions==NULL)
  {
    variable Zs = qualifier("Z", [1,2,6,7,8,10,12,14,16,18,20,26]);
    ions = String_Type[int(sum(Zs))];
    variable Z, ion, i=0;
    foreach Z (Zs)
      _for ion (1, Z, 1)
      { ions[i] = strlow(atom_name(Z)+"_"+Roman(ion));
	i++;
      }
  }
  variable field, fields = ["r", "r_outer", "log_xi", "temp", "press", ions];
  variable pops = @Struct_Type(fields);
  foreach field (fields)
    set_struct_field(pops, field, Float_Type[nr_shells]);

  variable verbose = qualifier_exists("verbose");
  _for i (0, nr_shells-1, 1)
  {
    if(verbose)  vmessage("%d/%d", i, nr_shells);
    ()=fits_movrel_hdu(F, 1);
    (pops.r[i], pops.r_outer[i], pops.temp[i], pops.press[i]) = fits_read_key(F, "rinner", "router", "temperat", "pressure");
    variable shell = fits_read_table(F, ["population", "ion", "e_excitation"]);
    foreach ion (ions)
    {
      variable ind = where(shell.ion==ion and shell.e_excitation==0);
      if(length(ind))
	get_struct_field(pops, ion)[i] = shell.population[ind[0]];
    }
  }
  fits_close_file(F);

  pops.log_xi = log10(luminosty/density/pops.r^2);
  pops.temp *= 1e4;
  return pops;
}
