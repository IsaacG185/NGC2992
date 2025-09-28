define filter_gti()
%!%+
%\function{filter_gti}
%\usage{Integer_Type ind[] = filter_gti(Double_Type time[], Struct_Type gti);
% or                      filter_gti(Double_Type time_lo[], time_hi[], Struct_Type gti);}
%\qualifiers{
%    \qualifier{minfracexp}{minimum fractional exposure a time bin has to have,
%                otherwise it is considered bad (lightcurves only, default: 1e-4)}
%    \qualifier{fracexp}{if set to a reference, returns the fractional exposure
%                of each time bin (lightcurves only)}
%    \qualifier{exposure}{if set to a reference, returns the livetime
%                in each time bin (lightcurves only)}
%    \qualifier{indarray}{return an array of index arrays instead (in case
%                of events only)}
%}
%\description
%    For a lightcurve given by \code{time_lo} and \code{time_hi}, this function
%    returns all indices \code{ind} to the time bins, for which the fractional
%    exposure time as defined by the good time intervals defined by \code{gti}
%    is at least \code{fracexp}.
%
%    For a list of events measured at times \code{time}, return a list of indices
%    to all events that were measured during the given set of good time intervals.
%    The good time intervals are defined by a \code{struct {start,stop}} where
%    \code{start} and \code{stop} define the start and stop times.
%
%    The code assumes that
%    - time and time_hi are in ascending order
%    - the gti does not contain any overlapping intervals
%    - gti, time, and time_hi have the same unit
%
%    Warning: the function applies a time sorting to the gti if necessary. This
%    	will MODIFY THE INPUT since structures are passed as references in S-Lang!
%!%-
{
    variable time, gti, time_hi = NULL;
    switch(_NARGS)
    { case 2: (time, gti) = (); }
    { case 3: (time, time_hi, gti) = (); }
    { help(_function_name()); return; }

    % consistency checks
    if (length(gti.start) != length(gti.stop)) {
	vmessage("error (%s): gti.start and gti.stop have to be of equal length", _function_name);
	return;
    }
    if (any(gti.start > gti.stop)) {
	vmessage("error (%s): gti.start > gti.stop detected", _function_name);
	return;
    }
    if (time_hi != NULL) {
	if (length(time) != length(time_hi)) {
	    vmessage("error (%s): time_lo and time_hi have to be of equal length", _function_name);
	    return;
	}
	if (any(time > time_hi)) {
	    vmessage("error (%s): time_lo > time_hi detected", _function_name);
	    return;
	}
    }

    variable i;

    %
    % ensure that gti is time sorted
    %
    if (any(gti.start[[1:]] - gti.start[[:-2]] < 0)) {
    	struct_filter(gti, array_sort(gti.start));
    	vmessage("warning (%s): GTI struct has been ordered by time!", _function_name);
    } 

    variable indarray = qualifier_exists("indarray");
    variable ind = indarray ? Array_Type[length(gti.start)] : Integer_Type[0];
      
    % abort if no GTI overlaps with time
    if (gti.stop[-1] < time[0] || gti.start[0] > (time_hi == NULL ? time[-1] : time_hi[-1])) {
    	return ind;
    } 

    %
    % filtering of events
    %
    if (time_hi == NULL ) {
	_for i (0,length(gti.start)-1,1) {
	    if (indarray) { ind[i] = where(gti.start[i]<=time<=gti.stop[i]); }
	    else { ind = [ind,where(gti.start[i]<=time<=gti.stop[i])]; }
	}
	return ind;
    }

    %
    % filtering of lightcurves
    %

    % calculate exposure of all lightcurve bins
    %
    variable npt=length(time);
    variable ngi=length(gti.stop);
    variable expo=Double_Type[npt];
    i=0; % counter for the light curve
    variable j=0; % counter for the GTI
    forever {
	% skip over all gti intervals that stop before the current lc bin
        % and
	% skip over all lc intervals that stop before the current gti bin
	while (j<ngi && i<npt) {
	  if (gti.stop[j]<time[i]) { j++; continue; }
	  if (time_hi[i]<gti.start[j]) { i++; }
	  else { break; }
	}
    	if (j == ngi || i == npt) { break; }
      
        if (gti.start[j]<=time[i]) {
	    % gti starts before the current time bin
            if (gti.stop[j]>=time_hi[i]) {
	        % gti ends after time bin -> time bin is fully exposed
                expo[i]+=time_hi[i]-time[i];
                i++; % go to next time bin
            } else {
		% gti overlaps at start of bin
                expo[i]+=gti.stop[j]-time[i];
                j++; % go to next gti bin
            }
        } else {
	    % gti starts later than time_lo
            if (gti.stop[j]<=time_hi[i]) {
		% gti is located completely in the time bin
                expo[i]+=gti.stop[j]-gti.start[j];
                j++; % go to the next gti bin
            } else {
		% gti extends beyond the end of the time bin
                expo[i]+=time_hi[i]-gti.start[j];
                i++; % go to next time bin
            }
        }
    }
	
    variable fracexp=expo[*]/(time_hi[*]-time[*]);

    % apply the fracexp limit resp. the gap finder
    ind = where(fracexp >= qualifier("minfracexp",1e-4));
    
    if (qualifier_exists("fracexp")) {
	fracexp = fracexp[ind];
	@(qualifier("fracexp")) = fracexp;
    }
    
    if (qualifier_exists("exposure")) {
	expo=expo[ind];
	@(qualifier("exposure")) = expo;
    }

    return ind;
}
