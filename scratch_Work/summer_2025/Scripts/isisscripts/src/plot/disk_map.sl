require("xfig");

private define x_axis_up(dist, theta, phi)
{
   xfig_set_eye(dist, theta, phi, computed_roll_angle(dist, theta, phi, (qualifier_exists("flip") ? -1 : 1)*vector(1,0,0), 90)); %set vector to the axis that should be up side!
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define disk_map()
%!%+
%\function{disk_map}
%\synopsis{Plots the megamaser disk using the output of Mark
%   Reid's Bayesian disk fitting routine.}
%\usage{disk_map(infile);}
%\qualifiers{
%\qualifier{radius: }{size of the plotted disk radius, in mas, default: reference radius from file}
%\qualifier{no_axes: }{flag to turn off the axes}
%\qualifier{no_los: }{flag to turn off the line-of-sight bar}
%\qualifier{no_disk: }{flag to turn off the wireframe disk model}
%\qualifier{no_data: }{flag to turn off the data points}
%\qualifier{no_grid: }{flag to turn off the grid}
%\qualifier{no_color: }{flag to plot everything in greyscale}
%\qualifier{scale: }{flag to scale the size of the data points by SNR}
%\qualifier{reverse_x: }{flag to reverse the x-axis orientation; not used here}
%\qualifier{side: }{see the maser disk along the line-of-sight in the x-y-plane}
%\qualifier{above: }{see the maser disk from above in the x-z-plane}
%\qualifier{projection: }{projects the maser spots in addition to the 3d view to the 2d planes}
%\qualifier{scalen: }{half scale length of the axes; default 1.1*radius of the disk, axes are [-scalen,scalen]}
%\qualifier{scalen_frac: }{distance from ticlabels to axes; default 1.05}
%\qualifier{label_dist: }{distance from labels to axes; default 1.3*radius}
%\qualifier{tics_length: }{length of the tics; default 0.2}
%}
%\description
%    Plots the megamaser disk using the output of Mark
%   Reid's Bayesian disk fitting routine. The input file for
%   this script is simply a text file containing the printout
%   of the Bayesian program. For instance, if the Bayesian
%   executable had the file name "fit_disk_v20*", then the Unix command
%        
%   ./fit_disk_v20* > input.prt
%           
%   would generate the appropriate input file for this script.
%   This script is matched to version 20 of Mark's program.
%   The default view on the disk is at theta=120° and phi=-130°,
%   with the x-axis showing upwards.
%
%   This function is rewritten from the IDL program disk_map.pro
%   from Dom Pesce in the version from July, 22, 2014.
%\example
%   For a 2D plot from above:
%   
%   isis> bla=disk_map("/userdata/data/litzinger/Radio/NGC1194/accel/disk_fitting/fit_disk_v20/jan2615/outjan2715";above);
%   isis> bla.render("disk_map_above.pdf");
%
%   or for a 3D plot with projection:
%
%   isis> bla=disk_map("/userdata/data/litzinger/Radio/NGC1194/accel/disk_fitting/fit_disk_v20/jan2615/outjan2715";projection);
%   isis> bla.render("disk_map.pdf");
%
%   Be careful!: If you plotted the 3d view and would like to plot
%   in 2d again you have to restart isis, as it still would plot in
%   3d view. To set the labels and tics correctly first plot the disk
%   with the default values and then change the values.
%   
%\seealso{xfig_3d_orbit_on_cube}
%!%-
{
   % ;---------------------------------------------------
   % ;----Reading in and organizing the data-------------
   % ;---------------------------------------------------
   variable infile;
   switch(_NARGS)
     { case 1: infile = ();}
     { help(_function_name()); return; }

%   variable a = fopen("/userdata/data/litzinger/Radio/NGC1194/accel/disk_fitting/fit_disk_v20/jan2615/out2715","r"); %open the file created by gfortran with ./model.out > v160714
   variable fp = fopen(infile,"r"); %open the file created by gfortran with ./model.out > v160714
   variable line = fgetslines(fp); %get the lines of the file
   variable x1,x2,x3,x4,x5,x6,x7,x8,x9;
   variable x_0 = 0.0;
   variable y_0 = 0.0;
   variable i_0 = 0.0;
   variable i_1 = 0.0;
   variable i_2 = 0.0;
   variable w_0 = 0.0;
   variable w_1 = 0.0;
   variable w_2 = 0.0;
   variable e = 0.0;
   variable peri_0 = 0.0;
   variable peri_1 = 0.0;
   variable r_ref = 0.0;
     
   %% Get the line after which the parameters are listed
   variable dl = is_substr(line[*],"Best global parameter values"); %search for the line which contains this string
   variable parameter_ref = where(dl>0); %get the line number
   
   %% Get the line where the number of unflagged maser spots is written
   variable nr = is_substr(line[*],"Number of unflagged"); %search for the line which contains this string
   variable nr1 = where(nr>0); %get the line number
   variable d = sscanf(line[nr1[0]],"%s %s %s %s %s %i\n",&x1, &x2, &x3, &x4, &x5, &x6);
   if (d==6)   {      print("all parameter ok");   } else {      print("one parameter missing");   };
   variable number = x6;
   
   %% Get the line where the reference radius is written
   variable ref_rad = is_substr(line[*],"Reference radius for"); %search for the line which contains this string
   variable ref1 = where(ref_rad>0); %get the line number
   d = sscanf(line[ref1[0]],"%s %s %s %s %s %s %f\n",&x1, &x2, &x3, &x4, &x5, &x6, &x7);
   if (d==7){   print("all parameter ok");} else {   print("one parameter missing");};
   r_ref = x7;
   
   variable vel = Double_Type[0];
   variable rad = Double_Type[0];
   variable phi = Double_Type[0];
   variable RA = Double_Type[0];
   variable DEC = Double_Type[0];
   variable y_err = Double_Type[0];
   
   variable values1 = line[parameter_ref+1];
   d = sscanf(values1[0],"%f %f %f %f %f %f\n",&x1, &x2, &x3, &x4, &x5, &x6);
   if (d==6){   print("all parameter ok");} else {   print("one parameter missing");};
   x_0 = x4;
   y_0 = x5;
   i_0 = x6*(PI/180.);
   
   variable values2 = line[parameter_ref+2];
   d = sscanf(values2[0],"%f %f %f %f %f %f\n",&x1, &x2, &x3, &x4, &x5, &x6);
   if (d==6) {  print("all parameter ok");} else {   print("one parameter missing");};
   i_1 = x1*(PI/180.);
   i_2 = x2*(PI/180.);
   w_0 = x3*(PI/180.);
   w_1 = x4*(PI/180.);
   w_2 = x5*(PI/180.);
   e = x6;
   
   variable values3 = line[parameter_ref+3];
   d = sscanf(values3[0],"%f %f %f\n",&x1, &x2, &x3);
   if (d==3){   print("all parameter ok");} else {   print("one parameter missing");};
   peri_0 = x1*(PI/180.);
   peri_1 = x2*(PI/180.);
   
   variable error_floors = is_substr(line[*],"Error floors (x,y,Vsys,Vhv,A)"); %search for the line which contains this string
   variable err1 = where(error_floors>0); %get the line number
   variable k;
   _for k(0,number-1,1)
   {
      variable erro = line[err1+2+k];
      d = sscanf(erro[0],"%f %f %f %f %f %f %f %f %f\n",&x1, &x2, &x3, &x4, &x5, &x6, &x7, &x8, &x9);
      if (d==9){print("all parameter ok");} else { print("one parameter missing");};
      vel = [vel,x2];
      RA = [RA,x4];
      DEC = [DEC,x6];
      y_err = [y_err,x7];
   };
   
   variable rad_phi = is_substr(line[*],"n_f  r(mas) phi(deg)"); %search for the line which contains this string
   variable rad1 = where(rad_phi>0); %get the line number
   _for k(0,number-1,1)
   {
      variable radphi = line[rad1+1+k];
      d = sscanf(radphi[0],"%f %f %f %f %f %f %f\n",&x1, &x2, &x3, &x4, &x5, &x6, &x7);
      if (d==7){print("all parameter ok");} else { print("one parameter missing");};
      rad = [rad,x2];
      phi = [phi,x3*(PI/180.)];
   };

   if (x_0 == 0){ print("No value found for parameter: BH Xo");};
   if (y_0 == 0){ print("No value found for parameter: BH Yo");};
   if (i_0 == 0){ print("No value found for parameter: i");};
   if (i_1 == 0){ print("No value found for parameter: di/dr");};
   if (i_2 == 0){ print("No value found for parameter: d2i/dr2");};
   if (w_0 == 0){ print("No value found for parameter: PA");};
   if (w_1 == 0){ print("No value found for parameter: dPA/dr");};
   if (w_2 == 0){ print("No value found for parameter: d2PA/dr2");};
   if (e == 0){ print("No value found for parameter: eccentricity");};
   if (peri_0 == 0){ print("No value found for parameter: peri azimuth");};
   if (peri_1 == 0){ print("No value found for parameter: dP-az/dr");};
   if (r_ref == 0){ print("No value found for parameter: reference radius");};

   variable index = where(vel > 0);
   vel = vel[index];
   rad = rad[index];
   phi = phi[index];
   RA = RA[index];
   DEC = DEC[index];
   y_err = y_err[index];

   variable i_data = i_0 + (i_1*(rad-r_ref)) + (i_2*((rad-r_ref)^2.));
   variable w_data = w_0 + (w_1*(rad-r_ref)) + (w_2*((rad-r_ref)^2.));

   variable x_data = RA - x_0;
   variable y_data = DEC - y_0;
   variable z_data = rad*cos(phi)*sin(i_data);

   index = array_sort(vel);
   vel = vel[index];
      
   variable type = String_Type[length(x_data)];
   type[0] = "b";
   variable str = ["b","s","r"];
   variable count = 0;

   variable n;
   _for n(1,length(vel)-1,1)
   {
      if (abs(vel[n]-vel[n-1]) > 100.)
        {
           count = count+1;
           if (count > 2)
             {
                count = 2;
             }
        }
           type[n] = str[count];
   };
   
   x_data = x_data[index];
   y_data = y_data[index];
   z_data = z_data[index];

   %---------------------------------------------------
   %------------Creating the warped disk---------------
   %---------------------------------------------------
   number = 50;
   if (qualifier_exists("radius"))
       { variable radius = qualifier("radius");   }
   else { radius = 1.0*max(abs(rad));       };       
   
   variable r = ([1:8:1])*(radius/8.);
   variable ecc_anom = [0:number+1:1]*(2.*PI/number);
   
   variable psi = peri_0 + (peri_1*r);
   
   variable X = Double_Type[length(r),length(ecc_anom)];
   variable Y = Double_Type[length(r),length(ecc_anom)];
   variable Z = Double_Type[length(r),length(ecc_anom)];
   
   %variable k;
   _for n(0,length(r)-1,1)
   {
      variable a = r[n]/(1. - e);
   
      variable i_now = i_0 + (i_1*(r[n]-r_ref)) + (i_2*((r[n]-r_ref)^2.));
      variable omega_now = w_0 + (w_1*(r[n]-r_ref)) + (w_2*((r[n]-r_ref)^2.));
   
      _for k(0,(length(ecc_anom)/2)-1,1) {
   
         variable rad_now = a*(1. - (e*cos(ecc_anom[k])));
   
         variable cos_phi = (cos(ecc_anom[k]) - e)/(1. - e*cos(ecc_anom[k]));
         variable sin_phi = sqrt(1. - (cos_phi^2.));
   
         variable cosp = (sin_phi*sin(psi[n])) + (cos_phi*cos(psi[n]));
         variable sinp = (sin_phi*cos(psi[n])) - (cos_phi*sin(psi[n]));
   
         X[n,k] = rad_now * ( (sin(omega_now)*cosp) - (cos(omega_now)*cos(i_now)*sinp) );
         Y[n,k] = rad_now * ( (cos(omega_now)*cosp) + (sin(omega_now)*cos(i_now)*sinp) );
         Z[n,k] = -rad_now * ( sin(i_now)*sinp );
      }
        
      _for k((length(ecc_anom)/2),length(ecc_anom)-1,1){
   
         rad_now = a*(1. - (e*cos(ecc_anom[k])));
   
         cos_phi = (cos(ecc_anom[k]) - e)/(1. - e*cos(ecc_anom[k]));
         sin_phi = -sqrt(1. - (cos_phi^2.));
   
         cosp = (sin_phi*sin(psi[n])) + (cos_phi*cos(psi[n]));
         sinp = (sin_phi*cos(psi[n])) - (cos_phi*sin(psi[n]));
   
         X[n,k] = rad_now * ( (sin(omega_now)*cosp) - (cos(omega_now)*cos(i_now)*sinp) );
         Y[n,k] = rad_now * ( (cos(omega_now)*cosp) + (sin(omega_now)*cos(i_now)*sinp) );
         Z[n,k] = -rad_now * ( sin(i_now)*sinp );
      };
   };


   %---------------------------------------------------
   %-------------------Plotting------------------------
   %---------------------------------------------------
   variable W=10, H=10; %effects only the 2d plots side and above
   variable xfig = xfig_plot_new(W,H);
   variable i,j;
   variable xlabel = ("East offset (mas)");
   variable ylabel = ("North offset (mas)");
   variable zlabel = ("Z offset (mas)");
   variable scalen = qualifier("scalen",nint(ceil(1.1*radius))); %scale length for the axis
   variable scalen_frac = qualifier("scalen_frac",1.15/1.1); %distance from ticlabels to axis
   variable label_dist = qualifier("label_dist",1.3*radius); %distance from labels to axis
   variable tics_length = qualifier("tics_length",0.2); %length of the tics
   
   if (qualifier_exists("side")) %plots the maser spots in the x-y-plane 
     {
	xfig = xfig_plot_new(W,H);
	xfig.world(scalen,-scalen,-scalen,scalen);
	xfig.xlabel("x offset (mas)");
	xfig.ylabel("y offset (mas)");
	_for j(0,length(x_data)-1,1)
	  {
	     variable theta = [1:21:1]*(2.*PI/20.);
	     phi = [1:21:1]*(PI/20.);
	     rad = 0.01*radius;

	     _for n(0,length(theta)-1,1)
	       {
		  variable x_sym = rad*sin(phi[n])*cos(theta[n]);
                  variable y_sym = rad*sin(phi[n])*sin(theta[n]);
 	       }
	     if (type[j] == "b")
	       {variable colo=sprintf("#%02X%02X%02X",0,0,255);   }
	     if (type[j] == "s")
	       {        colo=sprintf("#%02X%02X%02X",0,150,50);   }
	     if (type[j] == "r")
	       {        colo=sprintf("#%02X%02X%02X",255,0,0);     }

	     variable new_phi=w_0+i_0; %rotate the disk so that it is at 0 north offset and tilt it with the inclination angle
             xfig.plot((x_sym+x_data[j])*cos(new_phi)-(y_sym+y_data[j])*sin(new_phi),(x_sym+x_data[j])*sin(new_phi)+(y_sym+y_data[j])*cos(new_phi);sym="circle",size=0.7,color="black",fill=20,fillcolor=colo);

	     _for n(0,length(r)-1,1)
	       {
		  xfig.plot(X[n,*]*cos(new_phi)-Y[n,*]*sin(new_phi),X[n,*]*sin(new_phi)+Y[n,*]*cos(new_phi));
	       }
	     variable dring = 2;
	     _for n(0,int(number/dring)-1,1)
	       {
		  xfig.plot(X[*,n*dring]*cos(new_phi)-Y[*,n*dring]*sin(new_phi),X[*,n*dring]*sin(new_phi)+Y[*,n*dring]*cos(new_phi);size=0.3);
               }
          }
     }
   else if (qualifier_exists("above")) %plots the maser spots as seen from above
     {
	xfig = xfig_plot_new(W,H);
	xfig.world(scalen,-scalen,scalen,-scalen);
	xfig.xlabel("x offset (mas)");
	xfig.ylabel("z offset (mas)");
	xfig.plot([-radius,radius],[0,0];line=0,width=3); %midline

	_for j(0,length(x_data)-1,1)
	  {
	     theta = [1:21:1]*(2.*PI/20.);
	     phi = [1:21:1]*(PI/20.);
	     rad = 0.01*radius;

	     _for n(0,length(theta)-1,1)
	       {
		  x_sym = rad*sin(phi[n])*cos(theta[n]);
                  y_sym = rad*sin(phi[n])*sin(theta[n]);
                  variable z_sym = rad*cos(phi[n]);
	       }
	     if (type[j] == "b")
	       { colo=sprintf("#%02X%02X%02X",0,0,255);     }
	     if (type[j] == "s")
	       { colo=sprintf("#%02X%02X%02X",0,150,50);    }
	     if (type[j] == "r")
	       { colo=sprintf("#%02X%02X%02X",255,0,0);     }

	     new_phi=w_0+i_0; %rotate the disk so that it is at 0 north offset and tilt it with the inclination angle
	     xfig.plot((x_sym+x_data[j])*cos(new_phi)-(y_sym+y_data[j])*sin(new_phi),(z_sym+z_data[j]);sym="circle",size=0.7,color="black",fill=20,fillcolor=colo);
	     xfig.plot(x_0*cos(new_phi)-y_0*sin(new_phi),0;sym="circle",color="black",fill=20,fillcolor="black",size=0.7);

	     _for n(0,length(r)-1,length(r)-1)
	       { xfig.plot(X[n,*]*cos(new_phi)-Y[n,*]*sin(new_phi),Z[n,*];line=5);     }
	     }
	}
   
   else  %plots the maser spots in 3d
     {
   	xfig_set_focus(vector(0,0,0));
        x_axis_up(1e5, 120, -130 );% theta is rotating along the y-axis
   
      if (qualifier_exists("no_axes"))
     { }
   else
     {
	xfig.add_object(xfig_new_polyline([-scalen,scalen],[scalen,scalen],[-scalen,-scalen]));%xaxis
	xfig.add_object(xfig_new_polyline([-scalen,-scalen],[-scalen,scalen],[scalen,scalen])); %yaxis
        xfig.add_object(xfig_new_polyline([-scalen,-scalen],[scalen,scalen],[-scalen,scalen])); %zaxis 
        xfig.add_object( xfig_new_text(xlabel; x0=0, y0=label_dist, z0=-label_dist, just=[0,0], rotate=-90)); % x-label
        xfig.add_object( xfig_new_text(ylabel; x0=-label_dist, y0=0, z0=label_dist, just=[0,0], rotate=-37)); % y-label
        xfig.add_object( xfig_new_text(zlabel; x0=-label_dist, y0=label_dist, z0=0, just=[0,0], rotate=25)); % z-label
	   if (qualifier_exists("no_grid"))
     {
	_for i(-scalen,scalen,1) %xaxis tics
	  { xfig.add_object(xfig_new_polyline([i,i],[scalen,scalen+tics_length],[-scalen,-scalen]));
	    xfig.add_object( xfig_new_text(sprintf("%i",i); x0=i, y0=scalen_frac*scalen, z0=-scalen_frac*scalen, just=[0.5,0], rotate=0 )); %xaxis
	  }
	_for j(-scalen,scalen,1) %yaxis tics
	  {  xfig.add_object(xfig_new_polyline([-scalen,-scalen],[j,j],[scalen,scalen+tics_length]));
	     xfig.add_object( xfig_new_text(sprintf("%i",j); x0=-scalen_frac*scalen, y0=j, z0=scalen_frac*scalen, just=[0.5,0.5], rotate=0 )); %yaxis
	  }
	_for k(-scalen,scalen,1)%zaxis tics
	  {  xfig.add_object(xfig_new_polyline([-scalen,-scalen],[scalen,scalen+tics_length],[k,k]));
	     xfig.add_object( xfig_new_text(sprintf("%i",k); x0=-scalen_frac*scalen, y0=scalen_frac*scalen, z0=k, just=[0,0], rotate=0 ));  %zaxis
	  }
     }
   else 
     {
	_for i(-scalen,scalen,1)
	  {
	     xfig.add_object(xfig_new_polyline([i,i],[-scalen,scalen],[-scalen,-scalen];color="lightgrey"));%xaxis grid
	     xfig.add_object(xfig_new_polyline([i,i],[-scalen,-scalen],[-scalen,scalen];color="lightgrey"));%xaxis grid
	     xfig.add_object( xfig_new_text(sprintf("%i",i); x0=i, y0=scalen_frac*scalen, z0=-scalen_frac*scalen, just=[0.5,0], rotate=0 )); %xaxis
	     xfig.add_object(xfig_new_polyline([i,i],[scalen,scalen+tics_length],[-scalen,-scalen]));%xaxis tics
	  }
	_for j(-scalen,scalen,1)
	  {
	     xfig.add_object(xfig_new_polyline([-scalen,-scalen],[j,j],[-scalen,scalen];color="lightgrey"));%yaxis grid
             xfig.add_object(xfig_new_polyline([-scalen,scalen],[j,j],[-scalen,-scalen];color="lightgrey"));%yaxis grid
             xfig.add_object( xfig_new_text(sprintf("%i",j); x0=-scalen_frac*scalen, y0=j, z0=scalen_frac*scalen, just=[0.5,0.5], rotate=0 )); %yaxis
             xfig.add_object(xfig_new_polyline([-scalen,-scalen],[j,j],[scalen,scalen+tics_length]));%yaxis tics
	  }
	_for k(-scalen,scalen,1)
	  {
             xfig.add_object(xfig_new_polyline([-scalen,-scalen],[-scalen,scalen],[k,k];color="lightgrey"));%zaxis grid
             xfig.add_object(xfig_new_polyline([-scalen,scalen],[-scalen,-scalen],[k,k];color="lightgrey"));%zaxis grid
             xfig.add_object( xfig_new_text(sprintf("%i",k); x0=-scalen_frac*scalen, y0=scalen_frac*scalen, z0=k, just=[0,0], rotate=0 ));  %zaxis
             xfig.add_object(xfig_new_polyline([-scalen,-scalen],[scalen,scalen+tics_length],[k,k]));%zaxis tics
	  }
     }
     };
   
   if (qualifier_exists("no_los"))
     {}
   else { xfig.add_object(xfig_new_polyline([0.,0.],[0,0],[0.,1.1*radius];color="blue",width=3)); }%los

   variable scaling = min(y_err)/y_err;

   if (qualifier_exists("no_data"))
     {}
   else 
     {
     	_for j(0,length(x_data)-1,1)
        {
           theta = [1:21:1]*(2.*PI/20.);
           phi = [1:21:1]*(PI/20.);
	   if (qualifier_exists("scale"))
	     { rad = 0.015*radius*scaling[j]; }
	   else{ rad = 0.01*radius;}
        
           _for n(0,length(theta)-1,1)
             {
		x_sym = rad*sin(phi[n])*cos(theta[n]);
                y_sym = rad*sin(phi[n])*sin(theta[n]);
                z_sym = rad*cos(phi[n]);
             }
           if (type[j] == "b")
             {
                colo=sprintf("#%02X%02X%02X",0,0,255);
             }
           if (type[j] == "s")
             {
                colo=sprintf("#%02X%02X%02X",0,150,50);
             }
           if (type[j] == "r")
             {
                colo=sprintf("#%02X%02X%02X",255,0,0);
             }
          xfig.add_object(xfig_new_text(`\LARGE .`;z0=z_sym+z_data[j],x0=(x_sym+x_data[j]),y0=y_sym+y_data[j],color=colo,depth=1));
        
           _for n(0,length(r)-1,1)
             {
                xfig.add_object(xfig_new_polyline(X[n,*],Y[n,*],Z[n,*];depth=2));
             }
           dring = 2;
           _for n(0,int(number/dring)-1,1)
             {
                xfig.add_object(xfig_new_polyline(X[*,n*dring],Y[*,n*dring],Z[*,n*dring];depth=2));
             }
	   if (qualifier_exists("projection"))
	     {
%		xfig.add_object(xfig_new_text(`\LARGE .`;z0=z_sym+z_data[j],x0=(x_sym+x_data[j]),y0=-scalen,color=colo,depth=1)); %z-east-plane
		xfig.add_object(xfig_new_text(`\LARGE .`;z0=z_sym+z_data[j],x0=-scalen,y0=y_sym+y_data[j],color=colo,depth=1));   %z-north-plane
		xfig.add_object(xfig_new_polyline([-scalen,-scalen],[-radius,radius],[0,0];line=0,width=1)); %midline
        	     _for n(0,length(r)-1,length(r)-1)
	       { xfig.add_object(xfig_new_polyline(-scalen,Y[n,*],Z[n,*];line=5)); %projected inner and outer Kepler curves on z-north-plane
	       }
		xfig.add_object(xfig_new_text(`\LARGE .`;z0=-scalen,x0=(x_sym+x_data[j]),y0=y_sym+y_data[j],color=colo,depth=1)); %north-east-plane
	     }
        }
     }
     }
   
   return xfig; 
}
