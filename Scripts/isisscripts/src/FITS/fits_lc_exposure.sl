define fits_lc_exposure(file)
%!%+
%\function{fits_lc_exposure}
%\synopsis{returns the exposure time of a lightcurve,
%    given by a FITS-file, in seconds}
%\usage{Double_Type fits_lc_exposure(String_Type file)}
%!%-
{
  variable dt, u;
  (dt,u) = fits_read_key(file,"TIMEDEL","TIMEUNIT");
  u = strlow(u);
  switch(u)
    { case "s": return dt; }
    { case "d": return dt*86400.; }
    { vmessage("warning (%s): lightcurve fits file contains unknown TIMEUNIT=\"%S\"",  _function_name(), u); }
}
