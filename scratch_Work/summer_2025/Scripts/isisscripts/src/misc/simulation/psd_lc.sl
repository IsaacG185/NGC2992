private define psd_lc_normalized_lightcurve(rate, mean, sigma, poisson, c)
{
  variable m = moment(rate);
  % renormalize to desired mean count rate and variance
  if (poisson)
  {
    % the real count rate is Poisson distributed, therefore the time
    % resolution and number of PCUs must be taken into account
    if( (sigma*c)^2 < mean*c)
       return vmessage("error (%s): sigma%s is too small", _function_name(), qualifier("id", ""));
    sigma = sqrt(((sigma*c)^2-mean*c))/c;

    return prand((mean + (rate-m.ave)/m.sdev * sigma)*c)/c;
  }
  else
    return        mean + (rate-m.ave)/m.sdev * sigma;
}


%%%%%%%%%%%%%
define psd_lc()
%%%%%%%%%%%%%
%!%+
%\function{psd_lc}
%\synopsis{simulate a random light curve that follows a given PSD using the algorithm of Timmer and Koenig}
%\usage{Double_Type rate[] = psd_lc(Integer_Type n, Double_Type dt, Ref_Type PSD);
%\altusage{(rate1, rate2) = psd_lc(Integer_Type n, Double_Type dt, Ref_Type PSD; time_lag_spectrum=...);}
%}
%\qualifiers{
%\qualifier{mean}{[= 100]: mean count rate of the simulated lightcurve}
%\qualifier{sigma}{[= 20]: standard deviation of the simulated lightcurve}
%\qualifier{poisson}{if Poisson noise should be applied on the lightcrurve}
%\qualifier{nr_PCUs}{[= 1]: number of PCUs}
%\qualifier{time_lag_spectrum}{spectrum of time lags (two lightcurves will be returned)}
%\qualifier{mean_2}{[= 100]: mean count rate of the second lightcurve}
%\qualifier{sigma_2}{[= 20]: standard deviation of the second lightcurve}
%}
%\description
%    \code{n} is the number of bins of the simulated lightcurve.
%    It should be a power of two for best performance of the FFT.
%    \code{dt} is the time resolution.
%    \code{PSD} is a reference to a function which takes one argument
%    -- the frequency -- and calculates the corresponding PSD value.
%    The number of PCUs is needed for the calculation of Poisson noise
%    if a mean RXTE count rate is given in counts/PCU.
%
%    If \code{time_lag_spectrum} is reference to a function of one argument
%    -- the frequency -- that calculates the time lag spectrum,
%    an additional second lightcurve is returned that has
%    the corresponding time lag with respect to the first one.
%
%    see Timmer & Koenig (1995): "On generating power law noise",
%    A&A 300, 707-710
%!%-
{
  variable n, dt, PSD;
  switch(_NARGS)
  { case 3: (n, dt, PSD) = (); }
  { return help(_function_name()); }

  variable n_2 = int(n/2);
  if(2*n_2 != n)
    return vmessage("error (%s): n must be even", _function_name());

  variable time_lag_spectrum = qualifier("time_lag_spectrum");  % if this qualifier is set, 2 lightcurves will be returned
  variable poisson = qualifier_exists("poisson");  % if poisson noise should be applied on the simulated lightcurve
  variable c = dt * qualifier("nr_PCUs", 1);

  % generate frequencies {1/T,...,1/2t}
  variable f = 1.*[1:n_2]/(n*dt);
  variable fa = @PSD(f ;;__qualifiers() );
  variable fac = sqrt(1/2.*fa);
  % multiply by gaussian distributed random number to get real and imaginary part
  variable pos_real = grand(n_2)*fac;
  variable pos_imag = grand(n_2)*fac;
  pos_imag[n_2-1] = 0;
  % get the values for negative frequencies as g(-f)=g*(f)
  variable real = [ 0., pos_real,  pos_real[[n_2-2:0:-1]] ];
  variable imag = [ 0., pos_imag, -pos_imag[[n_2-2:0:-1]] ];
  variable z = real + imag*1i;

  psd_lc_normalized_lightcurve
    (
	Real( fft(z, 1) ),       % simulated light curve from its Fourier transform
	qualifier("mean", 100),  % mean count rate of the simulated lightcurve
	qualifier("sigma", 20),  % standard deviation of the lightcurve to be simulated
	poisson,
	c
    );  % first return value left on stack

  if(time_lag_spectrum == NULL)
    return;  % no timelag given => no second lightcurve

  %
  % simulate the second lc with a time lag
  %
  variable f1 = [0, f];
  variable f2 = f[[n_2-2:0:-1]];
  psd_lc_normalized_lightcurve
    (
	Real( fft(z*[exp( 2i*PI*f1 * @time_lag_spectrum(f1 ;;__qualifiers() )),
		     exp(-2i*PI*f2 * @time_lag_spectrum(f2 ;;__qualifiers() ))], 1) ),
	qualifier("mean_2", 100),  % mean count rate of the simulated lightcurve
	qualifier("sigma_2", 20),  % standard deviation of the lightcurve to be simulated
	poisson,
	c
      ; id="_2"
    );  % second return value left on stack
}
