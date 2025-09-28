require("gsl", "gsl");

% helper function: interpolate the cross-correlation
% given by the ccf-qualifier at the point x
private define _pulseprofile_phase_connect_ccfint(x) {
  variable ccf = qualifier("ccf");
  variable phi = 1.*[0:length(ccf)]/length(ccf);
  if (x < 0) { x++; }
  if (x >= 1) { x--; }
  variable f = qualifier("f");
  return gsl->interp_cspline_periodic(x, phi, [ccf, ccf[0]]);
}

%%%%%%%%%%%%%%%%%%%%%%%%
define pulseprofile_phase_connect() {
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulseprofile_phase_connect}
%\synopsis{UNDER DEVELOPMENT; returns the phase shift between two pulse profiles}
%\usage{(Double Type phi, ccf) = pulseprofile_phase_connect(Struct_Type prof, ref);}
%\qualifiers{
%    \qualifier{shift}{automatically shifts the given profile in order to match
%            the phase of the reference profile (caution: overwrites
%            the input!)}
%}
%\description
%    UNDER DEVELOPMENT, USE WITH CAUTION! Send questions or bugs to
%    matthias.kuehnel@sternwarte.uni-erlangen.de
%
%    Determines the phase shift of the pulse profile 'prof' with
%    respect to the reference profile 'ref' by a cross-correlation.
%    The cross-correlation is interpolated to enhance the precision
%    beyond the pulse profile binning. Both pulse profiles need to
%    have the same number of bins.
%
%    The input structures have to have the same fields as returned
%    by 'epfold'.
%    
%    The resulting phase shift 'phi' and the maximum value of the
%    cross-correlation 'ccf' are returned.
%\seealso{pfold, CCF_1d}
%!%-
  variable prof, ref;
  switch (_NARGS)
    { case 2: (prof, ref) = (); }
    { help(_function_name); return; }

  % sanity check
  variable nbins = length(ref.value);
  if (length(prof.value) != nbins) {
    vmessage("error(%s): different number of phase bins", _function_name);
  }
  % calculate cross correlation function
  variable ccf = CCF_1d(ref.value, prof.value); 
  % find and interpolate maximum
  variable k = where_max(ccf)[0];
  variable ki = find_function_maximum(
    &_pulseprofile_phase_connect_ccfint, (k-1.)/nbins, (k+1.)/nbins;
    qualifiers = struct { ccf = ccf }
  );
  variable ccfi = _pulseprofile_phase_connect_ccfint(ki; ccf = ccf);
  % shift profile
  if (qualifier_exists("shift")) {
    if (ccfi > qualifier("ccflim")) {
      prof.value = shift_intpol(prof.value, -ki*nbins);
      prof.error = shift_intpol(prof.error, -ki*nbins);
    } else {
      vmessage("warning(%s): match below limit in order to shift the profile, skipping...");
    }
  }
  return (ki, ccfi);
}
