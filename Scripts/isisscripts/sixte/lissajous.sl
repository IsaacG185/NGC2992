%%%%%%%%%%%%%%%%%%%%%%%
define lissajous_pattern(){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{lissajous_pattern}
%\synopsis{calculates a Lissajous pattern for 3:4 ratio with PI/4 offset}
%\usage{variable li = lissajous_pattern();}
%\qualifiers{
%\qualifier{amplitude}{[1.0]: amplitude by default from -1 to 1}
%\qualifier{tstart}{[0.0]: tstart}
%\qualifier{tstop}{[1.0]: tstop}
%\qualifier{x0}{[0.0]: x0}
%\qualifier{y0}{[0.0]: y0}
%}
%\description
%    An ARF is built from a mirror area, filter-,
%    support grid-, detector layer transmission
%    information. The transmission files-parameters
%    have to be file names of transmission tables 
%    in the format:
%
%!%-

   variable ampl = qualifier("amplitude",1.0);
   variable tstart = qualifier("tstart",0.0);
   variable tstop  = qualifier("tstop",1.0);
   
   variable a = 3/4.;
   variable b = 4/4.;

   variable offset=PI/4.;
   
   variable t = [0:1.0:#1000];

   variable x = sin(a*t*2*PI*4+offset)*ampl;
   variable y = sin(b*t*2*PI*4)*ampl;

   t *= tstop;
   t += tstart;

   x+= qualifier("x0",0.0);
   y+= qualifier("y0",0.0);
   
   return struct{t=t,x=x,y=y};
}
