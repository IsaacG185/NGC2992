%%%%%%%%%%%%%%
define foufreq(time)
%%%%%%%%%%%%%%
%!%+
%\function{foufreq}
%\synopsis{Timing Tools: Calculation of the Fourier Frequency Array}
%\usage{Double_Type freq[] = foufreq(Double_Type time[]);}
%\description
%     Calculates the Fourier frequency array corresponding
%     to a given equally-binned time array.
%!%-
{
  variable dimseg = length(time);
  return [1:dimseg/2] * 1. / ( (time[1]-time[0]) * dimseg );
}
