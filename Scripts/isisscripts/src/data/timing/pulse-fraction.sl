% -*- mode: slang; mode: fold; -*- %

private define _ma_pf (pp, val) %{{{
{
  variable slo, shi,wlo,whi;
  if (NULL == val)
  {
    wlo = [wherefirstmin(pp.value)];
    whi = [wherefirstmax(pp.value)];
    shi = max(pp.value);
    slo = min(pp.value);
  }
  else
  {
    ifnot (0.0 < val < 0.5)
      throw UsageError, "PF ma: value must be between 0 and 0.5";

    variable s = array_sort(pp.value);
    variable cs = cumsum(pp.value[s]);

    variable lo = wherefirst(cs/cs[-1]>=val);
    if (NULL == lo) lo = 0;
    variable hi = wherelast(cs/cs[-1]<(1.0-val));
    if (NULL == hi) hi = length(pp.value)-1;

    shi = pp.value[s[hi]];
    slo = pp.value[s[lo]];
    wlo = where(pp.value<=pp.value[s[lo]]);
    whi = where(pp.value>=pp.value[s[hi]]);
  }

  variable ehi = sqrt(sumsq(pp.error[whi]))/length(whi);
  variable elo = sqrt(sumsq(pp.error[wlo]))/length(wlo);

  return (shi-slo)/(shi+slo), 2.0/(shi+slo)^2*sqrt((shi*elo)^2+(slo*ehi)^2);
}
%}}}

private define _rms_pf (pp, val) %{{{
{
  variable m = mean(pp.value);
  variable s = sumsq(pp.value-m);
  variable e = sum(sqr(pp.value-m)*pp.error);
  variable N = length(pp.value);

  return sqrt(s)/sqrt(N)/m, sqrt(e)/sqrt(s)/sqrt(m*2*N);
}
%}}}

private define _fft_pf (pp, val) %{{{
{
  variable N = length(pp.value)/2+1;
  variable ft = fft(pp.value, 1);
  variable r = 2*abs(ft[[0:N-1]]);

  % the error here is technically incorrect, it would be correct
  % if all pp.error would be equal. Let's hope it is not to far off
  variable e = sqrt(sumsq(pp.error))*[1.0, Double_Type[N-1]+0.5];

  variable s, whm;

  if (NULL == val)
  {
    whm = [1:N-1];
  }
  else if (typeof(val)==Int_Type)
  {
    if (val <= 0)
      throw UsageError, "PF fft: value must be positive";
    whm = [1:min([val,N-1])];
  }
  else
  {
    ifnot (0 < val < 1)
      throw UsageError, "PF fft: value must be between 0 and 1";

    variable sc = cumsum(r[[1:N-1]]);
    variable wlo = wherefirst((sc-sc[0])/(sc[-1]-sc[0])>=(1.0-val));
    if (NULL == wlo) wlo = 1;
    whm = [1:wlo];
  }

  s = sumsq(r[whm]);
  return sqrt(s)/r[0], sqrt(s*e[0]^2/r[0]^4 + sumsq(r[whm]*e[whm])/r[0]^2/s);
}
%}}}

private define _area_pf (pp, val) %{{{
{
  variable wlo, slo, whi;

  if (NULL == val)
  {
    wlo = [wherefirstmin(pp.value)];
    whi = [[0:wlo[0]-1],[wlo[0]+1:length(pp.value)-1]];
    slo = min(pp.value);
  }
  else
  {
    ifnot (0.0 < val < 1.0)
      throw UsageError, "PF area: value must be between 0 and 1";

    variable s = array_sort(pp.value);
    variable cs = cumsum(pp.value[s]);

    variable lo = wherefirst(cs/cs[-1]>=val);
    if (NULL == lo) lo = 0;
    wlo = where(pp.value<=pp.value[s[lo]], &whi);
    slo = pp.value[s[lo]];
  }

  variable ttot = sum(_max(pp.value, slo));
  variable etot = sumsq(pp.error[whi]);
  variable tmin = sum(_max(pp.value-slo, 0));
  variable emin = sumsq(pp.error[wlo]);

  return tmin/ttot, sqrt(length(pp.value)*((ttot-tmin)^2*etot+tmin^2*emin))/ttot^2;
}
%}}}

