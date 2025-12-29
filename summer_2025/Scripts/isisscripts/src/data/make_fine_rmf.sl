%%%%%%%%%%%%%%%%
%!%+
%\function{make_fine_rmf}         
%\synopsis{creates a fine RMF }
%\usage{make_fine_rmf (Data_Id [Integer], Factor [Integer]);}
%\description
%   Creates a fine RMF. Therefore each data bin will be split into 
%   a certain number of bins, specified by the variable "Factor".
%\seealso{load_slang_rmf}   
%!%-
private define rmf_profile (bin_lo, bin_hi, x, parms)
{
   variable rmf = Double_Type[length(bin_lo)];
   variable i = where (bin_lo < x <= bin_hi);
   rmf[i] = 1.0;
   return rmf/sum(rmf);
}

define make_fine_rmf()
{
   variable iDat,fac;
   switch(_NARGS)
   { case 2: (iDat,fac) = ();}
   { help(_function_name()); return; }
   variable dat = _A(get_data_counts(iDat));
   fac = int(fac);
   
   if (fac <= 0) 
     return -1;
   
   variable i, ind, n = length(dat.bin_lo);
   variable lo = Double_Type[n*fac], hi = @lo;
   
   _for i(0,n-1,1)
   {
      ind = [i*fac:(i+1)*fac-1];
      (lo[ind],hi[ind]) = log_grid(dat.bin_lo[i],dat.bin_hi[i],fac);
   }   
   return load_slang_rmf (&rmf_profile,dat.bin_lo,dat.bin_hi,lo,hi;parms=fac,grid="en");
}
