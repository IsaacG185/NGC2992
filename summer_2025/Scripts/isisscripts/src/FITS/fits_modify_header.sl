%%%%%%%%%%%%%%%%%%%%%%%%%
define fits_modify_header()
%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_modify_header}
%\synopsis{modifies the header of a FITS file}
%\usage{fits_modify_header(String_Type filename, keyword, value[, comment]);}
%\description
%    fits_modify_header uses the external FTOOL \code{fmodhead} and is therefore deprecated.
%    Use \code{fits_update_key} from ISIS' cfitsio module instead.
%\seealso{fits_update_key}
%!%-
{
  message("fits_modify_header is deprecated. Use fits_update_key instead.");

  variable filename, keyword, value, comment="";
  switch(_NARGS)
  { case 3: (filename, keyword, value) = (); }
  { case 4: (filename, keyword, value, comment) = (); }
  { help(_function_name()); return; }

  variable tmpfile = sprintf(".tmp.fits_modify_header.%d.%d", getuid(), getpid());
  variable F = fopen(tmpfile, "w");
  ()=fprintf(F, "%s %s / %s\n", keyword, value, comment);
  ()=fclose(F);
  ()=system(`fmodhead "$filename" $tmpfile`$);
  ()=remove(tmpfile);
}
