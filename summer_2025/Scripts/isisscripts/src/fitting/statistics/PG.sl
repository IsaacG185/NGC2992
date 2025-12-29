%%%%%%%%%%%%%%%%%%%%%%%%
static define PG_function (S, m, weight)
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{PG_function}
%\synopsis{sets fitting statistic for poisson source counts and already subtracted gaussian background}
%\usage{set_fit_statistic("PG");}
%\description
%    	This fitting statistic can be used when dealing with
%	 	low count spectra that have already been subtracted
%		by the instrumental background. Cash statistics are
%		not suited for this task since purely poisson distri-
%		buted counts are assumed in that case. 
%		This version of the fitting statistic has been derived
%		from the profile likelihood statistic for zero back-
%		ground counts from:
%
%		https://heasarc.gsfc.nasa.gov/xanadu/xspec/manual/XSappendixStatistics.html
%
%		The statistic should be used when fitting low count 
%		spectra of the Swift/BAT instrument.
%		IMPORTANT: the statistic can only be used when fitting
%		count rate spectra since the exposure times for each
%		channel have dummy values of 1s.
%\seealso{set_fit_statistic}
%!%-
{
	variable ts = 1;
	variable tb = 1;
	variable sig = 1.0/sqrt(weight);
	variable d = sqrt((ts*sig^2+tb^2*m)^2 - 4*tb^2*(ts*sig^2*m-S*sig^2));
	variable f = (-(ts*sig^2+tb^2*m) + d)/(2*tb^2);
	
       	variable PG = ts*(m+f) - S*log(ts*m+ts*f) + 1.0*(tb^2*f^2)/(2*sig^2) - S*(1-log(S));
       	return (PG, 2*sum(PG));
}

static define PG_report (stat, npts, nvpars)
{
    variable s = sprintf ("  PG = %0.4g\n", stat);
    return s;
}

add_slang_statistic ("PG", &PG_function, &PG_report);

