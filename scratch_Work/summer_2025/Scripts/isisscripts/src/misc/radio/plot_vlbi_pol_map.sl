require("xfig");

% ISSUES: qualifiers given to plot_vlbi_map in struct{ } forces them, if this script is called multiple times,
% the last enforcement will be also valid for the upcoming call of plot_vlbi_map.
% The question, which qualifier should be free is currently under debate.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define plot_vlbi_pol_map ()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{plot_vlbi_pol_map}
%\synopsis{creates a polarimetric image of a VLBI map using according .fits files (provided by DIFMAP)}
%\usage{(Struct_Type xfig-map, Struct_Type xfig-colormap) = plot_vlbi_pol_map(String_Type \code{fitsfile flux-map-1},
%                  String_Type \code{filename flux-map-2}, String_Type \code{filename plot-product})}
%\altusage{(Struct_Type xfig-map, Struct_Type xfig-colormap, Struct_Type xfig-vectormap) =
%                  plot_vlbi_pol_map(String_Type \code{fitsfile flux-map-1}, String_Type \code{fitsfile EVPA-map},
%                  String_Type \code{filename flux-map-2}, String_Type \code{filename plot-product})}
%\qualifiers{
%\qualifier{n_sigma_pol}{[=5] start color scaling of polarized flux at \code{n_sigma*sigma}}
%\qualifier{n_sigma_vec}{[=5] start plotting of EVPA vectors at \code{n_sigma*sigma} in reference to the polarized flux}
%\qualifier{colmap_pol}{if set, plot most significant polarized flux (depending on n_sigma_pol),
%                                      recommended: color map "iceandfire"}
%\qualifier{colmap_back}{if set, plot polarized flux or total intensity flux, recommended: color map "ds9b"}
%\qualifier{pol_cont}{set to 1 in order to plot contours of flux-map-1}
%\qualifier{pol_cont_col}{[="white"] color of contours of flux-map-1}
%\qualifier{pol_cont_depth}{[=0] depth of contours of flux-map-1}
%\qualifier{pol_translate}{[=0.4] if plot_pol_colmap=0, the contours of polarized flux will be translated
%                                      by \code{pol_translate*range_in_declination}}
%\qualifier{render_object}{[=1] set to 1 in order to render the plot object}
%}
%\description
%   This function uses the existing maps flux-map-1 (polarized flux),
%   (the EVPA_map for the electric vector position angle) and
%   flux_map_2 (polarized flux or total intensity flux) to plot the polarized flux
%   as color-coded map (and the EVPA as vectors) - cutted at the most significant contours
%   depending on n_sigma_pol - on top of the total intensity contours or as contours
%   vertically translated to them.
%   One has the flexibility to plot the polarized flux distribution instead of the total
%   intensity flux color-coded depending on the map given for flux-map-2.
%   All qualifiers of \code{plot_vlbi_map} are forwarded to this function.
%\seealso{plot_vlbi_map}
%!%-
{
  variable pfits,chifits,ifits,plotpath;

  switch(_NARGS)
  {case 3: (pfits,ifits,plotpath) = (); }
  {case 4: (pfits,chifits,ifits,plotpath) = (); }

  variable def_pol_cmap = "iceandfire";
  variable def_I_cmap = "ds9b";  
  
  variable n_sigma_vec = qualifier("n_sigma_vec",5.);
  variable n_sigma_pol = qualifier("n_sigma_pol",5.);
  variable colmap_pol = qualifier("colmap_pol");
  variable colmap_pol_depth = qualifier("colmap_pol_depth",100);  
  variable colmap_back = qualifier("colmap_back");
  variable pol_cont = qualifier("pol_cont",0);  
  variable pol_cont_col = qualifier("pol_cont_col","white");
  variable pol_cont_depth = qualifier("pol_cont_depth",1);      
  variable pol_translate = qualifier("pol_translate",0.4); % percentage of dec-range    
  variable plot_components = qualifier("plot_components");
  variable render_object = qualifier("render_object",1);
  
  variable P,chi,xf_P,xf_PP,xf_I,xf_II,xf_vec;
  variable k;
  
  % clrcut qualifier sets minimum of map to 3sigma above the background;  color map always ranges from min(map) to max(map), here: min=black!
  if (_NARGS==4)
  {
    (xf_vec) = plot_vlbi_map(chifits,pfits,"I_map.pdf";; struct_combine (__qualifiers, struct {axis_color="white",axis_depth=1000,source_color="white",no_labels,
      return_xfig,plot_clr_img=0,plot_cont=0,plot_beam=0,plot_vec=1,n_sigma=n_sigma_vec,src_name=NULL,obs_date=NULL}));
  }
  else xf_vec = xfig_plot_new; % dummy

  if (qualifier_exists("colmap_back"))  
  {
    (xf_I,xf_II) = plot_vlbi_map(ifits,"I_map.pdf";; struct_combine (__qualifiers, struct {axis_color="black",
      plot_cont=1,return_xfig}));    
    (xf_P) = plot_vlbi_map(pfits,"P_map.pdf";; struct_combine (__qualifiers, struct {axis_color="white",axis_depth=1000,date_color="white",source_color="white",
      no_labels,plot_cont=pol_cont,cont_color=pol_cont_col,plot_beam=0,plot_clr_img=0,n_sigma=n_sigma_pol,src_name=NULL,obs_date=NULL,return_xfig}));
    xf_II.y2label("Total Intensity [mJy/beam]");
  }
  else if (qualifier_exists("colmap_pol"))
  {
    (xf_I) = plot_vlbi_map(ifits,"I_map.pdf";; struct_combine (__qualifiers, struct {axis_color="black",
      plot_cont=1,cont_depth=2,plot_clr_img=0,return_xfig}));
    (xf_P,xf_PP) = plot_vlbi_map(pfits,"P_map.pdf";; struct_combine (__qualifiers, struct {axis_color="white",axis_depth=1000,source_color="white",
      no_labels,plot_cont=pol_cont,cont_color=pol_cont_col,plot_beam=0,clrcut=1,n_sigma=n_sigma_pol,bkg_white,src_name=NULL,obs_date=NULL,return_xfig,
      colmap_depth=colmap_pol_depth,cont_depth=pol_cont_depth}));
    xf_PP.y2label("\begin{center}$\mathrm{Polarized~Intensity}$ \\ $\mathrm{[mJy/beam]}$\end{center}"R);
  }
  else
  {
    (xf_I) = plot_vlbi_map(ifits,"I_map.pdf";; struct_combine (__qualifiers, struct {axis_color="black",axis_depth=1000,
      return_xfig,plot_clr_img=0,plot_cont=1}));
    (xf_P) = plot_vlbi_map(pfits,"P_map.pdf";; struct_combine (__qualifiers, struct {axis_color="white",axis_depth=1000,source_color="white",
      no_labels,plot_cont=pol_cont,cont_color=pol_cont_col,plot_beam=0,n_sigma=n_sigma_pol,plot_clr_img=0,clrcut=1,src_name=NULL,obs_date=NULL,return_xfig}));
  }
  if (qualifier_exists("pol_translate"))
  {
    xf_P.translate(vector(0, -(qualifier("dec_mas")[1]-qualifier("dec_mas")[0])*pol_translate,0));
    xf_vec.translate(vector(0, -(qualifier("dec_mas")[1]-qualifier("dec_mas")[0])*pol_translate,0));
  }
  xf_P.axes(;off);
  xf_vec.axes(;off);
%  xf_P.set_depth(1);
%  xf_vec.set_depth(5);
  xf_I.add_object(xf_P); % total I contours and P-color map with color map in PP
  xf_I.add_object(xf_vec);

  
  
%  if (qualifier_exists("plot_components")) {
%    variable comps = fits_read_table(ifits);
%    comps.deltax *= 3.6e6;
%    comps.deltay *= 3.6e6;
%    variable pos_comps = struct_filter(comps, where(comps.flux > 0); copy);
%    variable neg_comps = struct_filter(comps, where(comps.flux < 0); copy);
%    xf_I.plot(pos_comps.deltax, pos_comps.deltay; sym="+",width=2,color=qualifier("pos_comp_color"),depth=1);
%    xf_I.plot(neg_comps.deltax, neg_comps.deltay; sym="*",width=2,color=qualifier("neg_comp_color"),depth=1);
%    if (qualifier_exists("model_circs")) {
%      _for k (0,length(pos_comps.deltax)-1,1) xf_I.plot(pos_comps.deltax[k], pos_comps.deltay[k];
%							sym="circle",size=3.*pos_comps.major_ax[k]*3.6e6,width=2,color=qualifier("pos_comp_color"),depth=1);
%      _for k (0,length(neg_comps.deltax)-1,1) xf_I.plot(neg_comps.deltax[k], neg_comps.deltay[k];
%							sym="circle",size=3.*pos_comps.major_ax[k]*3.6e6,width=2,color=qualifier("neg_comp_color"),depth=1);
%    }
%  }
    
  if (render_object==1) {
    if (qualifier_exists("colmap_pol") == 0 && qualifier_exists("colmap_back") == 0) xfig_new_hbox_compound(xf_I).render(plotpath);
    if (qualifier_exists("colmap_back")) xfig_new_hbox_compound(xf_I,xf_II).render(plotpath);
    if (qualifier_exists("colmap_pol")) xfig_new_hbox_compound(xf_I,xf_PP).render(plotpath);
    if (qualifier_exists("colmap_back") && qualifier_exists("colmap_pol"))
      throw RunTimeError, sprintf("%s: can't plot both full- and polarized intensity color maps", _function_name(), _function_name());
  }

  if (_NARGS==4 && qualifier_exists("colmap_back")) return (xf_I,xf_II,xf_vec);
  if (_NARGS==4 && qualifier_exists("colmap_pol")) return (xf_I,xf_PP,xf_vec);  
  if (_NARGS==3 && qualifier_exists("colmap_back")) return (xf_I,xf_II);
  if (_NARGS==3 && qualifier_exists("colmap_pol")) return (xf_I,xf_PP);  
}

