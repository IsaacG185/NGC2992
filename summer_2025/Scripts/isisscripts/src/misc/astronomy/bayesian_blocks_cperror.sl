%%%%%%%%%%%%%%%%%%%%%
define bayesian_blocks_cperror() {
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{bayesian_blocks_cperror}
%\synopsis{calculates the probability distribution
%    of the change point positions}
%\usage{Struct_Type[] bayesian_blocks(Struct_Type blocks);}
%\description
%    After
%      Scargle et al., 2013, ApJ 764, 167
%    the uncertainty of the position of a change point in
%    a bayesian block representation can be estimated by
%    calculating the fitness of a block with variing
%    change point position, while all other change points
%    are kept fix. Although inter-change-point dependencies
%    are neglected in this approach, it can be used to
%    derive proper uncertainties as long as the resulting
%    distributions do not overlap.
%
%    This function is an implementation of this procedure
%    based on the MatLab-programs 'figure_cp_error' and
%    'cp_prob' by the authors above.
%
%    The input 'blocks' have to be calculated previously
%    by the 'bayesian_blocks' function. The returned
%    structure array contains the probability distribution
%    'prob' (integral = 1.) over the time-tags 'tt' for
%    each change point (i.e., the array index corresponds
%    to the change point index). From each individual
%    distribution an uncertainty for the location of the
%    change point can be estimated via, e.g., its width.
%\seealso{bayesian_blocks}
%!%-
  variable blocks;
  switch (_NARGS)
    { case 1: blocks = (); }
    { help(_function_name); return; }

  variable num_cp = length(blocks.change_points);
  variable id_cp, tt_1, cp_1, tt_2, cp_2, cp_center, tt_center;
  variable iu, tt_use, tt_use_min, tt_use_max;
  variable num, dt, dt_median, tt_range, block_length;
  variable id_left, t1, t2, n1, n2, log_prob_1, log_prob_2;
  variable log_prob_vec, log_prob_max;
  variable prob = struct_array(num_cp, struct { tt, prob });
  % loop over all change points
  _for id_cp (0, num_cp-1, 1) {
    %%% get position and times of adjacent and current change points
    % previous
    if (id_cp == 0) { tt_1 = blocks.tt_all[0]; }
    else {
      cp_1 = blocks.change_points[id_cp-1];
      tt_1 = blocks.tt_all[cp_1];
    }
    % current
    cp_center = blocks.change_points[id_cp];
    tt_center =  blocks.tt_all[cp_center];
    % following
    if (id_cp == num_cp-1) { tt_2 = blocks.tt_all[-1]; }
    else {
      cp_2 = blocks.change_points[id_cp+1];
      tt_2 = blocks.tt_all[cp_2];
    }

    % indices of data in current block
    iu = where(blocks.tt_all >= tt_1 and blocks.tt_all <= tt_2);
    tt_use = blocks.tt_all[iu];
    tt_use_min = tt_use[0];
    tt_use_max = tt_use[-1];

    % calculate fitness of current block with variing change point position
    num = length(tt_use);
    dt = diff(tt_use);
    if (min(dt) < 0) { vmessage("error (%s): points must be ordered", _function_name); return; }
    dt_median = median(dt);

    tt_range = tt_use_max - tt_use_min;
    block_length = tt_use_max - [tt_use_min, .5*(tt_use[[1:]] + tt_use[[:-2]]), tt_use_max];
    log_prob_vec = Double_Type[num];

    _for id_left (0, num-1, 1) {
      t2 = block_length[id_left];
      t1 = tt_range - t2;

      n1 = id_left;
      n2 = num - n1;

      log_prob_1 = id_left == 0 ? 0. : n1 * log(1. * n1 / t1);
      log_prob_2 = n2 * log(1. * n2 / t2);

      log_prob_vec[id_left] = log_prob_1 + log_prob_2;
    }
    
    log_prob_max = max(log_prob_vec);
    prob[id_cp].prob = exp(log_prob_vec - log_prob_max);
    prob[id_cp].prob /= sum(prob[id_cp].prob);
    prob[id_cp].tt = @(tt_use);
  }

  return prob;
}
