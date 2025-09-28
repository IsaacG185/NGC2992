%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define pvm_fit_pars_txt2fits()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pvm_fit_pars_txt2fits}
%\usage{pvm_fit_pars_txt2fits(String_Type txt_filename);}
%!%-
{
  variable txt_filename;
  switch(_NARGS)
  { case 1: txt_filename = (); }
  { help(_function_name()); return; }

  variable fits_filename;
  if(string_match(txt_filename, "\.txt", 1))
    (fits_filename, ) = strreplace(txt_filename, ".txt", ".fits", 1);
  else
    fits_filename = txt_filename + ".fits";

  variable t = ascii_read_table(txt_filename, [{"%F","min"},{"%s",""},{"%F","conf_min"},{"%s",""},{"%s","name"},{"%s",""},{"%F","value"},{"%s",""},{"%F","conf_max"},{"%s",""},{"%F","max"}];startline=2);
  fits_write_binary_table(fits_filename, "confidence intervals", t);
}
