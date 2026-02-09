define scale_hist(hist, scal){
%!%+
%\function{scale_hist}
%\synopsis{scale a histogram}
%\usage{Struct_Type hist = scale_hist(hist, scal);}
%\description
%    Scale a histogram structure with fields bin_lo, bin_hi, value, and
%    err. The value field is scaled by the factor scal. The err field,
%    if present is scaled accordingly. If other fields are present,
%    those are preserved and passed on. Only presence of value and 
%    err are checked for, but err is optional.
%\seealso{add_hist, shift_hist, stretch_hist}
%!%-   
   if(_NARGS==0) {  help(_function_name()); return; }
   
   variable ns = struct_copy(hist);
   ifnot(struct_field_exists(ns, "value")){
	  help(_function_name()); return;
   }
   ns.value *= scal;
   if(struct_field_exists(ns,"err")){
	  ns.err *= scal;
   }
   return ns;
}
