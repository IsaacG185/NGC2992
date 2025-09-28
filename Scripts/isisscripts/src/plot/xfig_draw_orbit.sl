require( "xfig" );

define xfig_draw_orbit ()
%!%+
%\function{xfig_draw_orbit}
%\synopsis{draws the orbit of a binary system into an exsiting xfig-object and
%    allow also to highlight specific phases}
%\usage{xfig_draw_orbit(Xfig_Object xf, Double_Type asini, i, ecc, omega, rstar)
%}
%\qualifiers{
%\qualifier{line_color}{[\code{="gray"}] color of the lines showing the
%           coordinate main axes and the orientation of the semi-major axis of
%           the orbit}
%\qualifier{phases}{[\code{=\{\}}] list of Double_Type[2] arrays indicating
%           the phases which should be highlighted}
%\qualifier{scale}{[\code{=1.05}]  compression/streching for the highlighted
%           phases over/under the orbit}
%\qualifier{phase_color}{[\code{="red"}] color of the highlighted phases,
%           can be a single string or an array of strings, with the same length
%           as phases so that every highlighted phase can be drawn in
%           a different color.}
%\qualifier{phase_width}{[\code{=2}] width of the highlighted phases, can
%           also be an array, just as phase_color.}
%\qualifier{star_color}{[\code{=lightblue}]  fill-color of the companion star}
%\qualifier{trueanom}{if set, phases are given in true anomaly, i.e., equal
%           delta-phi values will correspond to equal delta-t on the
%           orbit.}
%\qualifier{zerolines}{[\code{=1}] plot x- and y-axis lines through [0,0]}
%\qualifier{phaselines}{draw a lightgray line every phase n*0.1 and label it}
%\qualifier{label_phase_switch}{[\code{=0}] : phase at witch phase labels
%           are switched from before the line to after the line.}
%\qualifier{label_pos}{[\code{=0.85}] distance of the phase labels from the 
%           orbit line, in fraction of distance to center.}
%\qualifier{nolabel} { : removes the coordinate system }
%}
%           
%\description
%    This function plots the orbit of a binary system as seen from
%    above into a given xfig-object. The orbital parameters asini
%    (semi-major axis, in lt-sec), i (inclination, in deg), ecc (eccentricity),
%    omega (argument of periastron, in deg) and the radius rstar (in r_sun)
%    of the companion star need to be supplied.
%    Qualifiers are passed through the xfig-plotting routine of the
%    orbit.
%        
%\examples
%     %orbit parameters of GX 301-2 according to Koh et al (1997).
%     variable asini = 368.3 ; % lt-sec (semi major axis)
%      variable i = 66; % degree to rad
%      variable ecc = 0.462 ;  %
%      variable omega = 310.4 ; % degrees
%      variable rstar = 43 ; % solar radii  in lt-sec
%
%      variable xfgx = xfig_plot_new(12,12) ;
%      xfgx.world(-600,450,-450, 600) ;
%      xfig_draw_orbit(xfgx, asini, i, ecc, omega, rstar ;
%        phases={[0.9184,0.9315]}, phase_color="red", phase_width=4, scale=1) ;
%      xfgx.plot([0,0],[-100,-370] ; line=1, forward_arrow, depth = 10,
%        arrow_thickness =2) ;
%      xfgx.xylabel(0,-400, "To Earth");
%      xfgx.render("plots/gx301_skizze2.eps") ;
%
%  \seealso{ellipse}
%!%-
{
variable xfgx, asini, i, ecc, omega, rstar ;
  switch(_NARGS)
    % [asini]=lt-sec, [i]=deg, [ecc]=N/A, [omega]=deg, [rstar]=R_sun
    { case 6: (xfgx, asini, i, ecc, omega, rstar) = (); }
    { help(_function_name()); return; }
      xfgx.axis(;off) ;

    variable c=  2.998e8 ; %speed of light in cm/s
    variable rsun=1.3914e9/2. ; %solar radius in cm

    i = i*PI/180.; % degree to rad

    variable a = asini/sin(i) ;
  
    variable b = sqrt( a^2 * (1.-ecc)*(1.+ecc) ); % semi-minor axis, lt-sec
    omega = omega*PI/180.;

    rstar = rstar*rsun/c ; % solar radii  in lt-sec

    variable scal = qualifier("scale",1.05) ;
    variable lcol = qualifier("line_color","gray") ;
  
    variable phases = qualifier("phases", {}) ;
    variable ph ;
    variable phcol = [qualifier("phase_color", "red")] ;
    variable phwid = [qualifier("phase_width", 2)] ;

    if (length(phcol)==1)
    {phcol = phcol[Integer_Type[length(phases)]];}
  if (length(phwid)==1)
     {phwid = phwid[Integer_Type[length(phases)]];}

if (length(phcol) < length(phases)) {  message("FATAL ERROR (sysdraw): phases color needs at least as many entries as phase list!") ; return ;}
if (length(phwid) < length(phases)) {  message("FATAL ERROR (sysdraw): phases width needs at least as many entries as phase list!") ; return ;}
variable ox1, oy1, ox, oy, phax, phay ;
variable stx, sty ;

(ox,oy) = ellipse(a, b, omega, [0:2*PI:#256]) ;
  
  (stx,sty) = ellipse(rstar,rstar,0,[0:2*PI:#256]) ;

  variable xymm = xfgx.get_world() ;
  
variable starcol = qualifier("star_color", "#"+rgb2hex(0.4, 0.6,1.0 ; string) );

xfgx.shade_region(stx,sty ; color=starcol, depth = 25) ;

  %all ellipses are shifted so that the star sits at [0,0].

  variable shiftx = a*ecc*cos(omega) ;
  variable shifty = a*ecc*sin(omega) ;

  xfgx.plot((ox-a*ecc*cos(omega)),(oy-a*ecc*sin(omega)) ;; __qualifiers) ;
  variable j = 0 , M, eccanom, theta  ;
  foreach ph (phases) {
    if (qualifier_exists("trueanom")){
      M = [0:2*PI:#2048] ; %mean anomaly, highly oversampled
      eccanom = KeplerEquation (M, ecc) ;
      (phax,phay) = ellipse(a*scal,b*scal,omega, eccanom[where(ph[0] <= M/2/PI < ph[1])]) ;
    }
    else{
      (phax,phay) = ellipse(a*scal, b*scal, omega, [ph[0]:ph[1]:#256]*2*PI) ;
    }
    xfgx.plot(phax-shiftx,phay-shifty ; color=phcol[j], depth = 5, width=phwid[j]) ;
    j++ ;
  }


if(qualifier_exists("phaselines")) {
  variable eccanom_cgrid = KeplerEquation([0.0:1:0.1]*2*PI, ecc) ;
  variable theta_cgrid = 2.*atan( sqrt( (1.+ecc)/(1.-ecc) )*tan(eccanom_cgrid/2.) );  % true anomaly from eccentric anomaly
  variable xlab,ylab ;
  variable labscal = qualifier("label_pos",0.85) ;
  variable darkgray = "#" + rgb2hex(0.4,0.4,0.4 ; string) ; % used for the phase labels

  variable phaswitch = qualifier("label_phase_switch", 0) ;
  ifnot (0<=phaswitch<1) {
    message("WARNING (xfig_draw_orbit): label_phase_switch must be in [0,1[, setting it now to default (=0)") ;
    phaswitch=0 ;
  }
  phaswitch = min(where([0:1:0.1] >= phaswitch)) ;

  
  _for j (0,phaswitch-1, 1){
    %phase indicator lines
    xfgx.plot([0,cos(theta_cgrid[j]+omega)]*1500,[0,sin(theta_cgrid[j]+omega)]*1500 ; color="gray", line=3) ;
    %their labels
    (xlab, ylab) = ellipse(a, b, omega, eccanom_cgrid[j]+0.07)  ;
    xfgx.xylabel((xlab-shiftx)*labscal, (ylab-shifty)*labscal,sprintf("%.1f", j/10. ) ;
  		 rotate=(theta_cgrid[j]+omega)/2/PI*360., color=darkgray, size ="\scriptsize"R ) ;
  }

  _for j (phaswitch,length(theta_cgrid)-1, 1){
    %phase indicator lines
    xfgx.plot([0,cos(theta_cgrid[j]+omega)]*1500,[0,sin(theta_cgrid[j]+omega)]*1500 ; color="gray", line=3, depth=81) ;
    %their labels
    (xlab, ylab) = ellipse(a, b, omega, eccanom_cgrid[j]-0.07)  ;
    xfgx.xylabel((xlab-shiftx)*labscal, (ylab-shifty)*labscal,sprintf("%.1f", j/10. ) ;
		 rotate=(theta_cgrid[j]+omega)/2/PI*360.+180, color=darkgray, size ="\scriptsize"R,depth=20 ) ;
}
}
  variable zerolines = qualifier("zerolines", 1) ;
  
  if (zerolines){
xfgx.plot([xymm[0],xymm[1]],[0,0] ; line=0, color=lcol);
xfgx.plot([0,0],[xymm[2],xymm[3]] ; line=0 , color=lcol);
  }
% xfgx.plot([xymm[0]:xymm[1]:#256],[xymm[0]:xymm[1]:#256]*tan(omega) ; line=3, color=lcol) ;

  ifnot (qualifier_exists("nolabel")) {
    xfgx.xlabel("[lt-sec]") ;
    xfgx.ylabel("[lt-sec]") ;
    xfgx.x1axis(;on) ;
    xfgx.x2axis(;on,ticlabels=0) ;
    xfgx.y1axis(;on) ;
    xfgx.y2axis(;on,ticlabels=0) ;
  }
  return asini, i ;
}
