require("get_component.sl");
require( "xfig" );

define plot_component() {
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{plot_component}
%\synopsis{to plot modelfit parameters of different components}
%\usage{plot_component([array of \code{struct comp}]);}
%\qualifiers{
%\qualifier{outputfile}{outputfile name and directory by hand}
%\qualifier{mjd_min}{[=53736.0] lower limit of time axis in mjd (default: 1/1/2006)}
%\qualifier{mjd_max}{[=55927.0] upper limit of time axis in mjd (default: 1/1/2012)}
%\qualifier{date_min}{[=2006.0] lower limit of time axis (default: 1/1/2006)}
%\qualifier{date_max}{[=2012.0] upper limit of time axis (default: 1/1/2012)}
%\qualifier{distance_min}{[=-2] lower limit of distance axis in mas}
%\qualifier{distance_max}{[=20] upper limit of distance axis in mas}
%\qualifier{flux_min}{[=1e-5] lower limit of flux axis in Jy}
%\qualifier{flux_max}{[=5] upper limit of flux axis in Jy}
%\qualifier{TB_min}{[=10^5] lower limit of brightness temperature axis in K}
%\qualifier{TB_max}{[=10^15] upper limit of brightness temperature axis in K}
%\qualifier{size_min}{[=1e-3] lower limit of size axis in mas^2}
%\qualifier{size_max}{[=100] upper limit of size axis in mas^2}
%\qualifier{pos_min}{[=-180] lower limit of pos angle in degrees}
%\qualifier{pos_max}{[=180] upper limit of pos angle in degrees}
%\qualifier{labels}{[=default] provide array of custom labels for the components}
%\qualifier{sym}{[=default] provide array of custom symbols for the components}
%\qualifier{symcolor}{[=default] provide array of custom colors for the components}
%\qualifier{symsize}{[=1] provide array of custom symbol sizes or one value to apply size to all}
%\qualifier{legend}{create a legend}
%\qualifier{lpos_x}{set the x position of the legend in world0 system (0 = left, 1=right)}
%\qualifier{lpos_y}{set the y position of the legend in world0 system (0 = bottom, 1=top)}
%\qualifier{linestyle}{[=default] set to 0 if the flux values should not be conntected (or to another value for 
% 					another line style}
%\qualifier{nocomp}{provide a comp structure (or array of structures) to plot not identified components in black}
%\qualifier{plots}{[=[9,10,3,4,11,12]]: provide an array of numbers to generated specified plots:
%					1:	distance vs mjd
%					2:	flux vs mjd
%					3:	T_B vs distance
%					4:	flux vs distance
%					5:	size vs distance 
%					6:	pos angle vs distance	
%					7:	size vs mjd
%					8:	pos angle vs mjd
%					9:	distance vs time
%					10:	flux vs time
%					11:	size vs time
%					12:	pos_angle vs time }
%}
%\description
%This functions creates overview plots for modelfit components. The required input format is the comp structure which can be obtained with get_component or an array of the comp structure.
%!%-
variable comp;
  switch(_NARGS)
  { case 1: (comp) = (); }
  { help(_function_name()); return; }

variable ii, jj;
variable major_ticks, minor_ticks;
variable mjd_min	= qualifier("mjd_min", 53736.0); % 1.1.2006
variable mjd_max	= qualifier("mjd_max", 55927.0); % 1.1.2012
variable date_min	= qualifier("date_min", 2006.0);
variable date_max	= qualifier("date_max", 2012.0);
variable distance_min	= qualifier("distance_min", -2);
variable distance_max	= qualifier("distance_max", 20);
variable flux_min	= qualifier("flux_min", 1e-5); % Jy
variable flux_max	= qualifier("flux_max", 5); % Jy
variable tb_min		= qualifier("tb_min", 10^5);
variable tb_max		= qualifier("tb_max", 10^15);
variable size_min	= qualifier("size_min", 1e-3);
variable size_max	= qualifier("size_max", 100);
variable pos_min	= qualifier("pos_min", -180);
variable pos_max	= qualifier("pos_max", 180);
variable dlabels	= qualifier("labels");
variable dsym		= qualifier("sym");
variable dsymcolor	= qualifier("symcolor");
variable dsymsize	= qualifier("symsize");
variable plots		= qualifier("plots",[9,10,3,4,11,12]);
variable x_legend	= qualifier("lpos_x",0.875);
variable y_legend	= qualifier("lpos_y",0.95);

if(qualifier_exists("symsize") == 0) {
	print("default symbol sizes selected");
	dsymsize = ones(length(comp));
}

if(qualifier_exists("symsize") == 1) {
  if(length(dsymsize) == 1) {
    variable copy_dsymsize = dsymsize;
    dsymsize = Double_Type [length(comp)];
    _for ii (0, length(comp)-1, 1){
      dsymsize[ii] = copy_dsymsize;
    }
  }
}

if(qualifier_exists("sym") == 0) {
	print("default symbols selected");
	dsym = Integer_Type [length(comp)];
	_for jj (0, length(comp)-1, 1){
	dsym[jj] = jj mod 9 + 1;
	}	
}

if(qualifier_exists("symcolor") == 0) {
	print("default symbol colors selected");
	dsymcolor = Integer_Type [length(comp)];
	dsymcolor = [16,5,23,17,11,8,2,20,14,13,19,31,33,32,18,12,6,15,21];
}

if(qualifier_exists("labels") == 0) {
	print("default labels selected");
	dlabels = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];
	if(length(comp) > length(dlabels)) {
	print("NO default labels possible!");
	exit(-1);
	}
}

variable pl, pl_comp, pl_all, npl, npl_comp, obj, box;

npl = length(plots);
pl = Struct_Type [npl];
obj = Struct_Type [npl];
box = Struct_Type [npl];

_for ii (0, npl-1, 1){
pl[ii] = xfig_plot_new(10., 10.);

switch(plots[ii]) 
	{ case 1:
	pl[ii].world( mjd_min, mjd_max,distance_min,distance_max);
	pl[ii].xlabel("Epoch [MJD]");
	pl[ii].ylabel("Distance [mas]");
	major_ticks = [-100:100:5];
	minor_ticks = [-100:100:1];
	pl[ii].y1axis(; major=major_ticks, minor= minor_ticks, world1);
	}
	{ case 2:
	pl[ii].world(mjd_min, mjd_max, flux_min, flux_max; ylog);
	pl[ii].xlabel("Epoch [MJD]");
	pl[ii].ylabel("Flux [Jy]");
	}
	{ case 3:
	pl[ii].world(distance_min, distance_max, tb_min, tb_max; ylog);
	pl[ii].xlabel("Distance [mas]");
	pl[ii].ylabel("$\mathrm{T_B}$ [K]"R);
	}
	{ case 4:
	pl[ii].world(distance_min, distance_max, flux_min, flux_max; ylog);
	pl[ii].xlabel("Distance [mas]");
	pl[ii].ylabel("Flux [Jy]");
	}
	{ case 5:
	pl[ii].world(distance_min, distance_max, size_min, size_max; ylog);
	pl[ii].xlabel("Distance [mas]");
	pl[ii].ylabel("A $\mathrm{[mas^2]}$"R);
	}
	{ case 6:
	pl[ii].world(distance_min, distance_max, pos_min, pos_max);
	pl[ii].xlabel("Distance [mas]");
	pl[ii].ylabel("Position Angle [deg]");
	}
	{ case 7:
	pl[ii].world(mjd_min, mjd_max, size_min, size_max;ylog);
	pl[ii].xlabel("Epoch [MJD]");
	pl[ii].ylabel("A $\mathrm{[mas^2]}$"R);
	}
	{ case 8:
	pl[ii].world(mjd_min, mjd_max, pos_min, pos_max);
	pl[ii].xlabel("Epoch [MJD]");
	pl[ii].ylabel("Position Angle [deg]");
	}
	{ case 9:
	pl[ii].world( date_min, date_max, distance_min,distance_max);
	pl[ii].xlabel("Epoch [y]");
	pl[ii].ylabel("Distance [mas]");
	major_ticks = [-100:100:5];
	minor_ticks = [-100:100:1];
	pl[ii].y1axis(; major=major_ticks, minor= minor_ticks, world1);
	}
	{ case 10:
	pl[ii].world(date_min, date_max, flux_min, flux_max; ylog);
	pl[ii].xlabel("Epoch [y]");
	pl[ii].ylabel("Flux [Jy]");
	}
	{ case 11:
	pl[ii].world(date_min, date_max, size_min, size_max;ylog);
	pl[ii].xlabel("Epoch [y]");
	pl[ii].ylabel("A $\mathrm{[mas^2]}$"R);
	}
	{ case 12:
	pl[ii].world(date_min, date_max, pos_min, pos_max);
	pl[ii].xlabel("Epoch [y]");
	pl[ii].ylabel("Position Angle [deg]");
	}

%create a rectangle for the legend in every plot
if(qualifier_exists("legend")==1){	
  box[ii] = xfig_new_rectangle (2.25, 0.4*(1+length(comp)));
  box[ii].set_area_fill (-1);
  box[ii].set_fill_color ("white");
  pl[ii].add_object (box[ii], x_legend, y_legend-length(comp)/50.;world00);
}

}

% loop over all components
_for jj (0, length(comp)-1, 1) {
  %Legend
  _for ii (0, npl-1, 1){
    if(qualifier_exists("legend")==1){
      obj[ii] = xfig_new_text (dlabels[jj]);
      pl[ii].add_object(obj[ii], x_legend + 0.025 , y_legend-0.025-jj/25.;world00);
      pl[ii].plot(x_legend-0.075,  y_legend-0.025-jj/25.; size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj],world00);
    }
  switch(plots[ii]) 
  { case 1:
  pl[ii].plot(comp[jj].mjd, comp[jj].distance; size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj],line = qualifier("linestyle",2), world1);
  }
  { case 2:
  pl[ii].plot(comp[jj].mjd, comp[jj].flux, 0.15*comp[jj].flux; eb_color=dsymcolor[jj], size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj], line = qualifier("linestyle",2), world1);
  }
  { case 3:
  pl[ii].plot(comp[jj].distance, comp[jj].tb; size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj], line = qualifier("linestyle",2), world1);
  }
  { case 4:
  pl[ii].plot(comp[jj].distance, comp[jj].flux, 0.15*comp[jj].flux; eb_color=dsymcolor[jj], size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj], line = qualifier("linestyle",2), world1);
  }
  { case 5:
  pl[ii].plot(comp[jj].distance, comp[jj].size; size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj], line = qualifier("linestyle",2), world1);
  }
  { case 6:
  pl[ii].plot(comp[jj].distance, comp[jj].posangle; size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj], line = qualifier("linestyle",2), world1);
  }
  { case 7:
  pl[ii].plot(comp[jj].mjd, comp[jj].size; size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj], line = qualifier("linestyle",2), world1);
  }
  { case 8:
  pl[ii].plot(comp[jj].mjd, comp[jj].posangle; size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj], line = qualifier("linestyle",2), world1);
  }
  { case 9:
  pl[ii].plot(comp[jj].date, comp[jj].distance; size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj],line = qualifier("linestyle",2), world1);
  }
  { case 10:
  pl[ii].plot(comp[jj].date, comp[jj].flux, 0.15*comp[jj].flux; eb_color=dsymcolor[jj], size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj], line = qualifier("linestyle",2), world1);
  }
  { case 11:
  pl[ii].plot(comp[jj].date, comp[jj].size; size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj], line = qualifier("linestyle",2), world1);
  }
  { case 12:
  pl[ii].plot(comp[jj].date, comp[jj].posangle; size=dsymsize[jj], sym=dsym[jj], symcolor=dsymcolor[jj], line = qualifier("linestyle",2), world1);
  }
  }
}

