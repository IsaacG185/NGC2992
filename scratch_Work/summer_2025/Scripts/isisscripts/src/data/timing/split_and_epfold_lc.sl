
private define get_qualifier ( qualifier_structure, qualifier_name, default_value ) { %{{{
   try {
      return get_struct_field ( qualifier_structure, qualifier_name );
   } catch InvalidParmError: {
      return default_value;
   }
}
%}}}

%%%%%%%%%%%%%%%%%%%%%
define split_and_epfold_lc()%{{{
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{split_and_epfold_lc}
%\synopsis{Takes lightcurve and pulse period, splits if necessary and executes epfold for each segment.}
%\usage{Struct_Type split_and_epfold_lc(Struct_Type OR Array_Type lc, Double_Type p0), all times in the same units}
%\qualifiers{
%\qualifier{exact}{Forces execution of pfold with exact qualifier}
%\qualifier{not_exact}{Forces execution of pfold without exact qualifier}
%\qualifier{exact_threshold}{see description (default: 6.)}
%\qualifier{split_only}{Only the splitting is performed}
%\qualifier{nbins}{Sampling of pfold (default: min(32, p0 / dt), dt time resolution}
%\qualifier{nsrch}{Number of trial periods for epfold (default: 1e4)}
%\qualifier{grid_steps}{Period resolution for epfold (default: not set)}
%\qualifier{search_range}{Period interval considered left/right of p0 in terms of dp=p0^2/T (default: 2.)}
%\qualifier{dpmin}{For very long lightcurves, this can replace dp (default: p0e-3)}
%\qualifier{gap_scale}{the smaller, the higher is the sensitivity for gaps (default: .5)}
%\qualifier{fracexp}{Only timebins with fracexp >= this value will be considered (default: 1.)}
%\qualifier{chatty}{chattiness (default: 1)}
%}
%\description
%
% The input lightcurve(s) should be a structure or an array of
% structures of the form:
%     lc = struct { time, rate, fracexp, error }
% where each field is an array of doubles. 
% The output is a structure of the form:
%     out = struct { time, [ epfold ], lc, dp, exact }
% Each field is an array, where each element corresponds to one of the
% segments the split has produced. The individual fields are:
%     * time: average time of segment
%     * epfold: struct { p, stat, nbins, badp }
%       (not output if 'split_only' qualifier has been used)
%     * lc: of the same form as input structure lc
%     * dp: either p^2 / T or dpmin
%     * exact: 1 if exact qualifier was used for epfold, 0 otherwise
% Remarks regarding qualifiers:
%     * by default, exact is only chosen if there are less than exact_threshold
%       pulses in the timespan considered. However, as of Sep 16,
%       there was a bug in pfold, so that exact is ONLY used if exact_threshold
%       the 'exact_threshold' qualifier exists. When this bug is fixed, please
%       change the constant at the beginning of the script
%     * nsrch and grid_steps are mutually exclusive. If you set nsrch
%       to 0, the default epfold routine will be
%       used
%     * All qualifiers can also be passed using a structure named
%       'epfold_qualifiers'. If this qualifier is present, its
%       content will overwrite all other qualifiers given. If passed
%       using this structure, all qualifiers must be assigned values
%       (e.g. exact = 0, split_only = 1). Makes scripts easier to
%       read.
%
%\seealso{pfold, epfold, pulseperiod_epfold, pulseperiod_search, find_peak}
%!%-
{
   variable exact_bug = 1; % set this to 0 when the bug in pfold (; exact) has been fixed
                                                                                                                                                                                                  
   variable lc, p0;                              % definition of lightcurve array of structures and initial trial period
   switch (_NARGS)                                     % the input is checked
      { case 2: (lc, p0) = (); }
      { help(_function_name); return; }
                                                                                                                                                                                                  
   % sanity checks
   if (typeof(lc) != Array_Type) { lc = [lc]; }        % further checks of the input data
   variable iii;
   _for iii (0, length(lc) - 1, 1) {
      try {
         variable timex = lc[iii].time;
         variable ratex = lc[iii].rate;
         variable fracexpx = lc[iii].fracexp;
         variable errorx = lc[iii].error;
         variable sumx = timex + ratex + fracexpx + errorx;
      } catch AnyError: {
         vmessage("Error(%s): lc must have fields time, rate, error, fracexp. These have to be arrays of numbers of the same length", _function_name);
         return;
      }
   }
   if (_typeof(lc) != Struct_Type) { vmessage("error(%s): light curves have to be an array of structures!", _function_name); return; }
   if (typeof(p0) != Double_Type) { vmessage("error(%s): pulse period has to be a floating point number!", _function_name); return; }
   if (p0 <= 0) { vmessage("error(%s): pulse period has to be > 0", _function_name); return; }
                                                                                                                                                                                                  
   % pre-process input
   variable nlc = length(lc);                          % nlc is the number of structures given, each structure contains one lightcurve etc.
   lc = array_map(Struct_Type, &struct_combine, COPY(lc), struct { split = 0, splitnum = 0 }); % the fields split and splitnum are added to each of nlc lc structures
   % qualifiers %{{{
   variable epfold_qualifiers_default = empty_struct (); 
   variable aa;
   if (qualifier_exists("exact_threshold")) { aa=struct{exact_threshold=qualifier("exact_threshold")};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }
   if (qualifier_exists("fracexp")) { aa=struct{fracexp=qualifier("fracexp")};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }
   if (qualifier_exists("search_range")) { aa=struct{search_range=qualifier("search_range")};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }
   if (qualifier_exists("dpmin")) { aa=struct{dpmin=qualifier("dpmin")};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }
   if (qualifier_exists("gap_scale")) { aa=struct{gap_scale=qualifier("gap_scale")};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }
   if (qualifier_exists("chatty")) { aa=struct{chatty=qualifier("chatty")};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }
   if (qualifier_exists("grid_steps")) { aa=struct{grid_steps=qualifier("grid_steps")};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }
   if (qualifier_exists("nsrch")) { aa=struct{nsrch=qualifier("nsrch")};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }
   if (qualifier_exists("nbins")) { aa=struct{nbins=qualifier("nbins")};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }
   if (qualifier_exists("split_only")) { aa=struct{split_only=1};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }
   if (qualifier_exists("exact")) { aa=struct{exact=1};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }
   if (qualifier_exists("not_exact")) { aa=struct{not_exact=1};epfold_qualifiers_default=struct_combine(epfold_qualifiers_default,aa); }

   if (length(get_struct_field_names(epfold_qualifiers_default)) != 0 and qualifier_exists("epfold_qualifiers") ) {
      vmessage("Warning(%s): You have provided qualifiers both as a structure and as individual arguments, I will only consider the structure", _function_name);
   }

   variable epfold_qualifiers = qualifier ( "epfold_qualifiers", epfold_qualifiers_default );
   if (typeof(epfold_qualifiers) != Struct_Type) {
      vmessage("Error(%s): epfold_qualifiers must be a structure", _function_name);
      return;
   }
   variable exact_threshold = get_qualifier ( epfold_qualifiers, "exact_threshold", 6.);
   if (struct_field_exists(epfold_qualifiers, "exact_threshold")) { exact_bug = 0; }
   variable fracexp = get_qualifier ( epfold_qualifiers, "fracexp", 1. ); % fractional exposure, if less than the defined value the data bin will not be considered
   variable sdp = get_qualifier ( epfold_qualifiers, "search_range", 2. ); % scales the period search range
   variable dpmin = get_qualifier ( epfold_qualifiers, "dpmin", 0.001*p0 ); % the minimum expected width of the chi2 peak (for high T p^2/T can be misleading)
   variable gs = get_qualifier ( epfold_qualifiers, "gap_scale", 0.5 );  % measure for the threshold at which a gap is detected
   variable chatty = get_qualifier ( epfold_qualifiers, "chatty", 1 );           % determines the program's behaviour
   variable grid_steps = get_qualifier ( epfold_qualifiers, "grid_steps", -1. );
   variable nsrch = get_qualifier ( epfold_qualifiers, "nsrch", struct_field_exists(epfold_qualifiers,"grid_steps") ? -1. : 1e4 );
   variable nbins = get_qualifier ( epfold_qualifiers, "nbins", -1 );
   variable split_only = get_qualifier ( epfold_qualifiers, "split_only", 0);
   variable exact = get_qualifier ( epfold_qualifiers, "exact", 0);
   variable not_exact = get_qualifier ( epfold_qualifiers, "not_exact", 0);
   % Sanity checks %{{{
   ifnot (typeof(exact_threshold) == Double_Type or typeof(exact_threshold) == Integer_Type) {
      vmessage("Warning(%s): exact_threshold must be a number, setting it to default", _function_name);
      exact_threshold = 6.;
   }
   exact_threshold = double(exact_threshold);
   ifnot (typeof(fracexp) == Double_Type or typeof(fracexp) == Integer_Type) {
      vmessage("Warning(%s): fracexp must be a number, setting it to default", _function_name);
      fracexp = 1.;
   }
   fracexp = double(fracexp);
   if (fracexp<0 or fracexp>1) {
      vmessage("Warning(%s): fracexp must be [0,1], setting it to default", _function_name);
      fracexp = 1.;
   }
   ifnot (typeof(sdp) == Double_Type or typeof(sdp) == Integer_Type) {
      vmessage("Warning(%s): sdp must be a number, setting it to default", _function_name);
      sdp = 2.;
   }
   sdp = double(sdp);
   if (sdp < 2.) { vmessage("warning(%s):  search_range should usually be chosen >= 2", _function_name); }
   ifnot (typeof(dpmin) == Double_Type or typeof(sdp) == Integer_Type) {
      vmessage("Warning(%s): dpmin must be a number, setting it to default", _function_name);
      dpmin = 0.001*p0;
   }
   dpmin = double(dpmin);
   if (dpmin < 0) {
      vmessage("Warning(%s): dpmin has to be > 0, setting it to default",  _function_name);
      dpmin = 0.001*p0;
   }
   ifnot (typeof(chatty) == Integer_Type) {
      vmessage("Warning(%s): chatty has to be either 1 or 0, setting it to default", _function_name);
      chatty = 1;
   }
   ifnot (chatty == 1 or chatty == 0) {
      vmessage("Warning(%s): chatty has to be either 1 or 0, setting it to default", _function_name);
      chatty = 1;
   }
   ifnot (typeof(nsrch) == Integer_Type or typeof(nsrch) == Double_Type) {
      vmessage("Warning(%s): nsrch must be a number, setting it to default", _function_name);
      nsrch = 1e4;
   }
   nsrch = nint(nsrch);
   ifnot (typeof(grid_steps) == Integer_Type or typeof(grid_steps) == Double_Type) {
      vmessage("Warning(%s): grid_steps must be number, setting it to default", _function_name);
      grid_steps = 0.001*p0;
   }
   if (nsrch*grid_steps > 0) { vmessage("error(%s): grid_steps and nsrch qualifiers are mutually exclusive", _function_name ); return; }
   ifnot (typeof(nbins) == Integer_Type or typeof(nbins) == Double_Type) {
      vmessage("Warning(%s): grid_steps must be number, setting it to default", _function_name);
      nbins = -1;
   }
   nbins = nint(nbins);
   ifnot (typeof(split_only) == Integer_Type) {
      vmessage("Warning(%s): split_only can only be 1 or 0, setting it to default", _function_name);
      split_only = 0;
   }
   ifnot (split_only == 0 or split_only == 1) {
      vmessage("Warning(%s): split_only can only be 1 or 0, setting it to default", _function_name);
      split_only = 0;
   }
   ifnot (typeof(exact) == Integer_Type) {
      vmessage("Warning(%s): exact can only be 1 or 0, setting it to default", _function_name);
      exact = 0;
   }
   ifnot (exact == 0 or exact == 1) {
      vmessage("Warning(%s): exact can only be 1 or 0, setting it to default", _function_name);
      exact = 0;
   }
   ifnot (typeof(not_exact) == Integer_Type) {
      vmessage("Warning(%s): not_exact can only be 1 or 0, setting it to default", _function_name);
      not_exact = 0;
   }
   ifnot (not_exact == 0 or not_exact == 1) {
      vmessage("Warning(%s): not_exact can only be 1 or 0, setting it to default", _function_name);
      not_exact = 0;
   }
   ifnot (exact * not_exact == 0) { vmessage("Error(%s): exact and not exact are mutually exclusive", _function_name); return; }
   %}}}
   %}}}
                                                                                                                                                                                                  
   % light curve properties and eventually split them
   variable lcp = struct {
      time = Double_Type[nlc],                          % mean time - just the centre of the time grid
      dt = Double_Type[nlc],                            % time resolution - width of the time bins
      len = Double_Type[nlc],                           % length - total length of the time grid
      bins = Integer_Type[nlc],                         % number of time bins - integer number of time bins
      dp = Double_Type[nlc],                            % formal epfold period resolution - the theoretical p^2/T limit, can be replaced by dpmin
   };
   % loop over light curve(s) (if splitted below until all segments were looped)
   variable i = 0;                                     % loop variable, loops over the individual structures in array lc
   while (i < nlc)
   { %{{{                                  % for all structures
      % field checks
      if (any(array_map(Integer_Type, &struct_field_exists, lc[i], ["time", "rate", "error", "fracexp"]) == 0)) { vmessage("erros(%s): light curve does not have all required fields!"); return; }
      % filter on fractional exposure
      struct_filter(lc[i], where(lc[i].fracexp >= fracexp));  % only those parts of the ith structure are allowed where the fracexp criterion is met
      % determine properties
      lcp.dt[i] = median ( (lc[i].time - shift(lc[i].time,-1))[[0:length(lc[i].time)-1]] );                % the aforementioned variables are filled with values
      lcp.len[i] = lc[i].time[-1]-lc[i].time[0] + lcp.dt[i];
      lcp.bins[i] = length(lc[i].time);
      lcp.time[i] = lc[i].time[0] + .5*lcp.len[i];
      lcp.dp[i] = p0^2 / lcp.len[i];
      % check on gaps and split light curve
      variable splitted = 0;                                  % counter variable
      if (lcp.len[i] - lcp.dt[i]*lcp.bins[i] > lcp.dt[i]) {   % if the total time span is larger than the number of bins times time step , do ... (i.e. there exist gaps)
         variable gt = max ( [ lcp.dt[i], gs*(p0^2/lcp.dp[i] - p0) ] );               % gap threshold - equals 'gapscale' times ( total time span - trial period )
         %if (chatty) { vmessage("  light curve [%d] contains gaps (threshold %.0f s)", i, gt); }
         variable slc = split_lc_at_gaps(lc[i], gt);           % where the gaps in the time grid are larger than the threshold, the structure is split -->
                                                               % returns an array of structures called slc (each of the contained structures doesn't contain gaps anymore)
         % splitted
         if (length(slc) > 1) {                                % if the lightcurve has been split , do ...
            splitted = 1;                                       % counter variable is changed
            slc[0].splitnum = length(slc)-1;                    % the first structure is assigned splitnum = number of structures - 1
            if (chatty) { vmessage("(%s): light curve splitted into %d segments", _function_name, slc[0].splitnum+1); }
            variable j;
            _for j (1, length(slc)-1, 1) {                      % iteration over all structures except for the very first one
               slc[j].split = j;                                 % variable split is set to the index of the structure in slc
               slc[j].splitnum = slc[0].splitnum;                % all splitnum in the array are the same
            }
            % insert into main array
            lc = [                                             % at the position of the previously unsplit structure the split structures are inserted 
               i>0 ? lc[[:i-1]] : Struct_Type[0], % up to i-1    % if i==0, no data is written, otherwise the ith lc-structures until i-1 are written
               slc, % splitted ones                              % the splitted structures are written
               lc[[i+1:]] % from i+1                             % the following lc-structures are written
            ];
            % increase number of light curves and property structure
            struct_filter(lcp, [[0:nlc-1], ones(slc[0].splitnum)*0]); % the number of fields in lcp (the property structure) is correspondingly increased
            nlc += slc[0].splitnum;                                   % the number of structures in the array lc is correspondingly increased
         }
      }
      % go on
      if (splitted == 0) { i++; }                             % if no splitting was necessary, the next structure can be approached, otherwise the current one is processed
   }                                                         % again (check???)
   %}}}
                                                                                                                                                                                                  
   % prepare output structure
   variable out = struct { %{{{                                  % out contains:
      time = Double_Type[nlc], 
      epfold = Struct_Type[nlc],    % error of period, the folding output for each structure
      lc = lc,                                                 % the input lightcurves (splitted now!)
      dp = Double_Type[nlc],
      exact = Integer_Type[nlc], }; %}}}
   
   % epoch folding
   _for i (0, nlc-1, 1) { %{{{                                   % it is iterated over all structures (splitted now!)
      if (lcp.len[i] < 2. * p0) { continue; }
      if (p0-lcp.dp[i]*sdp < 0 || p0+lcp.dp[i]*sdp > lcp.len[i]) {
        vmessage("warning(%s): period search range too large, skipping light curve [%d]", _function_name, i);
        % sdp = min ( [ ( lcp.len[i] - p0 ) / lcp.dp[i], p0 / lcp.dp[i] ] );
        continue;
      }
      % epoch folding
      variable psr = _max(lcp.dp[i]*sdp, dpmin); % period search range - it's the maximum of the theoretical one (p^2/T*scaling) and the minimum allowed one
      
      variable pmin = _max(p0-0.4*p0, p0-psr, 0);                        % no negative periods allowed! -- added by Leander
      variable pmax = _min(p0+psr, p0+0.8*p0);
      variable epf;
                                                                                                                                                                                                   
      if ( split_only ) {
         if (i==0) { vmessage("(%s): Skipping epoch folding, only splitting of the lc has been performed", _function_name); }
         epf = empty_struct();
      } else { %{{{         
         nbins = (nbins < 0) ? (min ( [ 32, nint(p0 / lcp.dt[i]) ] )) : nbins; % nbins is set. The current p0/dt version is very small sometimes, but avoids problems with oversampling
         variable exct;
         if ( exact ) {
            exct = 1.;
         } else {
            if  ( exact ) { 
               exct = -1.;
            } else {
               if  ( ( ( max(lc[i].time) - min(lc[i].time) ) / p0  < exact_threshold ) and not exact_bug) { % normally, only the first criterion should be necessary. When 'exact' is working again remove the 2nd
                  exct = 1.;
               } else {
                  exct = -1.;
               }
            }
         }                                                                                                                                                                                                 
         if (exct == 1) {
            out.exact[i] = 1;
         } else {
            out.exact[i] = 0;
         }

         % For different configurations epfolding is carried out.
         if (nsrch > 0 and exct > 0.) { %{{{
            vmessage("(%s): epochfolding with exact, nsrch=%d, nbins=%d", _function_name, nsrch, nbins);
            epf = epfold(                                 % the epochfolding is calculated with the usual ISIS function
               lc[i].time, lc[i].rate, pmin, pmax;        % the required paramaters are given
               nsrch=nsrch, dt = lcp.dt[i]*lc[i].fracexp, nbins=nbins, chatty = -1, exact,
                        ); %}}}
         } else if (nsrch < 0 and exct > 0.) { %{{{ 
            vmessage("(%s): epochfolding with exact, grid_steps=%lf, nbins=%d", _function_name, grid_steps, nbins);
            epf = epfold(                                 % the epochfolding is calculated with the usual ISIS function
               lc[i].time, lc[i].rate, pmin, pmax;        % the required paramaters are given
               dp=grid_steps, dt = lcp.dt[i]*lc[i].fracexp, nbins=nbins, chatty = -1, exact,
                        ); %}}}
         } else if (nsrch > 0 and exct < 0.) {%{{{ 
            vmessage("(%s): epochfolding without exact, nsrch=%d, nbins=%d", _function_name, nsrch, nbins);
            epf = epfold(                                 % the epochfolding is calculated with the usual ISIS function
               lc[i].time, lc[i].rate, pmin, pmax;        % the required paramaters are given
               nsrch=nsrch, dt = lcp.dt[i]*lc[i].fracexp, nbins=nbins, chatty = -1,
                        ); %}}}
         } else if (nsrch < 0 and exct < 0.) {%{{{ 
            vmessage("(%s): epochfolding without exact, grid_steps=%lf, nbins=%d", _function_name, grid_steps, nbins);
            epf = epfold(                                 % the epochfolding is calculated with the usual ISIS function
               lc[i].time, lc[i].rate, pmin, pmax;        % the required paramaters are given
               dp=grid_steps, dt = lcp.dt[i]*lc[i].fracexp, nbins=nbins, chatty = -1,
                        ); %}}}
         } else if (nsrch == 0 and exct > 0.) {%{{{
            vmessage("(%s): epochfolding with exact, default, nbins=%d", _function_name, nbins);
            epf = epfold(                                 % the epochfolding is calculated with the usual ISIS function
               lc[i].time, lc[i].rate, pmin, pmax;        % the required paramaters are given
               dt = lcp.dt[i]*lc[i].fracexp, nbins=nbins, chatty = -1, exact,
                        ); %}}}
         } else if (nsrch == 0 and exct < 0.) {%{{{
            vmessage("(%s): epochfolding without exact, default, nbins=%d", _function_name, nbins);
            epf = epfold(                                 % the epochfolding is calculated with the usual ISIS function
               lc[i].time, lc[i].rate, pmin, pmax;        % the required paramaters are given
               dt = lcp.dt[i]*lc[i].fracexp, nbins=nbins, chatty = -1,
                        ); %}}}
         } else {
            vmessage ("error(%s): corrupted qualifier set", _function_name);
            return;
         }                                                                                                                                                                                                
      }%}}}

                                                                                                                                                                                                      
      out.dp[i]=lcp.dp[i];
      % save into output
      out.epfold[i] = epf;   % these values are written into the output structure
      out.time[i]   = mean(lc[i].time);                                            % the out.time is the average of the time scale
   } %}}}
   if (split_only) {out=reduce_struct(out, "epfold");}
                                                                                                                                                                                                  
   % sort by time
   variable n = array_sort(lcp.time);
   struct_filter(lcp, n);
   struct_filter(out, n);
   
   return out;                                                                    % that's it
}
%}}}
