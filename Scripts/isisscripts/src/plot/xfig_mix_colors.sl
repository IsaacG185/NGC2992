require("xfig");

define xfig_mix_colors(color1,color2,fraction) {
%!%+
%\function{xfig_mix_colors}
%\synopsis{mix two named xfig colors}
%\usage{xfig_mix_colors(color1,color2,fraction)}
%\qualifiers{
%\qualifier{name}{xfig name of the color mix}
%}
%\description
% This function mixes two named xfig colors in rgb space. The function looks up
% the rgb values of color1 and color2, and mixes their rgb values according
% to 
% new color=color1*fraction+color2*(1-fraction)
% The operations are analoguous to the color mixing performed by the xcolor
% package of LaTeX (the operation is similar to LaTeX's color1!fraction!color2
% syntax). 
% The function returns the xfig name of the new color, or nothing if the
% name qualifier is given (recommended).
%\seealso{mix_rgb_colors}
%!%-
  variable rgb=color_mix(xfig_lookup_color_rgb(color1),
			 xfig_lookup_color_rgb(color2),fraction);

  variable colname;
  if (qualifier_exists("name")) {
      xfig_new_color(qualifier("name"),rgb);
      return;
  } else {
      colname=color1+"_"+sprintf("%3.3i",int(fraction*1000))+"_"+color2;
      xfig_new_color(colname,rgb);
      return colname;
  }
}

