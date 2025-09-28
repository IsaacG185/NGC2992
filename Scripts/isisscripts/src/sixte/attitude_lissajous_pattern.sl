define attitude_lissajous_pattern(prefix,expos,ra,dec){ %{{{
%!%+
%\function{attitude_lissajous_pattern}
%\synopsis{creates an Attitude File for a Lissajous pattern}
%\usage{attitude_lissajous_pattern(prefix,expos,ra,dec)}
%!%-

   %% attitude in RA, Dec given in degrees
   %% choose an amplitude of 15arcsec by default
   variable ampl = (qualifier("amplitude",15)*2/3600.);
   
   variable li = lissajous_pattern(;amplitude=ampl,tstop=expos,
				   x0=atof(ra),y0=atof(dec));
   
   variable att = struct{time=li.t*1.0001,ra=li.x,dec=li.y};
   variable skeys = struct{
      MJDREF=qualifier("MJDREF",52000.00),
      TSTART=min(att.time),
      TSTOP =max(att.time),
      ALIGNMEN=qualifier("alignment","NORTH"),
      origin="ECAP"
   };
   
   variable file = prefix+".att";
   
   fits_write_binary_table(file,"ATT",att,skeys);
   
   vmessage(" writing Attitude file %s",file);

   return file;
}
%}}}

