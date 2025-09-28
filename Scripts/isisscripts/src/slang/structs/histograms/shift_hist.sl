define shift_hist(hist, shft){
%!%+
%\function{shift_hist}
%\synopsis{shift a histogram}
%\usage{Struct_Type hist = shift_hist(hist, shift);}
%\description
%    Shift the grid of a histogram structure with fields bin_lo, 
%    bin_hi, value, and err. The bin_lo and bin_hi fields are shifted
%    by the amount shift. If other fields are present,
%    those are preserved and passed on. Only presence of bin_lo and 
%    bin_hi are checked for. 
%\seealso{add_hist, scale_hist, stretch_hist}
%!%-   
   if(_NARGS==0) {  help(_function_name()); return; }
   
   variable ns = struct_copy(hist);
   ifnot(struct_field_exists(ns, "bin_lo") and 
		 struct_field_exists(ns, "bin_hi")){
	  help(_function_name()); return;
   }
   
   ns.bin_lo += shft;
   ns.bin_hi += shft;
   
   return ns;
}
