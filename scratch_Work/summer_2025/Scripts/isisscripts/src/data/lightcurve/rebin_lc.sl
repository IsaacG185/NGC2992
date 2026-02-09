define rebin_lc()
%!%+
%\function{rebin_lc}
%\synopsis{rebins a lightcurve structure to a new time resolution}
%\usage{Struct_Type new_lc = rebin_lc(Struct_Type lc, Double_Type new_dt);}
%\qualifiers{
%\qualifier{time}{[= \code{"time"}] field name in the structure containing the time}
%\qualifier{rate}{[= \code{"rate"}] field name(s) in the structure containing the rate(s)}
%\qualifier{error}{[= \code{"error"}] field name(s) containig the corresponding error(s)}
%\qualifier{float}{type cast rate(s) and error(s) to Float_Type}
%\qualifier{verbose}{shows the assumed time resolution of the initial light curve}
%}
%\description
%    The original light curve \code{lc} may contain discontinuities.
%    \code{new_lc.rate[i]} contains the average \code{lc.rate}
%    where \code{new_lc.time[i] <= lc.time < new_lc.time[i]+new_dt}.
%    \code{error^2} is rebinned accordingly.
%
%    The structure fields "\code{time, rate, error}" may have arbitrary names,
%    but these must then be specified by the according qualifiers.
%    \code{new_lc} will also have  these field names. In addition, a "\code{time_hi}"
%    field is added, which contains the upper boundary of the time bins.
%\example
%    \code{lc1 = struct { time=[1:10], rate=[1:10]^2, , error=[1:10] };}\n
%    \code{LC1 = rebin_lc(lc1, 2);}\n
%
%    \code{lc2 = struct { t=[1:10], r1=[1:10]^2, r2=[1:10]^3, e1=[1:10], e2=[1:10]^1.5 };}\n
%    \code{LC2 = rebin_lc(lc2, 2; time="t", rate=["r1", "r2"], error=["e1", "e2"]);}\n
%\seealso{rebin}
%!%-
{
  variable lc, new_dt;
  switch(_NARGS)
  { case 2: (lc, new_dt) = (); }
  { help(_function_name()); return; }

  variable timefield = qualifier("time", "time");
  ifnot(struct_field_exists(lc, timefield))
    return vmessage("error (%s): structure has no field '%s'", _function_name(), timefield);
  variable time_lo = get_struct_field(lc, timefield);
  variable dt = min( time_lo[[1:]] - time_lo[[:-2]] );
  variable time_hi = time_lo + dt;  % Do not use make_hi_grid here; light curve might contain gaps!
  if(qualifier_exists("verbose"))
    vmessage("%s assumes initial time resolution %g", _function_name(), dt);
  if(dt==0)
    vmessage("error (%s): minimum time difference of input light curve is zero", _function_name());
  if(new_dt < dt)
    vmessage("warning (%s): new_dt=%g < dt=%g (=> interpolation)", _function_name, new_dt, dt);

  variable t = [min(time_lo) : max(time_lo) : new_dt];  %| new
  variable t_hi = make_hi_grid(t);                      %| bins
  variable lc_ = @Struct_Type([timefield+["", "_hi"], "n"]);
  set_struct_fields(lc_, t, t_hi, rebin(t, t_hi, time_lo, time_hi, 0*time_lo+1));
  lc_.n[where(lc_.n==0)] = -1;

  variable ratefields  = [ qualifier("rate",  "rate")  ];  %| always make ratefields
  variable errorfields = [ qualifier("error", "error") ];  %| and errorfields be arrays
  variable n_rate = length(ratefields);  %| here /number/ of rate and error fields;
  variable n_err = length(errorfields);  %| but will change below (twice)
  if(n_rate != n_err)
  { variable m = min([n_rate, n_err]);
    vmessage("warning (%s): length(rate fields)=%d != length(error fields)=%d, only using first %d fields", _function_name(), n_rate, n_err, m);
    (n_rate, n_err) = (m, m);
  }

  variable float = qualifier_exists("float");

  variable i;
  _for i (0, n_rate-1, 1)  % /numbers/, won't be needed below this line
  { (n_rate, n_err) = (ratefields[i], errorfields[i]);  % now /name/ of rate and error fields; but will change below
    ifnot(struct_field_exists(lc, n_rate))
      return vmessage("error (%s): structure has no field '%s'", _function_name(), n_rate);
    ifnot(struct_field_exists(lc, n_err))
      return vmessage("error (%s): structure has no field '%s'", _function_name(), n_err);
    variable s = @Struct_Type([n_rate, n_err]);         % /names/, won't be needed below this line
    (n_rate, n_err) = (      rebin(t, t_hi,  time_lo, time_hi, get_struct_field(lc, n_rate) ) /lc_.n,   % now /new/ rate field
                       sqrt( rebin(t, t_hi,  time_lo, time_hi, get_struct_field(lc, n_err)^2))/lc_.n ); % now /new/ error field
    if(float)
     (n_rate, n_err) = (typecast(n_rate, Float_Type), typecast(n_err, Float_Type));
    set_struct_fields(s, n_rate, n_err);
    lc_ = struct_combine(lc_, s);
  }
  struct_filter(lc_, where(lc_.n>0));
  return lc_;
}
