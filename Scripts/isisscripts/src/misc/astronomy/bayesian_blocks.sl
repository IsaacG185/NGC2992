
%%%%%%%%%%%%%%%%%%%%%
define bayesian_blocks() {
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{bayesian_blocks}
%\synopsis{find bayesian blocks in the given data}
%\usage{Struct_Type bayesian_blocks(Struct_Type[] data);}
%\qualifiers{
%    \qualifier{fp_rate}{value of the false positive rate, which is
%                the probability that a found change point
%                with the current value of ncp_prior is
%                actually not significant (default: .01)
%                WARNING: This has no influence on data of     
%                type 3, where the default ncp_prior, fp_rate
%                is 0.05, and it is not possible to change this
%                currently.}
%    \qualifier{ncp_prior}{controls the tolerance level used to find
%                the change points. The value has to be an
%                array of estimates for the order of number
%                of blocks for each given dataset. The
%                probability P that the final number of
%                blocks N_blocks is then given by
%                  log(P) ~ ncp_prior * N_blocks
%                Thus, ncp_prior has to be decreased to
%                increase the final number of blocks.
%                The default value is determined by a
%                formula derived from simulations, given by
%                  ncp_prior = 4 - log(73.53*fp_rate*N^-0.478) 
%                for data modes 1 and 2 and 
%                  ncp_prior = 1.32 + 0.577*log(N) 
%                for data mode 3, where N is the number of
%                data points.}
%    \qualifier{do_iter}{number of iterations on ncp_prior
%                (default: 0)}
%    \qualifier{dt_min}{events within the given time range are
%                considered to be simultaneous and a new
%                combined event at the average time is added
%                (default: 0)}
%    \qualifier{num_skip}{maximal number of consecutive simultaneous
%                events (time difference < dt_min)}
%    \qualifier{gti}{structure containing the GTIs for the given
%                events (data mode 1) with the fields 'start'
%                and 'stop'. The blocks are searched for each
%                GTI individually, thus the function returns
%                an array structures! If GTIs are given only
%                ONE input dataset is allowed (at the moment).}
%    \qualifier{gti_mindt}{all GTIs shorter than the given duration are
%                ignored (i.e. no blocks are searched)
%                (default: 0)}
%}
%\description
%    This function is an S-lang implementation of the
%    'find_blocks_mult' MatLab-program described in
%      Scargle et al., 2013, ApJ 764, 167
%    which source code is available on the arXiv.
%
%    WARNING: The full functionality has not been tested
%    yet, thus please use with caution!
%
%    Depending on the fields of the input 'data' structure,
%    the best Bayesian block representation is determined.
%    The available data modes are:
%    1: Event data
%      Double_Type[] tt        - time tags of events
%    2: Binned data (data without specific uncertainties,
%       e.g., counts vs. time)
%      Double_Type[] tt        - time tags
%      Double_Type[] nn_vec    - binned data at tt
%WARNING! Mode 2 possibly has bugs! Use with extreme caution!
%    3: Point measurements (data with known uncertainties,
%       e.g., radio flux vs. time)
%      Double_Type[] tt        - time tags
%      List_Type[]   cell_data - cell data at tt defined as
%                     { Double_Type[] data, uncertainties }
%
%    The output structure contains
%      change_points - time INDICES of the change points
%      tt_all        - combined time tags of all datasets
%      ncp_prior_vec - ncp_prior value of each dataset
%      data_matrix   - see Fig. 2 of Scargle et al. 2013
%      last          - index of the last change point
%                      over tt_all
%      best          - fitness (=statistics) over tt_all
%      index_vec     - dataset index over tt_all
%      data_mode_vec - data mode of each dataset
%
%   The algorithm can handle multiple datasets, which are
%   combined internally to one dataset (tt_all). Zero
%   blocks are handled as well.
%
%   NOTE: in case of events (data mode 1) it is important
%         to provide the GTIs via the corresponing qualifier
%         as well. Otherwise the block statistics are
%         probably wrong and thus the total block
%         represenation!
%
%   To finally retrieve the block represenatation of the
%   input data, the 'get_blocks_data' function can be used.
%\seealso{get_blocks_data}
%!%-
  variable data;
  switch (_NARGS)
   { case 1: data = (); }
   { help(_function_name); return; }

  % check on type of given data
  if (typeof(data) != Array_Type)
  {
    data = [data];
  }
  if (_typeof(data) != Struct_Type)
  {
    vmessage("error (%s): input data has to be a structure", _function_name);
    return;
  }

  % check if GTIs are given -> determine blocks for each GTI separately
  if (qualifier_exists("gti"))
  {
    % only one dataset is allowed
    if (length(data) > 1){
      vmessage("error (%s): in case of GTIs only one dataset is allowed", _function_name);
      return;
    }
    data = data[0];
    % only datamode 1 is allowed
    if (struct_field_exists(data, "cell_data") or struct_field_exists(data, "nn_vec"))
    {
      vmessage("error (%s): in case of GTIs only event data is allowed", _function_name);
      return;
    }
    % check GTI structure
    variable gti = qualifier("gti");
    if (typeof(gti) != Struct_Type)
    {
      vmessage("error (%s): GTIs have to be defined via a structure", _function_name);
      return;
    }
    ifnot (struct_field_exists(gti, "start") and struct_field_exists(gti, "stop"))
    {
      vmessage("error (%s): GTI structure is missing fields", _function_name);
      return;
    }
    
    % recursively call the function itself
    variable gtidt = qualifier("gti_mindt", 0.);
    struct_filter(gti, where(gti.stop - gti.start >= gtidt));
    vmessage("considering %d GTIs", length(gti.start));
    variable out = Struct_Type[length(gti.start)];
    variable qual = reduce_struct(__qualifiers, ["gti", "gti_mindt"]);        
    variable g, n;
    _for g (0, length(out)-1, 1) {
      n = where(gti.start[g] <= data.tt <= gti.stop[g]);
      if (length(n) > 1)
      {
	out[g] = bayesian_blocks(struct { tt = data.tt[n] } ;; qual);
      }
      else {
	vmessage("warning: GTI number %d has less than two events, ignoring...", g+1);
      }
    }
    return out;  
  }

  % copy data structure since it gets modified below
  data = COPY(data);
  
  % preferences and variables
  variable num_series = length(data); % number of time series
  variable do_iter = qualifier("do_iter", 0); % number of iterations on ncp_prior
  variable fp_rate = qualifier("fp_rate", .01); % value of false positive rate
  
  % set up data matrix
  variable data_mode_vec = Integer_Type[num_series]; % all zeros
  variable ncp_prior_vec = Double_Type[num_series];
  variable tt_start_vec = @ncp_prior_vec;
  variable tt_stop_vec = @ncp_prior_vec;
  variable ii_start_vec = @data_mode_vec;
  variable tt = Double_Type[0]; % initialize master time array
  variable ii_start = 1-1; % initialize marker for parsing the data
  variable row_count = 1; % first row is array containing all times

  variable d;
  _for d (0, num_series-1, 1) {
    % identify data mode (3=point measurements, 2=binned data, 1=event_data)
    if (struct_field_exists(data[d], "cell_data"))
    {
     data_mode_vec[d] = 3;
    } else if (struct_field_exists(data[d], "nn_vec"))
    {
      data_mode_vec[d] = 2; vmessage("WARNING! Entering mode 2.. there are possibly bugs in this mode! Use with caution!");
    } else
    {
      data_mode_vec[d] = 1;
    }

    row_count = row_count + 2; % these modes all take two rows

    % process time markers (all data modes must have one)
    variable tt_this = @(data[d].tt);
    variable dt_this = diff(tt_this);
    if (any(dt_this < 0))
    {
      vmessage("error (%s): data must be time ordered", _function_name);
      return;
    }

    if (data_mode_vec[d] == 1)
    {
      % combine any duplicate time_tags:
      variable dt_min = qualifier("dt_min", 0); % set to small value >0 to combine nearly equal times
      variable num_skip = qualifier("num_skip", 3);
      variable nn_vec = ones(length(tt_this));
      variable ii_dupe = where(dt_this <= dt_min); % indices of small intervals
      while (length(ii_dupe) > 0)
      {
        variable iu = ii_dupe[[0:length(ii_dupe)-1:num_skip]];
        % replace with average of the two identical (or close) times
        tt_this[iu] = .5*(tt_this[iu] + tt_this[iu+1]);
        % replace with sum of the two corresponding cell populations
        nn_vec[iu] = nn_vec[iu] + nn_vec[iu+1];

        % remove second member of these pairs
	tt_this = tt_this[complement([0:length(tt_this)-1], iu+1)];
	nn_vec = nn_vec[complement([0:length(nn_vec)-1], iu+1)];

        % any more duplicates?  If so, go again; if not, you are done.
        dt_this = diff(tt_this);
        ii_dupe = where(dt_this <= dt_min);
      }

      % store adjusted data back into master data structure
      data[d] = struct_combine(data[d], struct { tt = tt_this, nn_vec = nn_vec });
    }

    variable num_points_this = length(tt_this);
    tt = [tt, tt_this]; % concatenate all times

    % this array keeps track of index ranges of entries for each series:
    ii_start_vec[d] = ii_start;
    ii_start = ii_start + num_points_this; % update to start of next series

    tt_start_vec[d] = struct_field_exists(data[d], "tt_start") ? data[d].tt_start : tt[0] - 0.5 * median(diff(tt)); % default start time
    tt_stop_vec[d] = struct_field_exists(data[d], "tt_stop") ? data[d].tt_stop : tt[-1] + 0.5 * median(diff(tt)); % default stop time

    % store ncp_prior if present; if not, use default
%    ncp_prior_vec[d] = struct_field_exists(data[d], "ncp_prior") ? data[d].ncp_prior : 4 - log(fp_rate/(0.0136*num_points_this^.478));
    if (struct_field_exists(data[d], "cell_data"))
    {
      ncp_prior_vec[d] = (qualifier_exists("ncp_prior") ? qualifier("ncp_prior")[d] : 1.32 + 0.577*log(num_points_this));
    }
    else
    {
      ncp_prior_vec[d] = (qualifier_exists("ncp_prior") ? qualifier("ncp_prior")[d] : 4 - log(fp_rate/(0.0136*num_points_this^.478)));
    }
  } % for num_series

  % construct data matrix  (Figure 2: Top Panel)
  variable num_rows = row_count;
  variable num_data = length( tt ); % total number of data points
  variable data_matrix = Double_Type[num_data, num_rows];
  variable index_vec = Integer_Type[num_data];

  row_count = 0; % reset row counter for staging of data
  data_matrix[*,0] = @tt; % first row contains all times (unordered)

  variable ii_stop, tt_stop, tt_start, dt_start, dt_stop;
  _for d (0, num_series-1, 1)
  {
    % get index range for data for this series
    ii_start = ii_start_vec[d];
    ii_stop = d == num_series-1 ? num_data-1 : ii_start_vec[d+1] - 1;
    index_vec[[ii_start:ii_stop]] = d; % keep track of series

    % compute mode-dependent fitness data
    if (data_mode_vec[d] == 1 || data_mode_vec[d] == 2)
    {
      nn_vec  = data[d].nn_vec;
      tt_this = data[d].tt;
      tt_start = tt_start_vec[d];
      tt_stop = tt_stop_vec[d];

      dt_start = .5*(tt_this[1] + tt_this[0]) - tt_start;
      dt_stop = tt_stop - .5*(tt_this[-2] + tt_this[-1]);
      variable delt_tt = [dt_start, .5*(tt_this[[2:length(tt_this)-1]] - tt_this[[0:length(tt_this)-3]]), dt_stop];

      row_count = row_count + 1;
      data_matrix[[ii_start:ii_stop], row_count] = @delt_tt;

      row_count = row_count + 1;
      data_matrix[[ii_start:ii_stop], row_count] = @nn_vec;
    }
    else if (data_mode_vec[d] == 3)
    {
      variable cd = data[d].cell_data;
      row_count = row_count + 1;
      data_matrix[[ii_start:ii_stop], row_count] = cd[0] / cd[1]^2; % (x/sig^2 )

      row_count = row_count + 1;
      data_matrix[*, row_count] = 1; % non-zero denominator
      data_matrix[[ii_start:ii_stop], row_count] = 1. / cd[1]^2; %  (1/sig^2)
    }
  } % for num_series

  % redistribute data according to time order (Figure 2: Bottom Panel):
  variable num_points = length(tt);
  variable dm = COPY(data_matrix);
  variable ii_sort = array_sort(data_matrix[*,0]); % time order index
  tt = tt[ii_sort];
  data_matrix[*,*] = data_matrix[ii_sort,*]; % re-order everything
  index_vec = index_vec[ii_sort];

  
  % now apply the basic dynamic programming algorithm
  tt_start = min(tt_start_vec);
  tt_stop  = max(tt_stop_vec); % min( tt_stop      );
  % make array of lengths of the "last blocks"
  variable block_length = tt_stop - [tt_start, .5*(tt[[1:length(tt)-1]] + tt[[0:length(tt)-2]]), tt_stop];

  variable iter_count = 0;

  variable best, last, R, fit_vec, nn_cum_vec, arg_log_vec, fit_vec_this, sum_x_1, sum_x_0;
  variable num_cp, err_this, cpt_old = NULL;
  while (1)
  { % if iterating, continue until maximum number is reached
    best = Integer_Type[0];
    last = Integer_Type[0];

    _for R (0, num_points-1, 1)
    {
      fit_vec = Double_Type[R+1]; % initialize last-block fitness array
      row_count = 1; % initialize
      
      _for d (0, num_series-1, 1)
      {
%	ncp_prior = ncp_prior_vec[d];

	if (data_mode_vec[d] == 1 || data_mode_vec[d] == 2)
	{
	  row_count = row_count + 1;
	  delt_tt = data_matrix[[0:R], row_count-1];

	  row_count = row_count + 1;
	  nn_vec = data_matrix[[0:R], row_count-1];

	  nn_cum_vec = reverse(cumsum(reverse(nn_vec)));
	  arg_log_vec = reverse(cumsum(reverse(delt_tt)));
	  arg_log_vec[where(arg_log_vec <= 0)] = _Inf;

	  fit_vec_this = nn_cum_vec * (log(nn_cum_vec) - log(arg_log_vec));
	}
	else if (data_mode_vec[d] == 3)
	{ % measurements, normal errors
          row_count = row_count + 1;
          cd = data_matrix[*,row_count-1];
          sum_x_1 = cumsum(cd[[R:0:-1]]); % sum( x / sig^2 )
    
          row_count = row_count + 1;
          cd = data_matrix[*,row_count-1];
          sum_x_0 = cumsum(cd[[R:0:-1]]); % sum( 1 / sig^2 )
                
          fit_vec_this = (sum_x_1[[R:0:-1]] ^ 2 / (4 * sum_x_0[[R:0:-1]]) );
	}

        fit_vec_this[where(isnan(fit_vec_this))] = 0;
        fit_vec += fit_vec_this - ncp_prior_vec[d];
      }

      last = [last, where_max([0, best] + fit_vec)];
      best = [best, ([0, best] + fit_vec)[last[-1]]];
    }

    % now find changepoints by iteratively peeling off the last block
    variable index = last[num_points-1];
    variable change_points = Integer_Type[0];

    while (index > 0)
    {
      change_points = [index, change_points];
      index = last[index - 1];
    }

    if (do_iter == 0)
    {
      break;
    } % done; not iterating on ncp_prior
    else
    {
      iter_count++;
      num_cp = length(change_points);

      if (num_cp < 1)
      {
	num_cp = 1;
      }

      if (cpt_old != NULL)
      {
	if (num_cp == length(cpt_old))
	{ % compare with previous iteration
	  err_this = sum(abs(change_points - cpt_old));
	}
	else
	{
	  err_this = _Inf;
	}

	if (err_this == 0)
	{
	  vmessage("converged at %d", iter_count);
	  break;
	}

	if (iter_count > do_iter)
	{
	  vmessage("did not converge at %d", iter_count);
	  break;
	}
      }

      fp_rate = 1 - (1-fp_rate)^(1./num_cp);
%      ncp_prior_old = @(ncp_prior_vec[d]);
      ncp_prior_vec[d] = 4 - log(fp_rate / (.0136 * num_points^.478));
      cpt_old = @change_points;
    }
  }
  return struct {
    change_points = change_points,
    tt_all = tt,
    ncp_prior_vec = ncp_prior_vec,
    data_matrix = data_matrix,
    last = last,
    best = best,
    index_vec = index_vec,
    data_mode_vec = data_mode_vec
  };
}