if(qualifier_exists("nocomp")) {
variable nocomp = qualifier("nocomp",NULL);
  _for ii (0, npl-1, 1){
    switch(plots[ii]) 
    { case 1:
    pl[ii].plot(nocomp.mjd, nocomp.distance; size=0.7, sym=5, symcolor="black", world1);
    }
    { case 2:
    pl[ii].plot(nocomp.mjd, nocomp.flux, 0.15*nocomp.flux; eb_color="black", size=0.7, sym=5, symcolor="black", world1);
    }
    { case 3:
    pl[ii].plot(nocomp.distance, nocomp.tb;  size=0.7, sym=5, symcolor="black", world1);
    }
    { case 4:
    pl[ii].plot(nocomp.distance, nocomp.flux, 0.15*nocomp.flux; eb_color="black", size=0.7, sym=5, symcolor="black", world1);
    }
    { case 5:
    pl[ii].plot(nocomp.distance, nocomp.size; size=0.7, sym=5, symcolor="black", world1);
    }
    { case 6:
    pl[ii].plot(nocomp.distance, nocomp.posangle; size=0.7, sym=5, symcolor="black", world1);
    }
    { case 7:
    pl[ii].plot(nocomp.mjd, nocomp.size;  size=0.7, sym=5, symcolor="black", world1);
    }
    { case 8:
    pl[ii].plot(nocomp.mjd, nocomp.posangle; size=0.7, sym=5, symcolor="black", world1);
    }
    { case 9:
    pl[ii].plot(nocomp.date, nocomp.distance; size=0.7, sym=5, symcolor="black", world1);
    }
    { case 10:
    pl[ii].plot(nocomp.date, nocomp.flux, 0.15*nocomp.flux; eb_color="black", size=0.7, sym=5, symcolor="black", world1);
    }
    { case 11:
    pl[ii].plot(nocomp.date, nocomp.size;  size=0.7, sym=5, symcolor="black", world1);
    }
    { case 12:
    pl[ii].plot(nocomp.date, nocomp.posangle; size=0.7, sym=5, symcolor="black", world1);
    }
  }
}



