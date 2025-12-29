%%%%%%%%%%%%%%%%%%%%%%%
define color_color_data()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{color_color_data}
%\synopsis{extracts light curves in 3 consecutive bands and the corresponding colors from an event list}
%\usage{Struct_Type dat = color_color_data(Struct_Type evts, Double_Type E0, E1, E2, E3);}
%\qualifiers{
%\qualifier{dt}{time resolution [default: 100]}
%\qualifier{field}{field used for selection of the bands [default: "pi"]}
%}
%\description
%    \code{dat.a} = lightcurve in "E0 <= field < E1" band\n
%    \code{dat.b} = lightcurve in "E1 <= field < E2" band\n
%    \code{dat.c} = lightcurve in "E2 <= field < E3" band\n
%    \code{dat.}x\code{_}y = x/y color for x, y = a | b | c
%\seealso{histogram}
%!%-
{
  variable evts, E0, E1, E2, E3; (evts, E0, E1, E2, E3) = ();

  variable t_lo = [min(evts.time) : max(evts.time) : qualifier("dt", 100)];
  variable t_hi = make_hi_grid(t_lo);
  variable field = get_struct_field(evts, qualifier("field", "pi"));
  variable dat = struct {
    time_lo = t_lo,
    time_hi = t_hi,
    A = histogram(evts.time[where(E0 <= field < E1)], t_lo, t_hi),
    B = histogram(evts.time[where(E1 <= field < E2)], t_lo, t_hi),
    C = histogram(evts.time[where(E2 <= field < E3)], t_lo, t_hi),
    A_B, A_C, B_A, B_C, C_A, C_B
  };
  print(dat);
  struct_filter(dat, where(dat.A>0 and dat.B>0 and dat.C>0));
  dat.A_B = 1.0*dat.A / dat.B;
  dat.A_C = 1.0*dat.A / dat.C;
  dat.B_A = 1.0*dat.B / dat.A;
  dat.B_C = 1.0*dat.B / dat.C;
  dat.C_A = 1.0*dat.C / dat.A;
  dat.C_B = 1.0*dat.C / dat.B;

  return dat;
}
