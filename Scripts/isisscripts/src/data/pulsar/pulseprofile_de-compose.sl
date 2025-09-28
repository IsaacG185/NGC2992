%%%%%%%%%%%%%%%
define pulseprofile_compose()
%%%%%%%%%%%%%%%
%!%+
%\function{pulseprofile_compose}
%\synopsis{composes a pulse profile from sine and cosine functions}
%\usage{Struct_Type pulseprofile_compose(Struct_Type decomposition);}
%\description
%    Inverse of pulseprofile_decompose, see its help for details.
%\seealso{pulseprofile_decompose, pfold}
%!%-
{
  variable nbins, phi0, a, b, ampl;
  switch (_NARGS)
    { case 1: (phi0) = ();
      nbins = phi0.nbins;
      ampl = phi0.ampl;
      a = phi0.a;
      b = phi0.b;
      phi0 = phi0.phi0;
    }
    { help(_function_name()); return; }

  % calculate profile
  variable output = ampl * ones(nbins);
  variable i, s, c, phi = 2*PI*[0:1:#nbins];
  _for i (1, length(a), 1) {
    (s,c) = sincos(i*phi - phi0*2*PI);
    output += a[i-1]*s + b[i-1]*c;
  }
  
  return struct {
    bin_lo = [0:1.*(nbins-1)/nbins:#nbins],
    bin_hi = [1./nbins:1:#nbins],
    value = output
  };
}

private variable _pulseprofile_decompose_fitwrapper_freep = struct {
  ai = NULL, bi = NULL, an = 0, bn = 0
};
private define _pulseprofile_decompose_fitwrapper(x, pars) {
  % only specific orders given?
  variable fwf = _pulseprofile_decompose_fitwrapper_freep;
  variable spec = (fwf.ai != NULL && fwf.bi != NULL);
  % highest order
  variable n = spec ? max([fwf.an,fwf.bn]) : (length(pars)-2)/2;
  % array of coefficients
  variable a = Double_Type[n], b = Double_Type[n];
  if (spec) {
    if (fwf.an > 0) { a[fwf.ai[[:fwf.an-1]]-1] = pars[[2:fwf.an+1]]; }
    if (fwf.bn > 0) { b[fwf.bi[[:fwf.bn-1]]-1] = pars[[fwf.an+2:]]; }
  } else {
    a[*] = pars[[2:n+1]];
    b[*] = pars[[-n:]];
  }

  % return composition
  return pulseprofile_compose(struct {
    nbins = length(x), phi0 = pars[0],
    ampl = pars[1], a = a, b = b
  }).value;
}

%%%%%%%%%%%%%%%
define pulseprofile_decompose()
%%%%%%%%%%%%%%%
%!%+
%\function{pulseprofile_decompose}
%\synopsis{decomposes a pulse profile into sine and cosine functions}
%\usage{Struct_Type pulseprofile_decompose(
%      Struct_Type profile[, Integer_Type[] a_orders, b_orders]
%    );}
%\qualifiers{
%    \qualifier{amin/amax}{array of min/max values for the allowed range
%                of coefficient a_n during the fit (same order
%                as a_orders). Needs a_orders and b_orders to
%                be specified (default: NULL)}
%    \qualifier{bmin}{same as amin/amax for b_n}
%    \qualifier{phi0rng}{range of allowed phase offets [min,max]
%                (default: [-1,1])}
%    \qualifier{amplrng}{range of allowed amplitudes [min,max]
%                (default: [-_Inf,+_Inf])}
%    \qualifier{initpars}{array of initial parameters in the form
%                [phi0[, ampl[, a_n..., b_n...]]]
%                The values for a_n and b_n only apply if
%                a_orders and b_orders are specified
%                (default: [0, mean(profile.value), 0..., 0...])}
%    \qualifier{maxord}{highest order to use (if no specific orders for
%            a or b are given; default: nbins/2-1)}
%}
%\description
%    The given pulse profile, F, of the form
%       struct { Double_Type[] bin_lo, bin_hi, value }
%    is fitted by a series of sine and cosine functions,
%    
%    F(phi) = ampl + sum_n^N a_n*sin(2PI*(phi+phi_0)*n)
%                            + b_n*cos(2PI*(phi+phi_0)*n)
%
%    where phi is the phase bin, ampl is the mean flux, N is
%    the highest order to use, phi_0 is a phase offset, and
%    a_n and a_b are the coefficients of the sine and cosine,
%    respectively.
%    By default the series is calculated up to the highest
%    possible order, which is related to the number of phase
%    bins (Nyquist frequency). It is also possible to specify
%    the orders, which has to be taken into account during the
%    fitting, for the sine and cosine function (a_orders and
%    b_orders, respectively).
%    The returned structure contains the resulting fit
%    parameters,
%    
%    struct {
%      Integer_Type nbins, % number of phase bins
%      Double_Type phi0,   % phase offset
%      Double_Type ampl,   % mean amplitude (zero order)
%      Double_Type[] a,    % sine coefficients
%      Double_Type[] b     % cosine coefficients
%    }
%
%    where the indices of the arrays a and b specify the order,
%    n, of the coefficient (starting with n=1). This structure
%    can be passed to 'pulseprofile_compose' to calculate the
%    modelled pulse profile from the coefficients.
%\example
%    % synthetic example profile
%    variable nbins = 32;
%    variable prof = struct { bin_lo, bin_hi, value };
%    (prof.bin_lo, prof.bin_hi) = linear_grid(0, 1, nbins);
%    prof.value  = 2 + 8*sin((prof.bin_lo)*2*PI)^2;
%    prof.value += 4*sin((prof.bin_lo)*PI);
%    hplot(prof);
%    
%    % decomposition using the first order sine and second
%    % order cosine coefficients only
%    variable decomp = pulseprofile_decompose(prof, [1], [2]);
%    ohplot(pulseprofile_compose(decomp));
%\seealso{pfold, pulseprofile_compose}
%!%-
{
  variable fwf = _pulseprofile_decompose_fitwrapper_freep;
  variable prof, spec = 0, ai = NULL, bi;
  switch(_NARGS)
    { case 1: (prof) = (); }
    { case 3: (prof, ai, bi) = ();
      fwf.ai = @ai;
      fwf.bi = @bi;
      spec = 1;
    }
    { help(_function_name()); return; }

  variable nbins = length(prof.value);

  % highest order (< Nyquist frequency)
  variable n = spec ? max([ai,bi]) : qualifier("maxord", nbins/2-1);
  if (n > nbins/2-1) { vmessage("error (%s): maxord needs to be <=d%!", _function_name, nbins/2-1); return; }
  
  % parameter ranges
  variable amin = spec ? qualifier("a_min", NULL) : NULL;
  variable amax = spec ? qualifier("a_max", NULL) : NULL;
  variable bmin = spec ? qualifier("b_min", NULL) : NULL;
  variable bmax = spec ? qualifier("b_max", NULL) : NULL;
  if (spec) {
    if (amin != NULL && length(amin) != length(ai)) { vmessage("error (%s): a_min has to have the same length as a_orders!", _function_name); return ; }
    if (amax != NULL && length(amax) != length(ai)) { vmessage("error (%s): a_max has to have the same length as a_orders!", _function_name); return ; }
    if (bmin != NULL && length(bmin) != length(bi)) { vmessage("error (%s): b_min has to have the same length as a_orders!", _function_name); return ; }
    if (bmax != NULL && length(bmax) != length(bi)) { vmessage("error (%s): b_max has to have the same length as a_orders!", _function_name); return ; }
  }
  variable phi0rng = qualifier("phi0rng", [-1,1]);
  if (length(phi0rng) != 2) { vmessage("error (%s): phi0rng has to have 2 elements", _function_name); return; }
  variable amplrng = qualifier("amplrng", [-_Inf,_Inf]);
  if (length(amplrng) != 2) { vmessage("error (%s): amplrng has to have 2 elements", _function_name); return; }
  
  % starting values (phi0, ampl)
  variable initpars = qualifier("initpars", Double_Type[0]);
  if (length(initpars) < 1) { initpars = [initpars, 0.]; }
  if (length(initpars) < 2) { initpars = [initpars, 2*mean(prof.value)]; }
  variable pars = [initpars[0], initpars[1]];
  variable a = Double_Type[0], b = Double_Type[0];
  % iterative fit
  variable i, k;
  _for i (1, n, 1) {
    % increase order
    if (spec) {
      k = wherefirst(ai == i);
      if (k != NULL) { a = [a, length(initpars) > 2 ? initpars[k] : 0]; }
      k = wherefirst(bi == i);
      if (k != NULL) { b = [b, length(initpars) > 2 ? initpars[length(ai)+k] : 0]; }
      fwf.an = length(a);
      fwf.bn = length(b);
    } else {
      a = [a, 0]; b = [b, 0];
    }
    pars = [pars[[0,1]], a, b];

    % fit
    (pars,) = array_fit(
      prof.bin_lo, prof.value, NULL, pars,
      [phi0rng[0], amplrng[0],
       amin == NULL || length(a) == 0 ? -_Inf*ones(length(a)) : amin[[:length(a)-1]],
       bmin == NULL || length(b) == 0 ? -_Inf*ones(length(b)) : bmin[[:length(b)-1]]],
      [phi0rng[1], amplrng[1],
       amax == NULL || length(a) == 0 ? +_Inf*ones(length(a)) : amax[[:length(a)-1]],
       bmax == NULL || length(b) == 0 ? +_Inf*ones(length(b)) : bmax[[:length(b)-1]]],
      &_pulseprofile_decompose_fitwrapper
    );
    a = pars[[2:length(a)+1]];
    b = pars[[length(a)+2:]];
  }

  % reset and return
  if (spec) {
    a = Double_Type[n]; b = Double_Type[n];
    if (fwf.an > 0) { a[fwf.ai[[:fwf.an-1]]-1] = pars[[2:fwf.an+1]]; }
    if (fwf.bn > 0) { b[fwf.bi[[:fwf.bn-1]]-1] = pars[[fwf.an+2:]]; }
    fwf.ai = NULL;
    fwf.bi = NULL;
    fwf.an = 0;
    fwf.bn = 0;
  }
  return struct {
    nbins = nbins,
    phi0 = pars[0],
    ampl = pars[1],
    a = a,
    b = b
  };
}
