define integral_cat2ds9(inputfile,outputfile)
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{integral_cat2ds9}
%\synopsis{a cat2ds9 like function for INTEGRAL catalogs}
%\usage{ ()=integral_cat2ds9(String_Type inputfile,
%                      String_Type outputfile)}
%\qualifiers{                     
%\qualifier{source_name}{name of the column with source names
%                        (default: NAME)}
%\qualifier{ra_name}{name of the column with right ascension of the
%                      sources (default: RA_OBJ)}
%\qualifier{dec_name}{:name of the column with declination of the
%                      sources (default: DEC_OBJ)}
%\qualifier{color}{color to be used for the ds9 region (default:
%                    black)}
%\qualifier{symbol}{form of the ds9 region (default:box)}
%\qualifier{noname}{only boxes, no text with source names}
%}
%!%-
{
  %open fits file
  variable cf = fits_open_file(inputfile+"+1","r");

  %qualifiers and default values when no qualifier set
  variable ra_name     = qualifier("ra_name","RA_OBJ");
  variable dec_name    = qualifier("dec_name","DEC_OBJ");
  variable source_name = qualifier("source_name","NAME");
  variable color       = qualifier("color","black");
  variable symbol      = qualifier("symbol","box");
  
  %read variable from file
  variable source=fits_read_col(cf,source_name);
  variable ra = fits_read_col(cf,ra_name);
  variable dec = fits_read_col(cf,dec_name);
  %close fits file
  fits_close_file(cf);
  
  %open output file for writing, write region data
  variable pf=fopen(outputfile,"w");
  ()=fprintf(pf,"global move=0 \n");
  ()=fprintf(pf,"global color=%s \n",color);
  variable i;
  for (i=0;i<length(source)-1;i++){
    if (qualifier_exists("noname")){
      ()=fprintf(pf,"fk5;point(%f,%f) # point=%s \n",ra[i],dec[i],symbol);
    }
    else{
      ()=fprintf(pf,"fk5;point(%f,%f) # point=%s text={%s} \n",ra[i],dec[i],symbol,source[i]);
    }
  }
  ()=fclose(pf);
  

  return(0);
}