if(npl mod 2 == 1) {
  npl_comp = npl / 2 + 1;
  pl_comp = Struct_Type [npl_comp];
    _for ii (0, npl / 2 - 1, 1) {
	pl_comp[ii] = xfig_new_hbox_compound (pl[ 2 * ii ], pl[2 * ii + 1], 0.5);
    }
   pl_comp[npl / 2] = xfig_new_hbox_compound (pl[npl -1], 0.5);
} else {
  npl_comp = npl / 2;
  pl_comp = Struct_Type [npl_comp];
  _for ii (0, npl_comp-1, 1) {
    pl_comp[ii] = xfig_new_hbox_compound (pl[ 2 * ii ], pl[2 * ii+1], 0.5);
  }
}


switch(npl_comp) 
  { case 1:
  pl_all = xfig_new_vbox_compound (pl_comp[0], 0.5);
  }
  { case 2:
  pl_all = xfig_new_vbox_compound (pl_comp[0], pl_comp[1], 0.5);
  }
  { case 3:
  pl_all = xfig_new_vbox_compound (pl_comp[0], pl_comp[1], pl_comp[2], 0.5);
  }
  { case 4:
  pl_all = xfig_new_vbox_compound (pl_comp[0], pl_comp[1], pl_comp[2], pl_comp[3], 0.5);
  }
  { case 5:
  pl_all = xfig_new_vbox_compound (pl_comp[0], pl_comp[1], pl_comp[2], pl_comp[3], pl_comp[4], 0.5);
  }
  { case 6:
  pl_all = xfig_new_vbox_compound (pl_comp[0], pl_comp[1], pl_comp[2], pl_comp[3], pl_comp[4], pl_comp[5], 0.5);
  }

if(qualifier_exists("outputfile")==1) {
variable outfile = qualifier("outputfile");
pl_all.render(outfile);
}

return pl_all;
}

