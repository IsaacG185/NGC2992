require( "xfig" );

%%%%%%%%%%%%%%%%%%%%%%%%
define xfigplot_hardnessratio_grid()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{xfigplot_hardnessratio_grid}
%\synopsis{plots hardness-grid and/or hardness-datapoints}
%\usage{xfigplot_hardnessratio_grid(Struct_Type tracks);
% or xfigplot_hardnessratio_grid(Struct_Type tracks, String_Type fits_hr_table
%    );}
%\qualifiers{
%\qualifier{outputdir}{String_Type, name of output directory,
%          default: 'testplot.pdf'}
%\qualifier{W}{Integer_Type, width of new xfig-plot}
%\qualifier{H}{Integer_Type, height of new xfig-plot}
%\qualifier{xrange}{Double_Type[2], range on x-axis}
%\qualifier{yrange}{Double_Type[2], range on y-axis}
%\qualifier{padx}{Double_Type, percentage of padding of whole plot in x direction,
%          default: 0.05}
%\qualifier{pady}{Double_Type, percentage of padding of whole plot in y direction,
%          default: 0.05}
%\qualifier{xlabel}{String_Type, label on x-axis}
%\qualifier{ylabel}{String_Type, label on y-axis}
%\qualifier{par1label}{String_Type, label within plot of par1}
%\qualifier{par1label_x}{Double_Type, x-position of 'par1label' as percentage 
%          (needs to be set, if 'par1label' is given)}
%\qualifier{par1label_y}{Double_Type, y-position of 'par1label' as percentage
%          (needs to be set, if 'par1label' is given)}
%\qualifier{par1label_c}{Integer_Type/String_Type, color of 'par1label' as RGB,
%          default: 0x000000 (black)}
%\qualifier{par2label}{String_Type, label within graph of par2}
%\qualifier{par2label_x}{Double_Type, x-position of 'par2label' as percentage
%          (needs to be set, if 'par2label' is given)}
%\qualifier{par2label_y}{Double_Type, y-position of 'par2label' as percentage
%          (needs to be set, if 'par2label' is given)}
%\qualifier{par2label_c}{Integer_Type/String_Type, color of 'par2label' as RGB,
%          default: 0x000000 (black)}
%\qualifier{extralabel}{String_Type, extra label within graph}
%\qualifier{extralabel_x}{Double_Type, x-position of 'extralabel' as percentage
%          (needs to be set, if 'extralabel' is given)}
%\qualifier{extralabel_y}{Double_Type, y-position of 'extralabel' as percentage
%          (needs to be set, if 'extralabel' is given)}
%\qualifier{extralabel_c}{Integer_Type/String_Type, color of 'extralabel' as RGB,
%          default: 0x000000 (black)}
%\qualifier{extralabel2}{String_Type, extra label within graph}
%\qualifier{extralabel2_x}{Double_Type, x-position of 'extralabel2' as percentage
%          (needs to be set, if 'extralabel' is given)}
%\qualifier{extralabel2_y}{Double_Type, y-position of 'extralabel2' as percentage
%          (needs to be set, if 'extralabel' is given)}
%\qualifier{extralabel2_c}{Integer_Type/String_Type, color of 'extralabel2' as RGB,
%          default: 0x000000 (black)}
%\qualifier{cstart}{Integer_Type/String_Type, start color of grid as RGB,
%          default: 0xC1CDCD (gray)}
%\qualifier{cstop}{Integer_Type/String_Type, stop color of grid as RGB}
%          default: 0xC1CDCD (gray)}
%\qualifier{lend1}{if exists, switch end (or begin) of tracks1 
%          (where each tracks' value will be assigned)}
%\qualifier{lend2}{if exists, switch end (or begin) of tracks2
%          (where each tracks' value will be assigned)}
%\qualifier{shift1x}{Double_Type, x-position of par1-values at end of track, default: 0.}
%\qualifier{shift1y}{Double_Type, y-position of par1-values at end of track, default: 0.}
%\qualifier{shift2x}{Double_Type, x-position of par2-values at end of track, default: 0.}
%\qualifier{shift2y}{Double_Type, y-position of par2-values at end of track, default: 0.}
%\qualifier{hr_x_col}{String_Type, name of hr_x-column ('fits_hr_table') for plotting datapoints}
%\qualifier{hr_y_col}{String_Type, name of hr_y-column ('fits_hr_table') for plotting datapoints}
%\qualifier{err_x_col}{String_Type, name of error_x-column ('fits_hr_table') for plotting datapoints}
%\qualifier{err_y_col}{String_Type, name of error_y-column  ('fits_hr_table)' for plotting datapoints}
%\qualifier{err_c}{Integer_Type/String_Type, color of errorbars as RGB
%          default: 0x000000 (black)}
%\qualifier{symbol_shape}{String_Type, shape of datapoints}
%\qualifier{symbol_size}{Double_Type, size of datapoints, default: 1.}
%\qualifier{symbol_cstart}{Integer_Type/String_Type, (start) color of datapoints as RGB}
%\qualifier{symbol_cstop}{Integer_Type/String_Type, stop color of datapoints as RGB,
%          if not given 'symbol_cstart' is color of all}
%\qualifier{source_col}{String_Type, name of source-column ('fits_hr_table') for plotting datapoints,
%          needs to be given only if different colors for different sources}
%\qualifier{extralabel_sources_x}{Double_Type, x-position of source_names as percentage
%          (if given, source names are displayed in their respective color)}
%\qualifier{extralabel_sources_y}{Double_Type, y-position of source_names as percentage
%\qualifier{tracks1}{Integer_Type, if given, only tracks1 are plottet}
%\qualifier{tracks2}{Integer_Type, if given, only tracks2 are plottet}
%\qualifier{notracks}{Integer_Type, if given, no tracks are plottet, 'fits_hr_table' must be
%          given for datapoints}
%}
%\description
%	- for only grid: give only tracks
%	- for grid with datapoints: give tracks and FITS-table with hardnessratios (and errors)
%       - for only datapoints: give tracks and FITS-table, but use 'notracks'-qualifier
%\seealso{hardnessratio_from_dataset}
%!%-
{
    variable i;
    variable pl, tracks, fits_hr_table;
    switch (_NARGS)
    { case 1: (tracks) = (); }
    { case 2: (tracks,fits_hr_table) = (); }
    { help(_function_name); return; }

    % create empty plot
    pl = xfig_plot_new(qualifier("W", 14), qualifier("H", 10)); 

    % set output directory  
    variable outputdir = qualifier("outputdir", "testplot.pdf");

    % check x/yrange-input
    if(qualifier_exists("xrange")){
      variable xrange = qualifier("xrange", NULL);
      if (length(xrange) != 2 ){
       vmessage("error (%s): xrange-qualifier must be array with 2 elements", _function_name);
       return;
      }
    }
    if(qualifier_exists("yrange")){
      variable yrange = qualifier("yrange", NULL);
      if (length(yrange) != 2 ){
        vmessage("error (%s): yrange-qualifier must be array with 2 elements", _function_name);
        return;
      }
    }

    % labels?
    variable xlabel = qualifier("xlabel", "x-axis");
    variable ylabel = qualifier("ylabel", "y-axis");
    variable par1label;
    variable par2label;
    variable extralabel;
    variable extralabel2;
    if(qualifier_exists("par1label")){par1label=qualifier("par1label");}
    if(qualifier_exists("par2label")){par2label=qualifier("par2label");}
    if(qualifier_exists("extralabel")){extralabel=qualifier("extralabel");}
    if(qualifier_exists("extralabel2")){extralabel2=qualifier("extralabel2");}
  
    % colors of grid?
    variable cstart = qualifier("cstart", 0xC1CDCD);
    variable cstop = qualifier("cstop", 0xC1CDCD);
    xfig_new_color("start",cstart);
    xfig_new_color("stop",cstop);
    variable col=String_Type[length(tracks)];
    _for i (0,length(tracks)-1,1) {
      col[i]=xfig_mix_colors("start","stop",i/(length(tracks)-1.));
    }

    % set world?
    variable padx = qualifier("padx",0.05);
    variable pady = qualifier("pady",0.05);
    if (pl.plot_data.world1_inited == 0) { 
      variable merge = merge_struct_arrays(tracks);
      if(qualifier_exists("xrange") && qualifier_exists("yrange")){
        pl.world(xrange[0],xrange[1],yrange[0],yrange[1]; padx=padx, pady=pady);
      }else if(qualifier_exists("xrange")){
        pl.world(xrange[0],xrange[1], min_max(merge.hr2); padx=padx, pady=pady);
      }else if(qualifier_exists("yrange")){
        pl.world(min_max(merge.hr1), yrange[0],yrange[1]; padx=padx, pady=pady);
      }else{
        pl.world(min_max(merge.hr1), min_max(merge.hr2); padx=padx, pady=pady);
      }
    }
  
    % lineend (where the numbers are plotted at the end of each track)
    variable lend1 = qualifier_exists("lend1") ? -1 : 0;
    variable lend2 = qualifier_exists("lend2") ? -1 : 0;

    % shift of numbers at each track
    variable shift1x =  qualifier("shift1x",0.);
    variable shift1y =  qualifier("shift1y",0.);
    variable shift2x =  qualifier("shift2x",0.);
    variable shift2y =  qualifier("shift2y",0.);

    variable ind1 = where( struct_array_2_struct_of_arrays( tracks ).linetype < 0 );
    variable ind2 = where( struct_array_2_struct_of_arrays( tracks ).linetype > 0 );
    % loop over all tracks

    variable tr1=0;
    variable tr2=0;
    variable notr=0;
    if(qualifier_exists("notracks")){notr=1;}
    if(qualifier_exists("tracks1")){tr1=1;}
    if(qualifier_exists("tracks2")){tr2=1;}

   if(notr == 0){
      if((tr1 == 1 && tr2 == 0) || (tr1 == 0 && tr2 == 0)){
       foreach i (ind1) {
         col[i]=xfig_mix_colors("start","stop",i/(length(ind1)-1.));
         pl.plot(tracks[i].hr1, tracks[i].hr2; line=0, color = col[i]);%,depth=1,width=3);
         pl.xylabel( tracks[i].hr1[lend1], tracks[i].hr2[lend1],
    	        sprintf("%.2f",tracks[i].par1[lend1]),shift1x,shift1y;color=col[i]);%,depth=1,width=3);
       }
      }

      if((tr2 == 1 && tr1 == 0) || (tr1 == 0 && tr2 == 0)){
       foreach i (ind2) {
         col[i]=xfig_mix_colors("start","stop",(i-min(ind2))/(length(ind2)-1.));
         pl.plot(tracks[i].hr1, tracks[i].hr2; line=0, color = col[i]);%,depth=1,width=3);
         pl.xylabel( tracks[i].hr1[lend2], tracks[i].hr2[lend2],
    	        sprintf("%.2f",tracks[i].par2[lend2]),shift2x,shift2y;color=col[i]);%,depth=1,width=3);
       }  
     }

   }

    % ensure all numbers have the same format
    pl.y1axis(; format="%.2f");
    pl.x1axis(; format="%.2f");

    % labels 
    pl.xlabel(xlabel);
    pl.ylabel(ylabel);
    if(qualifier_exists("par1label")){
      variable par1label_x = qualifier("par1label_x", 0.1);
      variable par1label_y = qualifier("par1label_y", 0.9);
      variable par1label_c = qualifier("par1label_c", 0x000000);
      pl.xylabel(par1label_x,par1label_y,sprintf(par1label);world0, color=par1label_c);%,depth=1,width=3);
    }
  
    if(qualifier_exists("par2label")){
      variable par2label_x = qualifier("par2label_x", 0.1);
      variable par2label_y = qualifier("par2label_y", 0.8);
      variable par2label_c = qualifier("par2label_c", 0x000000);
      pl.xylabel(par2label_x,par2label_y,sprintf(par2label);world0, color=par2label_c);%,depth=1,width=3); 
    }

    if(qualifier_exists("extralabel")){
      variable extralabel_x = qualifier("extralabel_x", 0.1);
      variable extralabel_y = qualifier("extralabel_y", 0.5);
      variable extralabel_c = qualifier("extralabel_c", 0x000000);
      pl.xylabel(extralabel_x,extralabel_y,sprintf(extralabel);world0, color=extralabel_c);%,depth=1); 
    }

    if(qualifier_exists("extralabel2")){
      variable extralabel2_x = qualifier("extralabel2_x", 0.1);
      variable extralabel2_y = qualifier("extralabel2_y", 0.5);
      variable extralabel2_c = qualifier("extralabel2_c", 0x000000);
      pl.xylabel(extralabel2_x,extralabel2_y,sprintf(extralabel2);world0, color=extralabel2_c);%,depth=1); 
    }

    pl.render(outputdir);

    %plot datapoints if given
    switch (_NARGS)
    { case 2: 
      %check whether names of hardnessratio-columns in FITS-file are given
      variable hr_x = qualifier("hr_x_col", NULL); 
      variable hr_y = qualifier("hr_y_col", NULL);
      if (hr_x == NULL || hr_y == NULL ){
       vmessage("error (%s): column names (hr_x_col,hr_y_col) of fits-table for plotting datapoints must be given", _function_name);
       return;
      } 
      %check whether names of hardnessratio_error-columns in FITS-file are given    
      variable err_x = qualifier("err_x_col", NULL); 
      variable err_y = qualifier("err_y_col", NULL);
      if (err_x == NULL || err_y == NULL ){
       vmessage("error (%s): column names (err_x_col,err_y_col) of fits-table for errorbars must be given", _function_name);
       return;
      }  

      %qualifiers
      variable fitsfile = fits_open_file(fits_hr_table,"r");
      variable x_col = fits_get_colnum(fitsfile,hr_x);  
      variable y_col = fits_get_colnum(fitsfile,hr_y);
      variable errx_col = fits_get_colnum(fitsfile,err_x);
      variable erry_col = fits_get_colnum(fitsfile,err_y);
      variable numrows = fits_get_num_rows(fitsfile);
      variable symbol_shape =  qualifier("symbol_shape", "point"); 
      variable symbol_size =  qualifier("symbol_size", 1.); 
      variable symbol_cstart =  qualifier("symbol_cstart", 0x000000); 
      variable err_c =  qualifier("err_c", 0x000000);      
      variable extralabel_sources_x;
      variable extralabel_sources_y;
      extralabel_sources_x=qualifier("extralabel_sources_x",0.5);
      extralabel_sources_y=qualifier("extralabel_sources_y",0.95);

      %for mixing colors: create list with all entries init: symbol_start
      variable col_symbol=(@["symbol_start"])[Integer_Type[numrows+1]];
      xfig_new_color("symbol_start",symbol_cstart);
      
      %needed for labeling of source names -> needs to be set outside loop
      

      %create mixed colors only if 'symbol_cstop is given'
      if(qualifier_exists("symbol_cstop")){  
        %column name of 'sources' must be given, in order to determine which hr's
	 %belong to the same source, e.g. same color       
        variable source_col = qualifier("source_col", NULL);
        if (source_col == NULL){
         vmessage("error (%s): column name (source_col) must be given", _function_name);
         return;
        }

        variable s_col = fits_get_colnum(fitsfile,source_col);
	variable symbol_cstop =  qualifier("symbol_cstop", 0x000000);
	xfig_new_color("symbol_stop",symbol_cstop);
	variable source_buffer=fits_read_cell(fitsfile,s_col,1);	

	variable count_sources=1;
        %get amount of different sources in fitsfile (for color-mixing)
        _for i (1,numrows,1) {
	    if(fits_read_cell(fitsfile,s_col,i) != source_buffer){
	      source_buffer=fits_read_cell(fitsfile,s_col,i);
	      count_sources++;
	    }       
        } 
              
        variable sources_label=struct{name=String_Type[count_sources+1],color=String_Type[count_sources+1]}; 
	  %color differs from source_col below (# of entries)		
	
	%reset source buffer
	source_buffer=fits_read_cell(fitsfile,s_col,1);
	%source name array for labeling
	sources_label.name[1]=source_buffer;
	sources_label.color[1]=col_symbol[1];
	
	%mixed color-tab
	variable count=1; %count of current source
	_for i (1,numrows,1) {
	   if(fits_read_cell(fitsfile,s_col,i) != source_buffer){ %only get new color, if source name differs
	     variable fraction=count*1./count_sources*1.;

	     if(fraction<1/4.)
   	      col_symbol[[i:]]=xfig_mix_colors("red","gold",fraction*4);
 	     else if(1/4.<=fraction<2/4.)
    	      col_symbol[[i:]]=xfig_mix_colors("green","red",(fraction-1/4.)*4);
  	     else
    	      col_symbol[[i:]]=xfig_mix_colors("blue","green",(fraction-2/4.)*4);

	     %col_symbol[[i:]]=xfig_mix_colors("symbol_start","symbol_stop",count/(count_sources*1.));
	     source_buffer=fits_read_cell(fitsfile,s_col,i);
	     count++;
	     sources_label.name[count]=source_buffer; 
	     sources_label.color[count]=col_symbol[i]; 
	   }       
      	}

	%label: source names if x-position is given
        if(qualifier_exists("extralabel_sources_x")){
	  variable y=0.; %height of each line
          _for i (1,count_sources,1) {	  
            pl.xylabel(extralabel_sources_x,extralabel_sources_y-y,sprintf(sources_label.name[i]);world0, color=sources_label.color[i]); 
	    y+=0.03;
    	  }
        }

      }  


      _for i (1,numrows,1) { 
      	  
	 pl.plot(fits_read_cell(fitsfile,x_col,i), fits_read_cell(fitsfile,y_col,i),
	 	fits_read_cell(fitsfile,errx_col,i),fits_read_cell(fitsfile,erry_col,i)
		; sym=symbol_shape,
	        symcolor=col_symbol[i],
		color=err_c,
		size=symbol_size, fill);%, depth=2); 	
      }

    }

    pl.render(outputdir);
}

