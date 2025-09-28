%%%%%%%%%%%%%%%%%%%%%
define bbootstrap() {
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{bbootstrap}
%\synopsis{1-parameter bootstrap calculation of function 'funct'}
%\usage{Array_Type bbootstrap(Array_Type data, Integer_Type num_samp
%                             [, funct = &mean, datatype = Double_Type]);}
%\qualifiers{
%    \qualifier{slow}{the balanced bootstrap is performed. This is
%            more accurate, especially for long-tailed
%            distributions, but is also much slower and
%            requires more memory.}
%}
%\description
%    This function has been ported from the IDL-routine
%    bbootstrap.pro by H.T. Freudenreich, HSTX, 2/95
%
%    This program randomly selects values to fill sets of
%    the same size as 'data'. Then calculates the 'funct'
%    of each, which is an optional function reference with
%    the &mean as default. It does this 'num_samp' times.
%    The 'datatype' returned by 'funct' has to be provided
%    to initialize the array returned by this function. 
%    If the slow-qualifier is set, the balanced bootstrap
%    method is used to obtain the samples, hence the name
%    'bbootstrap'. This method requires, however, more
%    virtual memory, and patience.
%
%    The user should choose 'num_samp' large enough to get
%    a good distribution. The sigma of that distribution
%    is then the standard deviation of the mean of the
%    returned 'funct'-vector.
%    For example, if input 'data' is normally distributed
%    with a standard deviation of 1.0, the standard
%    deviation of the returned 'funct'-vector (by default
%    the mean) will be ~1.0/sqrt(N-1), where N is the
%    number of values in 'data'.
%
%    WARNING: at least 5 points must be input.
%             The more, the better.
%!%-
  variable data, num_samp, funct = &mean, datatype = Double_Type;
  switch(_NARGS)
    { case 2: (data, num_samp) = (); }
    { case 4: (data, num_samp, funct, datatype) = (); }
    { help(_function_name); return; }

  variable anser = datatype[num_samp];
  variable n = length(data);
  variable i;
  
  if (qualifier_exists("slow")) {
    % concatenate everything into one long vector
    variable m = num_samp*n;
    variable biggy = Double_Type[m];
    variable k = n-1;
    variable i1 = 0;
    _for i (0, num_samp-1, 1) {
      biggy[[i1:i1+k]] = data;
      i1 += n;
    }

    % now scramble it!
    % select m numbers at random, repeating none
    biggy = biggy[array_permute(m)];

    % now divide it into num_samp units and perform the funct on each.
    i1 = 0;
    _for i (0, num_samp-1, 1) {
      anser[i] = @funct(biggy[[i1:i1+k]]);
      i1 += n;
    }
  }

  else {
    seed_random(_time*2+1);
    variable seeds = int(urand(num_samp)*1e6+1);
    _for i (0, num_samp-1, 1) {
      % update the random number seed and get uniform random numbers between 0 and n-1
      seed_random(seeds[i]);
      variable r = int(urand(n)*n);
      variable v = data[r];
      anser[i] = @funct(v);
    }
  }

  return anser;
}
