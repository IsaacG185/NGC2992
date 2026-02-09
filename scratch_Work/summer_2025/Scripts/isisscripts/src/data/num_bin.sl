%%%%%%%%%%%%%%%%
define num_bin()
%%%%%%%%%%%%%%%%
%!%+
%\function{num_bin}
%
%\synopsis{Number of noticed bins}
%\usage{Double_Type = num_bin (hist_index);}
%\description
%       Use this function to retrieve number of
%       noticed bins.
%\qualifiers{
%    \qualifier{dof}{gives degrees of freedom instead of number of bins}
%}
% 
%\example
%       isis>xray = load_data("data.pha");
%       isis>variable num = num_bin(1);
%
%\seealso{dof}
%!%-
{
    variable dset;

    switch(_NARGS)
    { case 1: dset  = (); }
    { help(_function_name()); return; }

    variable ff = get_fit_fun();
    variable fv = Fit_Verbose;
    variable tmp_stat;

    Fit_Verbose=-1;
    () = eval_counts(&tmp_stat);
    Fit_Verbose = fv;

    variable nbin = typecast (tmp_stat.num_bins, Double_Type);
    variable nvar = typecast (tmp_stat.num_variable_params, Double_Type);
    variable number = nbin;
    variable dof1 = nbin-nvar;

    if (qualifier_exists("dof")){
	return dof1;
    }
    else {
	return number;
    }
}  
