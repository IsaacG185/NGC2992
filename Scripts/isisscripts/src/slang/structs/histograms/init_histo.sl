define init_histo(){
%!%+
%\function{init_histo}
%\synopsis{initialize a struct with histogram fields}
%\usage{init_histo([Integer_Type len]);}
%\description
%     Return a new struct with the typical fields of a histogram:
%     bin_lo, bin_hi, value, err. If the optional argument is present,
%     the fields are initialized with a Double_Type array of that
%     length. Else the fields are empty. 
%\seealso{read_histo, init_histo, add_hist, shift_hist, 
%           scale_hist, stretch_hist}
%!%-   
   variable s = struct{bin_lo,bin_hi,value,err};
   if(_NARGS==0) { return @s; }   
   else if(_NARGS==1){ 
	  variable len = ();
	  s.bin_lo = Double_Type[len];
	  s.bin_hi = Double_Type[len];
	  s.value = Double_Type[len];
	  s.err = Double_Type[len];
	  return @s;
   }
   else  { help(_function_name()); return; }
}
