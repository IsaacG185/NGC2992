%%%%%%%%%%%%%
define dcf ()
%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{dcf}
%\synopsis{compute the Edelson & Krolik discrete correlation function and returns a structure with the correlation}
%\usage{dcf(time_a, val_a, tima_be, val_b);}
%\qualifiers{
%\qualifier{err_a [=0]}{:  array containing the measurement errors of
%             val_a. If given, this is taken into
%             account by using eq. (3) of Edelson & Krolik.
%             NOTE: There are lots of problems with interpreting the
%             DCF computed this way instead of using Edelson & Krolik,
%             eq. (2), and it is NOT recommended to give erra and errb
%             (see, e.g., White & Peterson, 1994, PASP, 106, 879)}
%\qualifier{err_b [=0]}{:	as err_a except for val_b}
%\qualifier{minlag [=mininum time difference between time_a and time_b]}{:	minumum lag to consider}
%\qualifier{maxlag [=maximum time difference between time_a and time_b]}{:	maximum lag to consider}
%\qualifier{numf [=int(min([length(val_a) ,length(val_b) ])/10)]}{:	number of lag bins for which to compute the DCF}
%\qualifier{minpt [=10]}{:	minimum number of data points for a DCF value to be}
%}
%\description
%    This is the imported version of the IDL subroutine dcf.pro \n
%    It will compute the Edelson & Krolik discrete correlation function. \n
%!%-
{
  variable dcf_struct= struct{lag,cor,sdev,numpt};
  variable time_a, val_a, time_b, val_b;
  switch(_NARGS)
  { case  4: (time_a, val_a, time_b, val_b) = (); }
  { help(_function_name()); return; }

  variable err_a = mean(qualifier("err_a",0));
  variable err_b = mean(qualifier("err_b",0));
  variable minpt = qualifier("minpt",10);
  if (minpt < 0) {
    print("minpt must be positive");
    return -1;
  }

  if(length(val_a) != length(time_a) || length(val_b) != length(time_b) ) {
    print("arraysize of value and time is different");
    return -1;
  }

  variable numf = qualifier("numf",int(min([length(val_a) ,length(val_b) ])/10));

  variable a = moment(val_a);
  variable b = moment(val_b);

  
  variable udcf = Double_Type [length(val_b), length(val_a)];
  variable dt = Double_Type [length(time_b), length(time_a)];
  variable ii;
  _for ii (0, length(val_b) - 1, 1) {
    udcf[ii,*] = (val_a - a.ave) * (val_b[ii] - b.ave);
    dt[ii,*] = time_a - time_b[ii];
  }
  udcf /= sqrt( (sqr(a.sdev) - sqr(err_a)) * (sqr(b.sdev) - sqr(err_b)));

  udcf = _reshape(udcf,length(val_b)*length(val_a));
  dt = _reshape(dt,length(val_b)*length(val_a));

  variable minlag = qualifier("minlag",min(dt));
  variable maxlag = qualifier("maxlag",max(dt));

  dcf_struct.lag = minlag + (maxlag - minlag) * [0:numf] / double(numf);
  
  variable index;
  index = array_sort(dt);
  udcf = udcf[index];
  dt = dt[index];
  dcf_struct.cor = Double_Type[numf];
  dcf_struct.cor[*] = _NaN;
  dcf_struct.sdev = Double_Type[numf];
  dcf_struct.numpt = Integer_Type[numf];
  variable npt1 = length(dt) - 1;

% go to the first lag bin
  variable start = 0;
  while(start < npt1 && dt[start] < dcf_struct.lag[0]) {
    start++;
  }
  variable stop = start;
  variable mom;

  _for ii (0, length(dcf_struct.lag)-2, 1) {
    while(stop < npt1 && dt[stop] < dcf_struct.lag[ii+1]) {
    stop++;
    }
    if(start < stop) {
      if(stop == npt1 && dt[stop] < dcf_struct.lag[ii+1]) {
        mom = moment(udcf[[start:stop]]);
        dcf_struct.cor[ii] = mom.ave;
        dcf_struct.sdev[ii] = mom.sdev;
        dcf_struct.numpt[ii] = stop-start;
      } else {
        mom = moment(udcf[[start:stop-1]]);
        dcf_struct.cor[ii] = mom.ave;
        dcf_struct.sdev[ii] = mom.sdev;
        dcf_struct.numpt[ii] = stop-start-1;
      }
      start=stop;
    }
  }
  dcf_struct.lag=(dcf_struct.lag[[0:numf-1]]+dcf_struct.lag[[1:numf]])/2.;
  variable ndx = where(dcf_struct.numpt < minpt);
  if(length(ndx) > 0) {
    dcf_struct.cor[ndx] = _NaN;
    dcf_struct.sdev[ndx] = _NaN;
  }
 
  return dcf_struct;
}
