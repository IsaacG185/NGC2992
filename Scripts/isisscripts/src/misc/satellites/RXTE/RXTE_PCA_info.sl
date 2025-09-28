define RXTE_PCA_info()
%!%+
%\function{RXTE_PCA_info}
%\synopsis{retrieves light curves for a given RXTE-PCA observation}
%\usage{Struct_Type RXTE_PCA_info(String_Type dirs[])}
%\qualifiers{
%  \qualifier{binning}{how much datapoints are to be summed up into a single point}
%  \qualifier{path}{path to the observation}
%  \qualifier{dirs}{subdirectories to the individual observing blocks}
%
%  \qualifier{noback}{set if no bkg subtraction is to be performed}
%  \qualifier{earthvle}{set if EarthVLE background model is to be used}
%  \qualifier{faint}{set if Faint background model is to be used}
%  \qualifier{q6}{set if Q6 background model is to be used
%                (default is to test for earthvle,faint,q6)}
%  \qualifier{skyvle}{set if SkyVLE background model is to be used
%             (default is 0 for noback,earthvle,faint,q6,skyvle)}
%  \qualifier{exclusive}{set to search for data that was extracted
%                with the exclusive keyword to pca_standard being set.}
%  \qualifier{top}{set to read top-layer data}
%  \qualifier{nopcu0}{set to search for data that was extracted
%                ignoring PCU0}
%  \qualifier{fivepcu}{plot count-rates wrt to whole PCA, i.e.,
%                normalizing to five PCU; default is to plot the average
%                countrate per PCU}
%  \qualifier{bary}{Try to use barycenter time column in data. Must be
%                   created with fxbary before into file with postfix _bary.}
%  \qualifier{t}{time array of data in MJD.}
%  \qualifier{c}{count array of data}
%  \qualifier{err}{Estimated error by applying Poisson statistic.
%            Binning/background subtraction will be acknowledged.}
%\description
%    The elements of \code{dirs} may contain globbing expressions.
%
%    The returned structure has the following fields:\n
%    \code{obstime = struct { start, stop}} with the times for each observation in \code{dirs}\n
%    \code{lc = struct { time, rate, error }} with the PCA light curve\n
%    \code{obscat = struct} with information from the observation catalogue (occultation, saa, good time)\n
%    \code{gti}\n
%    \code{xfl = struct} with information from the filter file
%\seealso{aitlib/rxte/readxtedata.pro}
%}
%!%-
%
{
  variable dirs;
  switch(_NARGS)
  { case 1: dirs = (); }
  { help(_function_name()); return; }

  dirs = glob(dirs);
  variable verbose = qualifier_exists("verbose");

  variable nobs = length(dirs);
  if(verbose)
  { vmessage("retrieving PCA info from %d directories:", length(dirs));
    array_map(Void_Type, &vmessage, "- %s", dirs);
    message("");
  }

  variable obstime = struct {
    start = Double_Type[nobs],
    stop  = Double_Type[nobs],
  };
  obstime.start[*] = 1e38;
  obstime.stop[*] = -1e38;
  variable lc = struct {
    time  = Double_Type[0],
    rate  = Double_Type[0],
    error = Double_Type[0],
  };

  % given the state of the PCA, here are ALL possible combinations of PCUs where at least one PCU is still on
  variable detoff = ["",
   "0", "1", "2", "3", "4",
   "01", "02", "03", "04", "12", "13", "14", "23", "24", "34",
   "012", "013", "014", "023", "024", "034", "123", "124", "134", "234",
   "0123", "0124", "0134", "0234", "1234"];
  variable numpcuon = 5 - array_map(Integer_Type, &strlen, detoff);

  if(qualifier_exists("nopcu0"))
    numpcuon[where(array_map(Integer_Type, &string_match, detoff, "0", 1) > 0)]--;

  % conversion of measured countrate to 1PCU
  variable factor = 1./numpcuon;

  if(qualifier_exists("fivepcu"))  factor *= 5;
  variable binning = qualifier("binning", 1);

  % prepare filename
  detoff = "_" + detoff + "off";
  detoff[0] = "";

  variable topins  = ""; if(qualifier_exists("top"))  topins = "_top";
  variable exclins = ""; if(qualifier_exists("exclusive"))  exclins = "_excl";
  variable ignore  = ""; if(qualifier_exists("nopcu0"))  ignore = "_ign0";
  variable baryins = ""; if(qualifier_exists("bary"))  baryins = "_bary";

  variable lcfiles = "/standard2f" + detoff + exclins + ignore + topins + "/standard2f" + detoff + exclins + ignore + topins + baryins + ".lc";
  variable deadfi = "/pcadead/RemainingCnt.lc";
  variable backfaint = "/pcabackest/standard2f_back_Faint"    + topins + "_good" + detoff + exclins + ignore + baryins + ".lc";
  variable backq6    = "/pcabackest/standard2f_back_Q6"       + topins + "_good" + detoff + exclins + ignore + baryins + ".lc";
  variable backsky   = "/pcabackest/standard2f_back_SkyVLE"   + topins + "_good" + detoff + exclins + ignore + baryins + ".lc";
  variable backearth = "/pcabackest/standard2f_back_EarthVLE" + topins + "_good" + detoff + exclins + ignore + baryins + ".lc";

  variable i, j;
  _for i (0, nobs-1, 1)
  {
    _for j (0, length(lcfiles)-1, 1)
    {
      variable path_dir_file = dirs[i] + lcfiles[j];
      if(stat_file(path_dir_file) != NULL)
      {
	variable tt, cc, ee;
	ifnot(qualifier_exists("back"))
	{
	  if(verbose)  message("reading " + path_dir_file);
	  variable srclc = fits_read_lc(path_dir_file);  %  readlc,tt,cc,path+dirs(i)+file(j),/mjd,bary=bary
	  tt = srclc.time;
	  cc = srclc.rate;
	  % readlc,t_err,c_err,path+dirs(i)+file(j),/mjd,bary=bary
	  % ee = sqrt(c_err/double(binning)) * factor[j]
          ee = sqrt(cc/binning) * factor[j];
	}
%         IF (keyword_set(deadcorr)) THEN BEGIN
%           IF (file_exist(path+dirs(i)+deadfi)) THEN BEGIN
%             pcadeadlc,tt,cc,path+dirs(i),/mjd
%           ENDIF
%         ELSE BEGIN
%           print,'READXTEDATA: deadtime correction failed: "/pcadead/RemainingCnt.lc" does not exist'
%         ENDELSE
%
	ifnot(qualifier_exists("noback"))
	{
	  variable backfi = "";
	  if(qualifier_exists("faint")    && backfi=="" && stat_file(dirs[i] + backfaint)!=NULL)  backfi = backfaint[j];
	  if(qualifier_exists("q6")       && backfi=="" && stat_file(dirs[i] + backq6   )!=NULL)  backfi = backq6[j];
	  if(qualifier_exists("skyvle")   && backfi=="" && stat_file(dirs[i] + backsky  )!=NULL)  backfi = backsky[j];
	  if(qualifier_exists("earthvle") && backfi=="" && stat_file(dirs[i] + backearth)!=NULL)  backfi = backearth[j];

	  if(backfi=="" && stat_file(dirs[i] + backsky[j])!=NULL)
	  { backfi = backsky[j];
	    if(verbose)  message(" No background lightcurve has been specified, using 'SkyVLE'");
	  }
	  if(backfi=="")
	    message("Specified background has not been found.");

	  backfi = dirs[i] + backfi;
	  if(verbose)  message(" reading " + backfi);
  	  variable bkglc = fits_read_lc(backfi);  % readlc,tb,cb,path+dirs(i)+backfi,/mjd,bary=bary
	  if(qualifier_exists("back"))
	  { tt = bkglc.time;
	    cc = bkglc.rate;
	  }
	  else
          { if(any(tt!=bkglc.time)) vmessage("error (%s): bkglc.time != srclc.time", _function_name());
	    cc -= bkglc.rate;
	  }
	}
        cc = cc * factor[j];

%	if(binning>1)  % rebin data
%	{ % skip data at end of read set not fitting into binning:
%	  variable len = length(cc)-1 - length mod binning;
%         tt = tt[0:len:binning];
%         cc = cc[0:len];
%         ee = ee[0:len];
%	  variable ccc, eee;
%  %%%%%  cc = rebin(cc,n_elements(cc) / BINNING)
%       }
%

	% begin and end of the observation
	obstime.start[i] = _min(obstime.start[i], tt);
	obstime.stop[i]  = _max(obstime.stop [i], tt);

	lc.time  = [lc.time,  tt];
	lc.rate  = [lc.rate,  cc];
	lc.error = [lc.error, ee];
      }
    }
  }
  % sort light curve
  struct_filter(lc, array_sort(lc.time));
  if(verbose)
    if(length(lc.time)<=1)
      message("no files found");
    else
      message("");

  % read timeline to get occultation-times, saa-times, ...
  variable obscat = NULL;
  variable obscat_days = Integer_Type[0];
  _for i (0, nobs-1, 1)
    obscat_days = [ obscat_days, [int(obstime.start[i]-49354) : int(obstime.stop[i]-49352)] ];
  % produce unique list of timelines
  if(any(obscat_days>=0))  obscat = RXTE_obscat_info( obscat_days[unique(obscat_days)];; __qualifiers() );
  if(verbose and obscat!=NULL)  message("");

  % read GTI-Files used for preparing the spectra
  variable gti = struct { start = Double_Type[0], stop = Double_Type[0] };
  variable gtfi;
  _for i (0, length(dirs)-1, 1)
    foreach gtfi ( dirs[i] + "/filter/good" + detoff + exclins + ignore + ".gti" )
      if(stat_file(gtfi)!=NULL)
      {
	if(verbose)  message("reading " + gtfi);
	variable MJDREF = fits_read_key(gtfi, "MJDREFI") + fits_read_key(gtfi, "MJDREFF");
	gtfi = fits_read_table(gtfi);
        gti.start = [gti.start, MJDREF + gtfi.start/86400.];
        gti.stop  = [gti.stop,  MJDREF + gtfi.stop /86400.];
      }
  struct_filter(gti, array_sort(gti.start));
  if(verbose)  message("");

  % read electron ratios and times when the PCUs were on from the filter files
  variable xfl = RXTE_filter_file_info( dirs + "/filter/*xfl" ;; __qualifiers());

  return struct {
    obstime = obstime,
    lc = lc,
    obscat = obscat,
    gti = gti,
    xfl = xfl,
  };
}
