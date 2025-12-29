%%%%%%%%%%%%%%%%%%%
define bgsubHEXTElc()
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{bgsubHEXTElc}
%\synopsis{calculates a background subtracted HEXTE lightcurve}
%\usage{Struct_Type lc = bgsubHEXTElc(Struct_Type srclc, Struct_Type bglc);
%\altusage{Struct_Type lc = bgsubHEXTElc(Struct_Type srclc, Struct_Type bglc1, Struct_Type bglc2);}
%}
%\description
%    HEXTE rocking -> Background is not measured simultaneously with source data.
%!%-
{
  variable srclc, bglc, bglc1, bglc2;
  switch(_NARGS)
  { case 2: (srclc, bglc) = (); }
  { case 3: (srclc, bglc1, bglc2) = (); bglc = sort_struct_arrays(merge_struct_arrays([bglc1, bglc2]), "time"); }
  { help(_function_name()); return; }

  variable av_bglc = struct { time=Double_Type[0], rate=Double_Type[0], error=Double_Type[0] };
  foreach ( split_lc_at_gaps( struct_filter(bglc, where(bglc.rate>0); copy), 30) )
  { variable bglc_part = ();
    av_bglc.time  = [av_bglc.time,  mean(bglc_part.time)];
    av_bglc.rate  = [av_bglc.rate,  mean(bglc_part.rate)];
    av_bglc.error = [av_bglc.error, mean(bglc_part.error)];
  }

  return struct {
    time  = srclc.time,
    rate  = srclc.rate - interpol(srclc.time, av_bglc.time, av_bglc.rate),
    error = sqrt( srclc.error^2 + interpol(srclc.time, av_bglc.time, av_bglc.error)^2 )
  };
}
