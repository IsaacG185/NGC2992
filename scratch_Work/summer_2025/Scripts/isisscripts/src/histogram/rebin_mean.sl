%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define rebin_mean()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{rebin_mean}
%\synopsis{rebins units like intensity, where you expect the binning
%to take the mean of the value, properly}
%\usage{intens_new = rebin_mean(r_nlo,r_nhi,r_lo,r_hi,intens);}
%!%-
% 
{
   variable r_nlo,r_nhi,r_lo,r_hi,intens;
   switch(_NARGS)
   { case 5: (r_nlo,r_nhi,r_lo,r_hi,intens) = (); }
   {    help(_function_name()); return; }
   
   
   variable rm = 0.5*(r_lo+r_hi);
   variable rm_new = 0.5*(r_nlo+r_nhi);
   variable l_new = length(rm_new);
   variable l = length(rm);
   variable intens_new = Double_Type[l_new];
  
  
  
  variable i,ind;  
  _for i(0,l_new-1,1)
  {    
    if (rm_new[i]<rm[0])
    {
      %special case: LOWER END extrapolation if new grid is a little larger than
      %the old one
      intens_new[0] = (intens[1]-intens[0])/(rm[1]-rm[0])*(rm[0]-rm_new[i])+intens[0];
    }
    else if (rm_new[i]>rm[-1]) 
    {
     %special case: UPPER END
     %extrapolation if new grid is a little larger than the old one
      intens_new[i] = (intens[l-2]-intens[l-1])/(rm[l-2]-rm[l-1])*(rm_new[i]-rm[l-1])+intens[l-1];
    }
    else
    {
      ind = where(rm<=rm_new[i])[-1];
      
      intens_new[i] = ((rm[ind+1]-rm_new[i])*intens[ind]+(rm_new[i]-rm[ind])*intens[ind+1])/
	(rm[ind+1]-rm[ind]);
    }
  }
    
  return intens_new;
}
