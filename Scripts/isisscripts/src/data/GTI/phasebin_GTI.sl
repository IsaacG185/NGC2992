%%%%%%%%%%%%%%%%%%%%
define phasebin_GTIs()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{phasebin_GTIs}
%\synopsis{computes the GTI time in phase bins}
%\usage{Double_Type dt[] = phasebin_GTIs(tstart, tstop, T0, P, n);}
%!%-
{
  variable tstart, tstop, T0, P, n;
  switch(_NARGS)
%  { case 2: (gti, n) = (); }
%  { case 3: (tstart, tstop, n) = (); }
%  { case 4: (gti, n, T0, P) = (); }
  { case 5: (tstart, tstop, T0, P, n) = (); }
  { help(_function_name()); return; }

  variable dt = Double_Type[n];
  variable dt_bin = P/n;
  variable i_start = int(floor( (tstart-T0)/P * n ));
  variable i_stop  = int(floor( (tstop -T0)/P * n ));
  variable i;
  _for i (0, length(tstart)-1, 1)
    if(i_start[i] == i_stop[i])  % start and stop fall in the same bin
      dt[i_start[i] mod n] += tstop[i] - tstart[i];
    else
    {
      dt[i_start[i] mod n] += T0 + (i_start[i]+1)*dt_bin - tstart[i];  % first bin, partially exposed
      dt[i_stop[i]  mod n] += tstop[i] - (T0 + i_stop[i]*dt_bin);  % last bin, partially exposed
      foreach i ([i_start[i]+1 : i_stop[i]-1] mod n)  % intermediate bins,
        dt[i] += dt_bin;                              % fully exposed
    }
  return dt;
}
