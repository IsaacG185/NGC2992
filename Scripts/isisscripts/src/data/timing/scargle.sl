define scargle()
%%%%%%%%%%%%%%%%%%
%!%+
%\function{scargle}
%\synopsis{Computes the lomb-scargle periodogram of an unevenly sampled lightcurve}
%\usage{Struct_Type res = scargle (t, c); % where t and c contain time and counts of the lc}
%\qualifiers{
%\qualifier{fmin}{minimum frequency to be used (NOT ANGULAR FREQ!), has precede over pmin, pmax}
%\qualifier{fmax}{maximum frequency to be used (NOT ANGULAR FREQ!), has precede over pmin, pmax}
%\qualifier{pmin}{minimum period to be used}
%\qualifier{pmax}{maximum period to be used}
%\qualifier{omega}{array of angular frequencies for which the PSD values are desired;
%                    if set, value for numf will be reset to length of omega during code}
%\qualifier{noise}{for the normalization of the periodogram.
%                    if not set, equal to the variance of the original lc.}
%\qualifier{numf}{number of independent frequencies}
%\qualifier{old}{if set computing the periodogram according to J.D. Scargle, 1982, ApJ 263, 835
%                  if not set, computing the periodogram with the fast algorithm
%                  of W.H. Press and G.B. Rybicki, 1989, ApJ 338, 277.}
%\qualifier{nu}{if set, output structure also contains frequency}
%\qualifier{om}{if set, output structure also contains angluar frequency}
%}
%\description
%     (transcribed from IDL-program scargle.pro)
%
%     The Lomb Scargle PSD is computed according to the definitions
%     given by Scargle, 1982, ApJ 263, 835, and Horne and Baliunas,
%     1986, ApJ 302, 757. Beware of patterns and clustered data
%     points as the Horne results break down in this case! Read and
%     understand the papers and this code before using it! For the
%     fast algorithm read W.H. Press and G.B. Rybicki, 1989, ApJ 338,
%     277.
%
%     The code is still stupid in the sense that it wants normal
%     frequencies, but returns angular frequency...
%
%     The transcribed version is version 1.7, 2000.07.28
%
%     Unlike the IDL function, the isis code returns a structure
%     containing the power spectral density (psd) and period and, if
%     specified by qualifiers, also the frequency (nu) and angular
%     frequency (om).
%
%\example
%     variable t = [0:100:0.1];
%     variable c = sin(t)+((rand(1000)/(2^32-1)*0.2)+0.9);
%     variable res = scargle(t, c; nu);
%     plot(res.period,res.psd);
%     plot(res.nu,res.psd);
%!%-
{
   
   % read in light curve given to the function
   variable whatyouget;
   variable i;
   variable m;
   variable t,c;
   switch(_NARGS)
     {case 2: (t,c)=();}
     {help(_function_name()); return;}
   
   % read qualifiers given, ordered like they are used in the code
   variable noise = qualifier("noise", sqrt(moment(c).var));
   
   % makes time managable (Scargle periodogram is time-shift invariant)
   
   variable time = t-t[0];
   
   % number of independent frequencies (Horne and Baliunas, eq. 13)
   variable n0 = length(time);
   variable horne = typecast((-6.362+1.193*n0+0.00098*n0^2.), Long_Type);
   
   % set numf or use default value if qualifier does not exist
   variable numf = int( qualifier("numf", ( horne<0 ? 5 : horne ) ) );

   % min. freq.  is 1/T
   variable fmin = double( qualifier("fmin", 1.0/qualifier("pmax", max(time) ) ) );
   
   % max. freq.: approx. to Nyquist frequency
   variable fmax = double( qualifier("fmax", 1.0/qualifier("pmin", (2.0*max(time))/n0 ) ) );

   % if fmin > fmax, calculations go crap
   if (fmin > fmax)
     {
	sprintf("Scargle Error: fmin > fmax! Check your inputs!");
     }
   
   
   % if omega is not given, compute it
   variable om;
   ifnot (qualifier_exists("omega"))
     {
	om = 2.*PI*(fmin+((fmax-fmin)*[0:numf-1]/(numf-1.)));
     }
   else
     {
	om = double(qualifier("omega"));
	numf = length(om);
     }

   % Periodogram
   variable px,nu,period;
   if (qualifier_exists("old"))
     {
	% subtract the mean from data
	variable cn = c-mean(c);
	
	% compute the periodogram
	px = Double_Type[numf];
	for (i=0; i<numf; i++)
	  {
	     variable tau = atan(sum(sin(2.*(om)[i]*time))/sum(cos(2.*(om)[i]*time)));
	     tau = tau/(2.*(om)[i]);
	     
	     variable co = cos(om[i]*(time-tau));
	     variable si = sin(om[i]*(time-tau));
	     
	     px[i] = 0.5*(sum(cn*co)^2/sum(co^2) + sum(cn*si)^2/sum(si^2));
	  }
	
	% correct normalization
	variable var = moment(cn).var;
	if (var!=0)
	  {
	     px=px/var;
	  }
	else
	  {
	     sprintf("Scargle Warning: Variance is zero");
	  }

	% some other nice helpers
	% computed here due to memory usage reasons

	nu = om/(2.*PI);
	period = 1./nu;

        whatyouget = struct { psd=px, period=period };
        if (qualifier_exists("nu")) { whatyouget = struct_combine( whatyouget, struct {nu=nu});}
        if (qualifier_exists("om")) { whatyouget = struct_combine( whatyouget, struct {om=om});}

        return whatyouget;
     }
   
   % Ref.: W.H. Press and G.B. Rybicki, 1989, ApJ 338, 277
   
   % Eq. (6); s2, c2
   variable s2 = Double_Type[numf];
   variable c2 = Double_Type[numf];
   
   for (i=0; i<numf; i++)
     {
	s2[i] = sum(sin(2.*om[i]*time));
	c2[i] = sum(cos(2.*om[i]*time));
     }

   % Eq. (2): Definition => tan(2omtau)
   % --- tan(2omtau) = s2/c2
   variable omtau = atan(s2/c2) / 2.;
  
   % cos(tau), sin(tau)
   variable cosomtau = cos(omtau);
   variable sinomtau = sin(omtau);
   
   % Eq. (7); sum(cos(t-tau)^2) and sum(sin(t-tau)^2)
   variable tmp = c2*cos(2.*omtau) + s2*sin(2.*omtau);
   variable tc2 = 0.5*(n0+tmp);      % sum(cos(t-tau)^2)
   variable ts2 = 0.5*(n0-tmp);      % sum(sin(t-tau)^2)
   
   % clean up
   tmp = 0.;
   omtau = 0.;
   s2 = 0.;
   c2 = 0.;
  
   % computing the periodogram for the original lc
   
   % subtract mean from data
   cn = c - mean(c);
   
   % Eq. (5); sh and ch
   variable sh = Double_Type[numf];
   variable ch = Double_Type[numf];
   
   for (i=0; i<numf; i++)
     {
	sh[i] = sum(cn*sin(om[i]*time));
	ch[i] = sum(cn*cos(om[i]*time));
     }
   
   % Eq. (3)
   px = (ch*cosomtau + sh*sinomtau)^2 / tc2
     + (sh*cosomtau - ch*sinomtau)^2 / ts2;
   
   % correct normalization
   px = 0.5*px/(noise^2);
   
   % some other nice helpers
   % computed here due to memory usage reasons

   nu = om/(2.*PI);
   period = 1./nu;

   whatyouget = struct { psd=px, period=period };
   if (qualifier_exists("nu")) { whatyouget = struct_combine( whatyouget, struct {nu=nu});}
   if (qualifier_exists("om")) { whatyouget = struct_combine( whatyouget, struct {om=om});}

   return whatyouget;
}
