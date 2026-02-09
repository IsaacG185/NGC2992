%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define fits_append_extension()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_append_extension}
%\synopsis{appends a FITS extension to another FITS file}
%\usage{fits_append_extension(String_Type infiles[], String_Type outfile);}
%\description
%    As the external FTOOL fappend is used for this task,
%    \code{infiles} may contain extension numbers according to the FTOOLS conventions.
%    The extensions are appended at the end of \code{outfile}.
%
%    This function should usually not be used!
%    ISIS' cfitsio module allows to write several extensions
%    into a file after opening it with fits_open_file.
%\seealso{fappend [FTOOLS], fits_append_tmp_extension}
%!%-
{
  variable infiles, outfile;
  switch(_NARGS)
  { case 2: (infiles, outfile) = (); }
  { help(_function_name()); return; }

  variable infile;
  foreach infile ([infiles])
  {
    variable cmd = `fappend "$infile" "$outfile"`$;
    if(qualifier_exists("verbose"))  message(cmd);
    ()=system(cmd);
  }
}
