%%%%%%%%%%%%%%%%%%%%%%%
define split_lc_at_gaps()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{split_lc_at_gaps}
%\synopsis{splits a light curve at gaps of a certain length}
%\usage{Struct_Type split_lc[] = split_lc_at_gaps(Struct_Type lc, Double_Type gap_threshold);}
%\qualifiers{
%\qualifier{time}{[\code{="time"}] time field}
%}
%\description
%    \code{lc} has to be a structure containing a \code{time} field, which is an array of ascending values,
%    and other fields, which are arrays of the same length. As soon as the difference of
%    sequential times is larger than \code{gap_threshold}, the structure is split, such that finally
%    an array of structures like \code{lc} is returned.
%
%   The following constructions are equivalent:\n
%      \code{split_lc_at_gaps(lc, gap_threshold)}\n
%      \code{split_struct(lc, blocks_between_gaps(lc.time, gap_threshold))}
%\seealso{split_struct, blocks_between_gaps}
%!%-
{
  variable lc, deltaT;
  switch(_NARGS)
  { case 2: (lc, deltaT)= (); }
  { help(_function_name()); return; }

  variable lcs = Struct_Type[0];
  variable t = get_struct_field(lc, qualifier("time", "time"));
  variable T0 = t[0];
  variable i, len = length(t);
  _for i (1, len, 1)
    if(i==len || t[i]>t[i-1]+deltaT)
    { % split
      variable T1 = (i<len ? t[i] : t[i-1]+deltaT);
      lcs = [lcs, struct_filter(lc, where(T0 <= t < T1); copy)];
      T0 = T1;
    }
  return lcs;
}
