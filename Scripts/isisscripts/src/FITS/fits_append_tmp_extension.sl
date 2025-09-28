%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define fits_append_tmp_extension()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_append_tmp_extension}
%\synopsis{appends a temporary FITS extension to another FITS file before deleting it}
%\usage{fits_append_tmp_extension(String_Type infiles[], String_Type outfile);}
%\description
%    As the external FTOOL fappend is used for this task,
%    \code{infiles} may contain extension numbers according to the FTOOLS conventions.
%    The extensions are appended at the end of \code{outfile}.
%    Afterwards, all \code{infiles} are deleted.
%
%    This function should usually not be used!
%    ISIS' cfitsio module allows to write several extensions
%    into a file after opening it with fits_open_file.
%\seealso{fappend [FTOOLS], fits_append_extension}
%!%-
{
  variable infiles, outfile;
  switch(_NARGS)
  { case 2: (infiles, outfile) = (); }
  { help(_function_name()); return; }

  fits_append_extension(infiles, outfile;; __qualifiers());

  variable infile;
  foreach infile ([infiles])
  {
    variable m = string_match(infile, `\(.*\)\[`, 1);
    if(m!=NULL)  infile = m[1];
    if(qualifier_exists("verbose"))  vmessage("removing %s", infile);
    ()=remove(infile);
  }
}
