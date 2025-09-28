define difmap_restore()
%!%+
%\function{difmap_restore}
%\synopsis{DIFMAP is used to restore a radio image with a new beam}
%\usage{String_Type outname = difmap_restore(String_Type \code{fitsfile}, Double_Type \code{smajor}, \code{sminor}, \code{pos_angle})}
%\qualifiers{
%\qualifier{chan}{[=i] choose channel (i,q,u)}
%\qualifier{xsize}{[= key "NAXIS1"] number of RA pixels}
%\qualifier{xsetp}{[= key "CDELT1"] step size of each RA pixel in mas}
%\qualifier{ysize}{[= key "NAXIS2"] number of DEC pixels}
%\qualifier{ysetp}{[= key "CDELT2"] step size of each DEC pixel in mas}
%\qualifier{uvtaper}{[= " "] pply a uvtaper before restoring}
%\qualifier{outname}{[= "xxxxMHz_restore.fits"] filename of the output, be default the
%                                frequency is read from the input file}
%\qualifier{overwrite}{overwrite file with outname if it already exists}
%}
%\description
%    This function creates a radio image with a given beam using DIFMAP. The
%    new beam has to be defined by its semimajor and semiminor axis and its
%    position angle. The new images is saved in the current working directory.
%    It is assumed that the UVF and MOD files have the same basename as the
%    provided file name if the FITS image.
%\seealso{make_spix}
%!%-
{
  message("running restore");
  variable path, major, minor, posang;
  switch(_NARGS)
  { case 4: (path, major, minor, posang) = (); }
  { help(_function_name()); return NULL; }

  if (system("which difmap  > /dev/null 2>&1") != 0)
  {
    vmessage("ERROR %s: program DIFMAP not found",_function_name());
    return NULL;
  };
  variable chan = qualifier("chan", "i");
  variable xsize  = qualifier("xsize", fits_read_key (path, "NAXIS1"));
  variable xstep  = qualifier("xstep", fits_read_key (path, "CDELT1")*(3.6e+6));
  variable ysize  = qualifier("ysize", fits_read_key (path, "NAXIS2"));
  variable ystep  = qualifier("ystep", fits_read_key (path, "CDELT2")*(3.6e+6));
  variable uvtaper = qualifier("uvtaper", " ");
  variable freqMHz= fits_read_key (path, "CRVAL3");
  freqMHz = freqMHz*1e-6;
  variable stem   = string_matches(path, "\\(.*\\).fits")[1];

  if ( stat_file (stem+".uvf")==NULL or stat_file (stem+".mod")==NULL)
  {
    vmessage("ERROR %s: required files for restoring the beam not found:",_function_name());
    vmessage("\t%s",stem+".uvf");
    vmessage("\t%s",stem+".mod");
    return NULL;
  };

  variable orig_major  = fits_read_key(path, "BMAJ")*(3.6e+6)/2.0; % clean x beam major axis in mas (semi major!)
  variable orig_minor  = fits_read_key(path, "BMIN")*(3.6e+6)/2.0; % clean x beam minor axis in mas (semi minor!)
  variable orig_posang = fits_read_key(path, "BPA");

  variable outname = qualifier("outname", sprintf("%dMHz_restore.fits", nint(freqMHz)));

  variable write_it = 1;
  if (stat_file(outname) != NULL) 
  {
    write_it = 0;
    vmessage("WARNING %s: outfile %s already exists",_function_name(),outname);
  }
  if (write_it == 0 and qualifier_exists("overwrite"))
  {
    write_it = 1; vmessage("overwriting %s",outname);
  }
  if (write_it == 0) vmessage("Using existing file. For a new file use the qualifier \"overwrite\".");
  
  if (write_it == 1)
  {
    %% DIFMAP uses full axis, not semi axis,
    %% DIFMAP seems to set the xsize and ysize to the half, when using wmap (saved image is smaller by 0.5 in both dimensions)
    variable difscript = `device /NULL
obs `+stem+`.uvf
rmod `+stem+`.mod
maps `+sprintf(`%f, %f, %f, %f`,2*xsize, xstep, 2*ysize, ystep)+`
uvw 0,-1
`+sprintf(`select %s`, chan)+`
uvtaper `+sprintf(`%s`, uvtaper)+`
restore `+sprintf(`%f,%f,%f`,2*major, 2*minor, posang)+`
wmap `+outname+`
quit`;
    ()=system("echo \'"+difscript+"\' | difmap > /dev/null 2>&1");
    try { ()=fits_read_key (outname, "NAXIS1"); }
    catch AnyError: { vmessage("DIFMAP failed to create an [%d,%d] image with a resolution of %f x %f mas",
			      xsize,ysize,xstep,ystep); return NULL;}
    ; % ; to terminate try block
  }
  return outname;
}
