%%%%%%%%%%%%%%%%%%%%
define getCommonGTIs()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{getCommonGTIs}
%\synopsis{returns a new set of GTIs which are both contained in gti1 and gti2}
%\usage{Struct_Type gti = getCommonGTIs(Struct_Type gti1, Struct_Type gti2);}
%\description
%    Good time intervals (GTIs) are stored in \code{{ start, stop }}-structs.
%!%-
{
  variable gti1, gti2;
  switch(_NARGS)
  { case 2: (gti1, gti2) = (); }
  { help(_function_name()); return; }

  % patch to make sure gti1 has the lower starting time.
  if(gti2.start[0] < gti1.start[0]){
    variable temp = gti2;
    gti2 = gti1;
    gti1 = temp;
  }

  variable gti = struct { start=Double_Type[0], stop=Double_Type[0] };
  variable len1 = length(gti1.start);
  variable len2 = length(gti2.start);
  variable i1=0, i2=0;
  while(i1<len1 && i2<len2)
  {
    variable t = _max(gti1.start[i1], gti2.start[i2]);
    while(i1<len1 && gti1.stop[i1]<t)  i1++;
    while(i2<len2 && gti2.stop[i2]<t)  i2++;

    if(i1<len1 && i2<len2 && gti1.start[i1]<= t && gti2.start[i2]<=t)
    { gti.start = [gti.start, t];
      gti.stop  = [gti.stop,  _min(gti1.stop[i1], gti2.stop[i2])];
      if(gti1.stop[i1] <= gti2.stop[i2])  i1++;
      if(gti1.stop[i1] >= gti2.stop[i2])  i2++;
    }
  }
  return gti;
}
