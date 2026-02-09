define xfig_compress_eps(file)
%!%+
%\function{xfig_compress_eps}
%\synopsis{Compresses an EPS-File via "pdftops -level3 -eps"}
%\usage{int = xfig_compress_eps(String_Type file)}
%\description
%    PS and EPS-Files created with xfig are usually much too large.
%    Using this function the size can be reduced by a factor of few. Simply
%    call this function after creating a PS or EPS with ".render(file)".
%!%-
{
  if (stat_file(file) == NULL)
  {
    vmessage("ERROR: %s(): %s does not exist", _function_name(), file);
    return -1;
  }
  if ("application/postscript" != strtrim(fgetslines(popen("file $file --mime-type -b"$,"r"))[0]))
  {
    vmessage("ERROR: %s(): %s is no [e]ps file", _function_name(), file);
    return -1;
  }

  variable tmp_pdf = "_temp.pdf";  % make sure that no existing files are overwritten with tmp_pdf:
  while (stat_file(tmp_pdf) != NULL) { tmp_pdf = char(nint(65+urand()*25)) + tmp_pdf; }
  
%  return system("ps2pdf -dEPSCrop $file $tmp_pdf; pdf2ps -dLanguageLevel=3 $tmp_pdf $file; rm -f $tmp_pdf"$ );
  return system("ps2pdf -dEPSCrop $file $tmp_pdf; pdftops -level3 -eps $tmp_pdf $file; rm -f $tmp_pdf"$ );
  % MB: the latter case produces smaller output and the bounding box should be set correctly

  % Mh: with pdftops >= 0.13.3, one could avoid tmp_pdf altogether:
  % return system("ps2pdf -dEPSCrop $file - | pdftops -level3 -eps - $file"$);
}
