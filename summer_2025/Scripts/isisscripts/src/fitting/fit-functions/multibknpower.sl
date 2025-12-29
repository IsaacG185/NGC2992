%%%%%%%%%%%%%%%%%%%%%%%%
define multibknpower_fit(bin_lo, bin_hi, pars)
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{multibknpower (fit-function)}
%\synopsis{implements a multiply-broken powerlaw}
%\description
%    Only break energies >0 and the corresponding photon indices are considered.
%    \code{PhoIndx0} applies for energies below the first break.
%    Each \code{PhoIndex}i applies for energies above \code{BreakE}i, but below the next break.
%    As for \code{bknpower}, the normalization is the flux of the first power law at 1 keV
%    (not necessarily the broken power law model)  in ph/s/cm^2/keV.
%!%-
{
  variable norm    = pars[ 0    ];
  variable Gamma   = pars[ 1    ];
  variable Ebreaks = pars[[2::2]];
  variable Gammas  = pars[[3::2]];

  variable ind = where(Ebreaks>0);
  ind = ind[array_sort(Ebreaks[ind])];
  Ebreaks = [Ebreaks[ind], _Inf];
  Gammas = Gammas[ind];
  variable n = length(ind);

  variable Elo = _A(bin_hi);
  variable Ehi = _A(bin_lo);
  variable value = 0*bin_lo;
  variable Ebinwidth = Ehi - Elo;

  variable E0 = 0;
  variable i;
  _for i (0, n, 1)
  {
    ind = where(Ehi>E0 and Elo<Ebreaks[i]);
    if(length(ind))
    {
      variable ELO = _max(E0,         Elo[ind]);
      variable EHI = _min(Ebreaks[i], Ehi[ind]);
      variable one_minus_Gamma = 1 - Gamma;
      value[ind] += norm * (one_minus_Gamma==0 ? log(EHI/ELO) : (EHI^one_minus_Gamma - ELO^one_minus_Gamma)/one_minus_Gamma);
    }
    if(i<n)
    {
      E0 = Ebreaks[i];
      norm *= E0^(Gammas[i]-Gamma);
      Gamma = Gammas[i];
    }
  }
  return reverse(value);
}

add_slang_function("multibknpower", ["norm", "PhoIndx0",
  "BreakE1", "PhoIndx1",
  "BreakE2", "PhoIndx2",
  "BreakE3", "PhoIndx3",
  "BreakE4", "PhoIndx4",
  "BreakE5", "PhoIndx5",
  "BreakE6", "PhoIndx6",
  "BreakE7", "PhoIndx7",
  "BreakE8", "PhoIndx8",
  "BreakE9", "PhoIndx9",
  "BreakE10", "PhoIndx10",
], 0);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define multibknpower_default(i)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  if(i==0)    return (1, 0,  0, 1e10); % norm
  if(i==1)    return (2, 0, -2, 9);    % PhoIndx0
  if(i mod 2) return (2, 1, -2, 9);    % PhoIndx[i]
              return (0, 1,  0, 1e6);  % BreakE[i]
}

set_param_default_hook("multibknpower", &multibknpower_default);
