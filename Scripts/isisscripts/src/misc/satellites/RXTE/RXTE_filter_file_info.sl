private define getPCUgti(time, p)
{
  % intelligent padding for values that aren't known
  % ... not so fast but safe
  variable ndx = where(p==255);
  if(length(ndx) > 0)
  {
    variable start = 0;
    if(ndx[0] == 0)
    { p[0] = p[wherefirst(p!=255)];
      start = 1;
    }
    variable i;
    _for i (start, length(ndx)-1, 1)
      p[ndx[i]] = p[ndx[i]-1];
  }

  variable p1 = shift(p, 1);
  p1[-1] = p1[-2];

  % where det switches on
  variable switch_on = where(p==0 and p1==1);
  % where the det turns off
  variable switch_off = where(p==1 and p1==0);

  variable gti = struct { start, stop };

  if(length(switch_on)==0 || length(switch_off)==0)  % special case that detector does nothing or turns on/off exactly once
  {
    if(length(switch_on)==0 && length(switch_off)==0) % nothing happens
    {
      if(p[0]==1) % always on
      { gti.start = [ time[0] ];
        gti.stop = [ time[-1] ];
      }
      else  % always off
      { % gti.start = Double_Type[0];
	% gti.stop = Double_Type[0];
	gti.start = [ time[0] ];
        gti.stop = [ time[0] ];
      }
      return gti;
    }
    if(length(switch_on)==0) % only a switch off observed
    { gti.start = [ time[0] ];
      gti.stop = [ time[switch_off[0]] ];
      return gti;
    }
    % last case: only switch on seen
    gti.start = [ time[switch_on[0]] ];
    gti.stop = [ time[-1] ];
    return gti;
  }

  % general case of multiple on/off events
  switch_on += 1;  % add one since we start in the next bin
  % take care of det being on at beginning or end
  if(switch_on[0] > switch_off[0])  switch_on = [0, switch_on];
  if(length(switch_on) > length(switch_off))  switch_off = [switch_off, length(p)-1];

  % and return the values
  gti.start = time[switch_on];
  gti.stop = time[switch_off];
  return gti;
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define RXTE_filter_file_info()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{RXTE_filter_file_info}
%\synopsis{returns RXTE filter file information}
%\usage{Struct_Type RXTE_filter_file_info(String_Type xflfiles[])}
%\seealso{aitlib/rxte/readxfl.pro}
%!%-
{
  variable xflfiles;
  switch(_NARGS)
  { case 1: xflfiles = (); xflfiles = glob(xflfiles); }
  { help(_function_name()); return; }

  variable not_nopcu0 = not qualifier_exists("nopcu0");

  variable xfl_info = struct {
    time = Double_Type[0],
    electron = Double_Type[0],
    pcu0 = struct { start = Double_Type[0], stop = Double_Type[0] },
    pcu1 = struct { start = Double_Type[0], stop = Double_Type[0] },
    pcu2 = struct { start = Double_Type[0], stop = Double_Type[0] },
    pcu3 = struct { start = Double_Type[0], stop = Double_Type[0] },
    pcu4 = struct { start = Double_Type[0], stop = Double_Type[0] },
  };

  variable i;
  _for i (0, length(xflfiles)-1, 1)
  { variable tab = fits_read_table(xflfiles[i], ["time", "electron0", "electron1", "electron2", "electron3", "electron4", "pcu0_on", "pcu1_on", "pcu2_on", "pcu3_on", "pcu4_on"]);
    tab.time = fits_read_key(xflfiles[i], "MJDREFI") + fits_read_key(xflfiles[i], "MJDREFF") + tab.time/86400.;
    xfl_info.time = [xfl_info.time, tab.time];

    % read the electron ratios.
    variable use_el0;
    if(not_nopcu0)
      % do not use PCU0 to gauge background since the Xenon layer is damaged
      % check whether all finite el0 values are 0;
      % if so, el0 cannot be used because the detector does not work
      use_el0 = (sum(tab.electron0[wherenot(isnan(tab.electron0) or isinf(tab.electron0))]) > 0);

    % number of valid measurements in each bin
    variable num_PCUs =   not(isnan(tab.electron1) or isinf(tab.electron1))
			+ not(isnan(tab.electron2) or isinf(tab.electron2))
			+ not(isnan(tab.electron3) or isinf(tab.electron3))
			+ not(isnan(tab.electron4) or isinf(tab.electron4));
    if(not_nopcu0 && use_el0)  num_PCUs += not(isnan(tab.electron0) or isinf(tab.electron0));

    % where the ratio is not defined (e.g. detector is switched off), set the value to 0.
    % this way the averaging procedure isn't screwed up.
    if(not_nopcu0)  tab.electron0[where(isnan(tab.electron0) or isinf(tab.electron0))] = 0;
    tab.electron1[where(isnan(tab.electron1) or isinf(tab.electron1))] = 0;
    tab.electron2[where(isnan(tab.electron2) or isinf(tab.electron2))] = 0;
    tab.electron3[where(isnan(tab.electron3) or isinf(tab.electron3))] = 0;
    tab.electron4[where(isnan(tab.electron4) or isinf(tab.electron4))] = 0;

    % average electron ratio
    variable electron = tab.electron1 + tab.electron2 + tab.electron3 + tab.electron4;
    if(not_nopcu0 && use_el0)  electron += tab.electron0;
    electron[where(num_PCUs!=0)] /= num_PCUs[where(num_PCUs!=0)];  % el is 0 where it hasn't been measured
    xfl_info.electron = [xfl_info.electron, electron];

    append_struct_arrays(&xfl_info.pcu0, getPCUgti(tab.time, tab.pcu0_on));
    append_struct_arrays(&xfl_info.pcu1, getPCUgti(tab.time, tab.pcu1_on));
    append_struct_arrays(&xfl_info.pcu2, getPCUgti(tab.time, tab.pcu2_on));
    append_struct_arrays(&xfl_info.pcu3, getPCUgti(tab.time, tab.pcu3_on));
    append_struct_arrays(&xfl_info.pcu4, getPCUgti(tab.time, tab.pcu4_on));
  }
  return xfl_info;
}