private define _fit_pf (pp, val) %{{{
{
  if (NULL == val)
    val = length(pp.value);

  variable ft = fft(pp.value, 1);
  variable ftc = Complex_Type[length(ft)];
  variable synt;
  ftc[0] = ft[0];
  variable N = length(ft);

  if (typeof(val) == Int_Type)
  {
    if (val < 1) throw UsageError, "PF fit: max harmonic must be larger than 0";
    val = min([val, length(pp.value)/2]);
    ftc[[1:val]] = ft[[1:val]];
    ftc[N-[1:val]] = ft[N-[1:val]];
    synt = fft(ftc, -1);
  }
  else
  {
    ifnot (0<val<1) throw UsageError, "PF fit: value must be between 0 and 1";

    synt = fft(ftc, -1);
    variable stat = sumsq((pp.value-Real(synt))/pp.error);
    variable i = 0;

    while ((i <= N/2) && stat/(N-(i+1)) > (1.0+val))
    {
      i++;
      ftc[i] = ft[i];
      ftc[N-i] = ft[N-i];
      synt = fft(ftc, -1);
      stat = sumsq((pp.value-Real(synt))/pp.error);
    }
  }

  variable lo = sqrt(N)*sum(Real(ftc[[1:N-1]])/2/PI/[1:N-1]-Imag(ftc[[1:N-1]])/2/PI/[1:N-1]);
  variable hi = sqrt(N)*sum(Real(ftc[[1:N-1]])/2/PI/[1:N-1]*sin(2*PI*[1:N-1]/N)
			    -Imag(ftc[[1:N-1]])/2/PI/[1:N-1]*cos(2*PI*[1:N-1]/N))
    + Real(ftc[0])*sqrt(N);

  variable pmin = min(Real(synt));

  return (hi-lo-pmin*N)/(hi-lo), (hi-lo-pmin)/(hi-lo)^2*sqrt(sumsq(pp.error));
}
%}}}

private variable PF_METHODS = Assoc_Type[Ref_Type];
PF_METHODS["ma"]   = &_ma_pf;
PF_METHODS["fft"]  = &_fft_pf;
PF_METHODS["dft"]  = &_fft_pf;
PF_METHODS["rms"]  = &_rms_pf;
PF_METHODS["area"] = &_area_pf;
PF_METHODS["fit"]  = &_fit_pf;

define pulse_fraction (pp)
%!%+
%\function{pulse_fraction}
%\synopsis{Calculate pulse fraction given a pulse profile}
%#c%{{{
%\usage{Double_Type (pf, pf_err) = pulse_fraction(Struct_Type pp; method);
%  \altusage{(pf, pf_err) = pulse_fraction(Struct_Type pp; method=value);}}
%
%\description
%  This function calculates the pulse fraction from the given
%  pulse profile (output of pfold) and given method.
%
%  Available methods are:
%    ma  : Modulation amplitude (min max), if a value 'a' is given,
%          calculate the amplitude between integral of pulse profile
%          that falls below the fraction 'a' and that which is above.
%
%    fft : Calculate the pulse fraction as sqrt(sumsq(A_k))/abs(A_0) where
%          A_k are the FFT amplitudes (k=1..N) and A_0 is the constant
%          factor. If value is given and of type Int_Type, take only the
%          FFT factors up to this value into account. If it is of type
%          Double_Type, take all the harmonics into account until the
%          remaining factors have a power of this fraction or less.
%
%    dft:  Same as fft.
%
%    rms : Calculate the RMS of the pulse profile, normalized by its average.
%
%    area: Calculate the area, that is, the integral of the pulse profile
%          subtracted the minimum. Normalized by the total area. The value,
%          if given, specifies the fraction that is considered the minimum.
%
%    fit:  Similar to fft. Takes all harmonics from the fft (or up to value
%          tolerance of a best fit, given in value). The resulting series
%          is integrated. If value is of type Int_Type, the series is
%          truncated at this harmonic.
%
%  To compute the pulse fraction only the fields 'values' and 'error' are
%  used. So if the PF is not obtained from \code{pfold} one can also run
%  it as
%    % RMS method example
%    pf = pulse_fraction(struct{value=..., error=...}; rms);
%
%  The input should have only positive values (i.e., not mean subtracted).
%
%  A rule of thumb is, that if the method is given without a value, that
%  the input is exact (i.e., values have no uncertainty). This is
%  appropriate for modelled pulse profiles. For measured data, giving a
%  value cuts down on the noise contributions and gives a more robust
%  estimate.
%
%  All methods also return an uncertainty estimate. Warning! Take the word
%  'estimate' here very seriously!
%
%\seealso{pfold}
%!%-
{
  variable pf, pfe, val, key;

  foreach key (get_struct_field_names(struct {@__qualifiers()}))
  {
    ifnot (assoc_key_exists(PF_METHODS, key))
      throw UsageError, sprintf("Pulse fraction method '%s' not known", key);
    val = qualifier(key);
    return @PF_METHODS[key](pp, val);
  }

  throw UsageError, "An estimator method for the pulse fraction must be specified, e.g., rms";
}
%}}}
