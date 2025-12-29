define SRT_spectrum()
%!%+
%\function{SRT_spectrum}
%\synopsis{extracts a spectrum from a SRT data structure}
%\usage{Struct_Type spec = SRT_spectrum(Struct_Type data);}
%\qualifiers{
%\qualifier{verbose}{}
%\qualifier{bins_to_cut}{[\code{=8}] number of bins at both sides of the spectrum that are discarded}
%\qualifier{bins_cut_low}{[\code{=0}] number of bins to additionaly cut from lower side}
%\qualifier{bins_cut_high}{[\code{=0}] number of bins to additionaly cut from upper side}
%\qualifier{normalize}{\code{spec.value} is normalized between 0 and 1.}
%\qualifier{vLSR}{transform the frequency grid to a velocity grid}
%\qualifier{filename=name}{plots the spectrum as name.ps in the
%     current directory}
%}
%\description
%\seealso{SRT_read}
%!%-
{
  variable data;
  switch(_NARGS)
  { case 1: data = (); }
  { help(_function_name()); return; }

  variable verbose = qualifier_exists("verbose");

  variable s = struct { bin_lo, bin_hi, value };
  variable f0 = data.f0[0];
  variable df = data.df[0];
  variable nbins = data.nbins[0];
  if(any(data.f0!=f0) || any(data.df!=df) || any(data.nbins!=nbins))
  {
    vmessage("error (%s): f0, df or nbins not constant", _function_name());
    return s;
  }

  s.bin_lo = f0 + [0 : nbins-1] * df;
  s.bin_hi = make_hi_grid(s.bin_lo);
  s.value = Float_Type[nbins];

  variable bins_cut_low=qualifier("bins_cut_low", 0), bins_cut_high=qualifier("bins_cut_high", 0);
  variable i, n, bins_to_cut=qualifier("bins_to_cut", 8);
  _for n (0, length(data.spec)-1, 1)
    _for i (bins_to_cut+bins_cut_low, nbins-1-bins_to_cut-bins_cut_high, 1)
      s.value[i] += data.spec[n][i];
  struct_filter(s, [bins_to_cut+bins_cut_low:nbins-1-bins_to_cut-bins_cut_high]);
  if(qualifier_exists("normalize"))
  {
    variable mn = min(s.value);
    variable mx = max(s.value);
    s.value = (s.value-mn)/(mx-mn);
  }
  else
    s.value /= length(data.spec);

  if(qualifier_exists("vLSR"))
  {
     
     if(string_match(getenv("USER"),"prakti",1) == 1)
     {
	message("\e[101m\e[34m\e[5m\e[25m Das sollt ihr schon selbst machen!!!\e[5m\e[m");
     } else
     {
	
	variable m = moment(data.vLSR);
	variable vcorr = m.ave;
	if(isnan(vcorr))
	{
	   vmessage("warning (%s): correction vLSR unknown", _function_name());
	   vcorr = 0;
	}
	else
	  if(verbose)
	    vmessage("<vcorr> = %f;  sdev(vcorr) = %f", vcorr, m.sdev);
	f0 = 1420.40575177;
	variable c = 299792.458;
	(s.bin_lo, s.bin_hi) = ( reverse((f0-s.bin_hi)/f0 * c - vcorr),
				 reverse((f0-s.bin_lo)/f0 * c - vcorr) );
     }
     
     xlabel("v [km/s]");
  } else
   {
      xlabel("Frequency [MHz]");
   }
   ylabel("T\\dAnt\\u [K]");
   
   if (qualifier_exists("filename"))
   {
      () = open_plot(qualifier("filename")+".ps/cps");
      hplot(s);
      close_plot; 
   }
   
   return s;
}
