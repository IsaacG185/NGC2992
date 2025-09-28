
private define get_vignet_keys(nenergies, noffsetangles, nrot){

   variable version = qualifier("version",strftime("%Y%m%d"));
   
   variable keys = struct {
      HDUCLASS = "OGIP",
      HDUCLAS1 = "RESPONSE",
      HDUVERS1 = "1.0.0",
      HDUCLAS2 = "VIGNET",
      HDUVERS2 = "1.1.0",
      VERSION  = version,
      
      MISSION  = qualifier("mission","none"),
      TELESCOP = qualifier("telescope","none"),
      DETNAM   = qualifier("detnam","none"),
      INSTRUME = qualifier("instrument","none"),
      
      TUNIT1   = "keV",
      TUNIT2   = "keV",
      TUNIT3   = "keV",
      TUNIT4   = "degree",
      TUNIT5   = "degree",
      TDIM6    = sprintf("(%d,%d,%d)", nenergies, noffsetangles, nrot)
     };
   
     return keys;

}

private define get_vignet_data(nenergies, noffsetangles, nrot){

   %      VIGNET   = Float_Type[1, length(energies)*length(offaxangles)*nPhi] 
   return struct {
      ENERG_LO = Float_Type[1, nenergies],
      ENERG_HI = Float_Type[1, nenergies],
      ENERGY   = Float_Type[1, nenergies],
      THETA    = Float_Type[1, noffsetangles],
      PHI      = Float_Type[1, nrot],
      VIGNET   = Float_Type[1, nrot, noffsetangles, nenergies] %% definition is not compliant with OGIP, but that's how we read it in sixte ...
   };
}

%%%%%%%%%%%%%%%%%%%%%%%
define fits_write_sixte_vignetting(){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_write_sixte_vignetting}
%\synopsis{write a vignetting file, which can be used in a Sixte instrument configuration XML file.}
%\usage{fits_write_sixte_vignetting((string) filename, energies, offaxangles [, phi = 0]);}
%\description
%  energies given in keV, offaxis angles given in arcmin
%!%-

   variable fname, energies, offaxangles, vign;
   switch(_NARGS)
   { case 4: (fname, energies, offaxangles, vign) = (); }
   { help(_function_name()); return; }
   
   variable nener = length(energies);
   variable nthet = length(offaxangles);
   variable nphi = 1;  %% currently not supported by sixte
   
   variable vignetting_data = get_vignet_data(nener,nthet,nphi);   
   variable keys=get_vignet_keys(nener, nthet, nphi);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % Fill the data structure:
  
   vignetting_data.THETA[0,*] = offaxangles*1./60.;
   vignetting_data.PHI[0, 0]  = 0.;
   vignetting_data.ENERG_LO[0,  0] = 0.0;
   vignetting_data.ENERG_HI[0, -1] = 20.0;
   
   
   variable ii;
   for (ii=0; ii<length(energies); ii++) {
      vignetting_data.ENERG_HI[0, ii-1] = 0.5*(energies[ii-1]+energies[ii]);
      vignetting_data.ENERG_LO[0,   ii] = 0.5*(energies[ii-1]+energies[ii]);
      vignetting_data.ENERGY[0,ii] = energies[ii];
      
      
      vignetting_data.VIGNET[0,0,*,ii]=vign[ii,*]/vign[ii,0]; %%.area[jj]/vig.area[0];
      print(vignetting_data.VIGNET[0,0,*,ii]);
      
      % for(jj=0; jj<length(offaxangles); jj++){
      %   vignetting_data.VIGNET[0,ii+jj*length(energies)]=vign[ii][*]/vign[ii][0]; %%.area[jj]/vig.area[0];
      % }
   }
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%					 
  % Store the data in the FITS file:
  variable fitsfile=fits_open_file(fname, "c"); % c => create file (delete, if already exists)
  fits_write_binary_table(fitsfile, "VIGNET", vignetting_data, keys);
  fits_close_file(fitsfile);

   
}