define rebinGroup()
%!%+
%\function{rebinGroup}
%\synopsis{rebins a \code{{bin_lo, bin_hi, value, err} struct}ure by a grouping factor}
%\usage{Struct_Type s_ = rebinGroup(Struct_Type s, Integer_Type n);}
%\seealso{rebin}
%!%-
{ variable s, lo, hi, value, err=NULL, nGrouping;
  switch(_NARGS)
  { case 2:
    (s, nGrouping) = ();
    if(_typeof(s) != Struct_Type) { message("usage: groupedStruct = rebinDensity(lo, hi, value[, err], nGrouping);"); return; }
    if(length(get_struct_field_names(s))>3)
    { return rebinGroup(s.bin_lo, s.bin_hi, s.value, s.err, nGrouping); }
    else
    { return rebinGroup(s.bin_lo, s.bin_hi, s.value, nGrouping); };
  }
  { case 4: (lo, hi, value, nGrouping) = (); }
  { case 5: (lo, hi, value, err, nGrouping) = (); }
  { help(_function_name()); return; }

  if(err==NULL) { s = struct { bin_lo, bin_hi, value }; } else { s = struct { bin_lo, bin_hi, value, err }; }
  s.bin_lo = lo[ [0:length(lo)-1:nGrouping] ];
  s.bin_hi = make_hi_grid(s.bin_lo);
  s.value = rebin(s.bin_lo, s.bin_hi,  lo, hi, value);
  if(err!=NULL) { s.err = sqrt( rebin(s.bin_lo, s.bin_hi,  lo, hi, err^2) ); }
  return s;
}
