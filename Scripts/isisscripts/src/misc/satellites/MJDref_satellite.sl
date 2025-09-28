define MJDref_satellite()
%!%+
%\function{MJDref_satellite}
%\synopsis{returns the reference date (MJD) of a satellite's time}
%\usage{Double_Type MJDref_satellite(String_Type satellite)}
%!%-
{
  variable satellite;
  switch(_NARGS)
  { case 1: satellite = (); }
  { help(_function_name()); }

  switch( strlow(satellite) )
  { case "chandra" : return 50814.; }
  { case "xmm"     : return 50814.; }
  { case "integral": return 51544.; }
  { case "suzaku"  : return 51544.00074287037037037; }
  { case "xte"
    or case "rxte" : return 49353.000696574074; }
  { case "swift"   : return 51910.00074287038; }   % at least for a BAT lightcurve
  { case "rhessi"  : return 43874.0; }   % calculated from position data text file
  { case "fermi"   : return 51910.; } % UTC 00:00:00 on 1. January 2001 
  % (fermi, see: http://adsabs.harvard.edu/abs/2010arXiv1002.2280T)
  { case "nustar"  : return 55197.00076601852; } % Jan 1, 2010, in TT time system
  { case "xrism"   : return 58484.00080074074; } % Jan 1, 2019
  vmessage(`warning (%s): MJDref of satellite "%s" not known`, _function_name(), satellite);
  return -1;
}
