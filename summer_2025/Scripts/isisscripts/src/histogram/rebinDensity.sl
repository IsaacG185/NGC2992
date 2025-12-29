%%%%%%%%%%%%%%%%%%%
define rebinDensity()
%%%%%%%%%%%%%%%%%%%
{ variable newLo, newHi, lo, hi, value;
  if(_NARGS!=5)
  { message("usage: newValue = rebinDensity(newLo, newHi,  lo, hi, value);"); return; }
  else
  { (newLo, newHi, lo, hi, value) = ();
    return rebin(newLo, newHi,  lo, hi, value*(hi-lo))/(newHi-newLo);
  }
}
