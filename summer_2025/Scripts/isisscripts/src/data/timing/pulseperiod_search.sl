define pulseperiod_search ( ) %{{{
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{pulseperiod_search}
%\synopsis{Looks for periodic signal in a lightcurve.}
%\usage{Struct_Type pulseperiod_search( lc [, p0 [, sigma ] ] )};
%\description
%
% The input lightcurve should be a structure of the form
%     lc = struct { time, rate, [ error ], [ fracexp ] }
% If error resp. fracexp are not given, they will be filled with
% sqrt(rate) resp. ones. All fields are arrays of doubles of the
% same length.
% p0 and sigma determine an initial guess for the period and an
% approximate error.
% The output is a structure of the form
%     { ep, pp, lc } 
% Each field is a list, in which each element corresponds to one
% segment of the lightcurve (multiple elements if the lightcurve
% contains considerable gaps).
% ep[i] contains epoch folding information, pp[i] the folded pulse profile
% and lc[i] the lightcurve under consideration.
% The function works the following way: (the functions used are given)
%
%     (1) If no p0 is given, a Fourier method is used to find an
%         initial guess for the period. A splitting is performed first
%         if necessary
%            * split_and_epfold_lc (; split_only), foucalc
%     (2) The input lightcurve is split if it contains gaps.
%            * split_and_epfold_lc (; split_only)
%     (3) A correction for any underlying variation in flux of the
%         lightcurve is performed.
%            * pulse2pulse_flux_lc
%     (4) For each segment an epochfolding is performed.
%            * split_and_epfold_lc
%     (5) The peak in the statistics of epfold is found.
%            * find_peak
%
% Qualifiers for the individual functions can be passed as structures
% with the names given below. See their helps for further information.
%
%\qualifiers{
%\qualifier{compact}{output contains only the essential information}
%\qualifier{epfold_fourier_qu}{contains qualifiers for step (1)}
%\qualifier{fourier_qu}{contains qualifiers for step (1)}
%\qualifier{epfold_split_qu}{contains qualifiers for step (2)}
%\qualifier{pulse2pulse_slope_qu}{contains qualifiers for step (3)}
%\qualifier{epfold_qu}{contains qualifiers for step (4)}
%\qualifier{find_peak_qu}{contains qualifiers for step (5)}
%\qualifier{no_slope_correction}{step (3) is not done}
%\qualifier{no_splitting}{step (2) is not done}
%\qualifier{exact}{forces epfold to use exact}
%\qualifier{not_exact}{forces epfold not to use exact}
%\qualifier{fourier}{fourier is used, even if p0 is given -- can be used to pass sigma}
%\qualifier{chatty}{boolean value (default: 1)}
%
%}
%\seealso{foucalc, split_and_epfold_lc, pulse2pulse_flux_lc, find_peak}
%!%-
{
   variable fourier = 0;
   variable lc;
   variable p0 = -1.;
   variable sigma = DOUBLE_MAX;
   switch (_NARGS)
   { case 1: lc = (); fourier = 1; }
   { case 2: (lc, p0) = (); }
   { case 3: (lc, p0, sigma) = (); }
   { help(_function_name); return; }
   
   % Sanity checks %{{{
   ifnot (typeof(lc) == Struct_Type) {
      vmessage("Error(%s): lightcurve is no Struct_Type", _function_name); return;
   }
   ifnot (struct_field_exists(lc, "time") and struct_field_exists(lc, "rate")) {
      vmessage("Error(%s): lightcurve has to contain fields named time and rate", _function_name); return;
   }
   ifnot (typeof(lc.time)==Array_Type and typeof(lc.rate)==Array_Type and _typeof(lc.time)==Double_Type and _typeof(lc.rate)==Double_Type) {
      vmessage("Error(%s): time and rate must be arrays of doubles", _function_name); return;
   }
   ifnot (length(lc.time) == length(lc.rate)) {
      vmessage("Error(%s): time and rate must have the same length"); return;
   }
   ifnot (struct_field_exists(lc, "error")) {
      vmessage("Warning(%s): lightcurve does not contain a field named error, setting it to sqrt(rate)", _function_name);
      variable err_struct = struct { error = sqrt(lc.rate) };
      lc = struct_combine ( lc, err_struct );
   }
   ifnot (struct_field_exists(lc, "fracexp")) {
      vmessage("Warning(%s): lightcurve does not contain a field named fracexp, setting it to ones", _function_name);
      variable fracexp_struct = struct { fracexp = double(ones(length(lc.time))) };
      lc = struct_combine ( lc, fracexp_struct );
   }
   ifnot (typeof(lc.error)==Array_Type and typeof(lc.fracexp)==Array_Type and _typeof(lc.error)==Double_Type and (_typeof(lc.fracexp)==Double_Type or _typeof(lc.fracexp)==Integer_Type)) {
      vmessage("Error(%s): error and fracexp must be arrays of numbers", _function_name); return;
   }
   ifnot ((length(lc.error) == length(lc.time)) and (length(lc.fracexp) == length(lc.time))) {
      vmessage("Error(%s): error and fracexp must have the length of time and rate", _function_name); return;
   }
   %}}}

   variable fourier_qualifiers = qualifier( "fourier_qu", empty_struct() );
   variable epfold_split_fourier_qualifiers = qualifier( "epfold_fourier_qu", empty_struct() );
   variable epfold_split_qualifiers = qualifier( "epfold_split_qu", empty_struct() );
   variable pulse2pulse_slope_qualifiers = qualifier( "pulse2pulse_slope_qu", empty_struct() );
   variable epfold_qualifiers = qualifier( "epfold_qu", empty_struct() );
   variable find_peak_qualifiers = qualifier( "find_peak_qu", empty_struct() );


   variable no_smoothing = (qualifier_exists("no_slope_correction")) ? 1 : 0;
   variable no_splitting = (qualifier_exists("no_splitting")) ? 1 : 0;
   fourier = (qualifier_exists("fourier")) ? 1 : fourier;
   variable exact = (qualifier_exists("exact")) ? 1 : 0;
   if (exact == 1) { epfold_qualifiers = struct_combine ( epfold_qualifiers, "exact" ); }
   variable not_exact = (qualifier_exists("not_exact")) ? 1 : 0;
   if (not_exact == 1) { epfold_qualifiers = struct_combine ( epfold_qualifiers, "not_exact" ); }
   ifnot (exact * not_exact == 0) { vmessage("Error(%s): you cannot give exact and not_exact", _function_name); return; }
   variable compact = (qualifier_exists("compact")) ? 1 : 0;
   variable chatty = qualifier("chatty", 1);
   
   if (fourier) { %{{{
      if(chatty) {vmessage("(%s): First look for period via Fourier", _function_name);}
      
      variable dt = median ( (lc.time - shift(lc.time,-1))[[0:length(lc.time)-1]] );
      variable split_fourier = split_and_epfold_lc ( lc, 4.*dt; epfold_qualifiers = struct { split_only = 1 });
      variable ii;
      variable f;
      variable fourier_periods = {};
      _for ii (0, length(split_fourier.lc)-1, 1) {
         variable lc_fourier = struct { time = split_fourier.lc[ii].time, rate1 = split_fourier.lc[ii].rate };
         variable ix = 0;
         variable power = 20;
         while (ix == 0) {
            try {
               fourier_qualifiers = struct_combine ( fourier_qualifiers, "compact" );
               f = foucalc ( lc_fourier, nint(2.^power);; fourier_qualifiers);
               ix = 1;
            } catch IndexError: {
               power += -1;
            }
            if (power<5) {
               f  = 0;
               ix = 1;
            }
         }
         if (typeof(f) == Integer_Type) { continue; }
         variable fourier_period = 1. / f.freq[where_max(f.signormpsd1)];
         list_append ( fourier_periods, fourier_period );
      }
      if (length(fourier_periods) == 0) { vmessage("Error(%s): Fourier search failed: No periods found.", _function_name); return; }
      fourier_periods = list_to_array ( fourier_periods );
      p0 = mean ( fourier_periods );
   } %}}}
   
   % prepare output
   variable out_p = {};
   variable out_lc = {};
   variable out_pp = {};

   % Epfold : split only. If no splitting, astronomical gap scale
   variable gs;
   if (no_splitting ==1) {
      gs = DOUBLE_MAX;
   } else {
      gs = 0.5;
   }

   variable split_add = struct { gap_scale = gs, split_only = 1, chatty = chatty };
   epfold_split_qualifiers = struct_combine( split_add, epfold_split_qualifiers );
   variable split = split_and_epfold_lc ( lc, p0; epfold_qualifiers = epfold_split_qualifiers ); 

   % For each segment do smoothing ( unless no_smoothing == 1 )
   variable jj;
   _for jj (0, length(split.lc) - 1, 1) {
      if ( typeof(split.lc[jj]) == Null_Type ) {
         vmessage("Warning(%s): Segment %d corrupted", _function_name, jj);
         continue;
      }
      if (no_smoothing == 0) {
         variable lc_red = struct {
            time = split.lc[jj].time,
            rate = split.lc[jj].rate,
            error = split.lc[jj].error };
         variable lc_avg = pulse2pulse_flux_lc ( lc_red, p0;; pulse2pulse_slope_qualifiers );
         if ( length(lc_avg.time) > 1 ) {
            if(chatty){vmessage("(%s): slope correction successful for segment %d", _function_name, jj);}
            lc_avg.rate = interpol_points(lc_red.time, lc_avg.time, lc_avg.rate);
            split.lc[jj].rate += mean(lc_avg.rate) - lc_avg.rate;
         } else {
            if(chatty){vmessage("Warning(%s): slope correction failed for segment %d", _function_name, jj);}
         }
         split.lc[jj].fracexp = ones(length(split.lc[jj].time));
      } else {
         if(chatty){vmessage("(%s): No slope correction is performed as you have chosen", _function_name);}
      }
      % For each segment do epochfolding, astronomical gap scale
      variable add_struct = struct { gap_scale = DOUBLE_MAX, chatty = chatty };
      epfold_qualifiers = struct_combine ( add_struct, epfold_qualifiers );
      if(chatty){vmessage("(%s): Performing epochfolding for segment %d", _function_name, jj);}
      variable ep = split_and_epfold_lc ( split.lc[jj], p0; epfold_qualifiers = epfold_qualifiers );
      % For each segment do find_peak
      if ( typeof(ep.epfold[0] ) == Null_Type ) {
         vmessage("Warning(%s): Epochfolding failed for segment %d", _function_name, jj);
         continue;
      }
      variable find_peak_in = struct { lc = ep.lc[0], p = ep.epfold[0].p, stat = ep.epfold[0].stat, nbins_epfold = ep.epfold[0].nbins, expectation = p0, sigma = sigma };
      variable find_peak_add = struct { pfold_not_exact = 1, exact = ep.exact[0], chatty=chatty };
      find_peak_qualifiers = struct_combine ( find_peak_add, find_peak_qualifiers );
      variable p = find_peak ( find_peak_in; find_peak_qualifiers = find_peak_qualifiers ); 
      
      if (struct_field_exists(p, "profile")) {
         list_append ( out_pp, p.profile );
         p = reduce_struct ( p, "profile" );
      }
      list_append ( out_p, p );
      list_append ( out_lc, ep.lc[0] );
   }

   variable output;
   if (compact) {
      variable mean_period = 0;
      variable mean_period_bad = 0;
      variable err_period=0;
      variable err_period_bad = 0;
      variable sum = 0;
      variable kk;
      _for kk (0, length(out_p) - 1, 1) {
         if (out_p[kk].badness < 2) {
            mean_period += out_p[kk].period;
            err_period += sqr(out_p[kk].error);
            sum += 1;
         }
         mean_period_bad += out_p[kk].period;
         err_period_bad += sqr(out_p[kk].error);
      }
      if (mean_period ==0) {
         mean_period = mean_period_bad/length(out_p);
         err_period = sqrt(err_period_bad) / length(out_p);
      } else {
         mean_period /= double(sum);
         err_period = sqrt(err_period) / double(sum);
      }
      output = struct {
         period = mean_period,
         error = err_period, 
         pp = out_pp };
   } else {
      output = struct {
         ep = out_p,
         pp = out_pp,
         lc = out_lc };
      if (length(output.pp) == 0) {
         output = reduce_struct(output, "pp");
      }
   }
   return output;
} %}}}
