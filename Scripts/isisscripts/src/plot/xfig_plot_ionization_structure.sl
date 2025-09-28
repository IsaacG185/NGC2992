% -*- mode: slang; mode: fold -*-

require("xfig");

%% necessary to make it work with slightly older SLang
%% 
#ifeval __get_reference("string_to_wchars")!=NULL

private define get_ions(abund, element){ %{{{
  variable allnames = get_struct_field_names(abund);

  variable pattern = sprintf("^%s_", strlow(element));
  variable ionnames = allnames[where(array_map(Integer_Type, &string_match, allnames, pattern))];

  return ionnames;
}
%}}}

private define capitalize(str){ %{{{
  return strsub(str, 1, toupper(string_to_wchars(str)[0]));
}
%}}}

private define filter_ionization_states(ionlabels, ionsel){ %{{{

  variable ii;
  variable nions = length(ionlabels);
  variable ions = String_Type[nions];
  variable ind = Integer_Type[nions];
  
  _for ii (0, nions - 1, 1){
    ions[ii] = strlow(ionlabels[ii][1]);
  }
  
  _for ii (0, length(ionsel)-1, 1){
    ind[where( ions == ionsel[ii])] = 1;
  }
  
  return where(ind);
}
%}}}

private define plot_single_ion(abund, element){ %{{{

  variable WIDTH = qualifier("width", 10);
  variable HEIGHT = qualifier("height", 3);
  variable XAXIS = qualifier ("xaxis", "radius");
  variable ion_states = qualifier("ion_states");
  variable xpow = qualifier("xpow", 10);

  variable abundthresh = qualifier("athresh", 0.3); % Threshold for ion abundance to be plotted
  
  if (XAXIS == "logxi"){ XAXIS = "ion_parameter";};

  ifnot (XAXIS == "radius"  or XAXIS == "ion_parameter"){
    () = printf("WARNING(%s): unknown xaxis qualifier! Using default: 'radius'\n", _function_name);
    XAXIS = "radius";
  }
    
  variable ionnames = get_ions(abund, element);
  variable ii;

  variable ionlabels = array_map (Array_Type, &strchop, ionnames, '_', 0);

  if (qualifier_exists("ion_states")){
    ionnames = ionnames[filter_ionization_states(ionlabels, ion_states)];
    ionlabels = ionlabels[filter_ionization_states(ionlabels, ion_states)];
    
  }

  variable pl = xfig_plot_new(WIDTH, HEIGHT);

  variable xval = get_struct_field(abund,XAXIS);

  if (XAXIS == "radius"){ 
    xval /= 10^(int(xpow));
  }
  
  pl.world(min(xval), max(xval), -0.1, 1.3);
  pl.yaxis(; format = "%.1f", ticlabels2 = 0);
  pl.xlabel(XAXIS == "radius" ? sprintf("radius~[$10^{%d}$cm]", int(xpow))+""R : "$\log\left(\xi\right)$"R);
  pl.ylabel(capitalize(ionlabels[0][0]));
  variable lpos;
  
  _for ii (0, length(ionnames) - 1, 1){
    pl.plot(xval, get_struct_field(abund, ionnames[ii]);; __qualifiers);

    if (max(get_struct_field(abund, ionnames[ii])) > abundthresh){ % only print labels for those ionization states that are visible
      lpos = mean( [xval[wherefirst(get_struct_field(abund, ionnames[ii]) >= abundthresh)], xval[wherelast(get_struct_field(abund, ionnames[ii]) >= abundthresh) ]] );
      % pl.xylabel(lpos, 1.1, capitalize(ionlabels[ii][0] + strup(ionlabels[ii][1])));
      pl.xylabel(lpos, 1.1, strup(ionlabels[ii][1]));
    }
  }

  % return ionlabels;
  return pl;
}
%}}}

