private define gliding_average ( p, stat, region ) { %{{{
   % region in promille of total length of p
   variable r = nint( length(p) * region / 1000. );
   variable out = Double_Type [ length(stat) ];
   variable i;
   _for i ( 0, length(p) - 1, 1 ) {
      variable x = p [[max([0,i-r]):min([length(p)-1,i+r])]];
      variable y = stat [[max([0,i-r]):min([length(p)-1,i+r])]];
      variable model = linear_regression ( x, y );
      out[i] = model.a + model.b * x[where_min(abs(x-p[i]))];
      }
   return out;
}
%}}}

private define quality_function ( mean1, sigma, x ) { %{{{
   if (abs(x-mean1)<sigma) {
      return 1. - 0.5*((x-mean1)/sigma)^6.;
   } else {
      return 0.5/((x-mean1)/sigma)^2.;
   }
}
%}}}

private define error_estimate ( p1, stat1, period, error2_lo, error2_hi ) { %{{{
   variable lo = error2_lo;
   variable hi = error2_hi;
   variable index_min = where_min(abs(p1 - period + lo));
   variable index_max = where_min(abs(p1 - period - hi));
   variable p = p1[[index_min:index_max]];
   variable stat = stat1[[index_min:index_max]];
   variable area = Double_Type [ length(p) ];
   area[0] = stat[0];
   variable i;
   _for i ( 1, length(area)-1, 1) {
      area[i] = area[i-1] + stat[i]; }
   variable areas = area - mean(area);
   areas = sign(areas) * log1p( abs(areas) );

   variable prime = Double_Type [ length(areas) ];
   _for i ( 0, length(prime)-1, 1 ) {
      variable grid = [ max( [ 0, i-1 ] ): min ( [ length(prime)-1, i+1 ] ) ];
      prime[i] = linear_regression ( p[grid], areas[grid] ).b;
      }
   variable where_peak = where_min( abs( period - p ) );
   variable mi = where_min ( abs( prime[[:where_peak]] - 0.75 * mean(prime) ) );
   variable ma = where_min ( abs( prime[[where_peak:]] - 0.75 * mean(prime) ) ) + where_peak;
   variable error_lo = p[where_peak] - p[mi];
   variable error_hi = p[ma] - p[where_peak];

   return mean( [ error_lo, error_hi ] );
}
%}}}

%private define sqrsinc_xyfit() { %{{{
%   variable xref, yref, par;
%   switch (_NARGS)
%   { case 0: return ["center [center]", "norm [norm]", "width [width]", "offset [offset]", "asymmetry [asymmetry]" ]; }
%   { case 3: (xref, yref, par) = (); }
%   { return; }
%   variable x = @xref - par[0];
%   variable xx = x*(1+(1+sign(x))*par[4])/par[2];
%   @yref = par[3] + par[1] * sqr( sin(xx)/(xx) );
%}
%}}}

private define get_qualifier ( qualifier_structure, qualifier_name, default_value ) { %{{{
   try {
      return get_struct_field ( qualifier_structure, qualifier_name );
   } catch InvalidParmError: {
      return default_value;
   }
}
%}}}

private define print_info(arg) {%{{{
   if (arg == "flags" ) {
      () = printf(`
      ; end_reached: If the distance from the peak to one of the ends of
                     the period search range is small, this flag is
                     either -1 or 1 for the lower resp. upper end.
      ; no_blocks: This flag counts the smoothing iterations necessary
                   until the block analysis succeeds (max 4). Indicator
                   for a noisy statistics.
      ; bad_profile: Indicates that the folded profile is quite noisy.
      ; bad_blocks: Indicates that all blocks where maxima are found are
                    quite broad relative to dp, usually an indicator
                    that the statistics is not well behaved.
      ; difference: An integer valued measure for the difference between
                    the peak found and the initial guess in terms of sigma.
      ; exact: Set if epfold was done with exact qualifier.
      ; fit_succeeded: If 0, the peak found from the fit differed
                       considerably from the first estimate. In this case
                       the fitted peak is not used.
      ; dp: Gives the dp used.
      ; [ t ]: The timespan of the lightcurve. If short relative to p, this
           can cause problems.

      `R);
   } else if (arg == "error") {
      () = printf(`
      Two errors are given: 'err_theory' and 'err_area'. Normally, both
      should be approximately equal.

      'err_theory' stems from the timing background of this function and is
      calculated using an empirical estimate given by Leahy 1987. Since it
      is sensitive to the height of the peak, it should NOT be used if you
      want to find the peak of some other curve than one stemming from the
      epochfolding statistics. In the context of timing, this error might
      be slightly underestimated. Furthermore, it is to be taken with
      great care if you used the 'exact' qualifier for epfold, because in
      this case the statistics seem to be wrong.

      'err_area' is a measure for the approximate width of the plateau on
      top of the peak. It basically finds the interval for which the
      curve's fluctuations are more significant than any underlying slope.
      Normally, it is slightly larger than 'err_theory'.

      The field named 'error' is just the combination of both errors added
      in quadrature. This should be a reasonable and perhaps slightly
      too conservative estimate of the error.

      `R);
   }
}
%}}}

