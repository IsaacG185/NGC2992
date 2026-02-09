define bin_average()
%!%+
%\function{bin_average}
%\synopsis{computes averages in histogram bins}
%\usage{Struct_Type bin_average(phi, rate, phi_lo[, phi_hi])}
%\qualifiers{
%\qualifier{err}{error on rate}
%\qualifier{quantiles}{array of quantiles to calculate for the distribution}
%\qualifier{quartiles}{calculate the .25, .5 and .75 quantiles}
%}
%\description
%    The fields of the returned structure are:\n
%    - \code{bin_lo} and \code{bin_hi}, defining the bins\n
%    - \code{value}: the average\n
%    - \code{err}: the standard error of the mean\n
%    - \code{n}: the number of points in each bin\n
%    and, if the \code{err} qualifier specifies an error array:\n
%    - \code{weighted_average}: an error-weighted average
%!%-
{
  variable phi, rate, phi_lo, phi_hi;
  switch(_NARGS)
  { case 3: (phi, rate, phi_lo) = (); phi_hi = make_hi_grid(phi_lo); }
  { case 4: (phi, rate, phi_lo, phi_hi) = (); }
  { help(_function_name()); return; }

  variable indices = wherenot(isnan(rate) or isinf(rate));
  phi = phi[indices];
  rate = rate[indices];

  variable N = length(phi_lo);
  variable rev;
  variable info = struct {
    bin_lo = phi_lo,
    bin_hi = phi_hi,
    value  = Double_Type[N],
    err    = Double_Type[N],
    n      = histogram(phi, phi_lo, phi_hi, &rev),
  };
  variable i;
  _for i (0, N-1, 1)
  { variable m = moment(rate[ rev[i] ]);
    info.value[i] = m.ave;
    info.err[i] = m.sdom;
  }
  variable err = qualifier("err");
  if(err!=NULL)
  {
    info = struct_combine(info, struct { weighted_average = Double_Type[N] });
    _for i (0, N-1, 1)
      info.weighted_average[i] = weighted_mean(rate[ rev[i] ], 1/err[ rev[i] ]^2);
  }
  variable quantiles = qualifier("quantiles");
  if(qualifier_exists("quartiles"))
  {
    if(quantiles==NULL)
      quantiles = [.25, .5, .75];
    else
    {
      quantiles = [quantiles, .25, .5, .75];
      quantiles = quantiles[array_sort(quantiles)];
    }
  }
  if(quantiles!=NULL)
  {
    variable fields = "quantile"+array_map(String_Type, &strtrans, array_map(String_Type, &string, quantiles), ".", "_");
    info = struct_combine(info, @Struct_Type(fields));
    _for i (0, N-1, 1)
    {
      variable r = rate[ rev[i] ];
      variable f;
      _for f (0, length(fields)-1, 1)
      {
	if(i==0)
	  set_struct_field(info, fields[f], Double_Type[N]);
	get_struct_field(info, fields[f])[i] = quantile(quantiles[f], r);
      }
    }
  }
  return info;
}
