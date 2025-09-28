define hardnessratio_simulate_grid_save (tracks,filename)
%!%+
%\function{hardnessratio_simulate_grid_save}
%\synopsis{saves the output of hardnessratio_simulate_grid into a fits
%    file}
%\usage{hardnessratio_simulate_grid_save(Struct_Type tracks,
%    String_Type filename);}
%\description
%    - tracks is the output strcutute of hardnessratio_simulate_grid
%\seealso{hardnessratio, hardnessratio_from_dataset,
%    xfigplot_hardnessratio_grid, xfigplot_hardnessratio_grid_load}
%!%-
{
  variable nn = length(tracks);  
  variable i;
  _for i (0,nn-1,1){
    
    variable temp = struct{par1=tracks[i].par1,
      par2=tracks[i].par2,
      hr1=tracks[i].hr1,
      hr2=tracks[i].hr2};
    
    if (i==0) {      
      fits_write_binary_table(filename,string(i+1),temp,
			      struct{linetype=tracks[0].linetype});
    }  else {      
      fits_append_binary_table(filename,string(i+1),temp,
			     struct{linetype=tracks[i].linetype});
    }
    
  }
  
}

define hardnessratio_simulate_grid_load (filename)
%!%+
%\function{hardnessratio_simulate_grid_load}
%\synopsis{load tracks saved with hardnessratio_simulate_grid_save}
%\usage{Struct_Type = hardnessratio_simulate_grid_save(String_Type filename);}
%\seealso{hardnessratio, hardnessratio_from_dataset,
%    xfigplot_hardnessratio_grid, xfigplot_hardnessratio_grid_save}
%!%-
{
  variable nn = fits_nr_extensions(filename);  
  variable tracks = Struct_Type[0];
  
  variable i;
  _for i (0,nn-1,1) {        
    tracks = [tracks,[struct_combine(fits_read_table(filename+"\["+string(i+1)+"\]"),
				     fits_read_key_struct(filename+"\["+string(i+1)+"\]","linetype"))]];       
  }
  
  return tracks;
  
}