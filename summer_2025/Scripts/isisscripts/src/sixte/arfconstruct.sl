
%%%%%%%%%%%%%%%%%%%%%%%
define ARFfromMirrorArea(arf, mirrorarea){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ARFfromMirrorArea}
%\synopsis{Sets the ARF values to the interpolated values of the given mirror area array.}
%\usage{ARFfromMirrorArea(arf, mirrorarea);}
%\seealso{ARFreadMirrorArea}
%!%-

  variable interpol_mirrorarea=interpol(0.5*(arf.energ_lo+arf.energ_hi), mirrorarea.energy, mirrorarea.area;extrapolate="none",null_value=0.0);
  interpol_mirrorarea[where(interpol_mirrorarea<0)] = 0.0;
  
  arf.specresp=interpol_mirrorarea;

}

%%%%%%%%%%%%%%%%%%%%%%%
private define ARFmultiplyFilter(arf, filter){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ARFmultiplyFilter}
%\synopsis{Multiplies the ARF values with the interpolated transmission of the given filter.}
%\usage{ARFmultiplyFilter(arf, filter);}
%\seealso{ARFfromMirrorArea, ARFmultiplySupport, ARFmultiplyFactor, ARFmultiplyDetQE}
%!%-

  variable interpol_filter=interpol(0.5*(arf.energ_lo+arf.energ_hi), filter.energy, filter.transmission;extrapolate="none",null_value=0.0);

  arf.specresp=arf.specresp*interpol_filter;

}

%%%%%%%%%%%%%%%%%%%%%%%
private define ARFmultiplySupport(arf, support, openFraction){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ARFmultiplySupport}
%\synopsis{Multiplies the ARF values with the interpolated transmission of the given support material, taking the open fraction into account.}
%\usage{ARFmultiplySupport(arf, support, openFraction);}
%\seealso{ARFfromMirrorArea, ARFmultiplyFilter, ARFmultiplyFactor, ARFmultiplyDetQE}
%!%-

  variable interpol_support=interpol(0.5*(arf.energ_lo+arf.energ_hi), support.energy, support.transmission;extrapolate="none",null_value=0.0);
  
arf.specresp=arf.specresp*(openFraction+(1.0-openFraction)*interpol_support);


}

%%%%%%%%%%%%%%%%%%%%%%%
private define ARFmultiplyFactor(arf, factor){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ARFmultiplyFactor}
%\synopsis{Multiplies the ARF values with the given factor.}
%\usage{ARFmultiplyFactor(arf, factor);}
%\seealso{ARFfromMirrorArea, ARFmultiplyFilter, ARFmultiplySupport, ARFmultiplyDetQE}
%!%-

  arf.specresp=arf.specresp*factor;

}

%%%%%%%%%%%%%%%%%%%%%%%
private define ARFmultiplyDetQE(arf, detectorLayers){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ARFmultiplyDetQE}
%\synopsis{Multiplies the ARF values with the total quantum efficiency, corresponding to the total transmission of the given detector layers.}
%\usage{ARFmultiplyDetQE(arf, detectorLayers);}
%\seealso{ARFfromMirrorArea, ARFmultiplyFilter, ARFmultiplySupport, ARFmultiplyFactor}
%!%-

  variable ii;
  variable total_transmission=Double_Type[length(arf.energ_hi)];
  total_transmission=1.;

  for(ii=0; ii<length(detectorLayers); ii++){
    variable layer_transmission=interpol(0.5*(arf.energ_lo+arf.energ_hi), 
					 detectorLayers[ii].energy, 
                                         detectorLayers[ii].transmission;
                                         extrapolate="none",null_value=0.0);
    total_transmission=total_transmission*layer_transmission;
  }
  
  variable qe=1.0-total_transmission;

   qe[where(qe<0)] = 0.0;
   
   arf.specresp=arf.specresp*qe;
}

%%%%%%%%%%%%%%%%%%%%%%%
private define ARFreadHenkeTransm(henkename){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ARFreadHenkeTransm}
%\synopsis{Reads a standard henke table ASCII-file and returns it as a structure. Energy (first column) must be given in eV and is converted into keV. Transmission (second column) between [0.;1.]. First 2 rows are assumed to be comments.}
%\usage{variable henketable=ARFreadHenkeTransm(henkename);}
%\seealso{ARFmultiplyFilter, ARFmultiplySupport, ARFmultiplyFactor, ARFmultiplyDetQE, ARFreadMirrorArea}
%!%-

   variable startline = qualifier("qestartline",3);
  variable henketable=ascii_read_table(henkename,
          [{"%F","energy"}, % [eV]
           {"%F","transmission"}];
            startline=startline);
            
  % convert ev to keV
   henketable.energy=henketable.energy/1000.;
  
  return henketable;
}