%%%%%%%%%%%%%%%%%%%%%
define find_peak ( ) %{{{
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{find_peak}
%\synopsis{Written for epoch folding purposes, it finds peaks of certain characteristics}
%\usage{Struct_Type find_peak(Struct_Type input)}
%\description
%
% The input should be a Struct_Type of the form:
%     { p, stat, [ lc ], [ nbins_epfold ] , [ expectation ] , [ sigma ] }
% The individual fields are:
%     * p, stat: arrays of doubles, the peak is looked for in stat
%     * lc: struct { time, rate }, the original lightcurve
%     * nbins_epfold: necessary in order to obtain an error estimate
%     * expectation: approximate location of the peak in p
%     * sigma: approximate error the expectation value has
% lc and nbins_epfold reflect the original application of this function,
% but it can be used without these arguments to find peaks in other
% curves.
% The output is a Struct_Type of the form:
%     { period, error, [ profile ], err_area, err_theory, width_lo,
%     width_hi, statvsp, flags, [ bayes ], [ fit ], badness }
% flags is a structure of indicators regarding the quality of the
% output, badness is a coarse estimate how well the process worked.
% A value of 0 is desirable, 1-2 could be acceptable, 3-4 is usually
% an indication of bad input data and for larger values something has
% seriously gone wrong. Fields marked [] will not be output if the
% qualifiers chosen require it.
% In the default configuration, this function works the following way:
%
%     (1) A bayesian block analysis finds possible maxima
%         * if the block analysis fails, a smoothing algorithm is used
%           to remove noise in the curve, since the block analysis is
%           quite susceptible to noise
%     (2) The maxima are ranked considering:
%         * the width (broad is an advantage, but very broad maxima in
%           comparison to dp = p^2 / T resp sigma are discarded)
%         * the distance to the expected value, where anything within
%           sigma is ranked approximately equal
%     (3) Maxima with a quality exceeding the tolerance level are
%         taken and the accurate peak is found:
%         * a first estimate is a weighted mean of points within the
%           maximum block
%         * the accurate value is determined by fitting a given
%           xy-function to the peak. The proportion of dp used for
%           choosing the range for the fit is controlled by the
%           qualifier fit_part. If you do not expect considerable
%           secondary maxima, this variable can be set as big as 1.
%           However, if secondary peaks are expected to occur, a value
%           this large can make the fit useless.
%     (4) For each possible peak the lightcurve is folded and the
%         resulting pulse profile is examined. The peak corresponding to
%         the best overall result is taken.
%
% If the fit_fct qualifier is used, the function has to have the following
% parameters (in this specific order):
%     (1) peak
%     (2) measure for the height
%     (3) measure for the broadness of the peak
%     (4) absolute offset
%     (5) measure for the asymmetry of the peak
% All qualifiers can also be passed using a structure named
% 'find_peak_qualifiers'. If this qualifier is given, its content will
% overwrite all other qualifiers. If using this structure, all
% qualifiers are expected to have values (i.e. only_max = 1). This is
% helpful if you want to make things easier to read in scripts.
%
%\qualifiers{
%\qualifier{only_max}{neither block analysis nor fit are performed}
%\qualifier{blocks_but_only_max}{block analysis is performed but only the highest bin in the best block taken}
%\qualifier{weighting}{weights for properties of a peak [area, sharpness, distance to expectation, profile quality] (default: [1,1,1,1])}
%\qualifier{no_fit}{nlock analysis is performed but only the first estimate taken}
%\qualifier{fit_fct}{an xyfit function for the fit, passed as a string (default: "sqrsinc")}
%\qualifier{fit_part}{measure for the part of the peak used for the fit (default: .3)}
%\qualifier{tolerance}{determines how many peaks are passed to step (4), in [0,1) (default: .99)}
%\qualifier{smoothing}{how strong the smoothing algorithm works (default: 10.)}
%\qualifier{ncp_prior}{argument for block analysis. If a string is given, the default block analysis routine will be used (default: 100)}
%\qualifier{fp_rate}{argument for block analysis, see its help}
%\qualifier{no_profile}{No pfold will be executed. Corresponds to tolerance -> 1 and less computation}
%\qualifier{nbins_pfold}{argument for pfold, see its help}
%\qualifier{pfold_not_exact}{changes how pfold is executed. Recommended as long as the exact-bug is not fixed}
%\qualifier{exact}{passes the information that the statistic was calculated using the exact qualifier}
%\qualifier{flag_info}{detailed information regarding the content of the flags structure is given, NOTHING else is done}
%\qualifier{error_info}{detailed information about the calculation of errors is given, NOTHING else is done}
%\qualifier{chatty}{boolean value (default: 1)};
%}
%\seealso{pulseperiod_search, epfold, pulseperiod_epfold, split_and_epfold_lc, bayesian_blocks, pfold}
%!%-
{
   variable qu = qualifier("find_peak_qualifiers", empty_struct());
   if (qualifier_exists("flag_info") or struct_field_exists(qu, "flag_info")) {
      print_info("flags");
      return;
   }
   if (qualifier_exists("error_info") or struct_field_exists(qu, "error_info")) {
      print_info("error");
      return;
   }

   variable lc = 0;
   variable p, stat, nbins_epfold;
   variable expectation = 0.;
   variable sigma_expectation = DOUBLE_MAX;
   % Qualifiers as usual %{{{
   % These qualifiers are given as usual. If a structure named 'find_peak_qualifiers' is given, it will *overwrite* any input here!
   variable find_peak_qualifiers_default = empty_struct ();
   variable aa;
   if (qualifier_exists("weighting")) { aa=struct{weighting=qualifier("weighting")};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("ncp_prior")) { aa=struct{ncp_prior=qualifier("ncp_prior")};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("fp_rate")) { aa=struct{fp_rate=qualifier("fp_rate")};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("smoothing")) { aa=struct{smoothing=qualifier("smoothing")};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("fit_fct")) { aa=struct{fit_fct=qualifier("fit_fct")};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("fit_part")) { aa=struct{fit_part=qualifier("fit_part")};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("tolerance")) { aa=struct{tolerance=qualifier("tolerance")};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("dp")) { aa=struct{dp=qualifier("dp")};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("nbins_pfold")) { aa=struct{nbins_pfold=qualifier("nbins_pfold")};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("chatty")) { aa=struct{chatty=qualifier("chatty")};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("blocks_but_only_max")) { aa=struct{blocks_but_only_max=1};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("no_profile")) { aa=struct{no_profile=1};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("exact")) { aa=struct{exact=1};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("pfold_not_exact")) { aa=struct{pfold_not_exact=1};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("only_max")) { aa=struct{only_max=1};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   if (qualifier_exists("no_fit")) { aa=struct{no_fit=1};find_peak_qualifiers_default=struct_combine(find_peak_qualifiers_default,aa); }
   %}}}

   if (length(get_struct_field_names(find_peak_qualifiers_default)) != 0 and qualifier_exists("find_peak_qualifiers") ) {
      vmessage("Warning(%s): You have provided qualifiers both as a structure and as individual arguments, I will only consider the structure", _function_name);
   }

   variable find_peak_qualifiers = qualifier ( "find_peak_qualifiers", find_peak_qualifiers_default );
   % Qualifiers as structure, Sanity checks %{{{
   % If present, the structure 'find_peak_qualifiers' overwrites all other qualifiers.
   variable weighting = get_qualifier ( find_peak_qualifiers, "weighting", [1,1,1,1] );%{{{
   ifnot (typeof(weighting) == Array_Type and (_typeof(weighting) == Double_Type or _typeof(weighting) == Integer_Type)) {
      vmessage("Warning(%s): weighting has to be an array of numbers, setting it to default", _function_name);
      weighting = [1,1,1,1];
   }
   ifnot (length(weighting) == 4) {
      vmessage("Warning(%s): weighting has to be an array of lenght 4, setting it to default", _function_name);
      weighting = [1,1,1,1];
   } 
   weighting = double(weighting); %}}}
   variable ncp_prior = get_qualifier ( find_peak_qualifiers, "ncp_prior", 100. );%{{{
   ifnot (typeof(ncp_prior) == Double_Type or typeof(ncp_prior) == Integer_Type) {
      ifnot (ncp_prior == "default") {
         vmessage("Warning(%s): ncp_prior has to be a number or 'default', setting it to 100", _function_name);
         ncp_prior = 100.;
      }
   }
   ifnot (typeof(ncp_prior) == String_Type) {
      ncp_prior = double(ncp_prior);
   } %}}}
   variable fp_rate = get_qualifier ( find_peak_qualifiers, "fp_rate", 0.3 );%{{{
   ifnot (typeof(fp_rate) == Double_Type and fp_rate <= 1.) {
      vmessage("Warning(%s): fp_rate has to be a number <= 1.0, setting it to 0.3", _function_name);
      fp_rate = 0.3;
   } %}}}
   variable smoothing = get_qualifier ( find_peak_qualifiers, "smoothing", 10. );%{{{
   ifnot (typeof(smoothing) == Double_Type or typeof(smoothing) == Integer_Type) {
      vmessage("Warning(%s): smoothing has to be a number, setting it to 10", _function_name);
      smoothing = 10.;
   }
   smoothing = double(smoothing);%}}}
   variable fit_fct = get_qualifier ( find_peak_qualifiers, "fit_fct", "sqrsinc" );%{{{
   ifnot (typeof(fit_fct) == String_Type) {
      vmessage("Warning(%s): fit_fct has to be String_Type, setting it to sqrsinc", _function_name);
      fit_fct = "sqrsinc";
   }%}}}
   variable fit_part = get_qualifier ( find_peak_qualifiers, "fit_part", 0.3 );%{{{
   ifnot (typeof(fit_part) == Double_Type) {
      vmessage("Warning(%s): fit_part has to be Double_Type, setting it to 0.3", _function_name);
      fit_part = 0.3;
   }%}}}
   variable tolerance = get_qualifier ( find_peak_qualifiers, "tolerance", 0.99 );%{{{
   ifnot (typeof(tolerance) == Double_Type or typeof(tolerance) == Integer_Type) {
      vmessage("Warning(%s): tolerance has to be a number, setting it to 0.99", _function_name);
      tolerance = 0.99;
   }
   tolerance = double(tolerance);%}}}
   variable dp = get_qualifier ( find_peak_qualifiers, "dp", -1 );%{{{
   ifnot (typeof(dp) == Double_Type or typeof(dp) == Integer_Type) {
      vmessage("Warning(%s): dp must be a number, using default routine", _function_name);
      dp = -1;
   }%}}}
   variable nbins_pfold = get_qualifier ( find_peak_qualifiers, "nbins_pfold", 100 );%{{{
   ifnot (typeof(nbins_pfold) == Integer_Type or typeof(nbins_pfold) == Double_Type) {
      vmessage("Warning(%s): nbins_pfold has to be a number, setting it to 100", _function_name);
      nbins_pfold = 100.;
   }
   nbins_pfold = nint(nbins_pfold);%}}}
   variable chatty = get_qualifier ( find_peak_qualifiers, "chatty", 1 );%{{{
   try {
      ifnot (chatty == 1 or chatty == 0) {
         vmessage("Warning(%s): chatty must be either 1 or 0, setting it to 1", _function_name);
         chatty = 1;
      }
   } catch AnyError: {
      vmessage("Warning(%s): chatty must be either 1 or 0, setting it to 1", _function_name);
      chatty = 1;
   }%}}}
   variable blocks_but_only_max = get_qualifier ( find_peak_qualifiers, "blocks_but_only_max", 0);%{{{
   ifnot (typeof(blocks_but_only_max) == Integer_Type) {
      vmessage("Warning(%s): blocks_but_only_max can only be 1 or 0, setting it to default", _function_name);
      blocks_but_only_max = 0;
   }
   ifnot (blocks_but_only_max == 0 or blocks_but_only_max == 1) {
      vmessage("Warning(%s): blocks_but_only_max can only be 1 or 0, setting it to default", _function_name);
      blocks_but_only_max = 0;
   }%}}}
   variable no_profile = get_qualifier ( find_peak_qualifiers, "no_profile", 0);%{{{
   ifnot (typeof(no_profile) == Integer_Type) {
      vmessage("Warning(%s): no_profile can only be 1 or 0, setting it to default", _function_name);
      no_profile = 0;
   }
   ifnot (no_profile == 0 or no_profile == 1) {
      vmessage("Warning(%s): no_profile can only be 1 or 0, setting it to default", _function_name);
      no_profile = 0;
   }%}}}
   variable exact = get_qualifier ( find_peak_qualifiers, "exact", 0);%{{{
   ifnot (typeof(exact) == Integer_Type) {
      vmessage("Warning(%s): exact can only be 1 or 0, setting it to default", _function_name);
      exact = 0;
   }
   ifnot (exact == 0 or exact == 1) {
      vmessage("Warning(%s): exact can only be 1 or 0, setting it to default", _function_name);
      exact = 0;
   }%}}}
   variable pfold_not_exact = get_qualifier ( find_peak_qualifiers, "pfold_not_exact", 0);%{{{
   ifnot (typeof(pfold_not_exact) == Integer_Type) {
      vmessage("Warning(%s): pfold_not_exact can only be 1 or 0, setting it to default", _function_name);
      pfold_not_exact = 0;
   }
   ifnot (pfold_not_exact == 0 or pfold_not_exact == 1) {
      vmessage("Warning(%s): pfold_not_exact can only be 1 or 0, setting it to default", _function_name);
      pfold_not_exact = 0;
   }%}}}
   variable only_max = get_qualifier ( find_peak_qualifiers, "only_max", 0);%{{{
   ifnot (typeof(only_max) == Integer_Type) {
      vmessage("Warning(%s): only_max can only be 1 or 0, setting it to default", _function_name);
      only_max = 0;
   }
   ifnot (only_max == 0 or only_max == 1) {
      vmessage("Warning(%s): only_max can only be 1 or 0, setting it to default", _function_name);
      only_max = 0;
   }%}}}
   variable no_fit = get_qualifier ( find_peak_qualifiers, "no_fit", 0);%{{{
   ifnot (typeof(no_fit) == Integer_Type) {
      vmessage("Warning(%s): no_fit can only be 1 or 0, setting it to default", _function_name);
      no_fit = 0;
   }
   ifnot (no_fit == 0 or no_fit == 1) {
      vmessage("Warning(%s): no_fit can only be 1 or 0, setting it to default", _function_name);
      no_fit = 0;
   }%}}}
   variable dp_given = (struct_field_exists(find_peak_qualifiers, "dp")) ? 1 : 0;
   %}}}

   switch (_NARGS)
   { case 1:
      variable input_struct = (); }
   { help(_function_name); return; }
   % Input processing, sanity checks %{{{
   variable no_epfold = 0.;
   try {
      p = input_struct.p;
      stat = input_struct.stat;
      ifnot (typeof(p) == Array_Type and typeof(stat) == Array_Type and _typeof(p) == Double_Type and _typeof(stat) == Double_Type) {
         vmessage("Error(%s): p and stat must be arrays of doubles", _function_name);
         return;
      }
      stat = stat [ array_sort(p) ];
      p = p [ array_sort(p) ];
   } catch AnyError: {
      vmessage("Error(%s): Input structure does not contain fields named p and stat",_function_name);
      return;
   }
   variable lc_provided = 1;
   try {
      lc = input_struct.lc;
      try {
         variable ttest = lc.time;
         variable rtest = lc.rate;
      } catch AnyError: {
         vmessage ("Warning(%s): Lightcurve does not have fields named time and rate, doing no_profile routine", _function_name);
         no_profile = 1;
         lc_provided = 0;
      }
      ifnot (typeof(ttest) == Array_Type and typeof(rtest) == Array_Type) {
         vmessage ("Warning(%s): Lightcurve fields are no arrays, doing no_profile routine", _function_name);
         no_profile = 1;
         lc_provided = 0;
      }
   } catch AnyError: {
      vmessage("Warning(%s): No lightcurve (field named lc) provided", _function_name);
      no_profile = 1;
      lc_provided = 0;
   }
   try {
      nbins_epfold = input_struct.nbins_epfold;
      ifnot (typeof(nbins_epfold) == Integer_Type) {
         vmessage("Warning(%s): nbins_epfold has to be Integer_Type, setting it to 32. Will make errors useless", _function_name);
         nbins_epfold = 32;
         no_epfold = 1;
      }
   } catch AnyError: {
      vmessage("Warning(%s): No field named nbins_epfold provided, setting to 32 (will make err_theory useless)", _function_name);
      nbins_epfold = 32;
      no_epfold = 1.; }
   try {
      expectation = input_struct.expectation;
      ifnot (typeof(expectation) == Double_Type) {
         vmessage("Warning(%s): expectation has to be Double_Type, setting it to the average of p", _function_name);
         expectation = mean(p);
      }
   } catch AnyError: {
      vmessage("Warning(%s): No field named expectation provided, setting it to the average of p", _function_name);
      expectation = mean(p); }
   try {
      sigma_expectation = input_struct.sigma;
      ifnot (typeof(sigma_expectation) == Double_Type) {
         vmessage("Warning(%s): sigma must be Double_Type, setting it to DOUBLE_MAX", _function_name);
         sigma_expectation = DOUBLE_MAX;
      }
   } catch AnyError: {
      vmessage("Warning(%s): No field named sigma provided, setting it to DOUBLE_MAX", _function_name);
      sigma_expectation = DOUBLE_MAX; }

   variable dp_default;
   
   if (lc_provided) {
      if (dp_given == 0) {
         if(chatty){vmessage("(%s): Setting dp to p^2 / T  -- theoretical prediction", _function_name);}
      }
      dp_default = sqr(expectation) / ( max(lc.time) - min(lc.time) );
   } else {
      if (sigma_expectation < DOUBLE_MAX - 1.) {
         if (dp_given == 0) {
            vmessage("Warning(%s): Setting dp to sigma -- because no profile given", _function_name);
         }
         dp_default = sigma_expectation;
      } else {
         if (dp_given == 0) {
            vmessage("Warning(%s): Setting dp to 0.1 * period span -- because no sigma and no profile given", _function_name);
         }
         dp_default = 0.1 * (max(p)-min(p));
      }
   }
   ifnot (typeof(dp) == Double_Type or typeof(dp) == Integer_Type) {
      vmessage("Warning(%s): dp has to be a number, setting it to %lf", _function_name, dp_default);
      dp = dp_default;
   }
   if (dp < 0) { dp = dp_default; }
   dp = double(dp);
   %}}}
   

   variable flags = struct { %{{{  % contains warnings and is used to calculate badness of epochfolding
      end_reached = 0,  % -1 for beginning, 1 for end reached
      no_blocks = 0, % either 0 or 1
      bad_profile = 0,
      bad_blocks = 0, % if no sufficiently small block has been found ( less than ~ 1.5 dp width );
      difference = 0, % measures the difference between the peak found and the prediction - a high value indicates problems
      exact = exact, % 1 if epfold was done with exact qualifier -- currently (as of Sept 16) this is NOT recommended!
      fit_succeeded = 0, % 1 if the fit seems to have been successful
      dp = dp, % measure for the width of the peak
      t = (no_profile==0) ? max(lc.time) - min(lc.time) : 0., % timespan -- short timespans w.r.t. period can pose a problem
   };
   if (no_profile) { flags = reduce_struct(flags, "t"); }
   %}}}

   variable where_noise = where ( stat - median(stat) < 3. * moment(stat - median(stat) ).sdev );
   variable sdev_noise = moment ( stat[where_noise] ).sdev;                                        % finds standard deviation of these values
   variable avg_noise = mean ( stat[where_noise] );                                                % finds mean value of noise

   variable blocks, where_maxima;
   if ( only_max ) {
      if(chatty){vmessage("(%s): Skipping bayesian block analysis as you have chosen", _function_name);}
      blocks = [0];
      where_maxima = [0];
   } else {
% bayesian block analysis, find local maxima
%{{{
   if(chatty){vmessage("(%s): Doing bayesian block analysis", _function_name);}
   variable stat_noisy = @stat; % the original statistics is later used in order to find the peak, we don't want to loose this information by smoothing things out

   variable smoothing_iterations = -1;

   variable bayes_input = struct { tt = p , nn_vec = stat };
   variable bayes_red; 
   do { % while the statistics curve is too noisy for a reasonable block analysis, the curve is smoothed
      if (smoothing_iterations > -0.5) { stat = gliding_average ( p, stat, smoothing ); }
      if (typeof(ncp_prior) == String_Type) {
         bayes_red = bayesian_blocks ( bayes_input; fp_rate=fp_rate ).change_points; % the curve is split into bayesian blocks ( N ~ 10^1 )
      } else {
         bayes_red = bayesian_blocks ( bayes_input; ncp_prior = ncp_prior,fp_rate=fp_rate ).change_points; % the curve is split into bayesian blocks ( N ~ 10^1 )
      }
      variable bayes = Integer_Type[length(bayes_red)+2];
      bayes[0]=0;
      bayes[[1:length(bayes)-2]]=bayes_red;
      bayes[-1]=length(p)-1;                                                                          % 'bayes' contains the boundaries between blocks and the start & end
      blocks = Double_Type[length(bayes)-1];
      variable i;
      _for i (0, length(blocks)-1, 1) {
         blocks[i] = mean ( stat[[bayes[i]:bayes[i+1]]] ); }                                          % 'blocks' contains the avg signal for each bayesian block
      where_maxima = Integer_Type[length(blocks)];
      variable where_minima = Integer_Type[length(blocks)];
      _for i (1, length(where_maxima)-2, 1) {
         if ( blocks[i-1] < blocks[i] and blocks[i+1] < blocks[i] ) { where_maxima[i] = 1; }          % contains indices of blocks that are local maxima
         else { where_maxima[i] = 0;
            if ( blocks[i-1] < blocks[i] and blocks[i+1] < blocks[i] ) { where_minima[i] = 1; }
            else { where_minima[i] = 0; }
              }
      }
      where_maxima[0]=0;
      where_maxima[length(where_maxima)-1]=0;
      smoothing_iterations += 1;
      bayes_input.nn_vec = stat;
   } while ( (length(bayes_red) < 2. or sum(where_maxima)<1.) and smoothing_iterations < 4 );
   flags.no_blocks = smoothing_iterations;

%}}}   
   }

   blocks = blocks * typecast(where_maxima, Double_Type); % now 'blocks' is zero everywhere except for the maxima
   variable conversion = length(p) / ( max(p) - min(p) ); % conversion factor between binning and period grid

   variable bayes_struct;
   if ( only_max ) {
      bayes_struct = empty_struct();
   } else { %{{{
      try {
         bayes_struct = struct {                                                                                                                           
            bin_lo = p[ bayes[[0:length(bayes)-2]] ],                                                                                               
            bin_hi = p[ bayes[[1:length(bayes)-1]] ],                                                                                               
            midpoints = 0.5 * p[ bayes[[0:length(bayes)-2]] ] + 0.5 * p[ bayes[[1:length(bayes)-1]] ],                                              
            blocks = blocks };
      } catch AnyError: {
         bayes_struct = empty_struct();
      }
   } %}}}

% determine quality of individual blocks
%{{{
   if (length(blocks) < 3 or sum(blocks) == 0 ) {
      variable pmin0 = where_max(stat)[0] - nint( conversion * dp );
      variable pmax0 = where_max(stat)[0] + nint( conversion * dp );
      variable first_p0 = where_max(stat)[0];
         if ( pmax0 >= length(p) ) {
               flags.end_reached = 1;
               pmax0 = length(p) - 1;
               pmin0 = nint ( 2*first_p0 - pmax0 ); }
         else {
            if ( pmin0 < 0 ) {
               flags.end_reached = -1;
               pmin0 = 0;
               pmax0 = nint ( 2*first_p0 ); }
              }
   } else {
      variable reached_ends = 0*ones(length(blocks));
      variable imps = Double_Type[length(blocks)];  % 'imps' contains the importance of a peak
      variable pmin = Integer_Type[length(blocks)];
      variable pmax = Integer_Type[length(blocks)];
      _for i (0, length(blocks)-1, 1) {
         if ( blocks[i]< 1e-5 ) { imps[i] = -DOUBLE_MAX; }
         else {
            variable midpoint = mean([bayes[i],bayes[i+1]]);
            pmin[i] = nint( midpoint - dp*conversion ); % a neighbourhood of +- p^2/T is defined
            pmax[i] = nint( midpoint + dp*conversion );
            if ( pmax[i] >= length(p) ) { % a flag is set if the possible peak is too close to a boundary of the period interval
                  reached_ends[i] = 1;                  
                  pmax[i] = length(p) - 1;
                  pmin[i] = max ( [ 0, nint ( 2*mean([bayes[i],bayes[i+1]]) - pmax[i] ) ] ); }
            else {
               if ( pmin[i] < 0 ) {
                  reached_ends[i] = -1;
                  pmin[i] = 0;
                  pmax[i] = min ( [ length(p)-1, nint ( 2*mean([bayes[i],bayes[i+1]]) ) ] ); }
                 }
   
            imps[i] = (sum(stat[[nint(0.5*pmin[i]+0.5*midpoint):nint(0.5*pmax[i]+0.5*midpoint)]]))^weighting[0] * (log(log1p(3.*dp/(p[bayes[i+1]] - p[bayes[i]]))))^weighting[1];
            
            if ( expectation>1e-10 and sigma_expectation>1e-10 ) {
               imps[i] *= (quality_function(expectation, sigma_expectation, p[nint(midpoint)]))^weighting[2]; }
         }
            % sharp features are slightly advantageous, but very broad features are highly disadvantageous
            % but a big area in the +- p^2/T interval is favoured
         }
%}}}

   variable possible_blocks = where(imps > (tolerance * max(imps) ) ); % usually only the true peak should fall into this category
   pmin0 = pmin[ possible_blocks ]; % but sometimes multiple similar maxima are found
   pmax0 = pmax[ possible_blocks ];
   if (length(possible_blocks)==0) { % this is needed if all imps are negative -- should not happen for sufficiently good data
      flags.bad_blocks = 1;
      possible_blocks = where_max(imps);
      pmin0 = pmin[ possible_blocks ];
      pmax0 = pmax[ possible_blocks ];
      }
   }

% determine the period for each possible peak -- normally just one iteration
%{{{
   variable v;
   variable smoothness = Double_Type [ length(pmin0) ]; % used to distinguish between various possible true peaks -- it measures the quality of the folded pulse profile
   variable periods = Double_Type [ length(pmin0) ];
   variable folded_profiles = {}; % contains the posstible profiles -- the best one is passed to output
   variable cum_areas = {}; % contains the cumulated area under a peak dependent on period
   variable fitsuccess = Integer_Type [ length(pmin0) ];
   variable fit_outcomes = Struct_Type [ length(pmin0) ];
   variable error_areas = Double_Type [ length(pmin0) ];

   if ( length(pmin0) > 1 ) {
      if(chatty){vmessage("(%s): Found %d possible peaks", _function_name, length(pmin0) );}
   }
   _for v ( 0, length(pmin0) - 1, 1 ) { 
      %preliminaries %{{{
      if (length(blocks)>2 and sum(blocks)!=0) { first_p0 = where_max ( stat[[pmin0[v]:pmax0[v]]] )[0] + pmin0[v]; }
      else { first_p0 = first_p0; }
      variable p_half_lo = ( where_min ( abs(stat[[pmin0[v]:first_p0]] - avg_noise - 0.5 * ( max(stat[[pmin0[v]:pmax0[v]]]) - avg_noise ) ) ) + pmin0[v] )[0]; % index
      variable p_half_hi = ( where_min ( abs(stat[[first_p0:pmax0[v]]] - avg_noise - 0.5 * ( max(stat[[pmin0[v]:pmax0[v]]]) - avg_noise ) ) ) + first_p0 )[0]; % index
      variable grid = p[[pmin0[v]:pmax0[v]]]; % the period grid for the individual possible peak within +- p^2/T
      variable peak_data = stat[[pmin0[v]:pmax0[v]]]; % chi^2 on the grid
      variable cum_area = Double_Type[length(grid)];
   
      cum_area[0] = ( grid[0] - p[pmin0[v]-1] ) * peak_data[0];
      _for i (1, length(cum_area)-1, 1) {
         cum_area[i] = cum_area[i-1] + ( grid[i] - grid[i-1] ) * peak_data[i]; }
      list_append ( cum_areas, cum_area );

      variable period = p[ where_min( abs(cum_area[[p_half_lo-pmin0[v]:p_half_hi-pmin0[v]]] - 0.5 * cum_area[p_half_hi-pmin0[v]] ) )[0] + p_half_lo ];
      % this approach is currently not used
      variable period_max = p[ where_max( stat[[pmin0[v]:pmax0[v]]] )[0] + pmin0[v] ];
      %}}}

      if (length(blocks) < 3 or sum(blocks) == 0) {
         period = period_max; % just the maximum in the statistic is taken
         fitsuccess [ v ] = 0; 
         fit_outcomes [ v ] = empty_struct();
      }
      else { 
      % find first period estimate %{{{
         variable peak_slice = [bayes[possible_blocks[v]]:bayes[possible_blocks[v] + 1]]; % index interval between the bayesian block boundaries of the possible peak
         variable n_important;
         n_important = max ( [ min( [ 3, length(peak_slice) ] ), nint(length(peak_slice) / 10.) ] ); % the number of points in 'peak slice' that is used
         variable important_indices = [peak_slice [ array_sort(stat_noisy[peak_slice])[[-n_important:]] ] ]; % corresponding periods, sorted by their statistic
         variable important_periods = p [ important_indices ];
         variable u;
         period = 0;
         variable u_sum = 0;
         _for u ( 0, n_important - 1, 1) {
            period += important_periods[u]/(u+1)^0.5; % a weighted average of the 'important_periods' is taken
            % only the index and not the statistic is taken as weight in order to reduce the impact of unexpectedly high statistics
            u_sum += 1/(u+1)^0.5;
         }
         period /= u_sum;
      %}}}
         ifnot (no_fit or blocks_but_only_max) {
         % find fit area %{{{
         variable period_index = where_min (abs(period-p[peak_slice]) ) + min(peak_slice);
         error_areas [v] = error_estimate ( p, stat, period, 0.25*dp, 0.25*dp );
         variable lo_boundary = where_min ( abs(p - period + fit_part*dp) );
         variable hi_boundary = where_min ( abs(p - period - fit_part*dp) );
         %}}}

         % perform fit %{{{
         variable xdata = p [[lo_boundary:hi_boundary]];
         variable ydata = stat_noisy [[lo_boundary:hi_boundary]]; % although the smoothed curve may look nicer, we don't want to loose information for the fit.
         variable w_dist = (abs(xdata - period))^0.25;
         variable id = define_xydata ( xdata, ydata, 0.1*(max(ydata)-min(ydata))*w_dist/(max(w_dist)) );
         try{
            xyfit_fun ( fit_fct );
            set_par ( 1, period );
            set_par ( 2, max(ydata) );
            set_par ( 3, 0.5 * (max(xdata) - min(xdata)) );
            set_par ( 4, min(ydata) );
            set_par ( 5, 0 );
            if (chatty) { vmessage ("(%s): Performing fit of possible peaks, using %s", _function_name, fit_fct); }
         } catch AnyError: {
            vmessage("Warning(%s): Fit function not suitable, using sqrsinc instead",_function_name);
            xyfit_fun ( "sqrsinc" );
            set_par ( 1, period );
            set_par ( 2, max(ydata) );
            set_par ( 3, 0.5 * (max(xdata) - min(xdata)) );
            set_par ( 4, min(ydata) );
            set_par ( 5, 0 );
         }
         variable a = fit_counts(; fit_verbose=-1);
         variable model;
         ( , model ) = get_xymodel ( id );
         fit_outcomes [v] = struct { xdata = xdata, ydata = ydata, ymodel = model };
         variable fit_period = get_par(1);
         delete_data (all_data);
         if (abs(fit_period - period) < 1.*min( [error_areas[v], sigma_expectation] ) and fit_period>min(p) and fit_period<max(p)) {
            period = @fit_period;
            fitsuccess[v] = 1;
         } else {
            fitsuccess[v] = 0;
         }
         %}}}
         } else {
            fit_outcomes[v] = empty_struct();
            if (v==0) { if(chatty){vmessage("(%s): No fit is performed as you have chosen", _function_name); }}
         }
      }

      ifnot (no_profile) {
         variable dt = lc.time - shift(lc.time, -1);
         dt[0] = median( dt[[1:length(dt)-1]] );
                                                                                                                                                           
         variable ix = 0;
         variable factor = 4.;
         variable folded_profile;
         if (nbins_pfold == 100 ) {
         while (ix==0) { %{{{
            if ( pfold_not_exact ) {
               folded_profile = pfold ( lc.time, lc.rate, period;nbins=min([100,nint(factor*period/0.125)]),dt=dt );
            } else {
               folded_profile = pfold ( lc.time, lc.rate, period;nbins=min([100,nint(factor*period/0.125)]),dt=dt,exact );
            }
            if (abs(mean(folded_profile.value)) > 0) { % only possible if no 'nan' is in the profile
               ix = 1;
            } else {
               factor *= 0.90;
               ix = 0;
            }
         } %}}}
         } else {
         while (ix==0) { %{{{
            if ( pfold_not_exact ) {
               folded_profile = pfold ( lc.time, lc.rate, period;nbins=nbins_pfold,dt=dt );
            } else {
               folded_profile = pfold ( lc.time, lc.rate, period;nbins=nbins_pfold,dt=dt,exact );
            }
            if (abs(mean(folded_profile.value)) > 0) { % only possible if no 'nan' is in the profile
               ix = 1;
            } else {
               vmessage("error(%s): the nbins_pfold you provided oversampled the pulse profile too much", _function_name);
               return;
            }
         } %}}}
         }
         list_append ( folded_profiles, folded_profile );
                                                                                                                                                           
         % estimate quality of profile %{{{
         variable j;
         variable jump = Double_Type [length(folded_profile.value)]; % contains the absolute differences between the flux in neighbouring phase bins
         variable random_jump = Double_Type [length(folded_profile.value)]; % contains the abs diff between the flux in two random phase bins
         _for j (0, length(jump)-1, 1) {
            jump[j] = abs(shift(folded_profile.value,j)[0] - shift(folded_profile.value,j+1)[0]);
            variable jj;
            variable all_jumps = Double_Type [length(random_jump)];
            _for jj (0, length(jump)-1, 1) {
               all_jumps[jj] = abs(shift(folded_profile.value,j)[0] - shift(folded_profile.value,jj)[0]); }
               random_jump[j] = mean(all_jumps);
            }
         if ( abs(mean(jump)) > 1e-5 ) { smoothness[v] = mean(random_jump) / mean(jump); } % the higher this ratio the less noise is in the folded profile
         else { smoothness[v] = mean(random_jump) * 1e10; } 
         %}}}
      }
      periods[v] = period;
   }
%}}}

% choose true peak and determine errors, set flags
%{{{
   if (length(blocks) < 3 or sum(blocks)==0) {
      imps = ones(1);
      possible_blocks = 0; }
   
   if (no_profile) { smoothness = 1.; }

   variable here_peak =  where_max( smoothness^weighting[3] * imps[possible_blocks] )[0]; % the index of the most probable maximum in the previously generated lists
   period = periods [ here_peak ];
   flags.fit_succeeded = fitsuccess[ here_peak ];
   variable fit_outcome = fit_outcomes[ here_peak ];
   variable out_profile;
   if (no_profile) {
      out_profile = empty_struct();
   } else {
      out_profile = folded_profiles [ here_peak ];
   }
   pmin0 = pmin0 [ here_peak ];
   pmax0 = pmax0 [ here_peak ];  
   variable where_period = where_min( abs(p - period) )[0];
   variable cum_a = cum_areas [ here_peak ];
   variable error68_lo = period - p[ where_min( abs(cum_a[[:where_period-pmin0]] - 0.32 * cum_a[where_period-pmin0] ) )[0] + pmin0];
   variable error68_hi = p[ where_min( abs(cum_a[[where_period-pmin0:]] - 0.32 * cum_a[where_period-pmin0] - 0.68 * cum_a[-1] ) )[0] + where_period] - period;
   variable error_area = error_estimate ( p, stat, period, error68_lo, error68_hi );
   variable correction_offset = max ( [ 0., avg_noise - nbins_epfold + 1 ] ); % the difference between the expected noise of (nbins-1) and the noise found in the statvsp
   variable error_theory;
   %% Leahy 1987: sigma(p) / delta(P) = 0.71 * (chired^2 - 1 )^-0.63 ( Monte Carlo simulation ) where delta(P)=P^2 / 2T
   %% dp = p^2/T is the half width of the peak
   %% chired^2 = chi^2 / (n-1) -- chi^2 of peak {i.e. max(stat)}, n is number of bins in folded lightcurve (nbins qualifier of epfold)
   error_theory = 0.5*dp*0.71*( (max(stat[[pmin0:pmax0]] - correction_offset)/(nbins_epfold - 1)) - 1 )^(-0.63); % the error estimate proposed by Leahy 1987
   ifnot ( error_theory < 1. or error_theory > 1. or error_theory == 1. ) { % if it is nan
      error_theory = error_area;
   }
   flags.bad_profile = (no_profile==0) ? nint ( log(length(out_profile.value))/(log(10)*max( smoothness )) ) : 0; % a flag set if even the best profile seems to be pure noise
   
   if ( expectation>1e-10 and sigma_expectation>1e-10 ) {
      flags.difference = nint(abs(period-expectation)/(3.*sigma_expectation));
   }
%}}}

   variable badness = nint( (1-flags.fit_succeeded) + abs(flags.end_reached) + flags.no_blocks + flags.difference + flags.bad_profile + flags.bad_blocks);
   if (no_fit or only_max or blocks_but_only_max) { badness += -1; }
   % combines all flags

variable out;
out = struct { %{{{
   period = period,                                                                                                                           
   error = sqrt ( sqr(error_area) + sqr(error_theory) ),                                                                                      
   profile = out_profile,                                                                                                                     
   err_area = error_area,                                                                                                                     
   err_theory = error_theory,                                                                                                                 
   % it has been estimated for sinusoidal signals, but its application in this case shows that the width of the noisy peak is nearly always   
   % excellently described by this error estimate -- hence we conclude it to be a viable way of giving limits to our period                   
   %width_lo = error68_lo,                                                                                                                    
   %width_hi = error68_hi,                                                                                                                    
   statvsp = struct {                                                                                                                         
      p= p,                                                                                                                                   
      stat = stat_noisy },                                                                                                                          
   flags = flags,                                                                                                                             
   bayes = bayes_struct,
   fit = fit_outcome,                                                                                                                         
   badness = badness }; %}}}                                                                                                                  
if ( length(get_struct_field_names(out.profile)) == 0 ) { out = reduce_struct(out, "profile"); }
if ( length(get_struct_field_names(out.fit)) == 0 ) { out = reduce_struct(out, "fit"); }
if ( length(get_struct_field_names(out.bayes)) == 0 ) { out = reduce_struct(out, "bayes"); }

   return out;
}
%}}}
