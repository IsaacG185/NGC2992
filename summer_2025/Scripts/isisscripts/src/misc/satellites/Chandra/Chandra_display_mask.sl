define Chandra_display_mask()
%!%+
%\function{Chandra_display_mask}
%\synopsis{shows the content of a Chandra mask file (msk1.fits)}
%\usage{Chandra_display_mask([String_Type filename]);}
%\description
%    \code{filename} can be a globbing expression.
%    If it is omitted, \code{acis*msk1.fits*} is assumed.
%
%    The mask file contains the valid part of the CCD,
%    i.e., the portion for which events can be telemetered.
%!%-
{
  variable pattern = "acis*msk1.fits*";
  switch(_NARGS)
  { case 0: ; }
  { case 1: pattern = (); }
  { return help(_function_name()); }

  variable files = glob(pattern);
  if(length(files)==0)
    return vmessage("error (%s): no mask file %s found", _function_name(), pattern);

  variable filename;
  foreach filename (files[array_sort(files)])
  {
    if(filename!=pattern)
      vmessage("\nisis> %s(\"%s\");", _function_name(), filename);
    variable F = fits_open_file(files[0], "r");
    while(_fits_movrel_hdu(F, 1)==0)
    {
      variable mask = fits_read_table(F);
      variable i;
      vmessage("\n%s:", fits_read_key(F, "HDUNAME"));
      _for i (0, length(mask.component)-1, 1)
	vmessage("#%d: %10s, CHIPX x CHIPY = [%4d:%4d] x [%4d:%4d],  samp_cyc = %2d,  PHA = [%d:%d]",
		 mask.component[i], mask.shape[i], mask.chipx[i,0], mask.chipx[i,1], mask.chipy[i,0], mask.chipy[i,1],
		 mask.samp_cyc[i], mask.phamin[i], mask.phamax[i]);
    }
    fits_close_file(F);
    message("");
  }
}
