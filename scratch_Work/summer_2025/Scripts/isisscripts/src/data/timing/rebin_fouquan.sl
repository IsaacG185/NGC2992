define rebin_fouquan()
%!%+
%\function{rebin_fouquan}
%\synopsis{rebins a Fourier quantity from timing analysis with foucalc}
%\usage{Struct_Type rebin_fouquan(freq, fouquan, numseg)}
%\description
%    \code{freq} is an array of the original Fourier frequencies.
%    \code{fouquan} is the array of original Fourier quantities.
%    \code{numseg} is the number of seqments used to calculate \code{fouquant}.
%
%    The output structure has the following fields, which are arrays:
%    - \code{freq_lo} and \code{freq_hi} define the new frequency bin.
%    - \code{freq} is the average original frequency in each bin.
%    - \code{n} is the number of original frequencies, and
%    - \code{n_tot} is the total number of values (including segmentation) contributing to each bin.
%    - \code{value} is the average Fourier quantity.
%    - \code{error = value/sqrt(n_tot)} is the 1 sigma error for the \code{n_tot} values.
%    - \code{sigma} is the standard deviation of the original quanities in each bin
%\qualifiers{
%\qualifier{logfreq}{}
%\qualifier{linfreq}{}
%\qualifier{newfreq}{array of new frequencies}
%\qualifier{nofreq}{no rebinning}
%\qualifier{verbose}{}
%}
%!%-
{
  variable fou, fields, field, freq, fouquan, numseg;
  variable new = struct { freq_lo, freq_hi, freq, n=NULL, n_tot };
  switch(_NARGS)
  { case 1: fou = ();
      fields = String_Type[0];
      foreach field (get_struct_field_names(fou))
	if(string_match(field, "^signormpsd", 1))
	  fields = [fields, field];
      return rebin_fouquan(fou, fields;; __qualifiers());
  }
  { case 2: (fou, field) = ();
      switch(typeof(field))
      { case String_Type:
          freq = fou.freq;
          fouquan = get_struct_field(fou, field);
          numseg = get_struct_field(fou, "numavgall");
      }
      { case Array_Type:
	  fields = field;
	  foreach field (fields)
	  {
	    variable tmp = rebin_fouquan(fou, field;; __qualifiers());
	    if(new.n==NULL)
	    {
	        (new.freq_lo, new.freq_hi, new.freq, new.n, new.n_tot)
	      = (tmp.freq_lo, tmp.freq_hi, tmp.freq, tmp.n, tmp.n_tot);
	    }
	    variable tmp_new = @Struct_Type(field+["", "_error", "_sigma"]);
	    set_struct_fields(tmp_new, tmp.value, tmp.error, tmp.sigma);
	    new = struct_combine(new, tmp_new);
	  }
	  return new;
      }
      { % else:
	  vmessage("error (%s): %S is not valid for field", _function_name(), typeof(field));
          return;
      }
  }
  { case 3: (freq, fouquan, numseg) = (); }
  { help(_function_name()); return; }

  variable fmin = min(freq);
  variable fmax = max(freq);

  % return structure
  new = struct_combine(new, struct { value, error, sigma });

  % check for qualifiers
  variable verbose = qualifier_exists("verbose");
  variable linfreq = qualifier("linfreq", NULL);
  variable logfreq = qualifier("logfreq", NULL);
  variable newfreq = qualifier("newfreq", NULL); % <<< qualifier newfreq has to be an array!

  % computing new frequency array
  if(qualifier_exists("nofreq"))
    new.freq_lo = freq;
  else
  {
    if((logfreq==NULL) && (linfreq==NULL) && (newfreq==NULL))
    { vmessage("warning (%s): no frequency rebinning specified. Assuming logfreq=0.15.", _function_name());
      logfreq = 0.15;
    }
    if(newfreq != NULL)
      new.freq_lo = newfreq;
    if(linfreq != NULL)
      new.freq_lo = fmin + [0:linfreq]*(fmax-fmin)/linfreq;
    if(logfreq != NULL)
      new.freq_lo = fmin * (1.+logfreq)^[0:log(fmax/fmin)/log(1.+logfreq)];
  }

  new.freq_hi = make_hi_grid(new.freq_lo);
  variable i, n = length(new.freq_lo);  % length of new arrays
  new.freq    = Double_Type[n];
  new.n       = Integer_Type[n];
  new.n_tot   = Integer_Type[n];
  new.value   = Double_Type[n];
  new.error   = Double_Type[n];
  new.sigma   = Double_Type[n];
  _for i (0, n-1, 1)
  {
    variable index = where(new.freq_lo[i] <= freq < new.freq_hi[i]);
    variable n_freqs = length(index);
    new.n[i] = n_freqs;
    if(typeof(numseg)==Array_Type)
      new.n_tot[i] = int(sum(numseg[index]));
    else
      new.n_tot[i] = n_freqs * numseg;
    if(n_freqs == 0)
    { if(verbose)
	vmessage("  ***(%s): Empty frequency-bin (#%d) found in %g-%g Hz.", _function_name(), i, new.freq_lo[i], new.freq_hi[i]);
    }
    else
    {
      variable av_value = sum(fouquan[index])/n_freqs;
      new.value[i] = av_value;
      new.error[i] = av_value/sqrt(new.n_tot[i]);  % one sigma error for n_tot measurements
      if(new.n_tot[i]>1)
        new.sigma[i] = sqrt( sum(sqr(fouquan[index])-av_value^2) / (new.n_tot[i]-1.)); % standard deviation of all the old psd values in the new frequency bin
      else
        new.sigma[i] = new.psd[i];

%     variable av_f_value = sum(fouquan[index]*freq[index])/n_freqs;
%     new.freq[i] = av_f_value / av_value;  % weighted average
      new.freq[i] = sum(freq[index])/n_freqs;
    }
  }

  index = where(new.n==0);
  while(length(index)>0)  % filtering for empty bins
  {
    if(index[0]==n-1)
      struct_filter(new, [:-2]);  % just discard the last bin
    else
    { new.freq_lo[index[0]+1] = new.freq_lo[index[0]];  % enlarge next bin
      struct_filter(new, [[0:index[0]-1], [index[0]+1:n-1]]);  % remove the empty bin
    }
    n--;
    index = index[[1:]]-1;
  }
  % struct_filter(newPSD, where(newPSD.n>0));

  return new;
}
