
define fplot() {
%!%+
%\function{fplot}
%\synopsis{plots data and residuals from the fits-files created with 'save_plot'}
%\usage{fplot(filename, [color, [dataset]]);}
%\qualifiers{
%\qualifier{flux}{plot flux [photons/s/cm^2/keV] and not [counts/bin]}
%\qualifier{overplot}{Overplot previous plot}
%\qualifier{type}{defines what should be plotted. It can have the values 'model', 'data', 'res' (residuals),
%      'ratio', 'diff' (difference between model an data. By default model and data is plotted.)}
%\qualifier{nolabel}{The routine uses the labels given in 'plot_options' and does not create its own. }
%\qualifier{space}{If at the qualifer 'type' data, model or diff is chosen, one can specifiy if it is
% plotted in counts/bin (by default), counts/keV/s ('density') or photons/keV/s/cm^2 ('flux').} 
%\qualifier{auto}{Set the ranges automatically.}
%\qualifier{xauto}{Set the x-range automatically.}
%\qualifier{yauto}{Set the y-range automatically.}
%\qualifier{unit}{Specifies the unit of the x-axis. By default the unit from the fitstable is taken. 
%       Possible values are 'keV' or Angstrom 'A'.}
%}
%\description
%   This function is designed to plot the data which was saved with
%   'save_plot' in a fits-file. Using the qualifiers you can choose
%   how the data should be displayed. By default the model and the
%   data is plotted in counts/bin.
%   
%   The data, model and diff qualifier can be combined with the
%   qualifier 'flux' in order to plot in photons/s/cm^2/keV instead of
%   counts/bin.
%   
%   To define the colors of the plot, you have to provide an array of
%   colors. The length of the array is equal to the number of loaded
%   spectra, as each color is associated with the spectra in the same order
%   given in the fits-file.
%   
%   If you provide the array 'dataset', only these spectra are
%   plotted. The numbers are assinged according to the order of the
%   single spectra in the extension of the fits-file. Using for
%   example 'fv <filename>', you can easily look up these numbers, as the
%   instrument which created the desired spectrum is also named in the
%   header of each extension.
%\examples
%   % save one dataset in a fits-file
%   save_plot("my_data",1);
%   % plot data and model in flux and the residuals in an additional panel
%   % -the data should be in red, color(2) and the data in black, color(1)
%   % -the ranges are set automatically
%   multiplot([3,1]);
%   fplot("my_data",2;type="data",space="flux",auto);
%   ofplot("my_data",1;type="model",space="flux",auto);
%   ofplot("my_data",2;type="res",auto);
%\seealso{save_plot}
%!%-
   
   
  variable rng = [0.,0.];
  variable xrng = [0.,0.];
  variable col;
  variable filename = "save_plot.fits";
  variable dataset;
  variable typ = qualifier("type","default");
  variable space = qualifier("space","counts");
    
   %% Plot Flux or Counts??
  variable ym = "model";
  variable yd = "value";
  variable yr = "err";
  if (space == "density") {
    ym = "model_density";
    yd = "density";
    yr = "density_err";
  } else if (space == "flux"){
    ym = "model_flux";
    yd = "flux";
    yr = "flux_err";    
  }
  
   variable a,b,c;
   switch(_NARGS)
   {case 1:filename = ();}
   {case 2: (filename, col) = (); }
   {case 3: (filename, col, dataset) = (); }   
   {help(_function_name()); return; }
   
   %% get number of datasets
   if (is_substr(filename,".fits") == 0 &  is_substr(filename,".FITS") == 0){
      filename = filename+".fits";      
   }
   
   variable n = fits_read_key(filename,"NUMDAT");
   ifnot (__is_initialized(&dataset)) {
      dataset = [1:n];
   }
   %% check if the required datasets are present
   variable ind = [where(dataset > n), where(dataset < 1)];
   if (length(ind) > 0){
      message("The required dataset '"+string(dataset[ind][0])
	      +"' is not present in "+filename);
      return;
   }
   n = length(dataset);
   
   ifnot (__is_initialized(&col)) {
      col = [1:length(dataset)];
   } 
   %% check if number of colors match the number of spectra
   else if (length(col) != length(dataset)){
    message("The number of colors and spectra have to be equal!");  
    return;
   }
  
  
  
  
   %% ++++++++  read data  +++++++++
   variable i,fits_ext;
   variable dat = Struct_Type[n];
   variable inf = Struct_Type[n];
   variable diff = Array_Type[n];
   variable res = Array_Type[n];
   variable ratio = Array_Type[n];
   variable ratio_err = Array_Type[n];
   variable tmp,j;
   variable plo = get_plot_options;

  for (i = 0; i < n; i++){
     %% get data
     fits_ext = filename+"+"+string(dataset[i]);
     
       %% write additional information
     inf[i] = struct{
       fitfun = fits_read_key(fits_ext,"fitfun"),
       model = fits_read_key(fits_ext,"model"),
       exposure = fits_read_key(fits_ext,"exposure")
     };

     %% get the real data
     dat[i] = fits_read_table(fits_ext);
     
     %% write also the data in bin-density
     dat[i] = struct_combine(dat[i], "density", "density_err","model_density");
     dat[i].density = dat[i].value/(dat[i].bin_hi-dat[i].bin_lo)/inf[i].exposure;
     dat[i].density_err = dat[i].err/(dat[i].bin_hi-dat[i].bin_lo)/inf[i].exposure;
     dat[i].model_density = dat[i].model/(dat[i].bin_hi-dat[i].bin_lo)/inf[i].exposure;
     
     %% convert units if desired
     variable unit = fits_read_key(fits_ext,"tunit1");
     if (qualifier("unit",unit) != unit) {
       unit = qualifier("unit",unit);
       dat[i] = _A(dat[i]);
       dat[i].model = reverse(dat[i].model);
       dat[i].model_flux = reverse(dat[i].model_flux);
       dat[i].flux = reverse(dat[i].flux);
       dat[i].flux_err = reverse(dat[i].flux_err);
     }
      diff[i] = (get_struct_field(dat[i],yd) - get_struct_field(dat[i],ym));
      res[i] = (dat[i].value - dat[i].model)/dat[i].err;
      ratio[i] = dat[i].value/dat[i].model;
      ratio_err[i] = dat[i].err/dat[i].model;
   }
   
   %% ++++++++ set labels ++++++++
   if (not qualifier_exists("nolabel")) {
     xlabel("Energy [keV]");
     if (unit == "A")  xlabel(`Wavelength [\A]`);
     if (space == "flux") {
       ylabel(`photons s\u-1\d cm\u-2\d keV\u-1\d`);
     }
     else if (space == "density") {
       ylabel("counts/keV/s");
     }
     else {
       ylabel("counts/bin");
     }
	   
     if (typ == "ratio")  ylabel("Ratio");
     if (typ == "res")  ylabel(`\gx`);
   }
   
   %% ++++++++  set ranges +++++++
    
   if (qualifier_exists("auto") or qualifier_exists("xauto")){
      xrng[0] = min_struct_field(dat,"bin_lo");
      xrng[1] = max_struct_field(dat,"bin_hi");
      xrange(xrng[0],xrng[1]);
   }
   
   
   if (qualifier_exists("auto") or qualifier_exists("yauto")){
      if (typ == "ratio") {
	 tmp = array_map(Double_Type, &min,ratio);
	 j = where(tmp == min(tmp))[0];
	 rng[0] = min(tmp)- ratio_err[j][where(ratio[j] == min(tmp))[0]];
	 
	 tmp = array_map(Double_Type, &max,ratio);
	 j = where(tmp == max(tmp))[0];
	 rng[1] = max(tmp) + ratio_err[j][where(ratio[j] == max(tmp))[0]];
      }
      else if (typ == "res") {
	 rng[0] = min(array_map(Double_Type, &min,res))-1;
	 rng[1] = max(array_map(Double_Type, &max,res))+1;
      }
      else if (typ == "diff") {
	 tmp = array_map(Double_Type, &min,diff);
	 j = where(tmp == min(tmp))[0];
	 rng[0] = min(tmp) - get_struct_field(dat[j],yr)[where(diff[j] == min(tmp))[0]];
	 
	 tmp = array_map(Double_Type, &max,diff);
	 j = where(tmp == max(tmp))[0];
	 rng[1] = max(tmp) + get_struct_field(dat[j],yr)[where(diff[j] == max(tmp))[0]];
      } else{
	 
	 tmp = Double_Type[n];
	 for (j = 0; j < n; j++ ) {
	    tmp[j] = min(get_struct_field(dat[j],ym));
	 }
	 j = where(tmp == min(tmp))[0];
	 rng[0] = min(tmp) - 
	   get_struct_field(dat[j],yr)[where(get_struct_field(dat[j],ym) == min(tmp))[0]];
	 
	 % make sure that ymin is not negative
	 if (rng[0] < 0) rng[0]=0;
	 
	 for (j = 0; j < n; j++ ) {
	    tmp[j] = max(get_struct_field(dat[j],ym));
	 }
	 j = where(tmp == max(tmp))[0];
	 rng[1] = max(tmp) +
	   get_struct_field(dat[j],yr)[where(get_struct_field(dat[j],ym) == max(tmp))[0]];
      }
      yrange(rng[0],rng[1]);   
   }
   
   %% +++++++  PLOT +++++++++++++
   % options
   
   % initialize plot, if a new plot should be created
  plo = get_plot_options;
  if ( (not qualifier_exists("overplot")) ){ %&& qualifier_exists("auto")){
    if (typ == "ratio" || typ == "res" || typ == "diff"){
      ylin;
    }
    init_plot;
   }
  if (typ == "model"){
    for (i =0;i<n;i++){
      color(col[i]);
      connect_points(1);
      ohplot(dat[i].bin_lo,dat[i].bin_hi,
	     get_struct_field(dat[i],ym));
    }
  } else if (typ == "data"){
    for (i =0;i<n;i++){
      color(col[i]);
      connect_points(0);
      oplot_with_err(dat[i].bin_lo,dat[i].bin_hi,
		     get_struct_field(dat[i],yd),
		     get_struct_field(dat[i],yr);xminmax);
    }
  } else if (typ == "ratio"){
    for (i =0;i<n;i++){
      %% line at 1
      connect_points(1);
      color(1);
      ohplot(dat[i].bin_lo,dat[i].bin_hi,ratio[i]*0+1);
      
      color(col[i]);
      connect_points(0);
      oplot_with_err(dat[i].bin_lo,dat[i].bin_hi,
		     ratio[i],
		     ratio_err[i];xminmax);
    }
   } else if (typ == "res"){
      for (i =0;i<n;i++){
	 %% line at 0
	 connect_points(1);
	 color(1);
	 ohplot(dat[i].bin_lo,dat[i].bin_hi,res[i]*0);
	 color(col[i]);
	 connect_points(0);
	 oplot_with_err(dat[i].bin_lo,dat[i].bin_hi,
			 res[i],
			 res[i]*0+1.;xminmax);
      }
   } else if (typ == "diff"){
      for (i =0;i<n;i++){
	 %% line at 0
	 connect_points(1);
	color(1);
	ohplot(dat[i].bin_lo,dat[i].bin_hi,diff[i]*0);
	
	 color(col[i]);
	connect_points(0);
	oplot_with_err(dat[i].bin_lo,dat[i].bin_hi,
			diff[i],
			get_struct_field(dat[i],yr);xminmax);
      }
   } else {
      %% else: plot DATA and MODEL
     for (i =0;i<n;i++){
       color(col[i]+2);
       connect_points(1);

       ohplot(dat[i].bin_lo,dat[i].bin_hi,
	      get_struct_field(dat[i],ym));
       
       
       color(col[i]);
       oplot_with_err(dat[i].bin_lo,dat[i].bin_hi,
		      get_struct_field(dat[i],yd),
		      get_struct_field(dat[i],yr);xminmax);
       
     }
   }
   set_plot_options(plo);  
}
