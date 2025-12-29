define rate2mdot (rate, sat, obj, erg)
{
  variable ratio = 0;
  if(sat=="INTEGRAL" && obj=="Vela X-1" && erg=="20-60")
    ratio = 1.04019e+35;  % This is only valid for the 20--60keV band using the spectrum from kreykenbohm08a and a rebinnend RMF version 1992a.
  else if(sat=="INTEGRAL" && obj=="Vela X-1" && erg=="20-30")
    ratio = 1.85141e+35;
  else if(sat=="INTEGRAL" && obj=="Vela X-1" && erg=="40-60")
    ratio = 7.11778e+35;
  else
    message("No known ratio value could be found!");

  variable eta = qualifier("eta", 0.1);  % accretion effiency
  variable c = 2.9979e10;  % speed of light in cm/s
  variable msun = 1.989e33;  % mass of sun in g
  variable mdot = (ratio * rate) / (eta * c^2) * (86400 * 365.2425) / msun;

  return mdot;  % in solar masses/year
}
