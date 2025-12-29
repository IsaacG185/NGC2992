define read_ep(){
%!%+
%\function{read_ep}
%\synopsis{read in the epoch files}
%\usage{read_ep([array of epoch fits files]);}
%\qualifiers{
%\qualifier{quadrant}{[=1] Quadrant which is defined as a positive distance ( RA, DEC > 0 == 1 || RA < 0, DEC > 0 == 2 || RA < 0, DEC < 0 == 3 || RA > 0, DEC < 0 == 4)
%}
%}
%\description
% This functions returns a structure of an Epoch . The require input is an array of epoch fits files.
%!%-
variable ep;
switch(_NARGS)
{ case 1: (ep) = (); }
{ help(_function_name()); return; }

variable Epoch, filename, nepochs, factor, ii, jj, dist;
variable Y, m, d;
variable unit = qualifier("unit","mas");
variable quadrant = qualifier("quadrant",1);
nepochs = length(ep);
Epoch = Struct_Type[nepochs];
switch (unit)
{
case "mas":
factor = 3.6e6;
}
{
case "degree":
factor = 1.0;
}

_for ii (0, nepochs-1, 1){
	filename = ep[ii];
	Epoch[ii] = fits_read_table (filename);
	if(quadrant == 1 || quadrant == 4){
	struct_filter(Epoch[ii],array_sort(Epoch[ii].deltax;dir=-1));
	} else {
	struct_filter(Epoch[ii],array_sort(Epoch[ii].deltax));
	}
	Epoch[ii] = struct_combine(Epoch[ii],"distance","mjd","tb","freq");
	Epoch[ii].mjd = fits_read_key(filename,"DATE-OBS");
	()=sscanf(Epoch[ii].mjd, "%4d-%2d-%2d, %2d:%2d", &Y, &m, &d);
	Epoch[ii].mjd = MJDofDate(Y, m, d);
	Epoch[ii].freq = fits_read_key(filename,"CRVAL3")/1.e9; %in GHz
	ifnot (qualifier_exists("zero")) {
	Epoch[ii].deltax = factor * Epoch[ii].deltax;
	Epoch[ii].deltay = factor * Epoch[ii].deltay;
	} else {
	%still does not work for counterjets
	Epoch[ii].deltax = factor * (Epoch[ii].deltax - Epoch[ii].deltax[length(Epoch[ii].deltax) - 1]);
	Epoch[ii].deltay = factor * (Epoch[ii].deltay - Epoch[ii].deltay[length(Epoch[ii].deltay) - 1]);
	}
	Epoch[ii].distance = sqrt(sqr(Epoch[ii].deltax) + sqr(Epoch[ii].deltay));
	Epoch[ii].major_ax = factor * Epoch[ii].major_ax;
	Epoch[ii].minor_ax = factor * Epoch[ii].minor_ax;
	Epoch[ii].tb = 1.22*1e+12*Epoch[ii].flux/(sqr(Epoch[ii].freq)*(Epoch[ii].major_ax)*(Epoch[ii].minor_ax)); % see Condon et al. 1982
	_for jj (0, length(Epoch[ii].flux) - 1, 1){
	  if(quadrant == 1){
	    if(Epoch[ii].deltax[jj] < 0 || Epoch[ii].deltay[jj] < 0){
	      Epoch[ii].distance[jj] = - sqrt(sqr(Epoch[ii].deltax[jj]) + sqr(Epoch[ii].deltay[jj]));
	  }}
	  if(quadrant == 2){
	    if(Epoch[ii].deltax[jj] > 0 && Epoch[ii].deltay[jj] < 0){
	      Epoch[ii].distance[jj] = - sqrt(sqr(Epoch[ii].deltax[jj]) + sqr(Epoch[ii].deltay[jj]));
	  }}
	  if(quadrant == 3){
	    if(Epoch[ii].deltax[jj] > 0 || Epoch[ii].deltay[jj] > 0){
	      Epoch[ii].distance[jj] = - sqrt(sqr(Epoch[ii].deltax[jj]) + sqr(Epoch[ii].deltay[jj]));
	  }}
	  if(quadrant == 4){
	    if(Epoch[ii].deltax[jj] < 0 && Epoch[ii].deltay[jj] > 0){
	      Epoch[ii].distance[jj] = - sqrt(sqr(Epoch[ii].deltax[jj]) + sqr(Epoch[ii].deltay[jj]));
	  }}
	}

};

return Epoch;
}