private define plot_info_field(abund,info){ %{{{

  variable WIDTH = qualifier("width", 10);
  variable HEIGHT = qualifier("height", 3);
  variable XAXIS = qualifier ("xaxis", "radius");
  variable xpow = qualifier("xpow", 10);
  
  if (XAXIS == "logxi"){ XAXIS = "ion_parameter";};
  
  ifnot (XAXIS == "radius"  or XAXIS == "ion_parameter"){
    () = printf("WARNING(%s): unknown xaxis qualifier! Using default: 'radius'\n", _function_name);
    XAXIS = "radius";
  }

  variable pl = xfig_plot_new(WIDTH, HEIGHT);

  variable xval = get_struct_field(abund,XAXIS);
  
  if (XAXIS == "radius"){
    xval /= 10^(int(xpow));
  }
  
  variable yval = get_struct_field(abund,info);
  variable ylabel;
  
  switch (info)
  { case "ion_parameter": ylabel = "$\log\left(\xi\right)$"R; }
  { case "x_e": ylabel = "$x_\mathrm{e}$)$"R; }
  { case "n_p": ylabel = "$n_\mathrm{p}$"R; }
  { case "pressure": ylabel = "$p$"R; }
  { case "temperature": ylabel = "$T~[10^4\,\mathrm{K}]$"R; }
  {() = printf("ERROR(%s): Unknown column in abundance FITS file selected! Aborting!", _function_name); return NULL;}
  
  pl.world(min(xval), max(xval), .9*min(yval), 1.1*max(yval));
  pl.ylabel(ylabel);
  pl.xlabel(XAXIS == "radius" ? sprintf("radius~[$10^{%d}$cm]", int(xpow))+""R : "$\log\left(\xi\right)$"R);
  pl.plot(xval, yval;; __qualifiers);
  return pl;
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%
define xfig_plot_ionization_structure (){ %{{{
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{xfig_plot_ionization_structure}
%\synopsis{plots the ionization structure from an abundance file produced by xstar}
%\usage{plot_ionization_structure(String_Type abundace_file, String_Type[] elements, String_Type ouput_file)}
%\qualifiers{
% \qualifier{xpow}{plot radius in units of 10^xpow (default: 10)}
% \qualifier{xaxis}{use 'logxi' or 'radius' to set the abscissa (default: radius)}
% \qualifier{temp}{add temperature panel}
% \qualifier{press}{add pressure panel}
% \qualifier{xee}{add electron fraction panel}
% \qualifier{dens}{add density panel}
% \qualifier{athresh}{only ionization states are plotted which exceed a certain threshold (default: 0.3)}
% \qualifier{ion_states}{string array of ionization states in roman numbers}
% \qualifier{width}{plot witdh}
% \qualifier{height}{plot height}
%
% All other qualifiers are passed to xfig_plot.plot()
%}
%\description
% This function produces and xfig plot of the ion abundance structure of
% an xstar calculation. The input parameters are the xstar abundance FITS
% file, a string array of the elements of interest and an output file name.
%
%\examples
%
%  xfig_plot_ionization_structure ("xout_abund1.fits", ["si", "FE", "Mg", "O"], "ion_abundance.pdf"; ion_states = ["iii", "v"], temp );
%
% plots the ion abundance of the ionization states III and V for the elements Silicon, Iron, Magnesium and Oxygen
% and the temperature as a function of radius.
%!%-

  variable abundfile, elements, filename;
  switch(_NARGS)
  {case 3: (abundfile, elements, filename) = ();}
  {help(_function_name()); return; }
  
  variable temp = qualifier_exists("temp") or qualifier_exists("temperature");
  variable press = qualifier_exists("press") or qualifier_exists("pressure");
  variable logxi = qualifier_exists("logxi");
  variable xe = qualifier_exists("xe") or qualifier_exists("x_e");
  variable np = qualifier_exists("dens") or qualifier_exists("density");
    
  variable abund = fits_read_table(abundfile + "[ABUNDANCES]");

  variable info =  where([logxi, xe, np, press, temp ]);
  variable ninfo = length(info);
  variable infoplts = Struct_Type[ninfo];

  variable infofields = ["ion_parameter", "x_e", "n_p", "pressure", "temperature"];
  
  variable ii;
  _for ii (0, ninfo - 1, 1){
    infoplts[ii] = plot_info_field(abund,infofields[info[ii]];; __qualifiers);
  }

  
  elements = [elements];
  variable nelements = length (elements);
  variable ionplts = Struct_Type[nelements];

  _for ii (0, nelements -1, 1){
    % print(elements[ii]);
    ionplts[ii] = plot_single_ion(abund, elements[ii];; __qualifiers);    
  }

  xfig_multiplot([infoplts,ionplts]).render(filename);
}
%}}}

#endif