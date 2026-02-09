%%%%%%%%%%%%%%%%%%%%%%%%
define ignore_large_bins()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ignore_large_bins}
%\synopsis{ignores those bins of a spectral dataset exceeding a maximal size}
%\usage{ignore_large_bis(Integer_Type id[], Double_Type maxsize);}
%\qualifiers{
%\qualifier{verbose}{}
%\qualifier{unit}{[=\code{"A"}]: maxsize may be in A or keV}
%}
%!%-
{
  variable id, maxsize;
  switch(_NARGS)
  { case 2: (id, maxsize) = (); }
  { help(_function_name()); }

  variable verbose = qualifier_exists("verbose");
  variable unit = qualifier("unit", "A");
  variable strlow_unit = strlow(unit);
  ifnot(any(strlow_unit==["a", "kev"]))
    return vmessage(`error (%s): unit="%s" is not allowed, only "A" or "keV"`, _function_name(), unit);
  unit = (strlow_unit=="kev");

  foreach id ([id])
  {
    variable d = get_data_counts(id);
    variable i, n = length(d.value);
    if(unit)
      (d.bin_lo, d.bin_hi) = (_A(1)/d.bin_hi, _A(1)/d.bin_lo);  % do not reverse arrays

    foreach i (get_data_info(id).notice_list)
      if(d.bin_hi[i]-d.bin_lo[i] > maxsize)
      {
	ignore_list(id, i);
	if(verbose)
	  vmessage("ignoring (wavelength-bin %4d) = (energy-bin %4d) @ [%6.2f, %6.2f] %s",
		   i, n-1-i, d.bin_lo[i], d.bin_hi[i], unit ? "keV" : "A"
		  );
      }
  }
}
