%%%%%%%%%%%%%
define sum_lc()
%%%%%%%%%%%%%
%!%+
%\function{sum_lc}
%\synopsis{combines light curves from one structure}
%\usage{Struct_Type sum_lc(Struct_Type lc, Array_Type inds)}
%\qualifiers{
%\qualifier{time}{name of the time field (default: \code{"time"})}
%\qualifier{rate}{format string for the rate field (default: \code{"rate%S"})}
%\qualifier{error}{format string for the error field (default: \code{"error%S"})}
%}
%\description
%    The rates in the fields of \code{lc} (named by \code{inds} 
%    via the \code{rate} format statement) are summed up.
%    The corresponding errors (named by the \code{error} format statement)
%    are added in quadrature.
%    The returned structure has the fields \code{time, rate, error}.
%\examples
%    % 1. Assume you have
%      lc = struct { time, rate1, error1, rate2, error2, rate3, error3 };
%    % Then
%      slc = sum_lc(lc, [1:3]);
%    % is equivalent to
%      slc = struct {
%        time = lc.time,
%        rate = lc.rate1 + lc.rate2 + lc.rate3,
%        error = sqrt( lc.error1^2 + lc.error2^2 + lc.error3^2 )
%      };
%
%    % 2. Assume you have
%      lc = struct { time, rate_a, err_a, rate_b, err_b, rate_c, err_c };
%    % Then
%      slc = sum_lc(lc, ["a", "b", "c"]; rate="rate_%s", error="err_%s");
%    % is equivalent to
%      slc = struct {
%        time = lc.time,
%        rate = lc.rate_a + lc.rate_b + lc.rate_c,
%        error = sqrt( lc.err_a^2 + lc.err_b^2 + lc.err_c^2 )
%      };
%!%-
{
  variable lc, ind, inds;
  switch(_NARGS)
  { case 2: (lc, inds) = (); }
  { help(_function_name()); return; }

  variable fmtrate = qualifier("rate", "rate%S");
  variable fmterr = qualifier("error", "error%S");
  variable slc = struct {
    time = get_struct_field(lc, qualifier("time", "time")),
    rate = Double_Type[length(lc.time)],
    error = Double_Type[length(lc.time)]
  };
  foreach ind (inds)
  {
    slc.rate += get_struct_field(lc, sprintf(fmtrate, ind));
    slc.error += get_struct_field(lc, sprintf(fmterr, ind))^2;
  }
  slc.error = sqrt( slc.error );

  return slc;
}
