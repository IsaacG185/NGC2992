define GTIoverlap()
%!%+
%\function{GTIoverlap}
%\synopsis{computes the overlap of an interval [t1, t2] with a set of good time invervals}
%\usage{Double_Type GTIopverlap(Double_Type t1, Double_Type t2, Struct_Type GTI}
%\seealso{getCommonGTIs}
%!%-
{
  variable t1, t2, GTI;
  switch(_NARGS)
  { case 3: (t1, t2, GTI) = (); }
  { help(_function_name()); return; }

  variable i, overlap=0;
  _for i (0, length(GTI.start)-1, 1)
  { variable diff = _min(GTI.stop[i], t2) - _max(GTI.start[i], t1);
    if(diff>0)  overlap += diff;
  }
  return overlap;
}
