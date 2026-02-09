define get_param_from_filename(){
%!%+
%\function{get_param_from_filename}
%\synopsis{returns a double parameter value from a string / filename}
%\usage{Double_Type val = get_param_from_filename(filename,key,regexp);}
%\description
%    For a given filename = data/f4l_flux0001000muCrabpattern.fits, the
%    value can be extracted by specifying the key="flux"; and a regexp
%    of regexp="flux\\([0-9.]+\\)muCrab"R;
%    Note that there is a strict naming convention:
%    1) only one "." to mark the file type
%    2) parameters are separated by "_"
%    3) the "key" parameter always has to be part of the parameter string
%       (i.e. fluxXXXXXXXmuCrab or fluxX.XXXXXXcgs without an underscore)
%    
%    If onle one argument is given, the above example for the flux is
%    automatically used as key and regexp.
%\seealso{simput_athenacrab}
%!%-

   variable s,key = "flux";
   variable regexp = "flux\([0-9.]+\)muCrab"R;
   switch(_NARGS)
   {case 1: (s) = (); }
   {case 3: (s,key,regexp) = (); }
   { help(_function_name()); return; }
   
   variable stmp = strchop(s,'/',0)[-1];

   s=stmp; % second part encodes the filetype
   stmp = strchop(s,'_',0);

   s = stmp[where(is_substr(stmp,key) == 1)];
   
   if (length(s) != 1){
      vmessage("Can not read convert parameter from file %s due to wrong format!",stmp);
      return -1.0;
   }
   s = s[0];
   stmp = string_matches (s,regexp)[1];

   return atof(stmp);
}
