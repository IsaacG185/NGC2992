% -*- slang -*-

try { require("COPY.sl"); }
catch AnyError:; ;

%  Version 1.4.3

private variable _fancy_plots_version = [1,4,3];
public variable fancy_plots_version=int(sum(_fancy_plots_version*[10000,100,1]));
public variable fancy_plots_version_string=sprintf("%d.%d.%d",
   _fancy_plots_version[0],_fancy_plots_version[1],_fancy_plots_version[2]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Most recent update: April 2016

% Big block of plotting functions, to allow you to do all sorts of
% XSPEC type plotting, and then some.  Plot parameters can be input as
% either a structure, or as qualifiers, or both.  (For the latter
% case, qualifiers supersede structure choices.)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Public Functions in This File.  Usage message when function is called
% without arguments.
%
% pg_info          : Writes out useful info about plotting choices.
% pg_color         : Make a few nice colors for pgplot
% sov              : An abbreviation of set_outer_viewport
% apj_size         : An autoset of resize/set_outer_viewport that works
%                    well for a "typical" ApJ one column plot.
% keynote_size     : An autoset of resize/set_outer_viewport that works
%                    well for a "typical" keynote presentation.
% open_print       : A version of open_plot that invokes pg_color first
% close_print      : A version of close_plot that will then display the 
%                    hardcopy via a chosen system utility (e.g., gv)
% set_plot_widths  : Routine to set all the plot line thicknesses
% nice_width       : An autoset of plot widths that works well for 
%                    papers and presentations (especially on Macs)
% set_plot_labels  : Resets all plot labels to their defaults, and can
%                    be used to change the default font.
% new_plot_labels  : Change the plot labels for all plot styles.
% add_plot_unit    : Create new X-/Y-unit combinations for the plots
% fancy_plot_unit  : My variation on ISIS's plot_unit.  Same choices as
%                    in ISIS, but this saves variables (x_unit, y_unit) 
%                    that will be used below.
% data_list        : List version of all_data
% write_plot       : Write the data from the plot functions to ASCII
%                    files
% plot_counts      : Plot background subtracted data as counts/bin,
%                    with choices of three kinds of residuals, or none 
%                    at all. (cstat overides defaults)
% plot_data        : Main plotting routine, to plot background sub-
%                    tracted data in detector counts space.  Counts
%                    per second per x_unit, with choices of three
%                    kinds of residuals, or none at all.
% plot_residuals   : A plot of just the data residuals
% plot_fit_model   : An hplot of just the background subtracted model.
% plot_unfold      : A plot of the unfolded spectra, or powers of 
%                    energy/freq./wavelength times unfolded spectra.
% plotxy           : Simple x-y (o)plots with error bars.
% plot_comps       : Plot individual components of a model
% plot_double      : Use two fancy plot functions at once, while also
%                    plotting individual components of a model

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Private Functions in This File - Used for the Plotting Internals 
%
% pd_set                : Set up variable to store data for ascii dump
% p_reset               : Reset the plot defaults
% multiplotit           : Set up two panes for residual plotting
% vaxis                 : Make a redshift or velocity x-axis
% make_exp_and_back     : Create data/backgrounds exposures & scales
% make_data             : Create plot data (plot_counts/data/residuals)
% hp_loop               : Sets index ranges for hplot so disjoint bits
%                       : of data, model, get plotted separately
% hp_loopit             : Does the actual hplotting for disjoint bits
% xerplot               : Put a bar at 0 or 1 across the residuals plot 
% start_plot            : Kluge to get auto-scaling right for multiple
%                       : data sets
% datplot_err           : Plot data error bars
% trans_strct_and_array : Transfer structure inputs to plot variables
% res_set               : Begin set-up of the residuals plot
% resplot               : Driver for the residual plots
% p_range_label         : Set up the plot ranges and labels
% make_default          : Create default plot parameters
% unpack_list           : Turn a list with internal arrays into a 
%                       : simple list of elements
% trans_strct           : Transfer structure inputs to plot variables
% make_array_a_list     : Turn an array into a list
% set_plot_parms_struct : Ultimately all plot choices are passed via
%                       : a structure, using this subroutine
% make_indices          : Parse the input data indices
% set_plot_parms        : Parse the input to the above routine

% make_flux             : Create the flux corrected data to be plotted
% write_plot_head       : Makes the header for ASCII files containing
%                         data from the plot functions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

variable fp = stderr;

public define pg_info()
%!%+
%\function{pg_info}
%\synopsis{Print a core dump of some useful pgplot and isis_fancy_plots information.}
%\usage{pg_info; -or- pginfo;}
%\description
%\seealso{Nearly all isis_fancy_plot functions return a use message if invoked without arguments}
%!%-
%!%+
%\function{pginfo}
%\synopsis{Print a core dump of some useful pgplot and isis_fancy_plots information.}
%\usage{pg_info; -or- pginfo;}
%\description
%\seealso{Nearly all isis_fancy_plot functions return a use message if invoked without arguments}
%!%-
{
   () = fprintf(fp,  "%s\n", %{{{
`
 # COLOR   SYMBOL    # COLOR       SYMBOL             # COLOR SYMBOL

 1 default dot       9 yllw green  mdot              17 green filled circle
 2 red     plus     10 green+cyan  fancy square      18 brown filled star
 3 green   cross    11 indigo      diamond           19 pink  big square
 4 blue    circle   12 purple      star           20-27 gold  sized circles
 5 cyan    cross    13 red+magenta solid triangle 28-31       left/right/
 6 magenta square   14 dark grey   hollow cross               up/down arrows
 7 yellow  triangle 15 light grey  star of david 32-127       ASCII symbols
 8 orange  earth    16 black       filled square

 Negative symbol #'s give filled symbols with that many sides
 Colors 17-27 must first be defined with pg_color();

 pointstyle(#)           : Choose one the above symbols.
 connect_points(#)       : -1 = line only / 0 = points only / 1 = both
 linestyle(#)            : (1) full line, (2) dashed, (3) dot-dash,
                           (4) dotted, (5) dash-dot-dot-dot

 line_or_color(#)        : plot(x,y,##), ## = linestyle(##), if # = 0
                                         ## = color, if # != 0 (default)

 set_line_width(#)       : Set the widths of lines in ISIS intrinsic plots
 set_frame_line_width(#) : Set the frame width
 charsize(#)             : Set character sizes in plots
 point_size(#)           : Set datapoint sizes in plots

 _pgsci(#)               : Set color index to #
 _pgtext(x,y,string)     : Write text in plot (use log10 of x/y for log plots)

 xlabel(), ylabel(), title(); with \u, \d, \g = up, down, greek
   \fn, \fr, \fi, \fs = normal, roman, italic, and script fonts
   \A = Angstrom, \. = center dot, \x = multiplication,
   (NOTE: Use \\ if placing within "  ", and \ if placing within `` `` !!!)

 Custom plot functions defined by ISIS fancy plots script (obtain help for
 individual functions, usually by invoking function without any arguments):

   Plotting routines  : plot_counts, plot_data, plot_unfold, plot_residuals,
                        plot_fit_model, plotxy, plot_comps, plot_double
   Output routines    : open_print, close_print (variant of intrinsics,
                        open_plot, close_plot), write_plot (write to ASCII)
   Input routines     : data_list (list version of all_data)
   Unit set routines  : fancy_plot_unit, add_plot_unit
   Color set routine  : pg_color
   Labelling routines : set_plot_labels, new_plot_labels
   Width/size routines: set_plot_widths, nice_width, sov,
                        apj_size, keynote_size
   Flux scale routines: set_power_scale
`); %}}}
}

alias("pg_info","pginfo");

%%%%%%%%%%%%%%%%%%%%%%%%

public define pg_color()
%!%+
%\function{pg_color}
%\synopsis{Set pgplot colors 17, 18, 19, 20 to a green, brown, pink, dark yellow (isis_fancy_plots package)}
%\usage{pg_color; -or- pgcolor;}
%\description
%\seealso{pg_info, pginfo}
%!%-
%!%+
%\function{pgcolor}
%\synopsis{Set pgplot colors 17, 18, 19, 20 to a green, brown, pink, dark yellow (isis_fancy_plots package)}
%\usage{pg_color; -or- pgcolor;}
%\description
%\seealso{pg_info, pginfo}
%!%-
{
   _pgshls(17,255,0.3,0.6);   % Define a decent green color for pgplot
   _pgshls(18,150,0.35,0.4);  % Define a decent brown color for pgplot
   _pgshls(19,120,0.75,0.75); % Define a pink color for pgplot

   % Define a dark yellow color for pgplot
   variable i; _for i (20,27,1){ _pgshls(i,180,0.45,0.65); }
}

alias("pg_color","pgcolor");

%%%%%%%%%%%%%%%%%%%

public define sov()
%!%+
%\function{sov}
%\synopsis{Set pgplot outer viewport (isis_fancy_plots package)}
%\usage{sov(Double_Type, Double_Type, Double_Type, Double_Type);}
%\description
%
% sov(xmin,xmax,ymin,ymax);
%
%   Equivalent to:
%      isis> v=struct{xmin,xmax,ymin,ymax};
%      isis> v.xmin=xmin;
%      isis> v.xmax=xmax;
%      isis> v.ymin=ymin;
%      isis> v.ymax=ymax;
%      isis> set_outer_viewport(v)
%   and:
%      isis> set_outer_viewport(struct{xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax});
%\seealso{set_outer_viewport, apj_size, keynote_size, nice_width, open_print, close_print, pg_color, pg_info}
%!%-
{
   variable v=struct{xmin,xmax,ymin,ymax};
   switch(_NARGS)
   {
    case 4:
      (v.xmin,v.xmax,v.ymin,v.ymax)=();
      set_outer_viewport(v);
      return;
   }
   {
      () = fprintf(fp, "\n%s\n", %{{{
` sov(xmin,xmax,ymin,ymax);

   Equivalent to:
      isis> v=struct{xmin,xmax,ymin,ymax};
      isis> v.xmin=xmin;
      isis> v.xmax=xmax;
      isis> v.ymin=ymin;
      isis> v.ymax=ymax;
      isis> set_outer_viewport(v)
   and:
      isis> set_outer_viewport(struct{xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax});
`                 );            %}}}
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%

public define apj_size()
%!%+
%\function{apj_size}
%\synopsis{Set the pgplot output size to something suitable for ApJ single column (isis_fancy_plots package)}
%\usage{apj_size;}
%\description
%
%   Use as:
%   isis> id = open_print("fig1.ps/vcps"); apj_size; nice_width;
%   isis> plot(x,y);
%   isis> close_print(id,"gv");
%\seealso{sov, keynote_size, nice_width, open_print, close_print, pg_color, pg_info}
%!%-
{
   resize(30,0.9);
   sov(0.13,0.65,0.1,0.65);
   charsize(1.05);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define keynote_size()
%!%+
%\function{keynote_size}
%\synopsis{Set the pgplot output size to something suitable for Keynoe presentations (isis_fancy_plots package)}
%\usage{apj_size;}
%\description
%
%   Use as:
%   isis> id = open_print("fig1.ps/vcps"); keynote_size; nice_width;
%   isis> plot(x,y);
%   isis> close_print(id,"gv");
%\seealso{sov, apj_size, nice_width, open_print, close_print, pg_color, pg_info}
%!%-
{
   resize(30,0.65);
   sov(0.13,0.65,0.1,0.65);
   charsize(1.1);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%

private variable fname = String_Type[0];

public define open_print(a)
%!%+
%\function{open_print}
%\synopsis{Wrapper around open_plot (and pg_color) to allow a system function to call the output file (isis_fancy_plots package)}
%\usage{id = open_print(String_Type);}
%\description
%
%   Use as:
%   isis> id = open_print("fig1.ps/vcps"); keynote_size; nice_width;
%   isis> plot(x,y);
%   isis> close_print(id,"gv");
%\seealso{close_print, sov, open_plot, close_plot, apj_size, keynote_size, nice_width, pg_color, pg_info}
%!%-
{
   variable id;
   variable fname_piece = strchop(a,'/',0);
   variable npiece = length(fname_piece);

   if( npiece < 2 )
   {
      message(" Need to specify a plot device.");
      return;
   } 

   id = open_plot(a);
   if(id>length(fname)-1){loop(id-length(fname)+1){fname=[fname,""];}}

   fname[id] = strjoin(fname_piece[[0:npiece-2]],"/");

   pg_color;
   return id;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define close_print()
%!%+
%\function{close_print}
%\synopsis{Wrapper around close_plot to allow system function to call the output file (isis_fancy_plots package)}
%\usage{close_print(window_id, String_Type);}
%\description
%
%   Use as:
%   isis> id = open_print("fig1.ps/vcps"); keynote_size; nice_width;
%   isis> plot(x,y);
%   isis> close_print(id,"gv");
%\seealso{open_print, sov, open_plot, close_plot, apj_size, keynote_size, nice_width, pg_color, pg_info}
%!%-
{
   variable a,b;
   switch(_NARGS)
   {
    case 1:
      a = ();
      close_plot(a);
      return;
   }
   {
    case 2:
      (a,b) = ();
      close_plot(a);
      () = system(b+" "+fname[a]+" &");
      return;
   }
   {
      message("Incorrect arguments.");
      return;
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Structure variable for saving plot data to files

static variable pd=struct{type, index, file, xaxis, yaxis, raxis, dlo,
 dhi, dval, derr, model_on, mlo, mhi, mval, con_mod, res, res_m, res_p, 
weight, exp, instrument, grating, order, part};

% Standard plot options accesible through the plot functions themselves

private variable parm_s = 
                    struct{ dcol, decol, mcol, ccol, cstyle, rcol, recol, dsym, rsym,
                            yrange, xrange, res, power, oplt, bkg, 
                            zshift, vzero, zaxis,
                            xlabel, ylabel, sum_exp, con_mod, gap, scale, no_reset};

% Parameters that should be lists on input

variable list_params=["dcol","decol", "dsym","mcol","ccol","cstyle","rcol","recol", 
                      "rsym","scale","yrange","xrange","bkg","zshift","gap"];

% All the parameters

private variable parms=[list_params,"res","oplt","vzero","zaxis","power",
                        "xlabel","ylabel", "sum_exp", "con_mod", "no_reset"];

private variable dcol_df, mcol_df, power_df, style_df, gap_df, sum_exp_df;

% Note that the following variables, including the list of data set
% indices, essentially get passed around like common block variables

private variable indx, dcol, decol, mcol, rcol, recol, dsym, rsym, 
                yrng, xrng, res, power, oplt, bkg,
                zshift, vzero, zaxis,
                xlabl, ylabl,
                pd_mean_not_sum=0, use_con_flux, rescale, no_reset, gap;

dcol_df = 4;         % Default data color is blue
style_df = 4;        % Default symbol is a circle
mcol_df = 2;         % Default model color red
power_df = 1;        % Default unfolded spectrum is Photons/cm^2/sec/Unit
xlabl=NULL;          % Default is to use the standard X plot labels
ylabl=NULL;          % Default is to use the standard Y plot labels
sum_exp_df = 1;      % Default is to sum exposure times when combining data for plot_data
use_con_flux = 1;    % Default is to smear the model through the response for plot_unfold
no_reset = 0;        % Default is to "reset" plots after plotting, so
		     % the subsequent plot takes place in the next
		     % panel (multi-plots), or redraws the window as a
		     % whole (single plots)
gap_df = 1;          % plots have gaps where the data does

public variable popt = @parm_s;  % Create a public structure variable for choices

% Plot options only accessible through set_plot_widths

private variable d_width, de_width, m_width, r_width, re_width, 
                 ebar_x, ebar_y, data_err;
d_width =1;    % Default widths on line thicknesses.
m_width =1; 
r_width =1;
de_width=1;
re_width=1; 
ebar_x = 0;    % Default is no caps on error bars
ebar_y = 0;
data_err=0;    % Default is no X error bars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Replaces old way of setting plot widths via global variables

public define set_plot_widths() 
%!%+
%\function{set_plot_widths}
%\synopsis{Sets plot widths for isis_fancy_plots package}
%\usage{set_plot_widths([;qualifiers]);}
%\qualifiers{
%\qualifier{m_width}{Model line width}
%\qualifier{d_width}{Data line width}
%\qualifier{de_width}{Data error bar line width}
%\qualifier{r_width}{Residual line width}
%\qualifier{re_width}{Residual error bar line width}
%\qualifier{ebar_x}{X error bar term cap length}
%\qualifier{ebar_y}{Y error bar term cap length}
%\qualifier{data_err}{!=0 X error bars plotted}
%}
%\description
%
% set_plot_widths(; d_width=#, de_width=#, r_width=#, re_width=#, m_width=#,
%                   ebar_x=#, ebar_y=#, data_err=#);
%
% Sets line widths on data, residuals, error bars, and models, sets the
% length of x/y error bar term caps (ebar_x, ebar_y), and toggles the
% X error bar plotting. Values are retained until explicitly overwritten.
%\seealso{nice_width, pg_info}
%!%-
{
   variable quals=["d_width","de_width","r_width","re_width","m_width",
                   "ebar_x","ebar_y","data_err"];

   if(sum(array_map(Integer_Type,&qualifier_exists,quals;;__qualifiers))==0)
   {
      () = fprintf (fp, "%s\n", %{{{
`
 set_plot_widths(; d_width=#, de_width=#, r_width=#, re_width=#, m_width=#,
                   ebar_x=#, ebar_y=#, data_err=#);

 Sets line widths on data, residuals, error bars, and models, sets the
 length of x/y error bar term caps (ebar_x, ebar_y), and toggles the
 X error bar plotting. Values are retained until explicitly overwritten.

 Current values:
`                   );           %}}}
      ()=fprintf(fp, "  Data                 : %3i\n", d_width);
      ()=fprintf(fp, "  Data Errors          : %3i\n", de_width);
      ()=fprintf(fp, "  Residuals            : %3i\n", r_width);
      ()=fprintf(fp, "  Residual Errors      : %3i\n", re_width);
      ()=fprintf(fp, "  Model                : %3i\n", m_width);
      ()=fprintf(fp, "  X error bar term caps: %3i\n", ebar_x);
      ()=fprintf(fp, "  Y error bar term caps: %3i\n", ebar_y);
      ()=fprintf(fp, "  X error bars on?     : %3i\n\n", data_err);
      return;
   }
   m_width  = int(abs(qualifier("m_width", m_width )))[0];
   d_width  = int(abs(qualifier("d_width", d_width )))[0];
   de_width = int(abs(qualifier("de_width",de_width)))[0];
   r_width  = int(abs(qualifier("r_width", r_width )))[0];
   re_width = int(abs(qualifier("re_width",re_width)))[0];
   ebar_x   = int(abs(qualifier("ebar_x",  ebar_x  )))[0];
   ebar_y   = int(abs(qualifier("ebar_y",  ebar_y  )))[0];
   data_err = int(abs(qualifier("data_err",data_err)))[0];
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%dcol_df = 4;         % Default data color is blue
%style_df = 4;        % Default symbol is a circle
%mcol_df = 2;         % Default model color red
%power_df = 1;        % Default unfolded spectrum is Photons/cm^2/sec/Unit
%pd_mean_not_sum = 0; % Default is to sum exposure times when combining data for plot_data
%use_con_flux = 1;    % Default is to smear the model through the response for plot_unfold
%gap_df = 1;          % plots have gaps where the data does

public define reset_plot_defaults() 
%!%+
%\function{reset_plot_defaults}
%\synopsis{Changes some of the defaults on the isis_fancy_plots package}
%\usage{reset_plot_defaults(;dcol=Integer_Type, ...);}
%\qualifiers{
%\qualifier{dcol}{Data color value}
%\qualifier{dsym}{Data symbol value}
%\qualifier{mcol}{Model color value}
%\qualifier{sum_exp}{!=0, Sum the exposures when combining data}
%\qualifier{use_con_flux}{!=0, the unfolded model includes response smearing}
%\qualifier{gap}{==0, plot models across data gaps.}
%}
%\description
%
% reset_plot_defaults(; dcol=#, dsym=#, mcol=#, sum_exp=#,
%                   use_con_flux=#, gap=#);
%
% Resets some of the plot defaults to a user's specifications. (See
% help messages for individual plotting functions, and pg_info, to
% understand these settings.)  Use with no arguments to see current
% values.
%\seealso{pg_info}
%!%-
{
   variable quals=["dcol","dsym","mcol","power","sum_exp",
                   "use_con_flux","gap"];

   if(sum(array_map(Integer_Type,&qualifier_exists,quals;;__qualifiers))==0)
   {
      () = fprintf (fp, "%s\n", %{{{
`
 reset_plot_defaults(; dcol=#, dsym=#, mcol=#, sum_exp=#,
                   use_con_flux=#, gap=#);

 Resets some of the plot defaults to a user's specifications. (See
 help messages for individual plotting functions, and pg_info, to
 understand these settings.)

 Current values:
`                   );           %}}}
      ()=fprintf(fp, "  dcol          : %3i\n", dcol_df);
      ()=fprintf(fp, "  dsym          : %3i\n", style_df);
      ()=fprintf(fp, "  mcol          : %3i\n", mcol_df);
      ()=fprintf(fp, "  sum_exp       : %3i\n", sum_exp_df);
      ()=fprintf(fp, "  use_con_flux  : %3i\n", use_con_flux);
      ()=fprintf(fp, "  gap           : %3i\n\n", gap_df);
      return;
   }
   dcol_df = int(abs(qualifier("dcol", dcol_df )))[0];
   style_df = int(abs(qualifier("dsym", style_df )))[0];
   mcol_df = int(abs(qualifier("mcol",mcol_df)))[0];
   sum_exp_df = int(abs(qualifier("sum_exp",sum_exp_df)))[0];
   use_con_flux = int(abs(qualifier("use_con_flux",  use_con_flux  )))[0];
   gap_df = int(abs(qualifier("gap",  gap_df  )))[0];
}

%%%%%%%%%%%%%%%%%%%%%%%%%%

public define nice_width()
%!%+
%\function{nice_width}
%\synopsis{Sets reasonable defaults for plot line widths.}
%\usage{nice_width;}
%\description
%
%  Equivalent to:
%    isis> set_plot_widths(;d_width=2, de_width=2, r_width=2, re_width=2, m_width=2);
%\seealso{set_plot_widths, apj_size, keynote_size, open_print, close_print}
%!%-
{
   variable dw=2, ew=2, fw=2, mw=2;
   set_frame_line_width(fw);
   set_line_width(dw);
   set_plot_widths(;d_width=dw, de_width=ew, r_width=dw, re_width=ew, m_width=mw);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private variable plopt=NULL;

private variable refplt = [&plot, &oplot];
private variable hrefplt = [&hplot, &ohplot];
private variable slangref;

% Beginning of the definition of the standard units we'll use.

private variable y_unit = "photons", x_unit="kev";
private variable zlo, zhi;

private variable ssk, ssw, ssh, vlbl, redlbl, clbl, mllbl;
private variable lk = ["ev","kev","mev","gev","tev",
                      "hz","khz","mhz","ghz",
                      "angstrom","a","nm","um","micron","mm","cm","m"];

private variable ak = Assoc_Type[String_Type], 
                 sk = Assoc_Type[String_Type];
private variable y_scl, y_scl_norm = Assoc_Type[Float_Type]; % For storing Y-axis scalings

unit_add("micron",0,1.e4);  % Same thing as "um"
unit_add("psd",1,1.);       % SITAR defines power spectra as keV based units
                            % since people have in the past used XSPEC to fit them

ak["ev"] = "eV"; ak["kev"] = "keV"; ak["mev"] = "MeV"; 
ak["gev"] = "GeV"; ak["tev"] = "TeV";
ak["hz"] = "Hz"; ak["khz"] = "kHz"; ak["mhz"] = "MHz"; ak["ghz"] = "GHz";
ak["angstrom"] = `\A`; ak["a"] = `\A`; ak["nm"] = "nm";
ak["um"] = `\gmm`; ak["micron"] = `\gmm`; 
ak["mm"] = "mm"; ak["cm"] = "cm"; ak["m"] = "m";
ak["psd"]= "Hz";

private variable xlbl = Assoc_Type[String_Type];
private variable ylbl = Assoc_Type[Array_Type];
private variable rlbl;
private variable pg_font;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define labels for each combination of possible x_unit & y_unit.

public define set_plot_labels()
%!%+
%\function{set_plot_labels}
%\synopsis{Restore default plot labels of isis_fancy_plots package}
%\usage{set_plot_labels(;pg_font="\\\\fr") -or- set_plot_labels(;pg_font=``\\\\fr``)}
%\qualifiers{
%\qualifier{pg_font}{="\\\\fn", "\\\\fr", "\\\\fs", or "\\\\fi"}
%}
%\description
%\seealso{new_plot_labels, fancy_plot_unit, add_plot_unit}
%!%-

    
{
   pg_font = qualifier("pg_font",`\fr`);
   pg_font = qualifier("pgfont",pg_font);
   
   ssk = pg_font+"Energy";
   ssw = pg_font+"Wavelength";
   ssh = pg_font+"Frequency";

   sk["ev"] = ssk; sk["kev"] = ssk; sk["mev"] = ssk; 
     sk["gev"] = ssk; sk["tev"] = ssk;
   sk["hz"] = ssh; sk["khz"] = ssh; sk["mhz"] = ssh; sk["ghz"] = ssh;
   sk["angstrom"] = ssw; sk["a"] = ssw; sk["nm"] = ssw;
     sk["um"] = ssw; sk["micron"] = ssw; sk["mm"] = ssw; sk["cm"] = ssw; sk["m"] = ssw;
   sk["psd"]= ssh; 

   variable nu_F_nu_lbls
    = [   `F\d\gn\u/\gn\u-2\d`,
          `F\d\gn\u/\gn`,
          `F\d\gn\u`,
       `\gnF\d\gn\u`
      ]+"  (";

   variable l_F_l_lbls
    = [        `F\d\gl\u`,
       `\gl`+  `F\d\gl\u`,
       `\gl\u2\dF\d\gl\u`,
       `\gl\u3\dF\d\gl\u`
      ]+"  (";

   variable ergs=`ergs cm\u-2\d s\u-1\d`;
   variable watts=`Watts cm\u-2\d`;

   variable lbl;
   foreach lbl (lk)
   {
      xlbl[lbl] = sk[lbl]+" ("+ak[lbl]+")";

      variable plot_data_lbl = `Counts s\u-1\d `+ak[lbl]+`\u-1\d`;
      variable plot_counts_lbls = 
         ["",          "", ak[lbl]+" ", ak[lbl]+`\u2\d `]
                          +"Counts/bin"+
         ["/"+ak[lbl], "",          "",               ""];

      variable nu_F_nu_suffix = 
         [" "+ak[lbl]+`\u-3\d)`, " "+ak[lbl]+`\u-2\d)`, " "+ak[lbl]+`\u-1\d)`, ")"];

      variable l_F_l_prefix =
         ["", "", ak[lbl]+" ", ak[lbl]+`\u2\d `];

      variable l_F_l_suffix = 
         [" "+ak[lbl]+`\u-1\d`, "", "", ""]+")";

      ylbl[lbl+"photons"] = pg_font+
         [plot_data_lbl,
          [ak[lbl]+`\u-1\d `,"",ak[lbl]+" ",ak[lbl]+`\u2\d `]
             +"Photons cm\\u-2\\d s\\u-1\\d "+ak[lbl]+"\\u-1\\d",
          plot_counts_lbls                                       ];

      y_scl_norm[lbl+"photons"] = 1.;  % Photons is photons

      ylbl[lbl+"mjy"] = pg_font+
         [plot_data_lbl,
          "I\\d\\gn\\u"+
              ["/"+sk[lbl]+`\u2\d  (mJy/`+ak[lbl]+`\u2\d)`,
                         "/"+sk[lbl]+"  (mJy/"+ak[lbl]+")",
                                                 "  (mJy)",
                       ` \x `+sk[lbl]+`  (mJy\.`+ak[lbl]+")"],
          plot_counts_lbls                                       ];

      y_scl_norm[lbl+"mjy"] = Const_h*1.e26; % The definition of mJy

      if(unit_info(lbl).is_energy==1)
      {
         ylbl[lbl+"ergs"] = pg_font+
            [plot_data_lbl,
             nu_F_nu_lbls+ergs+nu_F_nu_suffix,
             plot_counts_lbls                                    ];

         % Converts plot_unfold(...;power=3) to ergs/cm^2/s

         y_scl_norm[lbl+"ergs"] = Const_eV*1.e3*unit_info(lbl).scale; 

         ylbl[lbl+"watts"] =  pg_font+
            [plot_data_lbl,
             nu_F_nu_lbls+watts+nu_F_nu_suffix,
             plot_counts_lbls                           ];

         % Converts plot_unfold(...;power=3) to Watts/cm^2

         y_scl_norm[lbl+"watts"] = Const_eV*unit_info(lbl).scale; 
      }
      else
      {
         ylbl[lbl+"ergs"] = pg_font+
            [plot_data_lbl,
             l_F_l_lbls+l_F_l_prefix+ergs+l_F_l_suffix,
             plot_counts_lbls                                             ];

         % Converts plot_unfold(...;power=1) to ergs/cm^2/s

         y_scl_norm[lbl+"ergs"] = Const_h*Const_c*1.e8/unit_info(lbl).scale; 

         ylbl[lbl+"watts"] = pg_font+
            [plot_data_lbl,
             l_F_l_lbls+l_F_l_prefix+watts+l_F_l_suffix,
             plot_counts_lbls                                             ];

         % Converts plot_unfold(...;power=1) to Watts/cm^2

         y_scl_norm[lbl+"watts"] = Const_h*Const_c*1.e5/unit_info(lbl).scale; 
      }
   }

   xlbl["psd"] = sk["psd"]+"("+ak["psd"]+")";

   ylbl["psdpsd_leahy"] = pg_font+["PSD Plot","PSD Plot","PSD Plot","PSD Plot","PSD Plot",
                                   ` Power (Leahy)/f`,
                                   ` Power (Leahy)`,
                                   ` f \x Power (Leahy)`,
                                   ` f\u2\d \x Power (Leahy)`];

   y_scl_norm["psdpsd_leahy"] = 1;  % Not really used in PSD plots

   ylbl["psdpsd_rms"] = pg_font+["PSD Plot","PSD Plot","PSD Plot","PSD Plot","PSD Plot",
                                 ` Power/f (RMS\u2\d/Hz\u2\d)`,
                                 ` Power (RMS\u2\d/Hz)`,
                                 ` f \x Power (RMS\u2\d)`,
                                 ` f\u2\d \x Power (RMS\u2\d \. Hz)`];

   y_scl_norm["psdpsd_rms"] = 1;  % Not really used in PSD plots

   rlbl = [pg_font+`\gx`,pg_font+`\gx\u2`,pg_font+"Ratio"];
   rlbl = [rlbl,rlbl];

   vlbl = pg_font+` Velocity  (km s\u-1\d)`;
   redlbl = pg_font+" Redshift  (z)";
   clbl = pg_font+[`\gDC/|\gDC|\u1/2`,`\gDC`];
   mllbl = pg_font+[`\gDML/|\gDML|\u1/2`,`\gDML`];
}

%%%%%%%%%%%%%%%%%%

set_plot_labels();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Allow the user to ovewrite default labels, and define labels for new
% plot unit types.

public define new_plot_labels()
%!%+
%\function{new_plot_labels}
%\synopsis{Create new plot labels for routines in isis_fancy_plots package.}
%\usage{new_plot_labels(String_Type [, String_Type]);}
%\qualifiers{
%\qualifier{xlabel}{New X-axis label}
%\qualifier{ylabel}{String array with new Y-axis labels for data}
%\qualifier{rlabel}{String array with new Y-axis labels for residuals}
%\qualifier{clabel}{String array with new Y-axis residual labels for Cash statistics}
%\qualifier{mllabel}{String array with new Y-axis residual labels for Maximum Likelihood statistics}
%\qualifier{vlabel}{String with new Doppler velocity X-axis label}
%\qualifier{zlabel}{String with new redshift X-axis label}
%\qualifier{pg_font}{PGPLOT font type (default is \\\\fr)}
%}
%\description
%
% new_plot_labels(x_unit [,y_unit];xlabel=string,ylabel=[string],...,
%                                   pg_font=string);
%
% Changes the default labels for plot_counts, plot_data, plot_unfold
% for the different units set by fancy_plot_unit. pg_font string will
% be *prepended* to all inputs. Use any valid pair of units to set residual,
% Cash statistic, or velocity/redshift axis labels.
%
% Use: 
%
%    set_plot_labels(;pg_font="\\\\fr") -or- set_plot_labels(;pg_font=``\\\\fr``)
%
% to restore defaults.
%
% Inputs:
%
%   x_unit : angstrom,a,nm,um,micron,cm,mm,m, ev,kev,mev,gev,tev,
%            hz,khz,mhz,ghz, psd
%   y_unit : photons (=default), ergs, watts, mjy, psd_leahy, or psd_rms
%   xlabel : String with new X-axis label
%   ylabel : String *array* (up to 9 elements) with new Y-axis labels.
%            Order of the array *must* be: 
%             [plot_data, plot_unfold(power=0->3),plot_counts(power=0->3)]
%   rlabel : String *array* (up to 3 elements) with new Y-axis labels for
%            residuals.  Order of the the array *must* be: 
%             [chi, chi^2, ratio]
%   clabel : String Array with new Cash statistic labels [res=1 or 4, 2 or 5,
%            which yield +/-sqrt(|Delta C|), Delta C, respectively]
%   mllabel: String Array with new Maximum Likelihood statistic labels [res=1 or 4, 
%            2 or 5, which yield +/-sqrt(|Delta ML|), Delta ML, respectively]
%   vlabel : String with new Doppler velocity X-axis label
%   zlabel : String with new Redshift X-axis label
%   pg_font: "\\\\fn", "\\\\fr", "\\\\fi", "\\\\fs" = normal, roman, italic,
%            or script fonts will be used on the labels (Default is \\\\fr.)
%\seealso{set_plot_labels, fancy_plot_unit, add_plot_unit}
%!%-
{
   variable str,xunit,yunit,lbl,lbly,xlbls,ylbls,ly,rlbls,lr,nvlbl,nredlbl,cashlbl;

   switch(_NARGS)
   {
      case 1:
      xunit = ();
      yunit = "photons";
   }
   {
      case 2:
      (xunit,yunit) = ();
   }
   {
      () = fprintf(fp, "%s\n", %%%{{{
`
 new_plot_labels(x_unit [,y_unit];xlabel=string,ylabel=[string],...,
                                   pg_font=string);

 Changes the default labels for plot_counts, plot_data, plot_unfold
 for the different units set by fancy_plot_unit. pg_font string will
 be *prepended* to all inputs. Use any valid pair of units to set residual,
 Cash statistic, or velocity/redshift axis labels.
 Use: 

    set_plot_labels(;pg_font="\\fr") -or- set_plot_labels(;pg_font=``\fr``)

 to restore defaults.

 Inputs:

   x_unit : angstrom,a,nm,um,micron,cm,mm,m, ev,kev,mev,gev,tev,
            hz,khz,mhz,ghz, psd
   y_unit : photons (=default), ergs, watts, mjy, psd_leahy, or psd_rms
   xlabel : String with new X-axis label
   ylabel : String *array* (up to 9 elements) with new Y-axis labels.
            Order of the array *must* be: 
             [plot_data, plot_unfold(power=0->3),plot_counts(power=0->3)]
   rlabel : String *array* (up to 3 elements) with new Y-axis labels for
            residuals.  Order of the the array *must* be: 
             [chi, chi^2, ratio]
   clabel : String Array with new Cash statistic labels [res=1 or 4, 2 or 5,
            which yield +/-sqrt(|Delta C|), Delta C, respectively]
   mllabel: String Array with new Maximum Likelihood statistic labels [res=1 or 4, 
            2 or 5, which yield +/-sqrt(|Delta ML|), Delta ML, respectively]
   vlabel : String with new Doppler velocity X-axis label
   zlabel : String with new Redshift X-axis label
   pg_font: "\\fn", "\\fr", "\\fi", "\\fs" = normal, roman, italic,
            or script fonts will be used on the labels (Default is \\fr.)
`                       );        %%%}}}
      return;
   }

   lbl  = strlow(xunit);
   lbly = strlow(xunit+yunit);
   xlbls   = qualifier("xlabel", NULL);
   ylbls   = qualifier("ylabel", NULL);
   rlbls   = qualifier("rlabel", NULL);
   nvlbl   = qualifier("vlabel", NULL);
   nredlbl = qualifier("zlabel", NULL);
   cashlbl = qualifier("clabel", NULL);
   mllbl   = qualifier("mllabel", NULL);
   pg_font = qualifier("pg_font",`\fr`);
   pg_font = qualifier("pgfont", pg_font);

   ifnot(assoc_key_exists(ylbl,lbly))
   {
      () = fprintf(fp, "\n%s\n", %{{{
`  Unrecognized combination of X- and Y-units. Define them with: 

   add_plot_unit(xunit,yunit;xscale=val,yscale=val);
`                  );            %}}}
      return;
   }

   if(xlbls != NULL)
   {
      xlbls=string([xlbls][0]); 
      xlbl[lbl] = pg_font+xlbls;
   }

   if(ylbls != NULL)
   {
      ylbls = [ylbls];
      ly = length(ylbls);
      if(ly>9){ ly = 9; }   

      ylbl[lbly][[0:ly-1]] = pg_font+ylbls[[0:ly-1]];
   }

   if(rlbls != NULL)
   {
      rlbls = [rlbls];
      lr = length(rlbls);
      if(lr>3){ lr = 3; }   

      rlbl[[0:lr-1]] = pg_font+rlbls[[0:lr-1]];
      rlbl[[4:4+lr-1]] = pg_font+rlbls[[0:lr-1]];
   }

   if(cashlbl != NULL)
   {
      cashlbl=string([cashlbl]); 
      clbl = pg_font+[clbl,clbl];
   }

   if(mllbl != NULL)
   {
      mllbl=string([mllbl]); 
      mllbl = pg_font+[mllbl,mllbl];
   }

   if(nvlbl != NULL)
   {
      nvlbl=string([nvlbl][0]); 
      vlbl = pg_font+nvlbl;
   }

   if(nredlbl != NULL)
   {
      nredlbl=string([nredlbl][0]); 
      redlbl = pg_font+nredlbl;
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define add_plot_unit()
%!%+
%\function{add_plot_unit}
%\synopsis{Create a new X-unit,Y-unit pair for isis_fancy_plots package}
%\usage{add_plot_unit(String_Type, String_Type [; ]);}
%\qualifiers{
%\qualifier{SEE BELOW}{}
%}
%\description
%
% add_plot_unit(xunit, yunit; xscale=val, yscale=val, is_energy=val,
%                             xlabel=str, ylabel=str, pgfont=str);
%
% Create a new X-unit and Y-unit pair for plot_counts, plot_data, plot_unfold,
% and plot_fit_model.  (yunit and yscale only affect plot_unfold; plot_counts
% and plot_data are only sensitive to the choice of xunit.) Set is_energy=1 if
% the xunit scales as keV (otherwise it defaults to scaling as Angstroms). xscale
% is the scaling of keV/xunit or A/xunit.  yscale scales *all* of the y-axes in
% the plot_unfold plots, so it must be set appropriately to achieve a desired
% effect.  xunit and yunit will be treated as lower case regardless of input.
% Note that existing X-units will not be overwritten; their already defined
% values will be used regardless of input.  A set of default axis labels will
% be produced, with "ylabel" substituting for:
%
%       "Photons cm^{-2} s^{-1}"   (the default)
%
% However, these labels can be rewritten using the new_plot_labels command.
%
% To get the scalings correct, remember that plot_unfold(...;power=2) is always
% photons/s/cm^2 in the absence of scalings, power=0 is proportional to flux
% for wavelength based X-units, while power=3 is proportional to flux for energy
% based units.  For these latter two cases, the yscale needs to account for
% divisions/multiplications of the scaled X-unit.
%
% Examples:
%
% To produce mJy vs. THz plots, use:
%
%    add_plot_unit("thz", "mjy"; xscale=Const_eV/Const_h*1.e12,
%                  yscale=Const_h*1.e26, xlabel="THz", ylabel="mJy/THz");
%
% Const_eV/Const_h*1.e12 ~ 4.14e-3 is keV per Terra-Hz
% plot_unfold(...;power=2) produces photons/s/cm^2 =>
%    (photons*xunit)/s/cm^2/xunit  (xunit scaling cancels out)
%
% We wish to convert this to mJy:
%
%    (photons*xunit/s/cm^2/xunit) =
%    [photons*(1.e-26 ergs)*Hz/(1.e-26 ergs)]/s/cm^2/Hz =
%    Hz/(1.e-26 ergs)*mJy
%
% hence multiplying by yscale=(1.e-26 ergs)/Hz = 1.e26*Const_h
% produces the desired scaling for plot_unfold.
%
% To produce BTU/Acre/s vs. keV plots, use:
%
% plot_unfold(...;power=3) for X-unit=keV produces keV/s/cm^2,
% which we wish to convert to BTU/Acre/s, hence xscale=1 and:
%
%    erg_p_btu = 1.055056e10                    % ISO ergs/BTU
%    cmsq_p_a = 4.0468564224e7                  % cm^2 per international acre
%    yscale = cmsq_p_a*Const_eV*1.e3/erg_p_btu  % cm^2/Acre*BTU/keV
%
% To achieve this same Y-unit vs. other energy based X-units,
% multiply yscale by keV/xunit, i.e., the value of xscale.
%\seealso{fancy_plot_unit, set_plot_labels, new_plot_labels}
%!%-
{
   variable xunit, yunit, xlbls, ylbls, xscl, is_en, pgfont;
   switch(_NARGS)
   {
      case 2:
      (xunit,yunit) = ();
      xunit = strlow(xunit);
      yunit = strlow(yunit);
      if(assoc_key_exists(ylbl,xunit+yunit))
      {
         () = fprintf(fp, "\n X-unit/Y-unit pair already exists\n");
         return;
      }
      xlbls = qualifier("xlabel","X");
      ylbls = qualifier("ylabel",`Photons cm\u-2\d s\u-1\d `);
      pgfont = qualifier("pgfont",`\fr`);
      is_en = int(qualifier("is_energy",0));
      if(is_en != 1 && is_en != 0){ is_en = 0; }
      xscl = qualifier("xscale",1.);
      y_scl_norm[xunit+yunit] = qualifier("yscale",1.);
      if(unit_exists(xunit))
      {
         xlbls = unit_info.name;
      }
      else
      {
         unit_add(xunit,is_en,xscl);
         xlbl[xunit] = pg_font + xlbls;
      }

      ylbl[xunit+yunit]
       = [pg_font
         +[`Counts s\u-1\d ` + xlbls + `\u-1\d`,
            xlbls + `\u-1\d `+ ylbls + xlbls + `\u-1\d`,
                               ylbls,
            xlbls +            ylbls,
            xlbls + `\u2\d ` + ylbls + xlbls + `\u-1\d`,  %%% <- Mh: The last `\u-1\d` is wrong, I guess.
                         "Counts/bin/"+xlbls,
                         "Counts/bin",
            xlbls +      " Counts/bin",
            xlbls + `\u2\d Counts/bin`
          ],
         ylbls];
   }
   {
      ()=fprintf(fp, "%s\n", %{{{
`
 add_plot_unit(xunit, yunit; xscale=val, yscale=val, is_energy=val,
                             xlabel=str, ylabel=str, pgfont=str);

 Create a new X-unit and Y-unit pair for plot_counts, plot_data, plot_unfold,
 and plot_fit_model.  (yunit and yscale only affect plot_unfold; plot_counts
 and plot_data are only sensitive to the choice of xunit.) Set is_energy=1 if
 the xunit scales as keV (otherwise it defaults to scaling as Angstroms). xscale
 is the scaling of keV/xunit or A/xunit.  yscale scales *all* of the y-axes in
 the plot_unfold plots, so it must be set appropriately to achieve a desired
 effect.  xunit and yunit will be treated as lower case regardless of input.
 Note that existing X-units will not be overwritten; their already defined
 values will be used regardless of input.  A set of default axis labels will
 be produced, with "ylabel" substituting for:

       "Photons cm\u-2\d s\u-1\d"   (the default)

 However, these labels can be rewritten using the new_plot_labels command.

 To get the scalings correct, remember that plot_unfold(...;power=2) is always
 photons/s/cm^2 in the absence of scalings, power=0 is proportional to flux
 for wavelength based X-units, while power=3 is proportional to flux for energy
 based units.  For these latter two cases, the yscale needs to account for
 divisions/multiplications of the scaled X-unit.

 Examples:

 To produce mJy vs. THz plots, use:

    add_plot_unit("thz", "mjy"; xscale=Const_eV/Const_h*1.e12,
                  yscale=Const_h*1.e26, xlabel="THz", ylabel="mJy/THz");

 Const_eV/Const_h*1.e12 ~ 4.14e-3 is keV per Terra-Hz
 plot_unfold(...;power=2) produces photons/s/cm^2 =>
    (photons*xunit)/s/cm^2/xunit  (xunit scaling cancels out)

 We wish to convert this to mJy:

    (photons*xunit/s/cm^2/xunit) =
    [photons*(1.e-26 ergs)*Hz/(1.e-26 ergs)]/s/cm^2/Hz =
    Hz/(1.e-26 ergs)*mJy

 hence multiplying by yscale=(1.e-26 ergs)/Hz = 1.e26*Const_h
 produces the desired scaling for plot_unfold.

 To produce BTU/Acre/s vs. keV plots, use:

 plot_unfold(...;power=3) for X-unit=keV produces keV/s/cm^2,
 which we wish to convert to BTU/Acre/s, hence xscale=1 and:

    erg_p_btu = 1.055056e10                    % ISO ergs/BTU
    cmsq_p_a = 4.0468564224e7                  % cm^2 per international acre
    yscale = cmsq_p_a*Const_eV*1.e3/erg_p_btu  % cm^2/Acre*BTU/keV

 To achieve this same Y-unit vs. other energy based X-units,
 multiply yscale by keV/xunit, i.e., the value of xscale.
`); %}}}
   }
   return;
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define fancy_plot_unit( )
%!%+
%\function{fancy_plot_unit}
%\synopsis{Change the x-axis, and possibly the y-axis units, in the isis_fancy_plots package.}
%\usage{fancy_plot_unit( String_Type [, String_Type]);}
%\description
%
% fancy_plot_unit(xunit [,yunit]);
%
% Change the X-axis plot units to "xunit" (as for the ISIS command
% plot_unit; and change the Y-axis unit to "yunit" (default yunit=
% "photons").  These will be used for the functions: plot_counts,
% plot_data, plot_unfold, plot_fit_model. Unit names are case insensitive.
%
% Available X-units:
%
%      eV, keV, MeV, GeV, TeV,
%      Angstrom, A, nm, um, mm, cm, m,
%      Hz, kHz, MHz, GHz,
%      psd   (used for plotting power spectra from SITAR)
%
% Available Y-units:
%
%      photons (default), mJy, ergs, watts, psd_leahy, psd_rms
%
% Units added via add_plot_unit are also supported.
%
% **NOTE**: Y-units photons/mJy/ergs/watts affect only plot_unfold, while
% psd_* are for plot_counts, but will also affect plot_data/plot_unfold.
%
% Fundamentally, power=1 is proportional to photons/cm^2/s/xunit
% (plot_unfold) or Counts/bin (plot_counts), with higher (lower) powers
% multiplying (dividing) by xunit. plot_data is always Counts/sec/xunit
% ("power" has no effect).
%
% mJy: y-unit for plot_unfold/power=2 is mJy.
%
% ergs: y-unit for plot_unfold/power=3 (xunit=keV, etc.) or power=1
%       (xunit=A, etc.) is ergs/cm^2/sec.
%
% watts: Similar behavior to the ergs unit, but yielding Watts/cm^2.
%
% psd_leahy/psd_rms are for use with SITAR timing routines, and plot
% Power Spectra in Leahy or (RMS/Hz)^2 units vs. Hz, using plot_counts.
%\seealso{plot_unit, add_plot_unit, set_plot_labels, new_plot_labels}
%!%-
{
 variable x_unit_arg, y_unit_arg;
 switch(_NARGS)
 {
  case 1:
    x_unit_arg = ();
    y_unit_arg = "photons";
 }
 {
  case 2:
    (x_unit_arg,y_unit_arg) = ();
 }
 {    ()=fprintf(fp, "%s\n", %{{{
`
 fancy_plot_unit(xunit [,yunit]);

 Change the X-axis plot units to "xunit" (as for the ISIS command
 plot_unit; and change the Y-axis unit to "yunit" (default yunit=
 "photons").  These will be used for the functions: plot_counts,
 plot_data, plot_unfold, plot_fit_model. Unit names are case insensitive.

 Available X-units:

      eV, keV, MeV, GeV, TeV,
      Angstrom, A, nm, um, mm, cm, m,
      Hz, kHz, MHz, GHz,
      psd   (used for plotting power spectra from SITAR)

 Available Y-units:

      photons (default), mJy, ergs, watts, psd_leahy, psd_rms

 Units added via add_plot_unit are also supported.

 **NOTE**: Y-units photons/mJy/ergs/watts affect only plot_unfold, while
 psd_* are for plot_counts, but will also affect plot_data/plot_unfold.

 Fundamentally, power=1 is proportional to photons/cm^2/s/xunit
 (plot_unfold) or Counts/bin (plot_counts), with higher (lower) powers
 multiplying (dividing) by xunit. plot_data is always Counts/sec/xunit
 ("power" has no effect).

 mJy: y-unit for plot_unfold/power=2 is mJy.

 ergs: y-unit for plot_unfold/power=3 (xunit=keV, etc.) or power=1
       (xunit=A, etc.) is ergs/cm^2/sec.

 watts: Similar behavior to the ergs unit, but yielding Watts/cm^2.

 psd_leahy/psd_rms are for use with SITAR timing routines, and plot
 Power Spectra in Leahy or (RMS/Hz)^2 units vs. Hz, using plot_counts.
`); %}}}
    return;
 }

 x_unit_arg=strlow(x_unit_arg);
 y_unit_arg=strlow(y_unit_arg);

 ifnot(assoc_key_exists(ylbl,x_unit_arg+y_unit_arg))
 {
    ()=fprintf(fp, "%s\n", %{{{
`
 X-unit, Y-unit pair does not exist.
 Use add_plot_unit(); to create them.
`             );            %}}}
    return;
 }
 % else: arguments are okay.
 x_unit = x_unit_arg;
 y_unit = y_unit_arg;

 if(x_unit == "psd")
 {
    plot_unit("kev");
 }
 else if(x_unit == "micron")
 {
    plot_unit("um");
 }
 else
 {
    () = fprintf(fp, "\n Also setting ISIS intrinsic plot units to: %s \n\n",x_unit);
    try{ plot_unit(x_unit); } % Try to set all ISIS plots to the X_unit
    catch AnyError: 
    { () = fprintf(fp, "\n Unit not recognized by ISIS intrinsic plot routines. \n\n"); }
 }

 y_scl=y_scl_norm[x_unit+y_unit];

 return;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% pd will store the plotted data.  There will be one Array_Type or
% List_Type index for each input data set or group.  Data/models only
% need a single array for each (they are either single data sets, or
% combined).  Residuals need lists to hold an array for each
% combination member.

private define pd_set(indx,indx_ln,ary_sze)
{
   variable pfield, i, j, a;

   variable list=[ "index", "file", "dlo", "dhi", "dval", "derr", 
                   "model_on", "mlo", "mhi", "mval", "weight",
                   "instrument", "grating", "order", "part"];
   
   foreach pfield (list)
   {
      set_struct_field( pd, pfield, Array_Type[indx_ln] );
   }

   pd.xaxis = "NONE";
   pd.yaxis = "NONE";
   pd.raxis = "NONE";
   pd.exp = Double_Type[indx_ln];

   pd.res = array_map(List_Type,&__pop_list,Char_Type[indx_ln]);
   pd.res_m = array_map(List_Type,&__pop_list,Char_Type[indx_ln]);
   pd.res_p = array_map(List_Type,&__pop_list,Char_Type[indx_ln]);

   pd.con_mod = 1;  % Unfolded model defaults to smeared by response

   _for i (0,indx_ln-1,1)
   {
      pd.file[i] = String_Type[ary_sze[i]];
      pd.instrument[i] = String_Type[ary_sze[i]];
      pd.grating[i] = String_Type[ary_sze[i]];
      pd.index[i] = Integer_Type[ary_sze[i]];
      pd.order[i] = Integer_Type[ary_sze[i]];
      pd.part[i] = Integer_Type[ary_sze[i]];
      pd.model_on[i] = ["      no"];

      _for j (0,ary_sze[i]-1,1)
      {
         pd.index[i][j]=[indx[i]][j];
         a = get_data_info([indx[i]][j]);
         pd.file[i][j] = a.file+"/part="+string(a.part)
                         +"/order="+string(a.order);
         pd.instrument[i][j] = a.instrument;
         pd.grating[i][j] = a.grating;
         pd.order[i][j] = a.order;
         pd.part[i][j] = a.part;
      }
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%

private define p_reset()
{
   set_plot_options(plopt);
   ifnot(no_reset) multiplot(1);
}  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define multiplotit(res)
{
   if(res) multiplot([3,1]);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define vaxis(i,bin_lo,bin_hi)
{
   if(unit_info(x_unit).is_energy)
   {
      if(vzero!=NULL)  % Velocity/redshift X-axis relative to vzero
      {
         zhi = (vzero-bin_lo)/bin_lo;
         zlo = (vzero-bin_hi)/bin_hi;

         if(zaxis)
         {
            bin_lo=zlo;
            bin_hi=zhi;
            xlabel(redlbl);
         }
         else 
         {
            bin_lo = ((zlo+1)^2-1)/((zlo+1)^2+1)*Const_c/1.e5;
            bin_hi = ((zhi+1)^2-1)/((zhi+1)^2+1)*Const_c/1.e5;
            xlabel(vlbl);
         }

      }
      else  % Or just redshift the existing X-axis
      {
         bin_lo = bin_lo*(1+zshift[i]);
         bin_hi = bin_hi*(1+zshift[i]);
      }      
   }
   else
   {
      if(vzero!=NULL) % Velocity/redshift X-axis relative to vzero
      {
         zlo = (bin_lo-vzero)/vzero;
         zhi = (bin_hi-vzero)/vzero;

         if(zaxis)
         {
            bin_lo=zlo;
            bin_hi=zhi;
            xlabel(redlbl);
         }
         else
         {
            bin_lo = ((zlo+1)^2-1)/((zlo+1)^2+1)*Const_c/1.e5;
            bin_hi = ((zhi+1)^2-1)/((zhi+1)^2+1)*Const_c/1.e5;
            xlabel(vlbl);
         }
      }
      else  % Or just redshift the existing X-axis
      {
         bin_lo = bin_lo/(1+zshift[i]);
         bin_hi = bin_hi/(1+zshift[i]);
      }
   }  
   return bin_lo, bin_hi;
}     

%%%%%%%%%%%%%%%%%%%

private define I(n)
{
   return n;
}

private variable _revr = [&I, &reverse], _rev;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define make_exp_and_back(hist_index)
{
   variable arfinfo,expos,scl,rb,nt,unbin_back,bin_back,rebin_back,iw;
   variable dscl = get_data_backscale(hist_index);
   variable dexp = get_data_exposure(hist_index); 
   variable bscl = get_back_backscale(hist_index);
   variable bexp = get_back_exposure(hist_index);

   if(bexp == NULL || bscl == NULL || bexp == 0 || min([bscl]) == 0)
   {
      scl = 1.;  % Throw our hands up and concede defeat
   }
   else 
   {
      scl = (dexp*dscl)/(bexp*bscl);
      if(1 < length(dscl)==length(scl))  % if dscl is an array
        scl[where(dscl==0)] = 0;         %   fix possible 0/0 = NaN elements
   }

   % Is scl a vector?  If yes, must bin to the data, such that
   % \sum_group scl*B_scaled = scl'*\sum_group*Bscl

   if(length(scl)>1)
   {
      % First, store the current binning, then unbin the data

      bin_back = get_back(hist_index);

      if(bin_back != NULL && length(bin_back)>1)
      {
         rb = get_data_info(hist_index).rebin;
         nt = get_data_info(hist_index).notice_list;
         rebin_data(hist_index,0);
         unbin_back = get_back(hist_index);

         % Multiply the unbinned, scaled background by scale, then bin
         rebin_back = rebin_array(scl*unbin_back,rb);
         scl = Double_Type[length(rebin_back)];   

         % Only compute scale where bin_back !=0
         iw = where(bin_back != 0);
         scl[iw] = rebin_back[iw]/bin_back[iw];

         % Set the data right again
         rebin_data(hist_index,rb);
         ignore(hist_index);
         notice_list(hist_index,nt);
      }
   }

   expos=dexp;
   arfinfo = get_data_info(hist_index).arfs[0];
   if(arfinfo != 0)
   {
      expos = get_arf_exposure(arfinfo);
      if(expos==NULL || expos<=0.) 
      {
         expos = dexp;
      }
   }

   return expos, scl;
}   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private variable pscale=1;

public define set_power_scale()
%!%+
%\function{set_power_scale}
%\synopsis{Determine the y-axis is scaled by energy when using the isis_fancy_plot package.}
%\usage{set_power_scale(Integer_Type);}
%\description
%set_power_scale(a);  
%
%  Determine how the y-axis is scaled by energy or wavelength when using
%  the fancy_plot routines. a=1, E|lambda is set to the midpoint of the 
%  bin. a=2, E|lambda is set to the geometric midpoint (i.e., sqrt(Elo*Ehi)).
%  a=3, E|lambda is set to the average value assuming an x^-2 powerlaw.
%  Any other values, and this message is printed.
%\seealso{fancy_plot_unit, add_plot_unit, plot_unfold, plot_counts}
%!%-
{
   variable a = 4;
   if(_NARGS==1)
   {
      a = ();
      a = int(a);
      if(a != 1 && a != 2 && a !=3) a = 4;
   }
   switch(a)
   {case 1: pscale=1; return; }
   {case 2: pscale=2; return; }
   {case 3: pscale=3; return; }
   {case 4:
      () = fprintf(fp, "\n%s\n", %{{{
`
set_power_scale(a);  

  Determine how the y-axis is scaled by energy or wavelength when using
  the fancy_plot routines. a=1, E|lambda is set to the midpoint of the 
  bin. a=2, E|lambda is set to the geometric midpoint (i.e., sqrt(Elo*Ehi)).
  a=3, E|lambda is set to the average value assuming an x^-2 powerlaw.
  Any other values, and this message is printed.
`
 %}}}
      );
      () = fprintf(fp, "   Current setting = %2i\n\n",pscale);
   }
}

private define power_scale(lo,hi,power)
{
   variable pow;
   switch(power)
   { case 0:
      switch(pscale)
      { case 1:      pow =  2./(lo+hi);                    }
      { case 2:      pow =  1./sqrt(lo*hi);                }
      { case 3:      pow =  (1-(lo/hi)^3)/(1-lo/hi)/lo/3.; }
   }
   { case 1:         pow = ones( length(lo) );             }
   { case 2: 
      switch(pscale)
      { case 1:      pow = (lo+hi)/2.;                     }
      { case 2:      pow = sqrt(lo*hi);                    }
      { case 3:      pow = lo*hi/(hi-lo)*log(hi/lo);       }
   }
   { case 3:
      switch(pscale)
      { case 1:      pow = sqr((lo+hi)/2.);                }
      { case 2 or 3: pow = (lo*hi);                        }
   }
   return pow;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define make_data(iindx,res,power,modc,bkgon,rescl)
{
   % Create the X-axis data (can be overridden with Velocity axis)

   % Manfred Hanke wants this done once, outside the loop *and* wants
   % error checking that all data sets have the same grid.  I actually
   % want to allow munging of the grids for things that are close, but
   % not exact, matches (e.g., HEXTE). I know, it's dangerous...

   variable unit_info_x = unit_info(x_unit);
   variable data = get_data_counts(iindx[0]);
   variable bin_lo = data.bin_lo;
   variable bin_hi = data.bin_hi;

   % Flip to energy, but don't reverse quite yet
   if(unit_info_x.is_energy)
     (bin_lo,bin_hi) = (_A(1)/bin_hi, _A(1)/bin_lo);

   bin_lo /= unit_info_x.scale;
   bin_hi /= unit_info_x.scale;

   % Powers of x to multiply against y-axis
      
   variable pow = power_scale(bin_lo,bin_hi,power); 

   % Noticed data indices
   variable dnote = get_data_info(iindx[0]).notice;    

   bkgon = int(bkgon);                                 % Background subtraction?
   variable meth = strtok(get_fit_statistic,";=")[-1]; % Fit Method

   % Running totals of plot variables
   variable tdata=0., tmodl=0., ters=0., tders=0., tbers=0., tbgd=0., texpos=0.;

   variable i; 
   foreach i (iindx)
   {
      data = get_data_counts(i);                   % Data (on wavelength grid)
      variable sys_err_frac = get_sys_err_frac(i); % Systematic errors
      variable sys_err2 = length(sys_err_frac)   
                         ? (sys_err_frac*data.value)^2
                         : 0;

      % Arf exposure and data backscale - the latter can exist
      % independently of an actual background

      variable expos, bdscl;
      (expos, bdscl) = make_exp_and_back(i);

      variable bgd = get_back(i);                  % The background, if it exists

      if(bgd == NULL)
      {
         bgd = Float_Type[length(data.value)];
         bdscl=0.;
      }

      variable modl;
      if(modc > 0) 
      {
         % Running total of model kept separate in case none defined
         modl = get_model_counts(i).value;

         % In ISIS, "background subtraction" does not affect defintion
         % of chi^2 derived from model counts, so tmodl suffices
   
         tmodl += modl; 
      }
      else
      {
         tmodl  += 0.*data.value;  % Make sure modl comes back as array, even
                                    % if empty (avoids various modc=0 checks)
      }

      % ... However, "background subtraction" does affect definition of
      % data error bars.  It increases the data error bars, and is 
      % *always* part of chi^2, if using data as definition of sigma

      variable ders = sqr( meth == "gehrels"
                           ? 1.+sqrt(data.err^2+0.75)
                           : data.err
                         ) + sys_err2;

      % Running total of exposure, data, data errors, and background
      % Note that we "undo" background error for *data*, if including
      % the background in the data plot.
      texpos += expos;
      tdata  += data.value; 
      tders  += ders;
      tbgd   += bgd;
      tbers  += bdscl*bgd;
   }

   if( meth == "model" && modc > 0 )
   {
      ters = tmodl;  % Residuals calculated from model errors
   }
   else
   {
      % Residuals always have background errors, if using data...
      ters = tders+tbers; % ...or data errors, if model not defined/chosen
   }

   % ... but data only have background errors if subtracting background
   ifnot(bkgon) tders += tbers; 

   ters  = sqrt(ters);
   tders = sqrt(tders);
   tbers = sqrt(tbers);

   % Reverse all arrays, if energy unit.
   variable r;
   if(unit_info_x.is_energy) 
     foreach r ([&bin_lo, &bin_hi, &pow, &dnote,
                 &tdata, &tmodl, &ters, &tders, &tbers, &tbgd])
            @r = reverse(@r);

   % Rescale everything
   tdata *= rescl[0]; tders *= rescl[0]; ters *= rescl[0]; tbgd *= rescl[0];
   tbers *= rescl[0]; tmodl *= rescl[0]; 

   variable perunit = ( bin_hi - bin_lo )*texpos;

#ifexists get_bin_corr_factor
   % --- Added by Remeis group, Thomas Duaser: new; for FERMI data ---
   if (get_bin_corr_factor(i) != NULL)
     perunit *= get_bin_corr_factor(i);
   % -------------------------------
#endif

   %  Make sure we only plot where data & model are well-defined

   variable iw;
   if(res <= 0 || modc == 0)
   {
      iw = where(dnote !=0);   % No residuals or no model
   }
   else if(res == 1 || res == 2 || res == 4 || res == 5)
   {
      iw = where(dnote != 0 and ters > 0.); % Chi/chi^2 residuals
   }
   else   % Ratio residuals, which need model defined & !=0
   {
      if( meth == "model" && modc > 0 )
      {
         iw = where(dnote != 0 and tmodl-tbgd-ters > 0.);
      }
      else
      {
         iw = where(dnote != 0 and tmodl-tbgd > 0.); 
      }
   }

   variable resd=0, mres=0, pres=0;
   if(modc > 0)
   {
      switch(res)
      {
       case 3 or case 6:                 % Ratio residuals
         resd = ones(length(tdata))*1.;
         mres = @resd;
         pres = @resd;
       
         % If background not subtracted, ratio the total data & model counts
         if( meth == "model" )
         {
            resd[iw] = (tdata[iw]-(1-_max(0,bkgon))*tbgd[iw])/
                       (tmodl[iw]-(1-_max(0,bkgon))*tbgd[iw]);
            pres[iw] = (tdata[iw]-(1-_max(0,bkgon))*tbgd[iw])/
                       (tmodl[iw]-(1-_max(0,bkgon))*tbgd[iw]-ters[iw]);
            mres[iw] = (tdata[iw]-(1-_max(0,bkgon))*tbgd[iw])/
                       (tmodl[iw]-(1-_max(0,bkgon))*tbgd[iw]+ters[iw]);
         }
         else
         {
            resd[iw] = (tdata[iw]-(1-_max(0,bkgon))*tbgd[iw])/
                       (tmodl[iw]-(1-_max(0,bkgon))*tbgd[iw]);
            mres[iw] = (tdata[iw]-(1-_max(0,bkgon))*tbgd[iw]-ters[iw])/
                       (tmodl[iw]-(1-_max(0,bkgon))*tbgd[iw]);
            pres[iw] = (tdata[iw]-(1-_max(0,bkgon))*tbgd[iw]+ters[iw])/
                       (tmodl[iw]-(1-_max(0,bkgon))*tbgd[iw]);
         }
      }
      {
       case 1 or case 2 or case 4 or case 5:  % Chi/Chi^2 residuals
         resd = ones(length(tdata))*1.;
         mres = @resd;
         pres = @resd;
         resd[iw] = (tdata[iw] - tmodl[iw]) / ters[iw];
         mres[iw] = resd[iw] - 1.;
         pres[iw] = resd[iw] + 1.;
     
         if(res == 2 || res == 5)
         {
            resd = sign(resd) * resd^2;
            mres = sign(mres) * mres^2;
            pres = sign(pres) * pres^2;
         }   

         variable iww, sgn_resd;

         if(meth=="cash") % Override Chi/Chi^2 if Cash statistics chosen
         {
            iww = where(tdata[iw] > 0);
            sgn_resd = sign(resd[iw])*2;
            resd[iw]= (tmodl[iw]-tdata[iw]);

            if(length(iww)>0)
            {
               resd[iw[iww]] += tdata[iw[iww]]*
                                  log(tdata[iw[iww]]/tmodl[iw[iww]]);
            }
            resd[iw] *= sgn_resd;

            if(res == 1 || res == 4) resd[iw] /= sqrt(abs(resd[iw]));
         }

         if(meth=="ml") % Override Chi/Chi^2 if Maximum Likelihood statistics chosen
         {
            iww = where(tmodl[iw] > 0);
            sgn_resd = sign(resd[iw])*2;
            resd[iw]= tmodl[iw] + log(tdata[iw]+1);

            if(length(iww)>0)
            {
               resd[iw[iww]] -= tdata[iw[iww]]*log(tmodl[iw[iww]]);
            }
            resd[iw] *= sgn_resd;

            if(res == 1 || res == 4) resd[iw] /= sqrt(abs(resd[iw]));
         }
      }
   }

   ifnot( bkgon )  % Leave the background in, or subtract it  
   {
      tdata = (tdata-tbgd)*pow;
      if(modc > 0) tmodl = (tmodl-tbgd)*pow;
   }
   else if(bkgon < 0)
   {
      tdata = tbgd*pow;
      tders = tbers;
   }
   else
   {
      tdata = tdata*pow;
      if(modc > 0) tmodl = tmodl*pow;
   }

   tders = tders*pow;

   if(pd_mean_not_sum !=0)  % Sum or average the exposures.
   {
	perunit=perunit/length(iindx);
   }
   return bin_lo,bin_hi,tdata,[tmodl],tders,iw, % Used by plot_counts/unfold
          perunit,[resd],[mres],[pres],         % Used by plot_data/residuals
          texpos;                               % Info Moritz wanted
}

%%%%%%%%%%%%%%%%%%%%%%%%%%

private define hp_loop(iw)
{
   variable wiw, ja, jb;
   wiw = where( (iw - shift(iw,-1)) > 1 );
   if(length(wiw) != 0)
   {
      ja = [0,wiw];
      jb = [wiw-1,length(iw)-1];
   }
   else
   {
      ja = [0];
      jb = [length(iw)-1];
   }
   return ja, jb;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define hp_loopit(xl,xh, y, color, iw, ja, jb, gaptest)
{
   pointstyle(-1);
   variable jj, diw;
   variable plt_opts=get_plot_options;
   variable minx=plt_opts.xmin;
   variable maxx=plt_opts.xmax;
   variable miny=plt_opts.ymin;
   variable maxy=plt_opts.ymax;

   if(gaptest)
   {
      _for jj (0,length(ja)-1,1)
      {
         diw = iw[[ja[jj]:jb[jj]]];
         if(    any(minx <= xl[diw] <= maxx)
             && any(minx <= xh[diw] <= maxx)
             && any(miny <=  y[diw] <= maxy) )
         {
            ohplot( xl[diw], xh[diw], y[diw], color );
         }
      }
   } 
   else
   {
      if(    any(minx <= xl[iw] <= maxx)
          && any(minx <= xh[iw] <= maxx)
          && any(miny <=  y[iw] <= maxy) )
      {
         oplot( (xl[iw]+xh[iw])/2., y[iw], color );
      }
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define xerplot(res,blo,bhi)
{
   variable xer=0.,vlo,lo,mid,hi,vhi;

   set_line_width(2); linestyle(2); connect_points(-1);

   if ( res == 3 || res == 6 ) xer = 1.;
  
   lo=_max(blo,get_plot_options.xmin); vlo=lo;
   hi=_min(bhi,get_plot_options.xmax); vhi=hi;
   mid=(lo+hi)/2.;

   if(-3.e38 < get_plot_options.xmin < lo)
      vlo=get_plot_options.xmin;

   if(hi < get_plot_options.xmin < 3.e38)
      vhi=get_plot_options.xmax;

   oplot( [vlo,lo,mid,hi,vhi],[xer,xer,xer,xer,xer], 1);

   set_line_width(r_width); linestyle(1);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A kluge to get the autoscaling right for multiple datasets.  Plot
% two small points in white to start the data off.

private define start_plot(axlo, axhi, aylo, ayhi)
{  
   if(oplt!=0) return 1;  % Bug out if this is an overplot
   variable p = get_plot_options, xlo, xhi, ylo, yhi;
   variable xloglo=-3.e38, yloglo=-3.e38;
   if(get_plot_options.logx) xloglo=1.e-38;
   if(get_plot_options.logy) yloglo=1.e-38;
   variable iw = where( axhi >= p.xmin and axlo <= p.xmax and
                        ayhi >= p.ymin and aylo <= p.ymax and
                        axlo > xloglo and aylo > yloglo );

   if(length(iw)==0 || max(abs([p.xmin,p.xmax,p.ymin,p.ymax]))<3.e38)
   {
      return 0;
   }
   else
   {
      xlo = min(axlo[iw]);
      xhi = max(axhi[iw]);
      ylo = min(aylo[iw]);
      yhi = max(ayhi[iw]);
   }

   if(p.ymin > -3.e38) ylo=p.ymin;
   if(p.xmin > -3.e38) xlo=p.xmin;
   if(p.ymax <  3.e38) yhi=p.ymax;
   if(p.xmax <  3.e38) xhi=p.xmax;

   connect_points(0); point_size(0.1); pointstyle(0);
   plot([xlo,xhi],[ylo,yhi],0);
   return 1;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define datplot_err(xm,xp,yy,yp,ym,width,col,isres)
{
   if(width==0 || col==0) return;

   _pgslw(int(width)); _pgsls(1);

   variable xx;

   xx = (xm+xp)/2.;

   if(get_plot_options().logx) 
   { 
      xm[where(xm <= 0)] = 1.e-38;
      xx[where(xx <= 0)] = 2.e-38;
      xp[where(xp <= 0)] = 3.e-38;
      xm = log10(xm); 
      xx = log10(xx); 
      xp = log10(xp); 
   }
   if(get_plot_options().logy) 
   { 
      ym[where(ym <= 0)] = 1.e-38;
      yy[where(yy <= 0)] = 2.e-38;
      yp[where(yp <= 0)] = 3.e-38;
      ym = log10(ym); 
      yy = log10(yy);
      yp = log10(yp); 
   }

   _pgsci(int(col));
   () = _pgerry(length(xx),xx,ym,yp,ebar_y);

   % Only residuals get X-error bars

   if(isres || data_err)
   {
      _pgsci(int(col));
      () = _pgerrx(length(xx),xm,xp,yy,ebar_x);
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define res_set(yrng,res)
{
   variable meth = strtok(get_fit_statistic,";=");
   meth = meth[-1];

   ylin;
   switch (length(yrng))
   {
    case 4:
      yrange(yrng[2],yrng[3]);
   }
   {
    case 3:
      yrange(yrng[2],NULL);
   }
   {
      yrange();
   }
 
   if(ylabl==NULL)
   {
      ylabel(rlbl[abs(res)-1]);
      if(meth=="cash" && (res==1 || res==4))
      {
         ylabel(clbl[0]);
      }
      if(meth=="cash" && (res==2 || res==5))
      {
         ylabel(clbl[1]);
      }
      if(meth=="ml" && (res==1 || res==4))
      {
         ylabel(mllbl[0]);
      }
      if(meth=="ml" && (res==2 || res==5))
      {
         ylabel(mllbl[1]);
      }
   }
   else
   {
      ylabel([ylabl][-1]);
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define resplot(yrng,res,indx,indx_ln,ary_sze,rsym,rcol,bkg)
{
   variable bin_lo,bin_hi,data,modl,ers,resd,mres,pres,iw;
   variable indx_use,i,j,jj,jstop,ja,jb;
   variable meth = strtok(get_fit_statistic,";=");
   meth = meth[-1];

   res_set(yrng,res);

   % If res <= 3, the residuals are to be left uncombined

   if(res > 3)  
   {
      indx_use = indx_ln;
      jstop=Integer_Type[indx_ln];  % Zeros, i.e., only one loop
   }
   else
   {
      indx_use = int(sum(ary_sze));
      jstop=ary_sze-1;              % As many loops as there are data sets
   }

   bin_lo = Array_Type[indx_use];  bin_hi = @bin_lo; 
   resd = @bin_lo; mres = @bin_lo; pres = @bin_lo; iw = @bin_lo;
   variable all_lo=Double_Type[0], all_hi=@all_lo, all_data_lo=@all_lo, 
            all_data_hi=@all_lo, istrt=0;

   jj=0;
   _for i (0,indx_ln-1,1)
   {
      _for j (0,jstop[i],1)
      {
         ifnot(jstop[i])    % Combine the residuals
         {
            (bin_lo[jj], bin_hi[jj],,,,iw[jj],,resd[jj],mres[jj],pres[jj],)= 
               make_data(indx[i],res,1,1,bkg[i],1.*ones(length(indx[i])));
         }
         else               % Don't combine residuals
         {
            (bin_lo[jj], bin_hi[jj],,,,iw[jj],,resd[jj],mres[jj],pres[jj],)= 
               make_data(indx[i][j],res,1,1,bkg[i],[1.]);
         }

         if(vzero!=NULL || zshift[i]!=0.)
         {
            (bin_lo[jj],bin_hi[jj]) = vaxis(i,bin_lo[jj],bin_hi[jj]);
         }

         % Save data to write to ASCII file later

         list_append(pd.res[i],resd[jj][iw[jj]]);
         list_append(pd.res_m[i],mres[jj][iw[jj]]);
         list_append(pd.res_p[i],pres[jj][iw[jj]]);

         pd.dlo[i] = bin_lo[jj][iw[jj]];
         pd.dhi[i] = bin_hi[jj][iw[jj]];

         all_lo = [all_lo,bin_lo[jj][iw[jj]]]; 
         all_hi = [all_hi,bin_hi[jj][iw[jj]]]; 
         all_data_lo = [all_data_lo,mres[jj][iw[jj]]]; 
         all_data_hi = [all_data_hi,pres[jj][iw[jj]]];

         jj++;
      }
   }

   pd.raxis = get_plot_options().ylabel;
   pd.xaxis = get_plot_options().xlabel;

   set_line_width(1);
   istrt = start_plot(all_lo, all_hi, all_data_lo, all_data_hi);

   jj=0;
   _for i (0,indx_ln-1,1)
   {
      _for j (0,jstop[i],1)
      {
         if(res==2 || res==5 || rsym[i][0]==0)   % Histogram plots
         {
            pointstyle(1);
            point_size(0.1);
         }
         else                                    % Data symbol plots
         {
            pointstyle(rsym[i][j]);
            point_size(plopt.point_size);
         }
         connect_points(0);  
         ifnot(min([jj+istrt+oplt,1])) % In case a plot hasn't been started yet...
         {
            slangref = refplt[0];
            @slangref((bin_lo[jj][iw[jj]]+bin_hi[jj][iw[jj]])/2.,resd[jj][iw[jj]],rcol[i][j]);
         }

         ifnot(jj) xerplot(res,min(all_lo),max(all_hi));

         % These should all be histograms without error bars
         if(res==2 || res==5 || ((meth=="cash" || meth=="ml") && (res!=3 && res!=6)))
         {
            connect_points(-1);
            (ja,jb) = hp_loop(iw[jj]);
            hp_loopit(bin_lo[jj], bin_hi[jj], resd[jj], rcol[i][0], iw[jj], ja, jb, 1);
         }
         else if(res==1 || res==3 || res==4 || res==6) % Have error bars, could be hists
         {
            datplot_err(bin_lo[jj][iw[jj]],bin_hi[jj][iw[jj]],resd[jj][iw[jj]],
                        mres[jj][iw[jj]],pres[jj][iw[jj]],re_width,recol[i][j],1);

            point_size(plopt.point_size);
            pointstyle(rsym[i][j]);
            connect_points(0);
            set_line_width(r_width);

            if(rsym[i][j] != 0)   % Plot with symbols
            {
               slangref = refplt[1];
               @slangref((bin_lo[jj][iw[jj]]+bin_hi[jj][iw[jj]])/2.,
                          resd[jj][iw[jj]],rcol[i][j]);	
            }
            else                  % Plot with histograms
            { 
               pointstyle(1);
               connect_points(1);
               (ja,jb) = hp_loop(iw[jj]);
               hp_loopit(bin_lo[jj],bin_hi[jj],resd[jj],rcol[i][j],iw[jj],ja,jb,1);
            }
         }
         jj++;
      }
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define p_range_label(res,power)
{
   % Very important!  I presume plot_bin_integral throughout these 
   % plotting functions!!!

   plot_bin_integral;

   multiplotit(res);

   if(xlabl==NULL)
   {
      xlabel(xlbl[x_unit]);
   }
   else
   {
      xlabel(xlabl);
   }

   if(vzero!=NULL)
   {
      xlin;
   }

   if(length(xrng)>1)
   {
      if((xrng[0]!=NULL) && (xrng[0]<=0))
      {
         xlin;
      }
      xrange(xrng[0],xrng[1]);
   }
   % No else ... so as to respect prior isis> xrange(...); choices,
   % but I will overwrite with new xrange choices.

   plopt = get_plot_options;

   if(ylabl==NULL)
   {
      ylabel(ylbl[x_unit+y_unit][power]);
   }
   else
   {
      ylabel([ylabl][0]);
   }

   if (length(yrng) > 1)
   {
      if((yrng[0]!=NULL) && (yrng[0]<=0))
      {
         ylin;
      }
      yrange(yrng[0],yrng[1]);
   }
   else
   {
      yrange();
   }

   return plopt;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set defaults on plotting parameters

private define make_default(strct,var,var_df,is_list)
{
   % strct holds user inputs, var_df defaults, and var the values to use

   ifnot(is_list) % if shouldn't be a list, make an array
   {
      if(typeof(strct)==List_Type)
      {
         strct = list_to_array(strct);
      }
   }
   if(strct!=NULL) % if value input, assign ...
   {
      @var=strct;
   }
   else
   {
      @var=var_df; % ... otherwise use default
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define trans_strct_and_array(strct,iln,ary,var,var_df)
{
   % strct holds user inputs, var_df defaults, and var the values to use
   % iln is the number of input data groups, ary the # of indices/group

   variable i, lparm, strc_use, lstrc;

   lparm=0;
   if(strct != NULL) lparm = min( [ length(strct), iln ] );

   % Create lists & arrays with default values, but overwrite
   % those portions that have actual user input

   _for i (0,lparm-1,1)    %% Some user input
   {
      strc_use=Integer_Type[ary[i]]+[var_df[i]][0];
      lstrc=length(strct[i]);
      strc_use[[0:min([lstrc-1,ary[i]-1])]]=
         [strct[i]][[0:min([lstrc-1,ary[i]-1])]];
      list_append(@var,strc_use);
   }
   _for i (lparm,iln-1,1)  %% No user input
   {
      strc_use=Integer_Type[ary[i]]+[var_df[i]][0];
      list_append(@var,strc_use);
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define trans_strct(strct,iln,var,var_df)
{  
   % strct holds user inputs, var_df defaults, and var the values to use
   % iln is the number of input data groups

   variable i, lparm;
   if(length(var_df)<iln) % Make sure defaults cover # of data sets
   {
      var_df = {var_df[0]};
      loop(iln-1){ list_append(var_df,var_df[0]); }
   }

   lparm = 0;
   if(strct != NULL) lparm = min( [ length(strct), iln ] );

   _for i (0,lparm-1,1)
   {
      list_append(@var,[strct[i]][0]);
   }
   _for i (lparm,iln-1,1)
   {
      list_append(@var,var_df[i]);
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make arrays into lists (for input)

private define make_array_a_list(a)
{
   variable b, c={};
   foreach b (a)
   {
      list_append(c,b);
   }
   return c;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make all_data into a list

public define data_list()
%!%+
%\function{data_list (isis_fancy_plots package)}
%\synopsis{Turn an array into a list.}
%\usage{data_list(Array);}
%\description
%\seealso{list_to_array}
%!%-
{
   return make_array_a_list(all_data);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The below, in fact, is the way all parameters will ultimately be
% set, and hence has all the error checking.  pstruct is a structure
% variable with the plot options (either input or the defaults), while
% indx is a list with the indices (single values or arrays to be
% combined).

private define set_plot_parms_struct(a, indx_ln, ary_sze)
{
   variable pstruct,i,list,lparm,mcol_df_use,strc_use,lstrc;
    
   pstruct = @a;

   foreach list (parms)
   {
      % An input structure might not have all fields

      ifnot(struct_field_exists( pstruct, list ))
      {
         pstruct = struct_combine( pstruct, list );
      }

      % Qualifiers will overwrite a structure field

      if(qualifier_exists(list))
      {
         set_struct_field(pstruct,list,qualifier(list,NULL));
      }

      % But NULL means "use defaults"

      if(get_struct_field( pstruct, list ) != NULL)
      {
         % Array inputs that should be lists are converted

         if(length(where(list_params==list))!=0)
         {
            if(typeof(get_struct_field(pstruct,list))!=List_Type)
            {
               set_struct_field(pstruct,list,
                   make_array_a_list(get_struct_field(pstruct,list)));
            }
         }
         else if(typeof(get_struct_field(pstruct,list))==List_Type)
         {
            set_struct_field(pstruct,list,
                             list_to_array(get_struct_field(pstruct,list)));
         }
      }
   }

   % No model plotting if models are undefined!

   if( get_fit_fun() != NULL && get_fit_fun() != "null" 
                             && get_fit_fun() != "bin_width(1)" )
   {
      mcol_df_use = mcol_df;
   }
   else
   {
      mcol_df_use = 0;
   }

   dcol={}; decol={}; mcol={}; rcol={}; recol={}; dsym={}; rescale={}; 
   rsym={}; bkg={}; zshift={}; gap={};

   % Transfer structure values over to the variables

   trans_strct(pstruct.dcol,indx_ln,&dcol,dcol_df);
   trans_strct(pstruct.decol,indx_ln,&decol,dcol);
   trans_strct(pstruct.dsym,indx_ln,&dsym,style_df);
   trans_strct(pstruct.mcol,indx_ln,&mcol,mcol_df_use);
   trans_strct(pstruct.zshift,indx_ln,&zshift,0.);
   trans_strct(pstruct.bkg,indx_ln,&bkg,0);
   trans_strct(pstruct.gap,indx_ln,&gap,gap_df);

   % Variables that could have arrays in the input list  

   trans_strct_and_array(pstruct.rcol,indx_ln,ary_sze,&rcol,dcol);
   trans_strct_and_array(pstruct.recol,indx_ln,ary_sze,&recol,rcol);
   trans_strct_and_array(pstruct.rsym,indx_ln,ary_sze,&rsym,dsym);
   trans_strct_and_array(pstruct.scale,indx_ln,ary_sze,&rescale,1.*ones(indx_ln));

   make_default(pstruct.yrange,&yrng,{NULL,NULL,NULL,NULL},1);
   make_default(pstruct.xrange,&xrng,{NULL},1);
   make_default(pstruct.xlabel,&xlabl,NULL,0);
      if(xlabl != NULL) 
      { 
         if(typeof(xlabl)==List_Type) xlabl=list_to_array(xlabl);
         xlabl = [xlabl][0]; 
      }
   make_default(pstruct.ylabel,&ylabl,NULL,0);
      if(ylabl != NULL) 
      { 
         if(typeof(xlabl)==List_Type) ylabl=list_to_array(ylabl);
         ylabl = [ylabl]; 
      }
   make_default(pstruct.power,&power,power_df,0); 
      power=abs(int([power][0]));
      if(power!=0 && power!=1 && power!=2 && power !=3) power=power_df;
   make_default(pstruct.res,&res,0,0); res=abs(int([res][0]));
      if(res!=0 && res!=1 && res!=2 && res!=3 && res!=4 && res!=5 && res!=6) res=0;
   make_default(pstruct.oplt,&oplt,0,0); oplt=abs(int([oplt][0]));
   make_default(pstruct.vzero,&vzero,NULL,0); 
      if(vzero!=NULL){ vzero=abs([vzero][0]); };
   make_default(pstruct.zaxis,&zaxis,0,0); zaxis=abs(int([zaxis][0]));
   make_default(pstruct.con_mod,&use_con_flux,1,0); 
      use_con_flux=abs(int([use_con_flux][0]));
   make_default(pstruct.no_reset,&no_reset,0,0); 
      no_reset=abs(int([no_reset][0]));
   make_default(pstruct.sum_exp,&pd_mean_not_sum,sum_exp_df,0);
      pd_mean_not_sum=abs(int([pd_mean_not_sum][0]-1));
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make sure the input indices form a list, and that any list within
% this list is replaced with an array of combination members, and that
% all indices are integers

private define make_indices(args)
{
   variable i, indx_ln, ary_sze, idx; 
   indx = args[0];
   if(typeof(indx) != List_Type) indx={ indx };

   indx_ln=length(indx);
   ary_sze=Integer_Type[indx_ln];

   _for i (0,indx_ln-1,1)
   {
      if(typeof(indx[i])==List_Type)
      {
         try
         {
            indx[i] = [combination_members(int(abs(indx[i][0])))];
            ary_sze[i] = length(indx[i]);
         }
         catch AnyError:
         {
            indx_ln = 0;
            return indx, indx_ln, ary_sze;
         }
      }
      else
      {
         foreach idx (indx[i])
         {
            try
            {
               indx[i] = int(abs(indx[i]));
               idx = int(abs(idx));
               () = get_data_info(idx).spec_num;
            }
            catch AnyError:
            {
               indx_ln = 0;
               return indx, indx_ln, ary_sze;
            }
         }
         ary_sze[i] = length(indx[i]);
      }
   }

   if(length(args)>2 || (length(args)>1 && typeof(args[-1])!=Struct_Type))
   {
      message(` 
 Multiple input arguments -- only the first will be plotted. Use list:

   plot_data({1,2,3},popt; qualifiers);

 to plot multiple datasets.
`            );
   }   
   return indx, indx_ln, ary_sze;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define set_plot_parms(nargs,args)
{
   variable indx_ln, ary_sze;

   (indx, indx_ln, ary_sze)  = make_indices(args);

   if(nargs > 1 && typeof(args[-1])==Struct_Type)
   {
      % Presume arguments are passed in a structure, but allow qualifiers
      % to overwrite the structure variables

      set_plot_parms_struct(args[-1],indx_ln,ary_sze;;__qualifiers);
   }
   else  % Or modify default structure based upon only qualifier inputs
   {
      set_plot_parms_struct(parm_s,indx_ln,ary_sze;;__qualifiers()); % Set defaults
   }

   return indx, indx_ln, ary_sze;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Strings for option descriptions that we will use many times

private variable ores_descript=
`  Residuals are units of chi, chi2, or ratio, and will be based upon whether
  one chooses sigma=model, data, or gehrels in set_fit_statistic();
  (data error bars are only affected by the latter two).
  set_fit_statistic("cash"); will alter the residuals to the Cash statistic.
  set_fit_statistic("ml"); will alter the residuals to the Maximum Likelihood statistic.
`;
private variable oopts=`
  Options below refer to structure variables/qualifiers

`;
private variable oindx=
`   indx    = list of data set indices to be plotted. Any indices grouped in
             an array within that list will be *combined* in the data plot.
             Single number in list is combo id, {#} = [combination_members(#)].
`;
private variable odcol=
`   dcol    = (pgplot) color value for data (or list of color values)
`;
private variable odecol=
`   decol   = (pgplot) color value for data error bars (or list of color values)
`;
private variable omcol=
`   mcol    = (pgplot) color value for model (or list of color values)
             0 => No model plotted
`;
private variable orcol=
`   rcol    = (pgplot) color value for residuals (or list of color values; arrays
             within the list allow for individual color values if portions of
             the data are combined, but their associated residuals are not)
`;
private variable orecol=
`   recol   = color for residual error bars (or list of color values; arrays
             within the list act as for residual color inputs)
`;
private variable odsym=
`   dsym    = (pgplot) symbol value for data (or list of symbol values)
             0 => histogram plot
`;
private variable orsym=
`   rsym    = (pgplot) symbol value for residuals (or list of symbol values;
             arrays within the list act as for residual color inputs)
             0 => histogram plot
`;
private variable oyrange=
`   yrange  = List of Y-limits for the data & model and (optionally) residuals
`;
private variable oxrange=
`   xrange  = List of X-limits for the data & model & residuals
             Note: Any X- or Y-range set to NULL is autoscaled
`;
private variable ooplt=
`   oplt    = 0 (default) for new plot, !=0 for overplotting
`;
private variable onrst=
`   no_reset= 0 (default)- plots *will* be reset, i.e., next plot moves to new pane
             (multiplot), next plot redraws window (single plot). no_reset=1 necessary
             for overplotting multiplots (oplt=1 sufficient for single plots).
`;
private variable ores=
`   res     = 0 (default), no residuals; 1, 2, or 3 = chi, chi2, or ratio residuals
             4, 5, or 6 = chi, chi2, or ratio, but combine residuals for combined data
             set_fit_method("cash"); or set_fit_method("ml") will cause res=(2 or 5) 
             or res=(1 or 4) to plot the residual for the Cash or Maximum Likelihood 
             statistic or its square root, respectively
`;
private variable obkg=
`   bkg     = List of 0's (subtract background-default), 1's (include backgrounds),
             or -1's (plot *only* the background [no model plotted in this case]).
             Ratio residuals will include background in data/model, other residuals
             are unaffected. Indices within a combination are treated the same.)
`;
private variable oxlabel=
`   xlabel  = String that will overwrite default X-axis label (default=NULL)
`;
private variable oylabel=
`   ylabel  = String or string array that will overwrite the default Y-axis labels
             (second element of array applies to residuals; default=NULL)
`;
private variable ozshift=
`   zshift  = List of redshifts to be applied to the data (default zshift={0,0,...})
`;
private variable ovzero=
`   vzero   = If set, the reference X-unit value to be defined as zero velocity.
             The X-axis then becomes a velocity axis (km/s) referenced to this
             point (default vzero=NULL; setting vzero/zaxis supersedes zshift)
`;
private variable ozaxis=
`   zaxis   = If not 0, use a redshift axis instead of a velocity axis *if* vzero
             is defined (default zaxis=0)
`;
private variable oscale=
`   scale   = Multiplicatively scale the Y-axis by the values in a list.
             Any arrays in the list should hold the individual scalings for
             data set arrays in the input index list.  **Note:**  these values
             only scale the plots, not the fits.  (Default values are 1.)
`;
private variable osum_exp=
`   sum_exp = If==1, then when combining data sets, sum the exposure times (as
             opposed to using the mean exposure time; default sum_exp=1).
`;
private variable ogap=
`   gap     =  1 (default), models are histograms with gaps where data has gaps,
              0          , model are bin-centered lines, without gaps.
`;
%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define plot_counts()
%!%+
%\function{plot_counts}
%\synopsis{Plot counts per bin (isis_fancy_plots package)}
%\description
%
%plot_counts({indx,[arry],{cid}},pstruct);  % pstruct = struct{ dcol, mcol, rcol, ...}
%plot_counts({indx,[arry],{cid}};dcol={val},mcol={val},rcol={val,[arry],val},...);
%
%  Plot background subtracted data, model, and residuals as counts/bin
%  Residuals are units of chi, chi2, or ratio, and will be based upon whether
%  one chooses sigma=model, data, or gehrels in set_fit_statistic();
%  (data error bars are only affected by the latter two).
%  set_fit_statistic("cash"); will alter the residuals to the Cash statistic.
%  set_fit_statistic("ml"); will alter the residuals to the Maximum Likelihood statistic.
%
%  Options below refer to structure variables/qualifiers
%
%   indx    = list of data set indices to be plotted. Any indices grouped in
%             an array within that list will be *combined* in the data plot.
%             Single number in list is combo id, {#} = [combination_members(#)].
%   dcol    = (pgplot) color value for data (or list of color values)
%   decol   = (pgplot) color value for data error bars (or list of color values)
%   mcol    = (pgplot) color value for model (or list of color values)
%             0 => No model plotted
%   rcol    = (pgplot) color value for residuals (or list of color values; arrays
%             within the list allow for individual color values if portions of
%             the data are combined, but their associated residuals are not)
%
%   recol   = color for residual error bars (or list of color values; arrays
%             within the list act as for residual color inputs)
%   dsym    = (pgplot) symbol value for data (or list of symbol values)
%             0 => histogram plot
%   rsym    = (pgplot) symbol value for residuals (or list of symbol values;
%             arrays within the list act as for residual color inputs)
%             0 => histogram plot
%   xrange  = List of X-limits for the data & model & residuals
%             Note: Any X- or Y-range set to NULL is autoscaled
%   yrange  = List of Y-limits for the data & model and (optionally) residuals
%   oplt    = 0 (default) for new plot, !=0 for overplotting
%   no_reset= 0 (default)- plots *will* be reset, i.e., next plot moves to new pane
%             (multiplot), next plot redraws window (single plot). no_reset=1 necessary
%             for overplotting multiplots (oplt=1 sufficient for single plots).
%   res     = 0 (default), no residuals; 1, 2, or 3 = chi, chi2, or ratio residuals
%             4, 5, or 6 = chi, chi2, or ratio, but combine residuals for combined data
%             set_fit_method("cash"); or set_fit_method("ml") will cause res=(2 or 5) 
%             or res=(1 or 4) to plot the residual for the Cash or Maximum Likelihood 
%             statistic or its square root, respectively
%   power  = 0, 1 (default), 2, or 3 for Counts/bin X
%            (1/Unit, 1, Unit, Unit^2), respectively
%   bkg     = List of 0's (subtract background-default), 1's (include backgrounds),
%             or -1's (plot *only* the background [no model plotted in this case]).
%             Ratio residuals will include background in data/model, other residuals
%             are unaffected. Indices within a combination are treated the same.)
%   xlabel  = String that will overwrite default X-axis label (default=NULL)
%   ylabel  = String or string array that will overwrite the default Y-axis labels
%             (second element of array applies to residuals; default=NULL)
%   zshift  = List of redshifts to be applied to the data (default zshift={0,0,...})
%   vzero   = If set, the reference X-unit value to be defined as zero velocity.
%             The X-axis then becomes a velocity axis (km/s) referenced to this
%             point (default vzero=NULL; setting vzero/zaxis supersedes zshift)
%   zaxis   = If not 0, use a redshift axis instead of a velocity axis *if* vzero
%             is defined (default zaxis=0)
%   scale   = Multiplicatively scale the Y-axis by the values in a list.
%             Any arrays in the list should hold the individual scalings for
%             data set arrays in the input index list.  **Note:**  these values
%             only scale the plots, not the fits.  (Default values are 1.)
%   gap     =  1 (default), models are histograms with gaps where data has gaps,
%              0          , model are bin-centered lines, without gaps.
%\seealso{plot_data, plot_unfold, plot_residuals, plot_fit_model, plotxy, plot_comps, plot_double}
%!%-
{
   variable i,args,indx_ln,iindx,ary_sze;
   variable data,bin_lo,bin_hi,modl,pres,mres,resd,ers,texp;
   variable iw;
   variable ja,jb;

   power_df=1; 

   if(_NARGS > 0)
   {
      args = __pop_list(_NARGS);
      (indx, indx_ln, ary_sze) = set_plot_parms(_NARGS,args;;__qualifiers());
      ifnot(indx_ln)
      {
         message("\n  One or more data sets undefined.\n");
         return;
      }
   }
   else
   {
      () = fprintf(fp, "\n%s\n", %{{{
`
plot_counts({indx,[arry],{cid}},pstruct);  % pstruct = struct{ dcol, mcol, rcol, ...}
plot_counts({indx,[arry],{cid}};dcol={val},mcol={val},rcol={val,[arry],val},...);

  Plot background subtracted data, model, and residuals as counts/bin
`
+ores_descript
+oopts+oindx+odcol+odecol+omcol+orcol+orecol+odsym+orsym+oxrange+oyrange+ooplt+onrst+ores
+`   power  = 0, 1 (default), 2, or 3 for Counts/bin X
            (1/Unit, 1, Unit, Unit^2), respectively
`
+obkg+oxlabel+oylabel+ozshift+ovzero+ozaxis+oscale+ogap); %}}}
      return;
   }

   %  And let the plotting begin ...

   plopt = p_range_label(res,power+5);

   % THE DATA & MODEL:

   pd_set(indx,indx_ln,ary_sze);
   pd.type="plot_counts";

   % Create the data first, in case the X or Y ranges are set to
   % autoscale.  This way we can get the autoscaling correct for the
   % full range of data

   texp = Double_Type[indx_ln]; bin_lo = Array_Type[indx_ln];  bin_hi = @bin_lo; 
   data = @bin_lo; modl = @bin_lo; ers = @bin_lo; iw = @bin_lo;
   variable all_lo=Double_Type[0], all_hi=@all_lo, all_data_lo=@all_lo, 
            all_data_hi=@all_lo, istrt=0;

   _for i (0,indx_ln-1,1)
   {
      (bin_lo[i], bin_hi[i], data[i], modl[i], ers[i], iw[i],,,,,texp[i]) = 
               make_data(indx[i],res,power,mcol[i],bkg[i],rescale[i]);
      
       if(vzero!=NULL || zshift[i]!=0.)
      {
         (bin_lo[i],bin_hi[i]) = vaxis(i,bin_lo[i],bin_hi[i]);
      }

      all_lo = [all_lo,bin_lo[i][iw[i]]]; 
      all_hi = [all_hi,bin_hi[i][iw[i]]]; 
      all_data_lo = [all_data_lo,data[i][iw[i]]-ers[i][iw[i]]]; 
      all_data_hi = [all_data_hi,data[i][iw[i]]+ers[i][iw[i]]];
   }

   istrt = start_plot(all_lo, all_hi, all_data_lo, all_data_hi);

   _for i (0,indx_ln-1,1)
   { 
      % Start the plots by plotting data points.  Choose mid-points of
      % bins, to ensure autoscaling matches between data & residuals

      if( dsym[i][0] == 0 )
      {
         pointstyle(1);
         point_size(0.1);
      }
      else
      {
         pointstyle(dsym[i][0]);
         point_size(plopt.point_size);
      }
      connect_points(0);
      ifnot(min([i+istrt+oplt,1]))  % In case we haven't started a plot yet...
      {
         slangref = refplt[0];
         @slangref((bin_lo[i][iw[i]]+bin_hi[i][iw[i]])/2.,data[i][iw[i]],dcol[i][0]);
      }
      point_size(plopt.point_size);

      % Start saving data for writing to an ASCII file

      pd.xaxis = get_plot_options().xlabel;
      pd.yaxis = get_plot_options().ylabel;
      pd.dlo[i] = bin_lo[i][iw[i]];
      pd.dhi[i] = bin_hi[i][iw[i]];
      pd.dval[i] = data[i][iw[i]];
      pd.derr[i] = ers[i][iw[i]];
      pd.exp[i] = texp[i];

      datplot_err(bin_lo[i][iw[i]],bin_hi[i][iw[i]],data[i][iw[i]],
                  data[i][iw[i]]-ers[i][iw[i]],data[i][iw[i]]+ers[i][iw[i]],
                  de_width,decol[i][0],0);

      set_line_width(d_width);

      if(dsym[i][0] != 0)   % Symbol plots
      {
         connect_points(0);
         pointstyle(dsym[i][0]);
         slangref = refplt[1];
         @slangref( (bin_lo[i][iw[i]]+bin_hi[i][iw[i]])/2., data[i][iw[i]], dcol[i][0] );
      }
      else                  % Histogram plots
      {  
         pointstyle(1);
         connect_points(-1);
         (ja,jb) = hp_loop(iw[i]);
         hp_loopit( bin_lo[i], bin_hi[i], data[i], dcol[i][0], iw[i], ja, jb, 1);
      }

      if(mcol[i][0] != 0 && bkg[i][0] >= 0)   % Only plot model if chosen & exists
      {
         set_line_width(m_width);  connect_points(-1);
         (ja,jb) = hp_loop(iw[i]);
         hp_loopit(bin_lo[i], bin_hi[i], modl[i], mcol[i][0], iw[i], ja, jb, gap[i]); 
         pd.model_on[i] = ["     yes"];
         pd.mlo[i] = bin_lo[i][iw[i]];
         pd.mhi[i] = bin_hi[i][iw[i]];
         pd.mval[i] = modl[i][iw[i]];
      }
   }

   % RESIDUAL PLOTS -

   if(res) resplot(yrng,res,indx,indx_ln,ary_sze,rsym,rcol,bkg);

   p_reset;
   return;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define write_plot_head(fph,i,plt_data,plt_res,plt_mod)
{
   variable lf = length(pd.file[i]),ilf=0;

   () = fprintf(fph,"# Plot Type : %s \n", pd.type);
   () = fprintf(fph,"# \n");
   () = fprintf(fph,"# X-axis    : %s \n", pd.xaxis);
   () = fprintf(fph,"# Y-Axis    : %s \n", pd.yaxis);
   () = fprintf(fph,"# Residual  : %s \n", pd.raxis);
   () = fprintf(fph,"# \n");

   if(vzero != NULL)
   {
      () = fprintf(fph,"# Velocity Axis Zero Point: %10.4e %s \n",vzero,x_unit);
      () = fprintf(fph,"# \n");
   }
   else if(zshift[i][0] != 0)
   {
      () = fprintf(fph,"# Source Redshifted by z = %10.4e \n",zshift[i][0]);
      () = fprintf(fph,"# \n");
   }

   if(lf>1 && plt_data>0)
   {
      () = fprintf(fph,"# Combined data comprised of data indices: \n# \n");
   }
   _for ilf (0,lf-1,1)
   {  
      () = fprintf(fph,"# Index- %3i,  Model Plotted- %s,  Data File: %s,   Scale: %10.4e \n", 
                       pd.index[i][ilf], pd.model_on[i][0], pd.file[i][ilf], rescale[i][ilf]);
   }
   () = fprintf(fph,"# \n");

   variable ans=" no";
   if(bkg[i][0]>0) ans="yes";
   if(bkg[i][0]<0) ans="background only";
   () = fprintf(fph,"# Background included in data and model-   %s \n",ans);
   () = fprintf(fph,"# \n");

   if(plt_data==1 || plt_res==1) % Data and/or residuals plot
   {
      ()=fprintf(fph,"# XAXIS_COLS   :   1 set  (X 2 columns - bin_lo, bin_hi)\n");
   }
   else if (plt_data==0 && plt_mod==1)  % Model only plot
   {
      ()=fprintf(fph,"# XAXIS_COLS   :   1 set  (X 2 columns - mbin_lo, mbin_hi)\n");
   }

   variable nr=length(pd.res[i]);
   variable rs="s";
   if(nr==1){rs=" ";}

   variable xhead="#         X_LO          X_HI";
   variable dhead="    DATA_VALUE    DATA_ERROR";
   variable mhead="   MODEL_VALUE";
   variable rhead="     RES_VALUE   RES_VAL-ERR   RES_VAL+ERR";
 
   % The four possible plot cases are 1) We plot only data and
   % residuals, 2) we plot only residuals, 3) we plot only model, 4)
   % we plot data, model, and residuals

   if(plt_data)
   {
      ()=fprintf(fph,"# DATA_COLS    :   1 set  (X 2 columns - Data, Error)\n");
   }

   if(plt_mod==1 && mcol[i][0] > 0 && bkg[i][0] >= 0 && pd.con_mod >0)
   {
      ()=fprintf(fph,"# MODEL_COLS   :   1 set  (X 1 column  - Value) \n");
   }

   if(plt_res==1 && nr>0)
   {
      ()=fprintf(fph,"# RESIDUAL_COLS: %3i set"+rs+" (X 3 columns - Mean, Mean-1Sigma, Mean+1Sigma)\n",nr);
   }

   () = fprintf(fph,"# \n"+xhead);

   if(plt_data)
   {
      () = fprintf(fph,dhead);
   }

   if(plt_mod==1 && mcol[i][0]>0 && bkg[i][0] >= 0 
                 && (pd.con_mod>0 || (plt_res==0 && plt_data==0)))
   {
      ()=fprintf(fph,mhead);
   }        

   if(plt_res==1 && nr>0)
   {
      loop(nr)
      {
         () = fprintf(fph,rhead);
      }
   }

   () = fprintf(fph,"\n");
}

%%%%%%%%%%%%%%%%%%%%%%%%%%

public define write_plot()
%!%+
%\function{write_plot}
%\synopsis{Write the data from the last plot made with the isis_fancy_plots package }
%\usage{[pd =] write_plot(root; head=0, data);}
%\qualifiers{
%\qualifier{head}{==0 to suppress header in output file}
%\qualifier{data}{if set, return data as a structure instead}
%}
%\description
%
% [pd =] write_plot(root; head=0, data);
%
% Creates ASCII files with the data from the last plot made (with any
% plot device) using plot_counts, plot_data, plot_residuals, or
% plot_unfold.  Data will be stored in columns in the following order-
% bin_lo, bin_hi, data_value, data_error (single column), model,
% {mean residual, residual-1sigma, residual+1sigma}.  There can be
% multiple sets of columns for the groups of residuals if the data are
% combined, but the residuals are not.
%
% Important notes:
%
%   The X-axis and Y-axis units will reflect those of the plot. The
%   binning and noticed data ranges will reflect data filters applied
%   within ISIS, but not the (usually more limited) plot range filters.
%
%   Each uncombined data set, or group of combined data sets, will be
%   be written to a separate ASCII file.  A file for combined data sets
%   can have multiple columns for residuals if they are left uncombined.
%
%   Combined data or residuals will only write out the chosen
%   combinations, not the individual pieces used to create them.
%
%   Files created from plot_residuals will only output the bin_lo/hi
%   grid and the residual/-/+ columns, not the data or model.
%
%   If the model or residuals were not plotted, they will not be
%   written to the ASCII file.
%
%   Plots made from plot_unfold will create separate files for the
%   data and the unfolded model, as they can be on different grids.
%   The model file will begin with the appropriate bin_lo, bin_hi.
%
% Inputs:
%
%   root- A string with the base file name.  Outputs will be--
%         root_#.dat, root_#.res (for plot residuals), and root_#.mod (for
%         plot_unfold, if the data and model are on separate grids). # will
%         will cycle from 0 to the number of input data groups-1, assigning
%         data sets in the order that they were input to the plot command.
%         ***Old files will be overwritten if 'root' is not a unique name.***
%
%   head- Set as a qualifier only.  If !=0 (default=1), the ASCII data
%         files will have useful header information appended, otherwise,
%         the files will just contain columns of data.
%
%   data- If the data qualifier exists, instead of writing an ASCII file, the 
%         write_plot function will return a structure with the data values from 
%         the last plot generated.
%\seealso{pg_info}
%!%-
{
   variable root;

#ifexists COPY
   if(qualifier_exists("data")) return COPY(pd);
#else
   if(qualifier_exists("data")) return pd;
#endif
   switch(_NARGS)
   {
      case 1:
      root = ();
      root = string(root);
   }
   {
      ()=fprintf(fp, "%s\n", %{{{
`
 [pd =] write_plot(root; head=0, data);

 Creates ASCII files with the data from the last plot made (with any
 plot device) using plot_counts, plot_data, plot_residuals, or
 plot_unfold.  Data will be stored in columns in the following order-
 bin_lo, bin_hi, data_value, data_error (single column), model,
 {mean residual, residual-1sigma, residual+1sigma}.  There can be
 multiple sets of columns for the groups of residuals if the data are
 combined, but the residuals are not.

 Important notes:

   The X-axis and Y-axis units will reflect those of the plot. The
   binning and noticed data ranges will reflect data filters applied
   within ISIS, but not the (usually more limited) plot range filters.

   Each uncombined data set, or group of combined data sets, will be
   be written to a separate ASCII file.  A file for combined data sets
   can have multiple columns for residuals if they are left uncombined.

   Combined data or residuals will only write out the chosen
   combinations, not the individual pieces used to create them.

   Files created from plot_residuals will only output the bin_lo/hi
   grid and the residual/-/+ columns, not the data or model.

   If the model or residuals were not plotted, they will not be
   written to the ASCII file.

   Plots made from plot_unfold will create separate files for the
   data and the unfolded model, as they can be on different grids.
   The model file will begin with the appropriate bin_lo, bin_hi.

 Inputs:

   root- A string with the base file name.  Outputs will be--
         root_#.dat, root_#.res (for plot residuals), and root_#.mod (for
         plot_unfold, if the data and model are on separate grids). # will
         will cycle from 0 to the number of input data groups-1, assigning
         data sets in the order that they were input to the plot command.
         ***Old files will be overwritten if 'root' is not a unique name.***

   head- Set as a qualifier only.  If !=0 (default=1), the ASCII data
         files will have useful header information appended, otherwise,
         the files will just contain columns of data.

   data- If the data qualifier exists, instead of writing an ASCII file, the 
         write_plot function will return a structure with the data values from 
         the last plot generated.
`                  );        %}}}

      return;
   }

   variable head = qualifier("head", 1);

   variable ndata=0, nres=0, i, j, fpd;
   if( pd.dval[0] != NULL ) ndata = length(pd.dval);
   if( pd.res [0] != NULL ) nres  = length(pd.res);

   _for i (0, max([ndata,nres])-1, 1)
   {
      variable columns = { pd.dlo[i], pd.dhi [i] };
      ifnot(pd.type=="plot_residuals")
      {
	 list_append(columns, pd.dval[i]);
	 list_append(columns, pd.derr[i]);
      }
      if( ( pd.type=="plot_counts" || pd.type=="plot_data"
	   || (pd.type=="plot_unfold" && pd.con_mod) )
	  && pd.mlo[i][0]!=NULL )
         list_append(columns, pd.mval[i]);

      _for j (0, length(pd.res[i])-1, 1)
         if(pd.res[i][j][0] != NULL)
         {
	    list_append(columns, pd.res  [i][j]);
	    list_append(columns, pd.res_m[i][j]);
	    list_append(columns, pd.res_p[i][j]);
         }

      switch(pd.type)
      { case "plot_counts" or case "plot_data" or case "plot_unfold":
         fpd = fopen("${root}_${i}.dat"$, "w");
         if(head)  write_plot_head(fpd,i,1,1,1);  % data, residuals, model
      }
      { case "plot_residuals":
         fpd = fopen("${root}_${i}.res"$, "w");
         if(head)  write_plot_head(fpd,i,0,1,0);  % only residuals
      }
      writecol(fpd, __push_list(columns));
      () = fclose(fpd);

      if(pd.type=="plot_unfold" && pd.mlo[i][0]!=NULL && not pd.con_mod)
      {
	 fpd = fopen("${root}_${i}.mod"$, "w");
	 if(head)  write_plot_head(fpd,i,0,0,1);  % model only
	 writecol(fpd, pd.mlo[i], pd.mhi[i], pd.mval[i]);
	 () = fclose(fpd);
      }
   }
}

alias("write_plot","writeplot");

%%%%%%%%%%%%%%%%%%%%%%%%%

public define plot_data()
%!%+
%\function{plot_data}
%\synopsis{Plot counts per unit per second (isis_fancy_plots package)}
%\description
%
%plot_data({indx,[arry],{cid}},pstruct);  % pstruct = struct{ dcol, mcol, rcol, ...}
%plot_data({indx,[arry],{cid}};dcol={val},mcol={val},rcol={val,[arry],val},...);
%
%  Plot background subtracted data, model, and residuals as counts/xunit/sec.
%  Residuals are units of chi, chi2, or ratio, and will be based upon whether
%  one chooses sigma=model, data, or gehrels in set_fit_statistic();
%  (data error bars are only affected by the latter two).
%  set_fit_statistic("cash"); will alter the residuals to the Cash statistic.
%  set_fit_statistic("ml"); will alter the residuals to the Maximum Likelihood statistic.
%
%  Options below refer to structure variables/qualifiers
%
%   indx    = list of data set indices to be plotted. Any indices grouped in
%             an array within that list will be *combined* in the data plot.
%             Single number in list is combo id, {#} = [combination_members(#)].
%   dcol    = (pgplot) color value for data (or list of color values)
%   decol   = (pgplot) color value for data error bars (or list of color values)
%   mcol    = (pgplot) color value for model (or list of color values)
%             0 => No model plotted
%   rcol    = (pgplot) color value for residuals (or list of color values; arrays
%             within the list allow for individual color values if portions of
%             the data are combined, but their associated residuals are not)
%   recol   = color for residual error bars (or list of color values; arrays
%             within the list act as for residual color inputs)
%   dsym    = (pgplot) symbol value for data (or list of symbol values)
%             0 => histogram plot
%   rsym    = (pgplot) symbol value for residuals (or list of symbol values;
%             arrays within the list act as for residual color inputs)
%             0 => histogram plot
%   xrange  = List of X-limits for the data & model & residuals
%             Note: Any X- or Y-range set to NULL is autoscaled
%   yrange  = List of Y-limits for the data & model and (optionally) residuals
%   oplt    = 0 (default) for new plot, !=0 for overplotting
%   no_reset= 0 (default)- plots *will* be reset, i.e., next plot moves to new pane
%             (multiplot), next plot redraws window (single plot). no_reset=1 necessary
%             for overplotting multiplots (oplt=1 sufficient for single plots).
%   res     = 0 (default), no residuals; 1, 2, or 3 = chi, chi2, or ratio residuals
%             4, 5, or 6 = chi, chi2, or ratio, but combine residuals for combined data
%             set_fit_method("cash"); or set_fit_method("ml") will cause res=(2 or 5) 
%             or res=(1 or 4) to plot the residual for the Cash or Maximum Likelihood 
%             statistic or its square root, respectively
%   bkg     = List of 0's (subtract background-default), 1's (include backgrounds),
%             or -1's (plot *only* the background [no model plotted in this case]).
%             Ratio residuals will include background in data/model, other residuals
%             are unaffected. Indices within a combination are treated the same.)
%   xlabel  = String that will overwrite default X-axis label (default=NULL)
%   ylabel  = String or string array that will overwrite the default Y-axis labels
%             (second element of array applies to residuals; default=NULL)
%   zshift  = List of redshifts to be applied to the data (default zshift={0,0,...})
%   vzero   = If set, the reference X-unit value to be defined as zero velocity.
%             The X-axis then becomes a velocity axis (km/s) referenced to this
%             point (default vzero=NULL; setting vzero/zaxis supersedes zshift)
%   zaxis   = If not 0, use a redshift axis instead of a velocity axis *if* vzero
%             is defined (default zaxis=0)
%   scale   = Multiplicatively scale the Y-axis by the values in a list.
%             Any arrays in the list should hold the individual scalings for
%             data set arrays in the input index list.  **Note:**  these values
%             only scale the plots, not the fits.  (Default values are 1.)
%   sum_exp = If==1, then when combining data sets, sum the exposure times (as
%             opposed to using the mean exposure time; default sum_exp=1).
%   gap     =  1 (default), models are histograms with gaps where data has gaps,
%              0          , model are bin-centered lines, without gaps.
%\seealso{plot_data, plot_unfold, plot_residuals, plot_fit_model, plotxy, plot_comps, plot_double}
%!%-
{
   variable i,args,indx_ln,iindx,ary_sze;
   variable data,bin_lo,bin_hi,modl,pres,mres,resd,ers,kcor=1.,perunit,texp;
   variable iw;
   variable ja,jb;

   if(_NARGS > 0)
   {
      args = __pop_list(_NARGS);
      (indx, indx_ln, ary_sze) = set_plot_parms(_NARGS,args;;__qualifiers());
      power=1; % No multiplying by X for plot_data (only plot_counts & plot_unfold)
      ifnot(indx_ln)
      {
         message("\n  One or more data sets undefined.\n");
         return;
      }
   }
   else
   {
      () = fprintf(fp, "%s\n", %{{{
`
plot_data({indx,[arry],{cid}},pstruct);  % pstruct = struct{ dcol, mcol, rcol, ...}
plot_data({indx,[arry],{cid}};dcol={val},mcol={val},rcol={val,[arry],val},...);

  Plot background subtracted data, model, and residuals as counts/xunit/sec.
`
+ores_descript
+oopts+oindx+odcol+odecol+omcol+orcol+orecol+odsym+orsym+oxrange+oyrange+ooplt+onrst+ores
+obkg+oxlabel+oylabel+ozshift+ovzero+ozaxis+oscale+osum_exp+ogap); %}}}
      return;
   }

   %  And let the plotting begin ...

   plopt = p_range_label(res,0);

   % THE DATA & MODEL:

   pd_set(indx,indx_ln,ary_sze);
   pd.type="plot_data";

   % Create the data first, in case the X or Y ranges are set to
   % autoscale.  This way we can get the autoscaling correct for the
   % full range of data

   texp = Double_Type[indx_ln]; bin_lo = Array_Type[indx_ln];  bin_hi = @bin_lo; 
   data = @bin_lo; modl = @bin_lo; ers = @bin_lo; iw = @bin_lo;
   variable all_lo=Double_Type[0], all_hi=@all_lo, all_data_lo=@all_lo, 
            all_data_hi=@all_lo, istrt=0;

   _for i (0,indx_ln-1,1)
   {
      (bin_lo[i],bin_hi[i],data[i],modl[i],ers[i],iw[i],perunit,,,,texp[i]) = 
               make_data(indx[i],res,power,mcol[i],bkg[i],rescale[i]);

      if(vzero==NULL && zshift[i]!=0 && unit_is_energy(x_unit)!=1)
         kcor = 1.+zshift[i];

      data[i] *= kcor/perunit;
       ers[i] *= kcor/perunit;
      modl[i] *= kcor/perunit;

       if(vzero!=NULL || zshift[i]!=0.)
      {
         (bin_lo[i],bin_hi[i]) = vaxis(i,bin_lo[i],bin_hi[i]);
      }

      all_lo = [all_lo,bin_lo[i][iw[i]]]; 
      all_hi = [all_hi,bin_hi[i][iw[i]]]; 
      all_data_lo = [all_data_lo,data[i][iw[i]]-ers[i][iw[i]]]; 
      all_data_hi = [all_data_hi,data[i][iw[i]]+ers[i][iw[i]]];
   }

   istrt = start_plot(all_lo, all_hi, all_data_lo, all_data_hi);

   _for i (0,indx_ln-1,1)
   { 
      % Start the plots by plotting data points.  Choose mid-points of
      % bins, to ensure autoscaling matches between data & residuals

      if( dsym[i][0] == 0 )
      {
         pointstyle(1);
         point_size(0.1);
      }
      else
      {
         pointstyle(dsym[i][0]);
         point_size(plopt.point_size);
      }
      connect_points(0);
      ifnot(min([i+istrt+oplt,1]))   % In case we haven't started a plot yet
      {
         slangref = refplt[0];
         @slangref((bin_lo[i][iw[i]]+bin_hi[i][iw[i]])/2.,data[i][iw[i]],dcol[i][0]);
      }
      point_size(plopt.point_size);

      pd.xaxis = get_plot_options().xlabel;
      pd.yaxis = get_plot_options().ylabel;
      pd.dlo[i] = bin_lo[i][iw[i]];
      pd.dhi[i] = bin_hi[i][iw[i]];
      pd.dval[i] = data[i][iw[i]];
      pd.derr[i] = ers[i][iw[i]];
      pd.exp[i] = texp[i];

      datplot_err(bin_lo[i][iw[i]],bin_hi[i][iw[i]],data[i][iw[i]],
                  data[i][iw[i]]-ers[i][iw[i]],data[i][iw[i]]+ers[i][iw[i]],
                  de_width,decol[i][0],0);

      set_line_width(d_width);

      if(dsym[i][0] != 0)       % Symbol plots
      {
         connect_points(0);
         pointstyle(dsym[i][0]);
         slangref = refplt[1];
         @slangref( (bin_lo[i][iw[i]]+bin_hi[i][iw[i]])/2., data[i][iw[i]], dcol[i][0] );
      }
      else                      % Histogram plots   
      {  
         pointstyle(1);
         connect_points(-1);
         (ja,jb) = hp_loop(iw[i]);
         hp_loopit( bin_lo[i], bin_hi[i], data[i], dcol[i][0], iw[i], ja, jb, 1);
      }

      if(mcol[i][0] != 0 and bkg[i][0] >=0)
      {
         set_line_width(m_width);  connect_points(-1);
         (ja,jb) = hp_loop(iw[i]);
         hp_loopit(bin_lo[i], bin_hi[i], modl[i], mcol[i][0], iw[i], ja, jb, gap[i]); 
         pd.model_on[i] = ["     yes"];
         pd.mlo[i] = bin_lo[i][iw[i]];
         pd.mhi[i] = bin_hi[i][iw[i]];
         pd.mval[i] = modl[i][iw[i]];
      }
   }

   % RESIDUAL PLOTS -

   if(res) resplot(yrng,res,indx,indx_ln,ary_sze,rsym,rcol,bkg);

   p_reset;
   return;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define plot_residuals()
%!%+
%\function{plot_residuals}
%\synopsis{Plot the data residuals (isis_fancy_plots package)}
%\description
%
%plot_residuals({indx,[arry],{cid}},pstruct);  % pstruct = struct{ rcol, rsym, ...}
%plot_residuals({indx,[arry],{cid}};dcol={val},rcol={val,[arry],val},rsym=...);
%
%  Plot data residuals, without plotting the data.  Residuals related to data
%  indices in [arry] will appear in a single ascii file if write_plot(); is
%  used, and will be combined in the plot if res>3 is chosen.
%
%  Options below refer to structure variables/qualifiers
%
%   indx    = list of data set indices to be plotted. Any indices grouped in
%             an array within that list will be *combined* in the data plot.
%             Single number in list is combo id, {#} = [combination_members(#)].
%   rcol    = (pgplot) color value for residuals (or list of color values; arrays
%             within the list allow for individual color values if portions of
%             the data are combined, but their associated residuals are not)
%   recol   = color for residual error bars (or list of color values; arrays
%             within the list act as for residual color inputs)
%   rsym    = (pgplot) symbol value for residuals (or list of symbol values;
%             arrays within the list act as for residual color inputs)
%             0 => histogram plot
%   xrange  = List of X-limits for the data & model & residuals
%             Note: Any X- or Y-range set to NULL is autoscaled
%   yrange  = List of Y-limits for the data & model and (optionally) residuals
%   oplt    = 0 (default) for new plot, !=0 for overplotting
%   no_reset= 0 (default)- plots *will* be reset, i.e., next plot moves to new pane
%             (multiplot), next plot redraws window (single plot). no_reset=1 necessary
%             for overplotting multiplots (oplt=1 sufficient for single plots).
%   res     = 0 (default), no residuals; 1, 2, or 3 = chi, chi2, or ratio residuals
%             4, 5, or 6 = chi, chi2, or ratio, but combine residuals for combined data
%             set_fit_method("cash"); or set_fit_method("ml") will cause res=(2 or 5) 
%             or res=(1 or 4) to plot the residual for the Cash or Maximum Likelihood 
%             statistic or its square root, respectively
%   xlabel  = String that will overwrite default X-axis label (default=NULL)
%   ylabel  = String or string array that will overwrite the default Y-axis labels
%             (second element of array applies to residuals; default=NULL)
%   zshift  = List of redshifts to be applied to the data (default zshift={0,0,...})
%   vzero   = If set, the reference X-unit value to be defined as zero velocity.
%             The X-axis then becomes a velocity axis (km/s) referenced to this
%             point (default vzero=NULL; setting vzero/zaxis supersedes zshift)
%   zaxis   = If not 0, use a redshift axis instead of a velocity axis *if* vzero
%             is defined (default zaxis=0)
%\seealso{plot_counts, plot_data, plot_unfold, plot_fit_model, plotxy, plot_comps, plot_double}
%!%-
{
   variable args,indx_ln,iindx,ary_sze;

   power_df=1; 

   if(_NARGS > 0)
   {
      args = __pop_list(_NARGS);
      (indx, indx_ln, ary_sze) = set_plot_parms(_NARGS,args;;__qualifiers());
      if(length(yrng)==2) yrng={NULL,NULL,yrng[0],yrng[1]}; 
      if(length(yrng)==1) yrng={NULL,NULL,yrng[0],NULL}; 
      ifnot(indx_ln)
      {
         message("\n  One or more data sets undefined.\n");
         return;
      }
   }
   else
   {
      () = fprintf(fp, "%s\n", %{{{
`
plot_residuals({indx,[arry],{cid}},pstruct);  % pstruct = struct{ rcol, rsym, ...}
plot_residuals({indx,[arry],{cid}};dcol={val},rcol={val,[arry],val},rsym=...);

  Plot data residuals, without plotting the data.  Residuals related to data
  indices in [arry] will appear in a single ascii file if write_plot(); is
  used, and will be combined in the plot if res>3 is chosen.
`
+oopts+oindx+orcol+orecol+orsym+oxrange+oyrange+ooplt+onrst+ores
+oxlabel+oylabel+ozshift+ovzero+ozaxis);%}}}
      return;
   }

   %  And let the plotting begin ...

   plopt = p_range_label(0,0);

   % THE DATA & MODEL:

   pd_set(indx,indx_ln,ary_sze);
   pd.type="plot_residuals";

   if(res) resplot(yrng,res,indx,indx_ln,ary_sze,rsym,rcol,bkg);

   p_reset;
   return;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define plot_fit_model()
%!%+
%\function{plot_fit_model}
%\synopsis{Plot background subtracted model as counts/xunit/sec (isis_fancy_plots package).}
%\description
%
%plot_fit_model({indx,[arry],{cid}},pstruct);  % pstruct = struct{ mcol, ...}
%plot_fit_model({indx,[arry],{cid}};mcol={val},...);
%
%  Plot background subtracted model as counts/xunit/sec.
%
%  Options below refer to structure variables/qualifiers
%
%   indx    = list of data set indices to be plotted. Any indices grouped in
%             an array within that list will be *combined* in the data plot.
%             Single number in list is combo id, {#} = [combination_members(#)].
%   mcol    = (pgplot) color value for model (or list of color values)
%             0 => No model plotted
%   xrange  = List of X-limits for the data & model & residuals
%             Note: Any X- or Y-range set to NULL is autoscaled
%   yrange  = List of Y-limits for the data & model and (optionally) residuals
%   oplt    = 0 (default) for new plot, !=0 for overplotting
%   no_reset= 0 (default)- plots *will* be reset, i.e., next plot moves to new pane
%             (multiplot), next plot redraws window (single plot). no_reset=1 necessary
%             for overplotting multiplots (oplt=1 sufficient for single plots).
%   bkg     = List of 0's (subtract background-default), 1's (include backgrounds),
%             or -1's (plot *only* the background [no model plotted in this case]).
%             Ratio residuals will include background in data/model, other residuals
%             are unaffected. Indices within a combination are treated the same.)
%   xlabel  = String that will overwrite default X-axis label (default=NULL)
%   ylabel  = String or string array that will overwrite the default Y-axis labels
%             (second element of array applies to residuals; default=NULL)
%   zshift  = List of redshifts to be applied to the data (default zshift={0,0,...})
%   vzero   = If set, the reference X-unit value to be defined as zero velocity.
%             The X-axis then becomes a velocity axis (km/s) referenced to this
%             point (default vzero=NULL; setting vzero/zaxis supersedes zshift)
%   zaxis   = If not 0, use a redshift axis instead of a velocity axis *if* vzero
%             is defined (default zaxis=0)
%   scale   = Multiplicatively scale the Y-axis by the values in a list.
%             Any arrays in the list should hold the individual scalings for
%             data set arrays in the input index list.  **Note:**  these values
%             only scale the plots, not the fits.  (Default values are 1.)
%   sum_exp = If==1, then when combining data sets, sum the exposure times (as
%             opposed to using the mean exposure time; default sum_exp=1).
%   gap     =  1 (default), models are histograms with gaps where data has gaps,
%              0          , model are bin-centered lines, without gaps.
%\seealso{plot_counts; plot_data, plot_unfold, plot_residuals, plotxy, plot_comps, plot_double}
%!%-
{
   variable i,args,indx_ln,iindx,ary_sze;
   variable bin_lo,bin_hi,modl,kcor=1,perunit,texp;
   variable iw;
   variable ja,jb;

   power_df=1; 

   if(_NARGS > 0)
   {
      args = __pop_list(_NARGS);
      (indx, indx_ln, ary_sze) = set_plot_parms(_NARGS,args;;__qualifiers());
      ifnot(indx_ln)
      {
         message("\n  One or more data sets undefined.\n");
         return;
      }
   }
   else
   {
      () = fprintf(fp, "%s\n", %{{{
`
plot_fit_model({indx,[arry],{cid}},pstruct);  % pstruct = struct{ mcol, ...}
plot_fit_model({indx,[arry],{cid}};mcol={val},...);

  Plot background subtracted model as counts/xunit/sec.
`
+oopts+oindx+omcol+oxrange+oyrange+ooplt+onrst+obkg+oxlabel+oylabel+ozshift+ovzero
+ozaxis+oscale+osum_exp+ogap); %}}}
      return;
   }

   %  And let the plotting begin ...

   plopt = p_range_label(res,0);

   % Create the data first, in case the X or Y ranges are set to
   % autoscale.  This way we can get the autoscaling correct for the
   % full range of data

   texp = Double_Type[indx_ln]; bin_lo=Array_Type[indx_ln];  bin_hi=@bin_lo; modl=@bin_lo; iw=@bin_lo; 
   variable all_lo=Double_Type[0], all_hi=@all_lo, all_modl=@all_lo, istrt=0;

   _for i (0,indx_ln-1,1)
   {
      (bin_lo[i],bin_hi[i],,modl[i],,iw[i],perunit,,,,texp[i]) = 
               make_data(indx[i],res,power,mcol[i],bkg[i],rescale[i]);

      if(vzero==NULL && zshift[i]!=0 && unit_is_energy(x_unit)!=1)
         kcor = 1.+zshift[i];

      modl[i] *= kcor/perunit;

      if(vzero!=NULL || zshift[i]!=0.)
      {
         (bin_lo[i],bin_hi[i]) = vaxis(i,bin_lo[i],bin_hi[i]);
      }

      all_lo = [all_lo,bin_lo[i][iw[i]]]; 
      all_hi = [all_hi,bin_hi[i][iw[i]]]; 
      all_modl = [all_modl,modl[i][iw[i]]];
   }

   istrt = start_plot(all_lo, all_hi, all_modl, all_modl);
   variable istrtII = 0;  % The first model could be 0'd out

   _for i (0,indx_ln-1,1)
   { 
      if(mcol[i][0] != 0)
      {
         pointstyle(1);
         point_size(0.1);
         connect_points(0);
         ifnot(min([istrt+istrtII+oplt,1]));
         {
            slangref = refplt[0];
            @slangref((bin_lo[i][iw[i]]+bin_hi[i][iw[i]])/2.,modl[i][iw[i]],mcol[i][0]);
            istrtII=1;
         }
         point_size(plopt.point_size);
         set_line_width(m_width);  connect_points(-1);
         (ja,jb) = hp_loop(iw[i]);
         hp_loopit(bin_lo[i], bin_hi[i], modl[i], mcol[i][0], iw[i], ja, jb, gap[i]); 
      }
   }
   p_reset;
   return;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private define make_flux(iindx,res,power,modc,bkgon,rscl,zshft)
{
   variable bin_hi, bin_lo, mbin_lo=NULL, mbin_hi=NULL, frst_modl, fmodl, 
            iwm=Integer_Type[0], iw, iwv, powm, jj, ja, jb,
            tdata=0., tmc = 0, tmodl=0., ters=0., twght=0., texp,
            wght, gdi, gdcu, gdcb, kcor=1., kp,i;

   (bin_lo,bin_hi,tdata,tmc,ters,iw, , , , , texp) = 
      make_data(iindx,res,power,modc,bkgon,rscl);

   _rev = _revr[0];
   kp=3-power;

   if(unit_is_energy(x_unit))
   {
      _rev = _revr[1];
      kp=(power-1);
   }

   if(vzero==NULL) kcor=(1.+zshft);
   kcor = kcor^kp;

   _for i (0,length(iindx)-1,1)
   {
      flux_corr(iindx[i]);                       % Flux correct the data
      wght = get_flux_corr_weights(iindx[i]);    % Flux correction weights

#ifexists get_bin_corr_factor
   % --- Added by Remeis group, Thomas Duaser: new; for FERMI data ---
     if (get_bin_corr_factor(iindx[i]) != NULL)
	wght *= @_rev(get_bin_corr_factor(iindx[i]));
#endif
 
      gdi = get_data_info(iindx[i]);             % Info about the original
      gdcb = get_data_counts(iindx[i]);          % binned & noticed data

      if(length(gdi.notice) != length(gdi.rebin))
      {
         rebin_data(iindx[i],0);
      }
      gdcu = get_data_counts(iindx[i]);          % The unbinned data

      if(length(gdi.notice) != length(gdi.rebin))
      {
         rebin_data(iindx[i],gdi.rebin);
         ignore(iindx[i]);
         notice_list(iindx[i],gdi.notice_list);  % Restore bins & bounds
      }

      % The spectral weights have to be rebinned to the data binning

      twght += rebin(gdcb.bin_lo,gdcb.bin_hi,gdcu.bin_lo,gdcu.bin_hi,
                     wght)/(gdcb.bin_hi-gdcb.bin_lo);

      if( modc != 0 )
      {
         fmodl = get_model_flux(iindx[i]);

         ifnot(i)       % Only do the bins for the first data index
         {
            frst_modl = @fmodl;

            if(unit_is_energy(x_unit))
            {
               mbin_lo = _A(fmodl.bin_hi)/unit_info(x_unit).scale;
               mbin_hi = _A(fmodl.bin_lo)/unit_info(x_unit).scale;
            }
            else
            {
               mbin_lo = fmodl.bin_lo/unit_info(x_unit).scale;
               mbin_hi = fmodl.bin_hi/unit_info(x_unit).scale;
            }

            %% Need to be more clever here.  Temporary (i.e., semi-
            %% permanent) kludge to have model gaps follow data gaps
  
            (ja,jb) = hp_loop(iw);
            _for jj (0,length(ja)-1,1)
            {
               iwv = iw[[ja[jj]:jb[jj]]]; 
               iwm = [ iwm, where( (mbin_lo >= min(bin_lo[iwv])) and
                                   (mbin_hi <= max(bin_hi[iwv]))  ) ];
            }

            powm = power_scale(mbin_lo,mbin_hi,power);
         }
         else             % All other models follow the first binning
         {
            fmodl.value=rebin(frst_modl.bin_lo,frst_modl.bin_hi,
                              fmodl.bin_lo,fmodl.bin_hi,fmodl.value);
         }
 
         fmodl.value = @_rev( fmodl.value );
         fmodl.value = fmodl.value / (mbin_hi-mbin_lo);
         fmodl.value[iwm] = fmodl.value[iwm]*powm[iwm];

         tmodl += rscl[i]*fmodl.value;
      }
   }
   twght = @_rev(twght);

   iw = iw[where(twght[iw]>0)];  % avoid infinities from zero weights

   variable factor1 = kcor * y_scl_norm[x_unit+y_unit];
   variable factor2 = factor1 / twght / (bin_hi-bin_lo);

   return bin_lo, bin_hi, factor2*tdata, factor2*ters, iw,             % data
          texp, factor2,                                               % the weights
          use_con_flux                                                 % &  either
          ? ( bin_lo, bin_hi, factor2*tmc, iw )                        %    convolved model
          : ( mbin_lo, mbin_hi, [factor1*tmodl/length(iindx)], iwm );  % or bare model
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define plot_unfold()
%!%+
%\function{plot_unfold}
%\synopsis{Plot flux-corrected spectra (isis_fancy_plots package).}
%\description
%
%plot_unfold({indx,[arry],{cid}},pstruct);  % pstruct = struct{ dcol, mcol, rcol, ...}
%plot_unfold({indx,[arry],{cid}};dcol={val},mcol={val},rcol={val,[arry],val},...);
%
%  Plot background subtracted unfolded data, model, and residuals using a
%  variety of X- and Y-units set by fancy_plot_unit(xunit, [yunit]);
%  Residuals are units of chi, chi2, or ratio, and will be based upon whether
%  one chooses sigma=model, data, or gehrels in set_fit_statistic();
%  (data error bars are only affected by the latter two).
%  set_fit_statistic("cash"); will alter the residuals to the Cash statistic.
%  set_fit_statistic("ml"); will alter the residuals to the Maximum Likelihood statistic.
%
%  Options below refer to structure variables/qualifiers
%
%   indx    = list of data set indices to be plotted. Any indices grouped in
%             an array within that list will be *combined* in the data plot.
%             Single number in list is combo id, {#} = [combination_members(#)].
%   dcol    = (pgplot) color value for data (or list of color values)
%   decol   = (pgplot) color value for data error bars (or list of color values)
%   mcol    = (pgplot) color value for model (or list of color values)
%             0 => No model plotted
%   rcol    = (pgplot) color value for residuals (or list of color values; arrays
%             within the list allow for individual color values if portions of
%             the data are combined, but their associated residuals are not)
%   recol   = color for residual error bars (or list of color values; arrays
%             within the list act as for residual color inputs)
%   dsym    = (pgplot) symbol value for data (or list of symbol values)
%             0 => histogram plot
%   rsym    = (pgplot) symbol value for residuals (or list of symbol values;
%             arrays within the list act as for residual color inputs)
%             0 => histogram plot
%   xrange  = List of X-limits for the data & model & residuals
%             Note: Any X- or Y-range set to NULL is autoscaled
%   yrange  = List of Y-limits for the data & model and (optionally) residuals
%   oplt    = 0 (default) for new plot, !=0 for overplotting
%   no_reset= 0 (default)- plots *will* be reset, i.e., next plot moves to new pane
%             (multiplot), next plot redraws window (single plot). no_reset=1 necessary
%             for overplotting multiplots (oplt=1 sufficient for single plots).
%   res     = 0 (default), no residuals; 1, 2, or 3 = chi, chi2, or ratio residuals
%             4, 5, or 6 = chi, chi2, or ratio, but combine residuals for combined data
%             set_fit_method("cash"); or set_fit_method("ml") will cause res=(2 or 5) 
%             or res=(1 or 4) to plot the residual for the Cash or Maximum Likelihood 
%             statistic or its square root, respectively
%   power  = 0, 1 (usual default), 2 (default for mJy) or 3 (default for ergs/Watts
%            vs. energy units)=> photons/cm^2/s/xunit *(1/xunit,1,xunit,xunit^2)
%   bkg     = List of 0's (subtract background-default), 1's (include backgrounds),
%             or -1's (plot *only* the background [no model plotted in this case]).
%             Ratio residuals will include background in data/model, other residuals
%             are unaffected. Indices within a combination are treated the same.)
%   xlabel  = String that will overwrite default X-axis label (default=NULL)
%   ylabel  = String or string array that will overwrite the default Y-axis labels
%             (second element of array applies to residuals; default=NULL)
%   zshift  = List of redshifts to be applied to the data (default zshift={0,0,...})
%   vzero   = If set, the reference X-unit value to be defined as zero velocity.
%             The X-axis then becomes a velocity axis (km/s) referenced to this
%             point (default vzero=NULL; setting vzero/zaxis supersedes zshift)
%   zaxis   = If not 0, use a redshift axis instead of a velocity axis *if* vzero
%             is defined (default zaxis=0)
%   scale   = Multiplicatively scale the Y-axis by the values in a list.
%             Any arrays in the list should hold the individual scalings for
%             data set arrays in the input index list.  **Note:**  these values
%             only scale the plots, not the fits.  (Default values are 1.)
%   gap     =  1 (default), models are histograms with gaps where data has gaps,
%              0          , model are bin-centered lines, without gaps.
%   con_mod= 1 (default), the smear the model by the detector response, otherwise 
%            plot the unsmeared model at the internal resolution of the arf
%
%  Note: Model flux is: ( \\\\int dE S(E) )/dE, while data is 
%  (C(h) - B(h))/(\\\\int R(h,E) A(E) dE)/dh/t, where A(E) is effective area, 
%  R(h,E) is RMF, C(h)/B(h) are total/background counts. Thus, the data 
%  and model will match best only in the limit of a delta function RMF, 
%  and in fact might look different than the residuals (which is the 
%  only proper comparison between data and model, anyhow).
%\seealso{set_power_scale, plot_counts, plot_data, plot_residuals, plot_fit_model, plotxy, plot_comps, plot_double}
%!%-
{
   variable args,i,indx, indx_ln, ary_sze,iw,iwm,ja,jb;
   variable bin_lo,bin_hi,mbin_lo,mbin_hi,data,ers,modl,twgt,texp;

   power_df=1;
   if(y_unit=="mjy")
   {
      power_df=2;
   }
   if((y_unit=="ergs" || y_unit=="watts") && unit_is_energy(x_unit))
      power_df=3;

   if(_NARGS > 0)
   {
      args = __pop_list(_NARGS);
      (indx, indx_ln, ary_sze) = set_plot_parms(_NARGS,args;;__qualifiers());
      ifnot(indx_ln)
      {
         message("\n  One or more data sets undefined.\n");
         return;
      }
   }
   else
   {
      () = fprintf(fp, "%s\n", %%%{{{
`
plot_unfold({indx,[arry],{cid}},pstruct);  % pstruct = struct{ dcol, mcol, rcol, ...}
plot_unfold({indx,[arry],{cid}};dcol={val},mcol={val},rcol={val,[arry],val},...);

  Plot background subtracted unfolded data, model, and residuals using a
  variety of X- and Y-units set by fancy_plot_unit(xunit, [yunit]);
`
+ores_descript
+oopts+oindx+odcol+odecol+omcol+orcol+orecol+odsym+orsym+oxrange+oyrange+ooplt+onrst+ores
+`   power  = 0, 1 (usual default), 2 (default for mJy) or 3 (default for ergs/Watts
            vs. energy units)=> photons/cm^2/s/xunit *(1/xunit,1,xunit,xunit^2)
`
+obkg+oxlabel+oylabel+ozshift+ovzero+ozaxis+oscale+ogap
+`   con_mod= 1 (default), the smear the model by the detector response, otherwise 
            plot the unsmeared model at the internal resolution of the arf

  Note: Model flux is: ( \int dE S(E) )/dE, while data is 
  (C(h) - B(h))/(\int R(h,E) A(E) dE)/dh/t, where A(E) is effective area, 
  R(h,E) is RMF, C(h)/B(h) are total/background counts. Thus, the data 
  and model will match best only in the limit of a delta function RMF, 
  and in fact might look different than the residuals (which is the 
  only proper comparison between data and model, anyhow).
`                  );          %%%}}}
      return;
   }

   %  And let the plotting begin ...
   
   plopt = p_range_label(res,power+1);

   % DATA/MODEL PLOTS - 

   pd_set(indx,indx_ln,ary_sze);
   pd.type="plot_unfold";

   % Create the data first, in case the X or Y ranges are set to
   % autoscale.  This way we can get the autoscaling correct for the
   % full range of data

   texp = Double_Type[indx_ln];
   bin_lo = Array_Type[indx_ln];  bin_hi = @bin_lo; twgt = @bin_lo;
   data = @bin_lo; modl = @bin_lo; ers = @bin_lo; iw = @bin_lo;
   mbin_lo = @bin_lo; mbin_hi = @bin_lo; iwm = @bin_lo;
   variable all_lo=Double_Type[0], all_hi=@all_lo, all_data_lo=@all_lo, 
            all_data_hi=@all_lo, istrt=0;

   _for i (0,indx_ln-1,1)
   {
      (bin_lo[i], bin_hi[i], data[i], ers[i], iw[i], texp[i], twgt[i],
       mbin_lo[i], mbin_hi[i], modl[i], iwm[i]       )=
         make_flux(indx[i],res,power,mcol[i],bkg[i],rescale[i],zshift[i]);

      if(vzero!=NULL || zshift[i]!=0.)
      {
         (bin_lo[i],bin_hi[i]) = vaxis(i,bin_lo[i],bin_hi[i]);
      }

      all_lo = [all_lo,bin_lo[i][iw[i]]]; 
      all_hi = [all_hi,bin_hi[i][iw[i]]];
      all_data_lo = [all_data_lo,data[i][iw[i]]-ers[i][iw[i]]];
      all_data_hi = [all_data_hi,data[i][iw[i]]+ers[i][iw[i]]];

      if(mcol[i][0] > 0 && bkg[i][0] >= 0)
      {
         if(vzero!=NULL || zshift[i]!=0.)
         {
            (mbin_lo[i],mbin_hi[i]) = vaxis(i,mbin_lo[i],mbin_hi[i]);
         }
         all_lo = [all_lo,mbin_lo[i][iwm[i]]]; 
         all_hi = [all_hi,mbin_hi[i][iwm[i]]]; 
         all_data_lo = [all_data_lo,modl[i][iwm[i]]]; 
         all_data_hi = [all_data_hi,modl[i][iwm[i]]];
      }
   }

   istrt = start_plot(all_lo, all_hi, all_data_lo, all_data_hi);

   _for i (0,indx_ln-1,1)
   { 
      % Start the plots by plotting data points.  Choose mid-points of
      % bins, to ensure autoscaling matches between data & residuals

      if( dsym[i][0] == 0 )
      {
         pointstyle(1);
         point_size(0.1);
      }
      else
      {
         pointstyle(dsym[i][0]);
         point_size(plopt.point_size);
      }
      connect_points(0);
      ifnot(min([i+istrt+oplt,1]))  % In case we haven't started a plot yet...
      {
         slangref = refplt[0];
         @slangref((bin_lo[i][iw[i]]+bin_hi[i][iw[i]])/2.,data[i][iw[i]],dcol[i][0]);
      }
      point_size(plopt.point_size);

      % Start saving data for writing to an ASCII file

      pd.xaxis = get_plot_options().xlabel;
      pd.yaxis = get_plot_options().ylabel;
      pd.dlo[i] = bin_lo[i][iw[i]];
      pd.dhi[i] = bin_hi[i][iw[i]];
      pd.dval[i] = data[i][iw[i]];
      pd.derr[i] = ers[i][iw[i]];
      pd.weight[i] = twgt[i][iw[i]];
      pd.exp[i] = texp[i];

      datplot_err(bin_lo[i][iw[i]],bin_hi[i][iw[i]],data[i][iw[i]],
                  data[i][iw[i]]-ers[i][iw[i]],data[i][iw[i]]+ers[i][iw[i]],
                  de_width,decol[i][0],0);

      set_line_width(d_width);

      if(dsym[i][0] != 0)   % Symbol plots
      {
         connect_points(0);
         pointstyle(dsym[i][0]);
         slangref = refplt[1];
         @slangref( (bin_lo[i][iw[i]]+bin_hi[i][iw[i]])/2., data[i][iw[i]], dcol[i][0] );
      }
      else                  % Histogram plots
      {  
         pointstyle(1);
         connect_points(-1);
         (ja,jb) = hp_loop(iw[i]);
         hp_loopit( bin_lo[i], bin_hi[i], data[i], dcol[i][0], iw[i], ja, jb, 1);
      }

      if(mcol[i][0] > 0 && bkg[i][0] >= 0)       % Only plot model if chosen & exists
      {
         set_line_width(m_width);  connect_points(-1);
         (ja,jb) = hp_loop(iwm[i]);
         hp_loopit(mbin_lo[i], mbin_hi[i], modl[i], mcol[i][0], iwm[i], ja, jb, gap[i]); 
         pd.model_on[i] = ["     yes"];
         pd.mlo[i] = mbin_lo[i][iwm[i]];
         pd.mhi[i] = mbin_hi[i][iwm[i]];
         pd.mval[i] = modl[i][iwm[i]];
         pd.con_mod = use_con_flux;
      }
   }

   % RESIDUAL PLOTS -

   if(res) resplot(yrng,res,indx,indx_ln,ary_sze,rsym,rcol,bkg);

   p_reset;
   return;
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                % 
%     Definitions for Simple plotxy Function     %
%                                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%

public define plotxy()
%!%+
%\function{plotxy}
%\synopsis{Generate a simple x/y plot with error bars (isis_fancy_plots package)}
%\description
%
% plotxy(x,dxm,dxp,y,dym,dyp, pstruct); % pstruct = struct{dcol, decol, xrng, ...}
% plotxy(x,dxm,dxp,y,dym,dyp; dcol=#, decol=#, ...);
%
% Also accepts:
%
% plotxy(x,y [,pstruct;qualifiers]);
% plotxy(x,dxm,dxp,y [,pstruct;qualifiers]);
% plotxy(x,,,y,dym,dyp [,pstruct;qualifiers]);
%
%   Plot simple x,y plots with error bars: x-dxm, x+dxp, etc.
%
%   Options below refer to structure variables/associative keys/qualifiers:
%
%   dcol  = (pgplot) color value for data
%   decol = (pgplot) color value for data
%   dsym  = (pgplot) symbol value for data
%           Note: dsym=0 will *not* produce a histogram plot
%   xrange= List of X-limits for the data. Ranges previously input
%           via xrange(); will be respected if this option is not set.
%   yrange= List of Y-limits for the data. Ranges previously input
%           via yrange(); will be respected if this is not set.
%   xlabel= String for the X-axis label
%   ylabel= String for the Y-axis label
%           Note: xlabel(); ylabel(); commands will also work.
%   oplt    = 0 (default) for new plot, !=0 for overplotting
%
%   Further note: plotxy(...); will apply the choices from connect_points(#);
%\seealso{plot_counts, plot_data, plot_unfold, plot_residuals, plot_fit_model, plotxy, plot_comps, plot_double}
%!%-
{
   variable args, ivars, x,xx,xm=NULL,xp=NULL, y,yy,ym=NULL,yp=NULL;
   plopt = get_plot_options;

   if(_NARGS > 0)
   {
      args = __pop_list(_NARGS);
      ivars=_NARGS;

      if(typeof(args[-1])==Struct_Type)
      {
         set_plot_parms_struct(args[-1],1,[1];;__qualifiers);
         ivars--;
      }
      else
      {
         set_plot_parms_struct(parm_s,1,[1];;__qualifiers);
      }

      if(ivars==2)
      {
         x = args[0];
         y = args[1];
      }
      else if(ivars==4 || ivars==5 || ivars==6)
      {
         x = args[0];
         xm = args[1];
         xp = args[2];
         y = args[3];
         if(ivars>=5) ym = args[4];
         if(ivars==6) yp = args[5];
      }
      else
      {
         () = fprintf(fp, "%s\n", %%%{{{
`
 Inconsistent number of input arguments (expecting 2, 4, or 6 inputs
 plus plot options structure and/or qualifiers).
`                     );          %%%}}}
         return;
      }
   }
   else
   {
     ()=fprintf(fp, "%s\n", %{{{
`
 plotxy(x,dxm,dxp,y,dym,dyp, pstruct); % pstruct = struct{dcol, decol, xrng, ...}
 plotxy(x,dxm,dxp,y,dym,dyp; dcol=#, decol=#, ...);

 Also accepts:

 plotxy(x,y [,pstruct;qualifiers]);
 plotxy(x,dxm,dxp,y [,pstruct;qualifiers]);
 plotxy(x,,,y,dym,dyp [,pstruct;qualifiers]);

   Plot simple x,y plots with error bars: x-dxm, x+dxp, etc.

   Options below refer to structure variables/associative keys/qualifiers:

   dcol  = (pgplot) color value for data
   decol = (pgplot) color value for data
   dsym  = (pgplot) symbol value for data
           Note: dsym=0 will *not* produce a histogram plot
   xrange= List of X-limits for the data. Ranges previously input
           via xrange(); will be respected if this option is not set.
   yrange= List of Y-limits for the data. Ranges previously input
           via yrange(); will be respected if this is not set.
   xlabel= String for the X-axis label
   ylabel= String for the Y-axis label
           Note: xlabel(); ylabel(); commands will also work.
`
+ooplt
+`
   Further note: plotxy(...); will apply the choices from connect_points(#);
`); %}}}
      return;
   }

   if(xlabl!=NULL) xlabel(xlabl);
   if(ylabl!=NULL) ylabel(ylabl[0]);

   if(length(xrng)>1)
   {
      if((xrng[0]!=NULL) && (xrng[0]<=0))
      {
         xlin;
      }
      xrange(xrng[0],xrng[1]);
   }
   if(length(yrng)>1)
   {
      if((yrng[0]!=NULL) && (yrng[0]<=0))
      {
         ylin;
      }
      yrange(yrng[0],yrng[1]);
   }

   set_line_width(d_width);
   point_style(dsym[0]);

   if(oplt==0)
   {
      plot(x,y,dcol[0]);
   }
   else
   {
      oplot(x,y,dcol[0]);
   }

   xx = @x*1.;
   yy = @y*1.;

   if(get_plot_options().logx) 
   { 
      xx[where(xx <= 0)] = 2.e-38;
      xx = log10(xx);
   }
   if(get_plot_options().logy) 
   { 
      yy[where(yy <= 0)] = 2.e-38;
      yy = log10(yy);
   }

   if( xm != NULL || xp != NULL )
   {
      if( xm == NULL ) xm = 0.*x;
      if( xp == NULL ) xp = 0.*x;

      xm=x-xm; xp=x+xp;

      if(get_plot_options().logx) 
      { 
         xm[where(xm <= 0)] = 1.e-38;
         xp[where(xp <= 0)] = 3.e-38;

         xm = log10(xm); 
         xp = log10(xp); 
      }

      _pgslw(de_width);
      _pgsci(decol[0]);
      () = _pgerrx(length(x),xm,xp,yy,ebar_x);
   }

   if( ym != NULL || yp != NULL )
   {
      if( ym == NULL ) ym = 0.*y;
      if( yp == NULL ) yp = 0.*y;

      ym=y-ym; yp=y+yp;

      if(get_plot_options().logy) 
      { 
         ym[where(ym <= 0)] = 1.e-38;
         yp[where(yp <= 0)] = 3.e-38;

         ym = log10(ym); 
         yp = log10(yp); 
      }

     _pgslw(de_width);
     _pgsci(decol[0]);
     () = _pgerry(length(x),xx,ym,yp,ebar_y);
   }

   set_line_width(d_width);
   point_style(dsym[0]);

   oplot(x,y,dcol[0]);
   color(dcol[0]);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%

public define plot_comps()
%!%+
%\function{plot_comps}
%\synopsis{Create a data plot with model components explicitly shown (isis_fancy_plots package)}
%\usage{plot_comps({data},&plot_func;dcol={val},mcol={val},ccol={val},cstyle=val,...);}
%\altusage{plot_comps({data},pstrut,&plot_func); where pstruct=struct{dcol, mcol, ...}}
%\description
%  Use a fancy plotting function, e.g., plot_counts or plot_data or
%  plot unfold, passed as a reference, and cycle through all the
%  components with a norm parameter.  Plot each of these as a separate
%  model component.  The plot functions now take two additional
%  optional qualifiers (which alternatively can be passed via the
%  pstruct structure variable): ccol and cstyle.  The ccol parameter
%  gives the color of the model components for each dataset, which can
%  be different from the color of the model for the complete model.
%  The cstyle allows a global change of the line_style for *all* of the
%  model components.  (I.e., only one alternate line_style can be
%  chosen.)  data is the usual combination of integers (=individual
%  data sets), arrays (=data sets to be combined), and lists (=id of
%  combined datasets).
%
%\examples
%    plot_comps({1,[2,3]},popt,&plot_counts;xrange={1,10});
%    plot_comps({5,8},&plot_unfold);
%    plot_comps({{1}},popt,&plot_data);
%\seealso{plot_counts, plot_data, plot_unfold, plot_residuals, plot_fit_model, plotxy, plot_comps, plot_double}
%!%-
{
   variable args;
   if(_NARGS == 2 || _NARGS==3)
   {
      args = __pop_list(_NARGS);
   }
   else
   {
      () = fprintf(fp, "%s\n", %%%{{{
`
plot_comps({data},pstruct,&plot_func);  % pstruct=struct{dcol, mcol, ...}
plot_comps({data},&plot_func;dcol={val},mcol={val},ccol={val},cstyle=val,...);

  Use a fancy plotting function, e.g., plot_counts or plot_data or
  plot unfold, passed as a reference, and cycle through all the
  components with a norm parameter.  Plot each of these as a separate
  model component.  The plot functions now take two additional
  optional qualifiers (which alternatively can be passed via the
  pstruct structure variable): ccol and cstyle.  The ccol parameter
  gives the color of the model components for each dataset, which can
  be different from the color of the model for the complete model.
  The cstyle allows a global change of the line_style for *all* of the
  model components.  (I.e., only one alternate line_style can be
  chosen.)  data is the usual combination of integers (=individual
  data sets), arrays (=data sets to be combined), and lists (=id of
  combined datasets). Examples:

    plot_comps({1,[2,3]},popt,&plot_counts;xrange={1,10});
    plot_comps({5,8},&plot_unfold);
    plot_comps({{1}},popt,&plot_data);
`                  );          %%%}}}
      return;
   }

   % Since plot_residuals might be called, have to make sure that
   % yrange is padded with two NULLS if only two values (defaulted to
   % data plot) are input.  res_yrange ultimately will always be
   % passed as a qualifier to the plot routines.

   variable i, j, res_yrange={NULL,NULL,NULL,NULL};
   variable dores = qualifier("res",0);

   % Allow model components to have different colors for each
   % *dataset* (i.e., all components for the same dataset will have
   % the same color).  Force this to default to the model color if
   % nothing is input.
   variable ccol = qualifier("ccol",NULL);
   variable cstyle = qualifier("cstyle",1);
   variable mcol = qualifier("mcol",NULL);

   % We have a plot structure variable input
   if(_NARGS == 3)
   {
      variable popt_save = @args[1];
      dores = popt_save.res;
      res_yrange = {};

      % Fill res_yrange with popt structure values, then pad with
      % NULLs

      _for i (0,length(popt_save.yrange)-1,1)
      {
         list_append(res_yrange,popt_save.yrange[i]);
      }
      _for i (length(popt_save.yrange),3,1)
      {
         list_append(res_yrange,NULL);
      }

      ccol = qualifier("ccol",popt_save.ccol);
      cstyle = qualifier("cstyle",popt_save.cstyle);
      mcol = qualifier("mcol",popt_save.mcol);

      dores = qualifier("res",dores);
   }

   if( ccol == NULL ) ccol = mcol;
   if( cstyle == NULL || 
       (typeof(cstyle) != Integer_Type && typeof(cstyle) != Long_Type) ) cstyle = 1;

   variable oline_style = get_plot_options().line_style;

   if( length(mcol) > 1 && length(mcol) > length(ccol) )
   {
      _for i (length(ccol),length(mcol)-1,1)
      {
         list_append(ccol,mcol[i]);
      }
   }
      
   variable yrange_tmp = qualifier("yrange",res_yrange);

   % First if block should only get executed if a yrange qualifier was
   % input

   if(length(yrange_tmp)<4)
   {
      res_yrange = {};
      _for i (0,length(yrange_tmp)-1,1)
      {
         list_append(res_yrange,yrange_tmp[i]);
      }
      _for i (length(yrange_tmp),3,1)
      {
         list_append(res_yrange,NULL);
      }
   }
   else
   {
      res_yrange = yrange_tmp;
   }

   variable fv_hold = Fit_Verbose;
   Fit_Verbose = -1;

   variable tmpfile="/tmp/plot_comps_"+string(getpid)+".par";
   save_par(tmpfile);

   % find all components that are a "norm" that aren't already 0,
   % aren't tied to another parameter, aren't a function of another
   % parameter, and won't break if set to 0

   variable normcomps = get_params("*");
   variable iw = Integer_Type[0];
   _for i (0,length(normcomps)-1,1)
   {
      if( normcomps[i].is_a_norm==1 &&
          normcomps[i].tie==NULL    &&
          normcomps[i].fun==NULL    &&
          ((normcomps[i].value>0 && normcomps[i].min<=0) ||  
           (normcomps[i].value<0 && normcomps[i].max>=0)   )
         )
         iw = [iw,i];
   } 
   normcomps = normcomps[iw];
   variable n_comps = length(normcomps);
   variable orig;
   
   variable first_plot=__qualifiers, middle_plot=@first_plot, 
            last_plot=@first_plot, res_plot=@first_plot, qfield;

   if(first_plot==NULL)
   { 
      first_plot = struct{dsym,dcol,decol,mcol,no_reset};
      middle_plot = struct{dsym,dcol,decol,oplt,no_reset};
      last_plot = struct{oplt,no_reset};
      res_plot = struct{yrange};
   }

   variable olist = {}, zlist = {};

   loop(length(args[0]))
   {
      list_append(olist,1);
      list_append(zlist,0);
   }

   % When doing model components, try to keep the data semi-hidden
   foreach qfield (["dsym","dcol","decol","mcol","res","no_reset"])
   {
      ifnot(struct_field_exists(first_plot,qfield))
      { 
         first_plot = struct_combine(first_plot,qfield);
      }
   }
   set_struct_field(first_plot, "dcol", zlist);
   set_struct_field(first_plot, "dsym", olist);
   set_struct_field(first_plot, "mcol", zlist);
   set_struct_field(first_plot, "res", 0);
   set_struct_field(first_plot, "no_reset", 1);

   foreach qfield (["dsym","dcol","decol","mcol","res","oplt","no_reset"])
   {
      ifnot(struct_field_exists(middle_plot,qfield))
      { 
         middle_plot = struct_combine(middle_plot,qfield);
      }
   }
   set_struct_field(middle_plot, "dcol", zlist);
   set_struct_field(middle_plot, "dsym", olist);
   set_struct_field(middle_plot, "mcol", ccol);
   set_struct_field(middle_plot, "res", 0);
   set_struct_field(middle_plot, "oplt", 1);
   set_struct_field(middle_plot, "no_reset", 1);

   foreach qfield (["res","oplt","no_reset"])
   {
      ifnot(struct_field_exists(last_plot,qfield))
      { 
         last_plot = struct_combine(last_plot,qfield);
      }
   }
   set_struct_field(last_plot, "res", 0);
   set_struct_field(last_plot, "oplt", 1);
   set_struct_field(last_plot, "no_reset", qualifier("no_reset", 0));

   if (dores)
   {
      set_struct_field(last_plot, "no_reset", 1);
      ifnot(struct_field_exists(res_plot,"yrange")) 
         res_plot = struct_combine(res_plot,"yrange");
      res_plot.yrange = res_yrange;
      multiplot([3,1]);
      mpane(1);
   }

   if(_NARGS<3)
   {
      @args[1](args[0];; first_plot);
   }
   else 
   {
      @args[2](args[0],popt_save;; first_plot);
   }

   % here is the main loop:   
   _for i (0,n_comps-1,1)
   { 
      load_par(tmpfile);
      orig = normcomps[i].value;
      _for j (0,n_comps-1,1) { set_par(normcomps[j].name,0.); };
      set_par(normcomps[i].name, orig);
      ()=eval_counts;

      line_style(cstyle);
      if(_NARGS<3)
      {
         @args[1](args[0];; middle_plot);
      }
      else 
      {
         @args[2](args[0],popt_save;; middle_plot);
      }
   };

   % And the final data plot ...
   load_par(tmpfile);
   ()=eval_counts;

   line_style(oline_style);
   if(_NARGS<3)
   {
      @args[1](args[0];; last_plot);
   }
   else 
   {
      @args[2](args[0],popt_save;; last_plot);
   }

   if (dores)
   {
      mpane(2);
      if(_NARGS<3)
      {
         plot_residuals(args[0];; res_plot);
      }
      else 
      {
         plot_residuals(args[0],popt_save;; res_plot);
      }
   }   
   () = remove(tmpfile);

   Fit_Verbose = fv_hold;
};

%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define plot_double()
%!%+
%\function{plot_double}
%\synopsis{Use two different plot functions in the same figure (isis_fancy_plots package)}
%\description
%
%plot_double({data},pstruct,&plot_funcI,&plot_funcII);  % pstruct=struct{dcol, mcol, ...}
%plot_double({data},&plot_funcI,&plot_funcII;dcol={val},mcol={val},ccol={val},...);
%
%  Using fancy plotting functions, e.g., plot_counts or plot_data or
%  plot unfold, passed as references, apply plot_funcI in the upper
%  panel and plot_funcII in the lower panel.  (If residuals are chosen
%  to be displayed, include a third panel for them beneath the first
%  two plots.)  In each plot, cycle through all the components with a
%  norm parameter.  Plot each of these as a separate model component.
%  The plot functions now take two additional optional qualifiers
%  (which alternatively can be passed via the pstruct structure
%  variable): ccol and cstyle.  The ccol parameter gives the color of
%  the model components for each dataset, which can be different from
%  the color of the model for the complete model.  The cstyle allows a
%  global change of the line_style for *all* of the model components.
%  (I.e., only one alternate line_style can be chosen.)  data is the
%  usual combination of integers (=individual data sets), arrays (=data
%  sets to be combined), and lists (=id of combined datasets). Plot
%  parameters retain their usual meaning, with the exception of yrange
%  and power.  yrange is now a list of up to 6 elements, with the first
%  two applying to plot_funcI, the next two applying to plot_funcII,
%  and the final two applying to the residuals. If power is a list of
%  two elements, then the first element applies to plot_funcI and the
%  second element applies to plot_funcII.
%
%\examples
%    plot_double({1,[2,3]},popt,&plot_unfold,&plot_counts;xrange={1,10});
%    plot_double({5,8},&plot_unfold,&plot_data);
%    plot_double({{1}},popt,&plot_data,&plot_counts);
%\seealso{plot_counts, plot_data, plot_unfold, plot_residuals, plot_fit_model, plotxy, plot_comps, plot_double}
%!%-
{
   variable args;
   if(_NARGS == 3 || _NARGS==4)
   {
      args = __pop_list(_NARGS);
   }
   else
   {
      () = fprintf(fp, "%s\n", %%%{{{
`
plot_double({data},pstruct,&plot_funcI,&plot_funcII);  % pstruct=struct{dcol, mcol, ...}
plot_double({data},&plot_funcI,&plot_funcII;dcol={val},mcol={val},ccol={val},...);

  Using fancy plotting functions, e.g., plot_counts or plot_data or
  plot unfold, passed as references, apply plot_funcI in the upper
  panel and plot_funcII in the lower panel.  (If residuals are chosen
  to be displayed, include a third panel for them beneath the first
  two plots.)  In each plot, cycle through all the components with a
  norm parameter.  Plot each of these as a separate model component.
  The plot functions now take two additional optional qualifiers
  (which alternatively can be passed via the pstruct structure
  variable): ccol and cstyle.  The ccol parameter gives the color of
  the model components for each dataset, which can be different from
  the color of the model for the complete model.  The cstyle allows a
  global change of the line_style for *all* of the model components.
  (I.e., only one alternate line_style can be chosen.)  data is the
  usual combination of integers (=individual data sets), arrays (=data
  sets to be combined), and lists (=id of combined datasets). Plot
  parameters retain their usual meaning, with the exception of yrange
  and power.  yrange is now a list of up to 6 elements, with the first
  two applying to plot_funcI, the next two applying to plot_funcII,
  and the final two applying to the residuals. If power is a list of
  two elements, then the first element applies to plot_funcI and the
  second element applies to plot_funcII.  Examples:

    plot_double({1,[2,3]},popt,&plot_unfold,&plot_counts;xrange={1,10});
    plot_double({5,8},&plot_unfold,&plot_data);
    plot_double({{1}},popt,&plot_data,&plot_counts);
`                  );          %%%}}}
      return;
   }

   variable i, j, res_yrange={NULL,NULL,NULL,NULL,NULL,NULL}, d1_yrange, d2_yrange;
   variable dores = qualifier("res",0);
   variable puse, pdo = qualifier("power",NULL);
   variable ccol = qualifier("ccol",NULL);
   variable cstyle = qualifier("cstyle",1);
   variable mcol = qualifier("mcol",NULL);

   if(_NARGS == 4)
   {
      variable popt_save = @args[1];
      dores = popt_save.res;
      dores = qualifier("res",dores);
      pdo = popt_save.power;
      pdo = qualifier("power",NULL);

      res_yrange = {};
      _for i (0,length(popt_save.yrange)-1,1)
      {
         list_append(res_yrange,popt_save.yrange[i]);
      }
      _for i (length(popt_save.yrange),5,1)
      {
         list_append(res_yrange,NULL);
      }

      ccol = qualifier("ccol",popt_save.ccol);
      cstyle = qualifier("cstyle",popt_save.cstyle);
      mcol = qualifier("mcol",popt_save.mcol);
   }

   if( ccol == NULL ) ccol = mcol;
   if( cstyle == NULL || 
       (typeof(cstyle) != Integer_Type && typeof(cstyle) != Long_Type) ) cstyle = 1;

   variable oline_style = get_plot_options().line_style;

   if( length(mcol) > 1 && length(mcol) > length(ccol) )
   {
      _for i (length(ccol),length(mcol)-1,1)
      {
         list_append(ccol,mcol[i]);
      }
   }

   variable yrange_tmp = qualifier("yrange",res_yrange);
   if(length(yrange_tmp)==1) yrange_tmp={};

   _for i (length(yrange_tmp),5,1)
   {
      list_append(yrange,NULL);
   }

   d1_yrange = {yrange_tmp[0],yrange_tmp[1]};
   d2_yrange = {yrange_tmp[2],yrange_tmp[3]};
   res_yrange = {yrange_tmp[4],yrange_tmp[5]};

   variable fv_hold = Fit_Verbose;
   Fit_Verbose = -1;

   variable tmpfile="/tmp/plot_double_"+string(getpid)+".par";
   save_par(tmpfile);

   % find all components that are a "norm" that aren't already 0,
   % aren't tied to another parameter, aren't a function of another
   % parameter, and won't break if set to 0

   variable normcomps = get_params("*");
   variable iw = Integer_Type[0];
   _for i (0,length(normcomps)-1,1)
   {
      if( normcomps[i].is_a_norm==1 &&
          normcomps[i].tie==NULL    &&
          normcomps[i].fun==NULL    &&
          ((normcomps[i].value>0 && normcomps[i].min<=0) ||  
           (normcomps[i].value<0 && normcomps[i].max>=0)   )
         )
         iw = [iw,i];
   } 
   normcomps = normcomps[iw];
   variable n_comps = length(normcomps);
   variable orig;
   
   variable first_plot=__qualifiers, middle_plot=@first_plot, 
            last_plot=@first_plot, res_plot=@first_plot, qfield;

   if(first_plot==NULL)
   { 
      first_plot = struct{dsym,dcol,decol,mcol,power,yrange,no_reset};
      middle_plot = struct{dsym,dcol,decol,power,yrange,oplt,no_reset};
      last_plot = struct{power,yrange,oplt,no_reset};
      res_plot = struct{yrange};
   }

   variable olist = {}, zlist = {};

   loop(length(args[0]))
   {
      list_append(olist,1);
      list_append(zlist,0);
   }

   % When doing model components, try to keep the data semi-hidden
   foreach qfield (["dsym","dcol","decol","mcol","yrange","res","no_reset","power"])
   {
      ifnot(struct_field_exists(first_plot,qfield))
      { 
         first_plot = struct_combine(first_plot,qfield);
      }
   }
   puse=pdo[0];
   set_struct_field(first_plot, "dcol", zlist);
   set_struct_field(first_plot, "dsym", olist);
   set_struct_field(first_plot, "mcol", zlist);
   set_struct_field(first_plot, "power", puse);
   set_struct_field(first_plot, "yrange", d1_yrange);
   set_struct_field(first_plot, "res", 0);
   set_struct_field(first_plot, "no_reset", 1);

   foreach qfield (["dsym","dcol","decol","yrange","mcol","res","oplt","no_reset","power"])
   {
      ifnot(struct_field_exists(middle_plot,qfield))
      { 
         middle_plot = struct_combine(middle_plot,qfield);
      }
   }
   set_struct_field(middle_plot, "dcol", zlist);
   set_struct_field(middle_plot, "dsym", olist);
   set_struct_field(middle_plot, "yrange", d1_yrange);
   set_struct_field(middle_plot, "power", puse);
   set_struct_field(middle_plot, "mcol", ccol);
   set_struct_field(middle_plot, "res", 0);
   set_struct_field(middle_plot, "oplt", 1);
   set_struct_field(middle_plot, "no_reset", 1);

   foreach qfield (["res","yrange","oplt","no_reset","power"])
   {
      ifnot(struct_field_exists(last_plot,qfield))
      { 
         last_plot = struct_combine(last_plot,qfield);
      }
   }
   set_struct_field(last_plot, "yrange", d1_yrange);
   set_struct_field(last_plot, "power", puse);
   set_struct_field(last_plot, "res", 0);
   set_struct_field(last_plot, "oplt", 1);
   set_struct_field(last_plot, "no_reset", 1);

   if (dores)
   {
      ifnot(struct_field_exists(res_plot,"yrange")) 
         res_plot = struct_combine(res_plot,"yrange");
      res_plot.yrange = res_yrange;
      multiplot([5,5,2]);
   }
   else
   {
      multiplot([1,1]);
   }

%%%  First Plot %%%

   mpane(1);

   if(_NARGS<4)
   {
      @args[1](args[0];; first_plot);
   }
   else 
   {
      @args[2](args[0],popt_save;; first_plot);
   }

   % here is the main loop:   
   _for i (0,n_comps-1,1)
   { 
      load_par(tmpfile);
      orig = normcomps[i].value;
      _for j (0,n_comps-1,1) { set_par(normcomps[j].name,0.); };
      set_par(normcomps[i].name, orig);
      ()=eval_counts;

      line_style(cstyle);
      if(_NARGS<4)
      {
         @args[1](args[0];; middle_plot);
      }
      else 
      {
         @args[2](args[0],popt_save;; middle_plot);
      }
   };

   % And the final data plot ...
   load_par(tmpfile);
   ()=eval_counts;

   line_style(oline_style);
   if(_NARGS<4)
   {
      @args[1](args[0];; last_plot);
   }
   else 
   {
      @args[2](args[0],popt_save;; last_plot);
   }

%%%  Second Plot %%%

   mpane(2);

   if(length(pdo)>1)
   {
      puse=pdo[1];
      set_struct_field(first_plot, "power", puse);
      set_struct_field(middle_plot, "power", puse);
      set_struct_field(last_plot, "power", puse);
   }
   set_struct_field(first_plot, "yrange", d2_yrange);
   set_struct_field(middle_plot, "yrange", d2_yrange);
   set_struct_field(last_plot, "yrange", d2_yrange);

   if(_NARGS<4)
   {
      @args[2](args[0];; first_plot);
   }
   else 
   {
      @args[3](args[0],popt_save;; first_plot);
   }

   % here is the main loop:   
   _for i (0,n_comps-1,1)
   { 
      load_par(tmpfile);
      orig = normcomps[i].value;
      _for j (0,n_comps-1,1) { set_par(normcomps[j].name,0.); };
      set_par(normcomps[i].name, orig);
      ()=eval_counts;

      line_style(cstyle);
      if(_NARGS<4)
      {
         @args[2](args[0];; middle_plot);
      }
      else 
      {
         @args[3](args[0],popt_save;; middle_plot);
      }
   };

   % And the final data plot ...
   load_par(tmpfile);
   ()=eval_counts;

   line_style(oline_style);
   if(_NARGS<4)
   {
      @args[2](args[0];; last_plot);
   }
   else 
   {
      @args[3](args[0],popt_save;; last_plot);
   }

%%% And the residuals %%%

   if (dores)
   {
      mpane(3);
      if(_NARGS<4)
      {
         plot_residuals(args[0];; res_plot);
      }
      else 
      {
         plot_residuals(args[0],popt_save;; res_plot);
      }
   }   
   () = remove(tmpfile);

   Fit_Verbose = fv_hold;
};
