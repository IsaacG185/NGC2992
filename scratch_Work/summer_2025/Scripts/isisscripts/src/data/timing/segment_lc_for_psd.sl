define segment_lc_for_psd(lc, dt, dimseg) { %{{{
%!%+
%\function{segment_lc_for_psd}
%\synopsis{Function to segment a lightcurve in preparation for a PSD,
%    filtering out the segments which do not fit into multiples of
%    the segmentation length.}
%\usage{segment_lc_for_psd(lc,dt,dimseg)}
%\qualifiers{
%    \qualifier{gapfactor}{relative factor, telling how large the gap is relative
%                to dt [default: 1.1]}
%    \qualifier{ratefield}{Name of rate field in lightcurve [default: rate]}
%    \qualifier{verbose}{Increase verbosity to display which parts of the
%                lightcurve and what proportion was rejected [default=0].}
%}
%\description
%    Given a lightcurve with gaps, this function segments it such that
%    only intervals of length "dimseg" (in bins) are present. Data
%    that does not fit into integer multiples of the segmentation
%    length are cut off.
%    
%    ATTENTION: Never use a discrete Fourier transform (e.g., 
%    foucalc) with a segmentation length ("dimseg") larger than chosen
%    in this function!
%\notes
%    The time array is not altered, so the lightcurve will still
%    contain gaps, however none that have different length than
%    "dimseg". In other words: The output data arrays can begin at
%    arbitrary times, so are *not* sorted to always start at integer
%    multiples of the segmentation length.
%\example
%    dt=1.; % (s)
%    len=64.; % (s)
%    offset=10; % background level
%    T=5.; % (s), sinusoid periodidity
%    omega=2*PI/T; % Angular frequency (rad/s)
%    time_arr=[0:len:dt];
%    lc = struct{ time = time_arr,
%                 rate = offset+sin(omega*time_arr)+0.1*grand(int(len/dt)) };
%    lc_gaps=struct{
%             time=[lc.time[[0:20]],lc.time[[30:55]]],
%             rate=[lc.rate[[0:20]],lc.rate[[30:55]]] };
%    dimseg=16; % (bins)
%    lc_split = segment_lc_for_psd(lc_gaps, dt, dimseg);
%    res=foucalc(struct{time=lc_split.time,rate1=lc_split.rate},dimseg);
%\seealso{split_lc_at_gaps, foucalc}
%!%-

  variable gapfactor = qualifier("gapfactor", 1.1); 
  variable ratefield = qualifier("ratefield", "rate");
  variable verbose = qualifier("verbose", 0);

  variable split_lc = split_lc_at_gaps(lc, dt*gapfactor);

  variable segmented_lc = struct{
    time=Double_Type[0],
    rate=Double_Type[0],
    error=Double_Type[0],
    rejected_time, n_segments, total_time
  };
  
  %% keep a record of the total time and the time thrown away
  variable total_time=0.; % (s)
  variable rejected_time=0.;
  variable n_segments=0;

  variable ii;
  _for ii (0,length(split_lc)-1,1) {
    
    variable exposure=split_lc[ii].time[-1]-split_lc[ii].time[0];
    total_time += exposure;
    
    % get how often the segment fits into a given part of the split lightcurve
    variable nn = int(length(split_lc[ii].time)/dimseg);

    % only do this if there is at least one segment
    if (nn > 0) {
      % note that each segment goes from 0 to nn*dimseg-1
      % (the -1 is the important part!)
      n_segments++;
      segmented_lc.time=[segmented_lc.time,split_lc[ii].time[[0:nn*dimseg-1]]];      
      segmented_lc.rate=[segmented_lc.rate,  
			 get_struct_field(split_lc[ii],ratefield)[[0:nn*dimseg-1]]];
      if (struct_field_exists(split_lc[ii],"error")){
	segmented_lc.error=[segmented_lc.error, split_lc[ii].error[[0:nn*dimseg-1]]];
      }
    } else {
      rejected_time += exposure;
      if (verbose > 1){
	vmessage("  ***(%s): Skipping lightcurve segment with index %i, length %gs", _function_name(), ii, exposure);
      }
    }
  }

  if (verbose > 0) {
    vmessage("  ***(%s): Rejected time: %g s (%g percent of total data time=%gs)",
	     _function_name(), rejected_time, rejected_time/total_time*100, total_time);
    vmessage("  ***(%s): Number of segments with length>%gs (dimseg=%d, dt=%gs): %d",
	     _function_name(), dt*dimseg, dimseg, dt, n_segments);
  }
  
  segmented_lc.rejected_time = rejected_time;
  segmented_lc.total_time = total_time;
  segmented_lc.n_segments = n_segments;
  
  return segmented_lc; 
} %}}}