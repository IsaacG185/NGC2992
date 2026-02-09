require( "xfig" ); 

%%%%%%%%%%%%%%
define SRT_get_mw_spectra() {
%%%%%%%%%%%%%%
%!%+
%\function{SRT_get_mw_spectra}
%\synopsis{computes Milky Way spectrum from SRT data}
%\usage{Struct_Type[] spectra = SRT_get_mw_spectra(Struct_Type data, Integer_Type[] chunks}
%\description
%	This function requires as input the SRT data in the format
%	given by SRT_read() and an array of integer numbers which are the chunks
%	with the spectrum data. If an array of chunk numbers is given then all
%	corresponding spectra are calculated and returned.
%	The spectra are determined with SRT_spectrum and all qualifiers of this
%	function can be used.
%\example
%	variable data = SRT_read("milkyway.rad");
%	variable spectra = SRT_get_mw_spectra(data,[1,4,7]);
%\seealso{SRT_spectrum, SRT_read}
%!%-

	variable data,chunks;
	switch(_NARGS)
	{ case 2: (data, chunks) = (); }
	{ help(_function_name()); return; }

	%find out how many spectra should be plotted
	variable spectra = Struct_Type[length(chunks)];
	variable i;

	%get data of the spectra
	for (i=0; i<length(chunks); i++) {
		spectra[i] = SRT_spectrum(data[chunks[i]];;__qualifiers);
	}

	return spectra;
}

%%%%%%%%%%%%%%
define SRT_plot_mw_spectra() {
%%%%%%%%%%%%%%
%!%+
%\function{SRT_plot_mw_spectra}
%\synopsis{plots Milky Way spectra from SRT data}
%\usage{SRT_plot_mw_spectra(Struct_Type[] spectrum);}
%\altusage{SRT_plot_mw_spectra(Struct_Type[] data, Integer_Type[] chunks);}
%\qualifiers{
%\qualifier{pad}{additional space between plot frame and data limits}
%\qualifier{fMax}{give the frequency of the cloud to be plotted, has to be of same length as spectra/chunks}
%\qualifier{fConfMax}{upper confidence level of the maximal frequency of the cloud to be plotted, has to be of same length as spectra/chunks}
%\qualifier{fConfMin}{lower confidence level of the maximal frequency of the cloud to be plotted, has to be of same length as spectra/chunks}
%\qualifier{fMaxLin}{type of line used to plot fMax}
%\qualifier{fConfLine}{type of line used to plot fConfMin and fConfMax}
%\qualifier{xlabel}{label for x-axis}
%\qualifier{ylabel}{label for y-axis}
%\qualifier{title}{title for plot, either as single title or for each plot individually as an array of strings}
%\qualifier{name}{file name of plot, either a single one or for each plot as a an array of string, specify file format, i.e., mw_scan.pdf}
%\qualifier{return_xfig}{return xfig-data instead of plotting}
%}
%\description
%	The function automatically plots Milky Way spectra obtained with the SRT.
%	It can be given a single or an array of spectra or the data and an array of chunk numbers. The required data format is based on the output of SRT_get_mw_spectrum and all of its qualifiers can be used.
%	It is possible to give the previously determined maximal frequency of the cloud and its upper and lower confidence interval as qualifier. This will create lines in the plot at the provided frequency.
%\seealso{SRT_get_mw_spectra, SRT_read, SRT_spectrum}
%!%-
%}

	variable spectra, data, chunks;
	switch(_NARGS)
	{ case 1: spectra = (); }
	{ case 2: (data, chunks) = (); }
	{ help(_function_name()); return; }

	%get spectra data
	if(_NARGS==2)
		spectra = SRT_get_mw_spectra(data,chunks;;__qualifiers);

	%create as many plots as spectra
	variable nSpectra = length(spectra);
	variable pl = Struct_Type[nSpectra];

	variable i, xmin, xmax, ymin, ymax, title, name;
	variable world_qualis = struct {
		padx = qualifier("pad",0.05),
		pady = qualifier("pad",0.05),
	};

	%allow plotting of max frequency and confidence interval
	%have to be of same length as number of spectra
	variable fMax, fConfMin, fConfMax;
	variable plot_fMax, plot_fConfMin, plot_fConfMax;
	if(qualifier_exists("fMax") && length(qualifier("fMax")) == nSpectra) {
		fMax = qualifier("fMax");
		plot_fMax = 1;
	}
	else
		plot_fMax = 0;
	
	if(qualifier_exists("fConfMin") && length(qualifier("fConfMin")) == nSpectra) {
		fConfMin = qualifier("fConfMin");
		plot_fConfMin = 1;
	}
	else
		plot_fConfMin = 0;
	
	if(qualifier_exists("fConfMax") && length(qualifier("fConfMax")) == nSpectra) {
		fConfMax = qualifier("fConfMax");
		plot_fConfMax = 1;
	}
	else
		plot_fConfMax = 0;	

	%do the plotting
	for(i=0; i<nSpectra; i++) {
		xmin = min(spectra[i].bin_lo);
		xmax = max(spectra[i].bin_lo);
		ymin = min(spectra[i].value);
		ymax = max(spectra[i].value);

		pl[i] = xfig_plot_new();
		pl[i].world(xmin,xmax,ymin,ymax;;struct_combine(__qualifiers,world_qualis));
		pl[i].hplot(spectra[i].bin_lo,spectra[i].value;;__qualifiers);

		if(plot_fMax == 1)
			pl[i].plot([fMax[i],fMax[i]],[0.,1.];line = qualifier("fConfLine",0),world10);
		if(plot_fConfMax == 1)
			pl[i].plot([fConfMax[i],fConfMax[i]],[0.,1.];line = qualifier("fConfLine",1),world10);
		if(plot_fConfMin == 1)
			pl[i].plot([fConfMin[i],fConfMin[i]],[0.,1.];line = qualifier("fConfLine",1),world10);
		
		pl[i].x2axis(;ticlabels=0);
		pl[i].y2axis(;ticlabels=0);
		if(qualifier_exists("vLSR"))
			pl[i].xlabel("$v$ [km/s]"R);
		else if(qualifier_exists("xlabel"))
			pl[i].xlabel(qualifier("xlabel"));
		else
			pl[i].xlabel("$\nu$ [MHz]"R);

		if(qualifier_exists("ylabel"))
			pl[i].ylabel(qualifier("ylabel"));
		else
			pl[i].ylabel("$T_\mathrm{Ant}$ [K]"R);

		
		title = qualifier("title");
		if(qualifier_exists("title") && length(title)==1)
			pl[i].title(title);
		else if(qualifier_exists("title") && length(title) == nSpectra)
			pl[i].title(title[i]);

		name = qualifier("name");
		ifnot(qualifier_exists("return_xfig")){
			if(qualifier_exists("name") && length(name)==1) {
				if(i<10)
					pl[i].render("0"+string(i+1) + "_" + name);
				else 
					pl[i].render(string(i+1) + "_" + name);
			}
			else if(qualifier_exists("name") && length(name)==nSpectra)
				pl[i].render(name[i]);
			else {
				if(i<9)
					pl[i].render("mw_spec_0" + string(i+1) + ".pdf");
				else
					pl[i].render("mw_spec_" + string(i+1) + ".pdf");
			}
		}
	}

	if(qualifier_exists("return_xfig"))
		return pl;
}

