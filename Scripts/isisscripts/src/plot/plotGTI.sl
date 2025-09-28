define plotGTI()
%!%+
%\function{plotGTI}
%\synopsis{visualizes Good Time Intervals}
%\usage{plotGTI(Struct_Type gti[, Double_Type offset]);}
%\qualifiers{
%\qualifier{ylevel}{plot GTIs at constant y-level}
%\qualifier{overplot}{}
%}
%!%-
{
  variable gti, offset=0;
  switch(_NARGS)
  { case 1: gti = (); }
  { case 2: (gti, offset) = (); }
  { help(_function_name()); return; }

  variable overplot = qualifier_exists("overplot");
  variable col = get_plot_options().color;
  variable ngtis = length(gti.start);
  variable ymin = offset-1;
  variable ymax = ngtis+offset;

  if (overplot){
    (,,ymin, ymax) = _pgqwin(); % Get ranges of current plot
  }
  variable dy = (ymax-ymin)/double(ngtis+1);

  ifnot(overplot){
    xrange(min(gti.start), max(gti.stop));
    yrange(ymin, ymax);
  }
  
  variable ii;
  _for ii (0, ngtis-1, 1){
    color(col); oplot([gti.start[ii], gti.stop[ii]], ymin+(ii+1)*dy*[1, 1]+offset);
  }
}

define oplotGTIs()
%!%+
%\function{oplotGTIs}
%\synopsis{visualizes Good Time Intervals}
%\usage{oplotGTIs(Struct_Type gti[, Double_Type offset]);}
%!%-
{
  variable gti, offset=0;
  switch(_NARGS)
  { case 1: gti = (); }
  { case 2: (gti, offset) = (); }
  { help(_function_name()); return;}

  plotGTI(gti, offset;; struct_combine(__qualifiers, struct{overplot}));
}