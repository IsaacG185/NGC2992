public variable unfold_corr_factor = Assoc_Type[Array_Type];
%%%%%%%%%%%%%%%%%%%%%%%%%%
define set_bin_corr_factor()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{set_bin_corr_factor}
%\synopsis{sets a simple bin correction factor (used in plot_data/unfold)}
%\usage{set_bin_corr_factor(Integer_Type data_id, Double_Type[nbins] corr_factor);}
%\seealso{load_fermi,get_bin_corr_factor,plot_unfold}
%!%-
{
   variable id,corr_factor;
   switch(_NARGS)
   { case 2: (id,corr_factor) = (); }
   { help(_function_name()); return; }
   unfold_corr_factor[string(id)]=@corr_factor;
   return;
}
define get_bin_corr_factor()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_bin_corr_factor}
%\synopsis{reads the bin correction factor set by set_bin_corr_factor}
%\usage{Double_Type[nbins] corr_factor = set_bin_corr_factor(Integer_Type data_id)}
%\seealso{load_fermi,set_bin_corr_factor}
%!%-
{
   variable id;
   switch(_NARGS)
   { case 1: (id) = (); }
   { help(_function_name()); return; }
   if(assoc_key_exists(unfold_corr_factor, string(id)) )
     return @unfold_corr_factor[string(id)];
   else
     return NULL;   
}
