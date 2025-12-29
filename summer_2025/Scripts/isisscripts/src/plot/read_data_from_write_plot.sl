define read_data_from_write_plot(fname)
%!%+
%\function{read_data_from_write_plot}
%\synopsis{reads data that was saved with "write_plot" in a structure}
%\usage{Structure str = read_data_from_write_plot(String_Type file)}
%\qualifiers{
%\qualifier{no_res}{: no residuals should be loaded}
%\qualifier{no_mod}{: no model included in dat file, implies no_res}
%\qualifier{y_fac[=0]}{: scale the y-axis by 10^{y_fac}}
%}
%\description
%    This function reads data from a plot saved with "write_plot" and returns
%    it in a structure which can be used for plotting.
%   
%    The structure tags are:
%      lo:  low energy
%      hi:  high energy
%      val: data value
%      err: uncertainty of the data value
%      model: model value of fit
%      res: residual
%      res_min: lower error bar
%      res_max: upper error bar
%
%    IMPORTANT: The filename has to be given without the ".dat" ending!
%
%    Note that if the data were saved with plot_unfold(...;...,power=3);
%    the values are automatically converted to ergs/s/cm^2
%\seealso{xfig_plot_unfold,xfig_plot_data,read_col,write_plot}
%!%- 
{
   if ( string_matches (fname,"[0-9.]\.dat"R) == NULL) fname = sprintf("%s.dat",fname);
  % convert keV to erg ???
   variable y_fac = qualifier("y_fac",0);
   variable keV2erg_fac = 1./(10^y_fac);
   
   variable b;
   variable F = fopen(fname,"r");
   while (-1 != fgets (&b, F))
   {
      if (b == "# Y-Axis    : \frkeV\u2\d Photons cm\u-2\d s\u-1\d keV\u-1\d \n"R)
      {
	 message("Using ergs/s/cm^2 by default now ...");
	 keV2erg_fac = keV2erg(1.;;__qualifiers);
	 break;
      }
   }

   
  variable lo,hi,val,err;  
  (lo, hi, val, err) =  readcol(fname, 1, 2, 3, 4);
  
  % convert to ergs
  val *= keV2erg_fac;
  err *= keV2erg_fac;

  % write it in a structure
  variable s = struct{lo=lo, hi=hi, val=val, err=err};
  
  ifnot(qualifier_exists("no_mod")){
    variable model;
    model =  readcol(fname, 5);
    model *= keV2erg_fac;

    s = struct_combine(s,struct{model=model});
    
    % are residuals given in the data-table???
    ifnot (qualifier_exists("no_res"))
    {
      variable res,res_min,res_max;
      (res, res_min, res_max) =   readcol(fname, 6,7,8);
      variable s_res = struct{  res=res, res_min=res_min, res_max=res_max  };
      s = struct_combine(s,s_res);
    }
  }
    
  return s;
}