%%%%%%%%%%%%%%%%%%%%%%%
define ARFreadMirrorArea(mirrorname){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ARFreadMirrorArea}
%\synopsis{Reads the mirror area ASCII-file and returns it as a structure.}
%\usage{variable mirrorarea=ARFreadMirrorArea(mirrorname);}
%\description
%    
%    The mirror area file has to be in the format:
%
%    TEXT
%    energy[0] [kev] area[0] [cm^2]
%    energy[1] [kev] area[1] [cm^2]
%\seealso{ARFfromMirrorArea}
%!%-

  variable arfstartline=qualifier("arfstartline", 2);
  vmessage("ARF File: read from line %d", arfstartline);
  
  variable mirrorarea=ascii_read_table(mirrorname,
          [{"%F","energy"}, % [keV]
           {"%F","area"}]; % [cm^2]
            startline=arfstartline);
  
  return mirrorarea;
}

%%%%%%%%%%%%%%%%%%%%%%%
define ARFconstruct(e_lo, e_hi, mirrorareafile, filterfiles, supportfiles, openFraction, detectorlayerfiles, factor)
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{ARFconstruct}
%\synopsis{Constructs an ARF in keV and cm^2-units from mirror area, filters, filter supports, detector material and additional factor information.}
%\usage{variable arf=ARFconstruct(e_lo, e_hi, mirrorareafile, filterfiles, supportfiles, open_fraction, detectorlayerfiles, factor);}
%\description
%    An ARF is built from a mirror area, filter-,
%    support grid-, detector layer transmission
%    information. The transmission files-parameters
%    have to be file names of transmission tables 
%    in the format:
%
%    TEXT
%    TEXT
%    energy[0] [ev] transmission[0]
%    energy[1] [ev] transmission[1]
%    ...             ...
%
%    These arrays are interpolated to the input energy 
%    grid (e_lo, e_hi).
%    The open_fraction is an array with the same lenght
%    as the number of filter support files and gives the
%    fraction of the support grid that is open for X-rays.
%    The mirror area file has to be in the format:
%
%    TEXT
%    energy[0] [kev] area[0] [cm^2]
%    energy[1] [kev] area[1] [cm^2]
%    ...             ...
%
%    The factor is an additional factor multiplied to the
%    ARF.
%    
%    The return value is a structure
%    
%    arf=struct{
%           energ_lo=e_lo,
%           energ_hi=e_hi,
%           specresp
%           };
%
%
%    To construct an ARF without mirrors included, it can be done by
%    setting mirrorareafile=NULL
%!%-
{
    variable arf=struct{
	energ_lo=e_lo,
	energ_hi=e_hi,
	specresp
    };

   variable mirrorarea;
   % allow to give no mirror area (makes sense for straylight
   % simulations)
   if (mirrorareafile==NULL){
      arf.specresp = e_lo*0 + 1;
   } else {
      % Get the mirror area
      mirrorarea=ARFreadMirrorArea(mirrorareafile ;; __qualifiers);
      ARFfromMirrorArea(arf, mirrorarea);
   }
      
  
    % Multiply with all filter transmissions
    variable ii;
    variable filter_transm;

    for(ii=0; ii<length(filterfiles); ii++){
	if(strcmp(filterfiles[ii], "NONE")){
	    filter_transm=ARFreadHenkeTransm(filterfiles[ii];;__qualifiers());
	    ARFmultiplyFilter(arf, filter_transm);
	}
    }

    % Multiply with all filter support transmissions
    variable support_transmission;
    for(ii=0; ii<length(supportfiles); ii++){
	if(strcmp(supportfiles[ii], "NONE")){
	    support_transmission=ARFreadHenkeTransm(supportfiles[ii];;__qualifiers());
	    ARFmultiplySupport(arf, support_transmission, openFraction[ii]);
	} else {
	    if (openFraction[ii]!=1.) {
		arf.specresp*=openFraction[ii];
	    }
	}
    }

    % Multiply with detector quantum efficiency
    variable n_layers=0;
    for(ii=0; ii<length(detectorlayerfiles); ii++){
	if(strcmp(detectorlayerfiles[ii], "NONE")){
	    n_layers++;
	}
    }
    if(n_layers>0){
	variable detector_layers=Struct_Type[n_layers];
	n_layers=0;
	for(ii=0; ii<length(detectorlayerfiles); ii++){
	    if(strcmp(detectorlayerfiles[ii], "NONE")){
		detector_layers[n_layers]=ARFreadHenkeTransm(detectorlayerfiles[ii];;__qualifiers() );
		n_layers++;
	    }
	}
	ARFmultiplyDetQE(arf, detector_layers);
    }
  
    % Multiply with additional factor
    ARFmultiplyFactor(arf, factor);
  
    % Return finished ARF
  
    return arf;

}
