%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ISIS timing-tools
%
% lcseg.sl - Tools for reading FITS-lightcurves from extraction directories
% 	             - cutting lightcurves into segments of given size
% 	             - sync'ing lightcurves to latest start and earliest stop
% 	             - search (time)arrays for gaps
% 	             - write gzipped, segmented FITS-lightcurve set to HD
%
% Functions: timegap()
% 	     timeseg()
% 	     lcsync()
% 	     lcseg()
% 	     lcsegcombine()
% 	     lcsegwrap()
%
% Short Descriptions:
%
% (gaps, gapdura, dblock) = timegap (timearray)
%
% Qualifiers: tolerance (Changes the maximum allowed relative deviation from the bintime)
% 	      bintime (Changes the bintime - standard: zeit[1]-zeit[0])
% Outputs:    gaps (Starting bins of gaps in timearray)
% 	      gapdura (Duration of the gaps)
% 	      dblock (Duration of the uninterupted parts of the timearray)
%
% (ndx, gaps, gapdura) = timeseg (timearray, dimseg)
%
% Qualifiers: tolerance (Changes the maximum allowed relative deviation from the bintime)
%  	      searchgap (Switches the use of timegap() on/off)
% Outputs:    gaps (Starting bins of gaps in timearray)
% 	      gapdura (Duration of the gaps)
% 	      ndx (Array of indices that can be used to segment the lightcurve)
%
% () = lcsegcombine (lcname, dimseg)
%
% Qualifiers: checktimes (When activated, the timearrays are checked for inconsistencies)
% Outputs:    None!
% Effects:    Writes a gzipped FITS file to disk, containing the complete
% XTE/PCA lightcurve structure for foucalc()
%
% lcsegcombine() has to be executed in the extraction-root-path to
% work correctly:
% (crux:/data/user/pirner/x-ray/cygx-1/rxte/)
% (pulsar:/proj.stand/mpai45/cygx1/extractions/)
%
% (lc) = lcsync (lclo,lchi)
%
% Inputs:  Structures of 4 low PCA(B) channels and 2 high PCA(E) channels
% Outputs: Structure with all 6 channels (sync'ed)
%
% () = lcsegwrap (lcname,dimseg[n])
%
% Effects: Same as lcsegcombine, dimseg may be an array of dimsegs
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define XTEtoRealtime (t)
{
    variable st;
    variable rt;
    st = dateOfMJD(MJDref_satellite("XTE")+(t/86400.));
    rt = string(st.year)+"-"+sprintf("%02d",st.month)+"-"+sprintf("%02d",st.day)+"_"+sprintf("%02d",st.hour)+"-"+sprintf("%02d",st.minute)+"-"+sprintf("%02.f",floor(st.second));
    return rt;
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define gapsync (tlo,thi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable bintime = qualifier ("bintime", tlo[1]-tlo[0]);
  variable tolerance = qualifier ("tolerance", 1e-8);

  variable lo_bad = where(tlo<thi[0] or tlo>thi[-1]);
  variable hi_bad = where(thi<tlo[0] or thi>tlo[-1]);

  message ("gapsync: Syncing common times in both EAs");
  variable igap;

  variable deltalo = (shift(tlo,1)-tlo)[[:-2]];
  foreach igap (where(abs(deltalo-bintime)/bintime > tolerance))
      hi_bad = [hi_bad, where( tlo[igap] < thi < tlo[igap+1] )];

  variable deltahi = (shift(thi,1)-thi)[[:-2]];
  foreach igap (where(abs(deltahi-bintime)/bintime > tolerance))
      lo_bad = [lo_bad, where( thi[igap] < tlo < thi[igap+1] )];

  % Create index arrays for lower and upper times

  return complementary_array([0:length(tlo)-1], lo_bad),
  complementary_array([0:length(thi)-1], hi_bad);
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define gapsync2 (tlo,thi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{

  variable bintime = qualifier ("bintime", tlo[1]-tlo[0]);
  variable tolerance = qualifier ("tolerance", 1e-8);
  variable deltalo = (shift(tlo,1)-tlo)[[0:length(tlo)-2]];
  variable deltahi = (shift(thi,1)-thi)[[0:length(thi)-2]];
  variable gaplo = where(abs(deltalo-bintime)/bintime > tolerance);
  variable gaphi = where(abs(deltahi-bintime)/bintime > tolerance);
  variable lengthlo = length (tlo);
  variable lengthhi = length (thi);

  variable lowstart=0;

    if (tlo[0] < thi[0])
    {
            lowstart = where(tlo == thi[0])[0];
    }

    variable highstart=0;

    if (tlo[0] > thi[0])
    {
            highstart = where (thi == tlo[0])[0];
    }

  message ("gapsync: Syncing common times in both EAs");

  variable tgaplo = tlo[gaplo];
  variable tgaphi = thi[gaphi];
  variable tgaploend = tlo[gaplo+1];
  variable tgaphiend = thi[gaphi+1];

  variable startlo = lowstart;
  variable starthi = highstart;
  variable stoplo = Integer_Type[0];
  variable stophi = Integer_Type[0];

  variable gap;
  foreach gap (tgaphiend)
    {
       startlo = [startlo, where(tlo == gap)];
    }

  foreach gap (tgaploend)
    {
      starthi = [starthi, where(thi == gap)];
    }

  foreach gap (tgaphi)
    {
      stoplo = [stoplo, where(tlo == gap)];
    }

  foreach gap (tgaplo)
    {
      stophi = [stophi, where(thi == gap)];
    }

  variable lowstop = lengthlo-1;;

  if (tlo[-1] > thi[-1])
    {
      lowstop = where(tlo == thi[-1])[0];
    }

  variable highstop = lengthhi-1;

  if (tlo[-1] < thi[-1])
    {
      highstop = where(thi == tlo[-1])[0];
    }

  stoplo = [stoplo,lowstop];
  stophi = [stophi,highstop];

  % Create index arrays for lower and upper times

  variable blockslo = length (startlo);
  variable blockshi = length (starthi);
  variable ndxlo = Integer_Type[0];
  variable ndxhi = Integer_Type[0];

  % Create lower indices

  variable i;
  for (i=0;i<blockslo;i++)
    {
      ndxlo = [ndxlo, [startlo[i]:stoplo[i]]];
    }
  for (i=0;i<blockshi;i++)
    {
      ndxhi = [ndxhi, [starthi[i]:stophi[i]]];
    }

  return ndxlo,ndxhi;

}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define timesync (timelo,timehi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable idxlo = Integer_Type[0];
  variable idxhi = Integer_Type[0];
  variable pointerlo;
  variable pointerhi;
  variable lengthlo = length(timelo);
  variable lengthhi = length(timehi);

  for (pointerlo=0,pointerhi=0;pointerlo<lengthlo && pointerhi<lengthhi;)
    {
      if (timelo[pointerlo] == timehi[pointerhi])
	{
	  idxlo = [idxlo,pointerlo];
	  idxhi = [idxhi,pointerhi];
	  pointerlo++;
	  pointerhi++;
	}
      else if (timelo[pointerlo] < timehi[pointerhi])
	{
	  pointerlo++;
	}
      else
	{
	  pointerhi++;
	}
    }

  return idxlo, idxhi;
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define timegap (zeit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable tolerance = qualifier ("tolerance", 1e-8);
  variable bintime = qualifier ("bintime", zeit[1]-zeit[0]);
  variable deltaT = (shift(zeit,1)-zeit)[[0:length(zeit)-2]];
  variable gaps = where(abs(deltaT-bintime)/bintime > tolerance);
  variable numgaps = length (gaps);
  variable dblock;
  variable gapdura;

% Check for bins shorter than the bintime!
  variable warn = length(where(deltaT < bintime));
  if (warn > 0)
    {
      message ("timegap: There are time differences shorter than the bintime!");
    }

  if (length(gaps)==0)
    {
      message ("timegap: There are no gaps in the time array");
      dblock = length(zeit);
      gapdura = Integer_Type[0];
    }
  else
    {
      message ("timegap: There are "+string(numgaps)+" gaps in the time array");
      dblock = gaps[0]+1;
      dblock = [dblock, shift(gaps,1)-gaps];
      dblock[-1] = length(zeit)-(gaps[-1]+1);
      gapdura = zeit[gaps+1]-zeit[gaps];
    }

  return gaps, gapdura, dblock;
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define timeseg (zeit, dimseg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable tolerance = qualifier ("tolerance", 1e-8);
  variable searchgap = qualifier ("searchgap", 1);
  variable bintime = qualifier ("bintime", zeit[1]-zeit[0]);
  variable ndx;
  variable gaps;
  variable gapdura;
  variable dblock;
  variable numseg;
  variable numtime;
  variable dstart;
  variable zseg;
  variable zndx;
  variable start;
  variable i;
  variable j;
  variable nn;
  variable tdseg;
  variable dtdseg;
  variable ndxtest;

  if (searchgap != 1)
    {
      numseg=int(length(zeit)/dimseg);
      numtime=numseg*dimseg;
      ndx=[0:numtime-1];
      gaps = NULL;
      gapdura = NULL;
    }
  else
    {
      (gaps, gapdura, dblock) = timegap(zeit;tolerance=tolerance,bintime=bintime);

      if (length(gaps) > 0)
	{
	  dstart=[0,gaps+1];
	}
      else
	{
	  dstart = 0;
	}

      zseg = int(dblock/dimseg);
      zndx = where (dblock >= dimseg);
      nn = length (zndx);

      if (nn > 0)
	{
	  dstart = dstart[zndx];
          dblock = dblock[zndx];
	  zseg = zseg[zndx];
	  start = -1;

	  for (i=0;i<nn;i++)
	    {
	      start = [ start , dstart[i] + dimseg*[0:zseg[i]-1] ];
	    }

	  start = start[[1:]];

      	}
      else
	{
	  message ("timeseg: Warning! Data do not contain a valid segment...");
	  return NULL,NULL,NULL, "noseg";
	}

      ndx = Int_Type[length(start)*dimseg];

      for (i=0; i<length(start); i++)
	{
	  ndx[[(i*dimseg):(((i+1)*dimseg)-1)]] = start[i]+[0:dimseg-1];
  	}

      tdseg = zeit[ndx[0]] - zeit [ndx[dimseg-1]];
      dtdseg = Double_Type[length(ndx)/dimseg];

      for (i=0; i<(length(ndx)/dimseg);i++)
	{
          dtdseg[i] = tdseg -(zeit[ndx[i*dimseg]] - zeit[ndx[((i+1)*dimseg)-1]]);
	}

      ndxtest = where ( dtdseg != 0.);

      if (length(ndxtest) != 0)
	{
	  message ("timeseg: dt != bintime in following indices:");
	  print (ndxtest);
	}

      start=0.;
    }

  return ndx, gaps, gapdura, NULL;

}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define lcseg (structarray,dimseg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable checktimes = qualifier ("checktimes", 0);
  variable segsize = string(dimseg);
  variable searchgap = qualifier ("searchgap", 1);
  variable i;
  variable ndx;
  variable gaps;
  variable gapdura;

  (ndx,gaps,gapdura) = timeseg(structarray.time,dimseg;searchgap=searchgap);

  structarray.time = structarray.time[ndx];

  variable rarray;
  foreach rarray (get_struct_field_names(structarray)[[1:]])
    {
      set_struct_field (structarray, rarray, get_struct_field(structarray, rarray)[ndx]);
    }

  return structarray,gaps,gapdura;
}
