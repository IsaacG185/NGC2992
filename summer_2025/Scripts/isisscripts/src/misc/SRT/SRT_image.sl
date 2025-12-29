define SRT_image()
%!%+
%\function{SRT_image}
%\synopsis{extracts an image from a SRT data structure containing an npoinscan}
%\usage{Float_Type img[] = SRT_image(Struct_Type data);}
%\qualifiers{
%\qualifier{plot}{plots the image}
%}
%\seealso{SRT_read}
%!%-
{
  variable data;
  switch(_NARGS)
  { case 1: data = (); }
  { help(_function_name()); return; }

  variable BEAMWIDTH = 7.;
  variable img = Float_Type[5,5];
  variable y;
  _for y (0, 4, 1)
  {
    variable eloff = (y-2)*BEAMWIDTH/2;
    variable irow = where(data.eloff == eloff);
    variable n = length(irow);
    switch(n)
    { case 5: img[y,*] = data.avflux[irow]; }
    { vmessage("warning (%s): row #%d at eloff=%.1f deg contains %d != 5 elements", _function_name(), y, eloff, n);
      variable azoff = data.azoff[irow];
      variable maxAbsAzoff = max(abs(azoff));
      variable i;
      i = where(-maxAbsAzoff == azoff                            ); if(length(i)>0)  img[y,0] = mean(data.avflux[irow[i]]);
      i = where(-maxAbsAzoff <  azoff <  0                       ); if(length(i)>0)  img[y,1] = mean(data.avflux[irow[i]]);
      i = where(                azoff == 0                       ); if(length(i)>0)  img[y,2] = mean(data.avflux[irow[i]]);
      i = where(                         0 < azoff <  maxAbsAzoff); if(length(i)>0)  img[y,3] = mean(data.avflux[irow[i]]);
      i = where(                             azoff == maxAbsAzoff); if(length(i)>0)  img[y,4] = mean(data.avflux[irow[i]]);
    }
  }

  if(qualifier_exists("plot"))
  {
    xlin; % xrange(-1.25*BEAMWIDTH, 1.25*BEAMWIDTH);
    ylin; % yrange(-1.25*BEAMWIDTH, 1.25*BEAMWIDTH);
    plot_image(img, 0, [-BEAMWIDTH:BEAMWIDTH:#5], [-BEAMWIDTH:BEAMWIDTH:#5]);
  }

  return img;
}
