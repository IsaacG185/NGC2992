define read_histo(inf){
%!%+
%\function{read_histo}
%\synopsis{read text data into histogram structure}
%\usage{Struct_Type hist = read_histo(String_Type filename);}
%\qualifiers{
%\qualifier{cols}{[=4] number of columns in the data file}
%\qualifier{collist}{array of column index for bin_lo, bin_hi,
%                    value, err in that order. Needs col=-1.}
%\qualifier{bin_lo}{column index for bin_lo. Needs col=-1.}
%\qualifier{bin_hi}{column index for bin_hi. Needs col=-1.}
%\qualifier{value}{column index for value. Needs col=-1.}
%\qualifier{err}{column index for err. Needs col=-1.}
%}
%\description
%    Read a text file with column data directly into a histogram
%    structure struct{bin_lo,bin_hi,value,err};. 
%    The default assumption is that the text file contains the four
%    columns bin_lo, bin_hi, value, and err in that order as the first
%    four columns in the file (further columns being ignored). 
%    Non-standard files can be processed via qualifiers. Missing
%    columns are populate with assumptions, e.g., the grid reflecting
%    the row numbers and the uncertainty assuming Poisson statistics.
%    If all columns are present, but out of order / other column
%    numbers, a list with column numbers can be supplied.
%    
%    Qualifier cols:
%        cols=4:  bin_lo, bin_hi, value, err
%        cols=1:  value. 
%                 Then bin_lo=[0:length(value)-1], bin_hi=bin_lo+1,
%                 err=sqrt(value). 
%        cols=2:  bin_lo, value. 
%                 Then bin_hi=make_hi_grid(lo), err=sqrt(value).
%        cols=3:  bin_lo, bin_hi, value.
%                 Then err = sqrt(value).
%        cols=-1: Either use collist qualifier to supply an array of
%                 column indices for all of bin_lo, bin_hi, value, err 
%                 (in this order). Or, for a sub-selection, use the
%                 bin_lo, bin_hi, value, and err to supply column
%                 indices individually. If any of those four equals 0,
%                 this field is ignored. Missing columns are populated
%                 as described above. 
%                 Presence of collist takes presedence over the others. 
%\seealso{init_histo, add_hist, shift_hist, 
%scale_hist, stretch_hist}
%!%-   
   variable cols = qualifier("cols",4);
   variable s = struct{bin_lo,bin_hi,value, err};
   switch(cols)
	 { case 1: 
		  s.value = readcol(inf,1);
		s.err = sqrt(s.value);
		s.bin_lo = [0: length(s.value)-1];
		s.bin_hi = [1: length(s.value)];
	 }
   	 { case 2: 
		  (s.bin_lo, s.value) = readcol(inf,1,2);
		s.err = sqrt(s.value);
		s.bin_hi = make_hi_grid(s.bin_lo);
	 }
   	 { case 3: 
		  (s.bin_lo, s.bin_hi, s.value) = readcol(inf,1,2,3);
		s.err = sqrt(s.value);
	 }
	 { case 4: 
		  (s.bin_lo, s.bin_hi, s.value, s.err) = readcol(inf, 1,2,3,4);
	 }
	 { case -1:
		  variable bl, bh, val, err, all;
		if(qualifier_exists("collist")){
		   all = qualifier("collist");
		   bl = all[0]; bh = all[1]; val = all[2]; err=all[3];
		}else{
		   bl = qualifier("bin_lo",0);
		   bh = qualifier("bin_hi",0);
		   val = qualifier("value",0);
		   err = qualifier("err",0);
		}
		if(val) s.value = readcol(inf, val);
		if(err) s.err = readcol(inf, err); else s.err = sqrt(s.value);
		if(bl) s.bin_lo = readcol(inf, bl); else s.bin_lo = [0:length(s.value)-1];
		if(bh) s.bin_hi = readcol(inf,bh); else s.bin_hi = make_hi_grid(s.bin_lo);
	 }
   return @s;
}
