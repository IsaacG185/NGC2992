define stretch_hist(hist, scal){
%!%+
%\function{stretch_hist}
%\synopsis{stretch a histogram grid}
%\usage{Struct_Type hist = stretch_hist(hist, scal);}
%\description
%    Stretch the grid of a histogram structure with fields bin_lo, 
%    bin_hi, value, and err. The bin_lo and bin_hi fields are scaled 
%    by the factor scal. If other fields are present, those are 
%    preserved and passed on. Only presence of bin_lo and bin_hi are
%    checked for. If scal is an array with [a0,a1,a2,a3...], the grid
%    is stretched with a polynomial function of 
%       a0 + a1*bin_lo + a2*bin_lo^2 + ... .
%\seealso{add_hist, shift_hist, scale_hist}
%!%-   
   if(_NARGS==0) {  help(_function_name()); return; }

   variable ns = struct_copy(hist);
   ifnot(struct_field_exists(ns, "bin_lo") and 
		 struct_field_exists(ns, "bin_hi")){
	  help(_function_name()); return;
   }

   if(typeof(scal) == Integer_Type or typeof(scal)==Double_Type){
	 % ns.bin_lo *=scal;
	 % ns.bin_hi *=scal;
	 % return ns;
	  scal = [0, scal];
   }
   
   variable xl = scal[-1];
   variable xh = scal[-1];
   variable ii;
   _for ii (length(scal)-2, 0, -1){
	  xl = scal[ii] + xl * ns.bin_lo;
	  xh = scal[ii] + xh * ns.bin_hi;
   }
   ns.bin_lo = xl;
   ns.bin_hi = xh;
   return ns;
}