%%%%%%%%%%%%%%%%%%%%%
define get_blocks_data() {
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_blocks_data}
%\synopsis{returnes the data of a Bayesian block representation}
%\usage{Struct_Type blockdata = get_blocks_data(Struct_Type blocks[, Integer_Type dataindex]);}
%\altusage{blockdata= get_blocks_data(Struct_Type[] blocks[, ...]);}
%\qualifiers{
%    \qualifier{datafun}{reference to a function to be called to
%              derive the block data (default: see text)}
%    \qualifier{errfun}{same as 'datafun', but for the block
%              uncertainties}
%    \qualifier{bydt}{divides the output data and uncertainties
%              by the length of the corresponding block,
%              can be assigned to a number used to divide
%              the data to for further normalization}
%}
%\description
%    Returnes the data of all block over time (e.g., a
%    lightcurve) with variable binsize from a previous
%    run of 'bayesian_blocks'. The default output
%    structure has the fields:
%      time  - lower time bin of a block
%      dt    - length of each block
%      data  - the data in the blocks and
%      error - and the corresponding uncertainties
%    The data and their uncertainties are calculated
%    from the original input data by functions (if
%    multiple dataset are present use the optional
%    'dataindex' parameter), which will be called for
%    each block and can be specified via qualifiers.
%    Their calling sequence is
%      Double_Type function(time, dt, data[, error])
%    where error is given in case of data mode 3
%    (point measurements) only. The default functions
%    depend on the data mode used previously:
%    1: Event data
%      datafun = sum(events)
%      errfun  = sqrt(sum(events))
%    2: Binned data
%      datafun = sum(nn_vec)
%      errfun  = sqrt(sum(nn_vec))
%    3: Point measurements
%      datafun = weighted_mean(cell_data[0],
%                              cell_data[1]; err)
%      errfun  = sqrt(sumsq(datafun - cell_data[0])
%                     / (length(cell_data[0]) - 1)
%                     / length(cell_data[0]))
%\example
%    % let 'evts' be a list of time-tagged events,
%    % find bayesian blocks
%    blocks = bayesian_blocks(struct { tt = evts });
%
%    % create a lightcurve of the block representation,
%    % 'bydt' will convert counts to rate
%    lc = get_blocks_data(blocks; bydt);
%
%    % plot the blocks
%    hplot(lc.time, lc.time+lc.dt, lc.data);
%\seealso{bayesian_blocks}
%!%-
  variable blocks, dinx = 0;
  switch (_NARGS)
    { case 1: blocks = (); }
    { case 2: (blocks, dinx) = (); }
    { help(_function_name); return; }

  if (typeof(blocks) != Array_Type) { blocks = [blocks]; }
  
  variable nb = int(sum(array_map(Integer_Type, &length, array_struct_field(blocks, "change_points")))) + length(blocks);
  variable out = struct {
    time = Double_Type[nb], dt = Double_Type[nb], data = Double_Type[nb], error = Double_Type[nb] 
  };

  variable g, no = 0;
  _for g (0, length(blocks)-1, 1) {
    variable b, ii_start = 0, ii_end, ftime, fdt, data, err;
    nb = length(blocks[g].change_points)+1;
    _for b (0, nb-1, 1) {
      % data indices of the block
      ii_end = (b < nb-1 ? blocks[g].change_points[b]-1 : length(blocks[g].tt_all)-1);
      % time information
      ftime = blocks[g].tt_all[[ii_start:ii_end]];
      fdt = blocks[g].tt_all[[ii_start+1:ii_end]] - blocks[g].tt_all[[ii_start:ii_end-1]];
      out.time[no+b] = blocks[g].tt_all[ii_start];
      out.dt[no+b] = blocks[g].tt_all[ii_end + (b < nb-1 ? 1 : 0)] - blocks[g].tt_all[ii_start];
      % input data within a block
      if (blocks[g].data_mode_vec[dinx] < 3) {
        data = blocks[g].data_matrix[[ii_start:ii_end],2+2*dinx];
        err = NULL;
      } else {
        data = blocks[g].data_matrix[[ii_start:ii_end],1+2*dinx] / blocks[g].data_matrix[[ii_start:ii_end],2+2*dinx];
        err = 1./sqrt(blocks[g].data_matrix[[ii_start:ii_end],2+2*dinx]);
      }
      % calculate output data
      if (qualifier_exists("datafun")) {
        if (blocks[g].data_mode_vec[dinx] < 3) { out.data[no+b] = @(qualifier("datafun"))(ftime, fdt, data); }
        else { out.data[no+b] = @(qualifier("datafun"))(ftime, fdt, data, err); }
      }
      else {
        if (blocks[g].data_mode_vec[dinx] < 3) { out.data[no+b] = sum(data); }
        else { out.data[no+b] = weighted_mean(data; err = err); }
      }
      % calculate output uncertainties
      if (qualifier_exists("errfun")) {
      if (blocks[g].data_mode_vec[dinx] < 3) { out.error[no+b] = @(qualifier("errfun"))(ftime, fdt, data); }
        else { out.error[no+b] = @(qualifier("errfun"))(ftime, fdt, data, err); }
      }
      else {
        if (blocks[g].data_mode_vec[dinx] < 3) { out.error[no+b] = sqrt(out.data[no+b]); }
       	else { out.error[no+b] = sqrt(sumsq(out.data[no+b] - data) / (length(data) - 1) / length(data)); }
      }
      % eventually divide by dt
      if (qualifier_exists("bydt")) {
        variable bydt = qualifier("bydt");
        if (bydt == NULL) { bydt = 1.; }
        out.data[no+b] /= (out.dt[no+b] * bydt);
        out.error[no+b] /= (out.dt[no+b] * bydt);
      }

      ii_start = ii_end + 1;
    }

    no += nb;
  }

  return out;
}
