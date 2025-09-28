% -*- mode: slang; mode: fold -*-

require("pgplot");

%; File: aglc.sl                "ACIS Grating Light Curve"
%; Author: David P. Huenemoerder <dph@space.mit.edu>
%; Original version: 2003.09.05
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This file is part of aglc (Acis Grating Light Curve).
% Copyright (c) 2007-2008 Massachusetts Institute of Technology 
%
% This software was developed by the MIT Kavli Institute for
% Astrophysics and Space Research under contract SV3-73016 from the
% Smithsonian Institution.
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either  version 2 of the
% License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
% General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
% 02110-1301, USA.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% versioning...
%
private variable _version = [1, 5, 3]   ; % major, minor, patch
variable aglc_version = sum( _version * [ 10000, 100, 1 ] ) ; 
variable aglc_version_string = sprintf("%d.%d.%d", 
_version[0],
_version[1],
_version[2] ) ; 
%
% PURPOSE: Compute light or phase curves from grating/ACIS event data.
%          Do chip by chip to apply proper GTI (implicitly from EXPNO)
%          then sum counts, average the exposure and compute rate.
%
%          Return a light curve structure.  Optionally write to file.
%
%          Parameters allow fairly general combinations of gratings
%          (HEG, MEG), orders, and wavelength regions.  E.g., lists of
%          wmin, wmax can be used to provide light curves for high-T
%          lines vs low-T lines.
%
%          Cross-dispersion limits can be set to select different
%          rectangular region in diffraction coordinates, such as for
%          binning backgrounds.
%
%  Unsupported:
%
%          Chip background (tg_part=99; outside Level 1.5 mask) is not
%          supported, since there is no wavelength assigned to the
%          non-grating order spatial region
%
%          Inter-order background (tg_m=99) is not supported, since
%          there are no wavelengths assigned to the unresolved events.
%
%          Zero-order is not supported, since there are no wavelengths
%          assigned in the zero order region. (use dmextract)
%
%          HRC: doesn't have complications of multi-chip GTI, so
%          dmextract and dm-filters will suffice.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUTS:
%
% evt1a: ACIS/grating events; must have grating coordinates.
%         Assumed "level 2": grade and status filtered (if not, a
%         filter can be specified).
% 
% stat1: Exposure reference; one EXPNO for every exposed frame.
%        stat1 is preferred, since it is smaller and will bin faster.
%        evt1 also has EXPNO, but could have dropped frames for very
%        bright sources.
%
% evt1: (optional) Unfiltered file for full exposure number set;
%       Can be given instead of stat1, but will be slower since will
%       contain many instances of each unique expno.
%
% tbin: time bin size, in seconds.
%
% wmin:  array of minima of wavelength ranges
%
% wmax:  array of maxima of wavelength ranges ... must be same number as in wmin 
%        These are paired 1-1
%        e.g.   [12.0], [12.2]                single line
%                12.0,  12.2                  same as above
%               [12.0, 18.9], [12.2, 19.1]    two regions, Ne10, O8
%
% tg: array of grating region types, one or both of ["HEG","MEG"], or "LEG"
%       Also accepted are scalars, lowercase, first character:
%                "h"
%                ["h", "MEG"]         etc
%                (but "LEG" should not occur w/ HEG or MEG).    
%
% orders:   array of integer orders;
%           e.g., [-1,1]; 1; [-3,-2,-1]; [[-3:-1],[1:3]];
%
% bkg: Optional flag;  any value means extract background curve
%      instead of source.
%
% Returned value is a  light curve structure:
% ( similar to that produced by dmextract opt=lc1 )
%
%     time_min = Double_Type[]
%     time_max = Double_Type[]
%     time = Double_Type[]
%     counts = Integer_Type[]
%     count_rate = Double_Type[]
%     stat_err = Double_Type[]
%     exposure = Double_Type[]
%
% additionally returned  in the structure are:
%     timezero  (== TSTART)
%     mjdref
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% GENERAL PROCEDURE: 
%
%     Form a filter from the parameters: wmin, wmax, tg, orders.  For
%     the source region, the filter is the default tg_d_min to
%     tg_d_max range.
%
%     If background, then the filter excludes the source region, and
%     backscale is computed as the ratio of bkg region width to source
%     region width, and the rate is scaled to the src region width.
%
%     The filter will specify one or more CCDs.  Each must be processed
%     independently to account for the proper exposure.    
%
%     The light curve will be made by binning the number of
%     occurrences of each exposure number (EXPNO) vs exposure number,
%     and converted to a rate vie each frame's exposure time of
%     TIMEDEL-0.04104 seconds.
%
%     The exposure per frame is done implicitly from the frames
%     present within the entire range of frames.  It is assumed that
%     the input events have already been filtered on the GTI.  NOTE:
%     this could easily be relaxed by referencing an appropriate set
%     of GTI tables and intersecting them with event times.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% REVISION HISTORY.
%
% 2011-02-08 - v-1.5.3 (Mh)
%  - fixed aglc_read_events().READ_GRP_PER_EXPNO for CC mode (=> 512)
%  - modified aglc_read_events().tstart such that times calculated
%    from expno's will better agree with original times
%  - _aglc2 adjusts the time bin size to a multiple of the frame time
%    s.timedel * s.READ_GRP_PER_EXPNO
%    instead of the effective frame exposure s.frame_exp
%  - remove xround in favour of S-Lang's intrinsic nint function
%
% 2010.09.16 - v-1.5.2
%  change the internal round() function to xround().
%  It is private, but one user (M.H.) reported a conflict with the
%  intrinsic round.  (I should use the intrinsic round() or nint()).
%  My round() fails on negative numbers, which don't matter here.
%  As a patch, rename it.
%
% 2010.08.24 - v-1.5.1
%    bug fix: aglc_write_curve() barfed due to NaNs in sum(c.exposure) for
%             FITS header keyword.  Now omit NaN in the sum.
%             
% 2010.08.10 - v-1.5.0:
%   fixed bug in aglc_phased() which caused a discontinuity in phase curves. 
%
%
% 2010.08.04 - 
%
%  Work the same changes as below into _aglc_phased2(), to handle the
%  rate and exposure properly.
%
% 2010.08.04 - 
%    Adopt changes made by Manfred Hanke which fixed an error with
%    differential frame dropouts on different CCDs.  Also compute a
%    self-consistent exposure, and add his rate error column to the
%    output. 
%
%   NOTE: this change has not yet been incorporated into the phase
%   computation; changes to _aglc_phased will be similar to those in
%   _aglc2 relative to  _aglc. 
%
% 2009.07.10 
%    v 1.3.9 - fix bug in status bit check.
%
% 2008.04.12 - cc is correct now (I think - see 2007.07.05 comments)
%    v 1.3.7: add BACKSCAL == 1.0 keywords to output file.
%             apply jed patches for external GTI tables.
%              Changes are back-compatible. New optional arguments
%              allow specification  of GTI files (like an flt1) in
%              aglc_read_events(), or via a qualifier, gti="flt1" in
%              aglc(). 
%
% 2007.07.03 - still bug in cc-mode; curve right shape, but time scaled wrong.
%              need to review both time and exposure. [fixed in 1.3.6]
%
% 2007.06.15 - bug in phase binning - used frame_exp, not timedel.
%              0.04104s /frame in time before conversion to phase.
%
%
% 2007.06.12  found bug in time grid - omitted the 0.04104 s/frame;
%             Found by getting wrong period in EX Hya.
%
%
% 2007.03.27  changed copyright to gpl version
%
% 2007.02.16  fix output counts data type; histogram() creates
%             UInteger_Type, but cfitsio requires Integer_Type.
%
% 2007.01.31  fix grid problem; time_min[1] was > time_max[0].
%
%
% 2006.10.14  revert to isis histogram to remove external dependency
%             on histogram module.  Should suffice to change "hist1d"
%             to "histogram" and in instances which use the reverse
%             indices, to change "&r" to ", &r".

% 2005.09.23  1.2.4 fixed aglc_write_curve - had 2 extname fields.
%
% 2005.06.10  1.2.3 fixed spelling error in usage message
%        .13        changed "static" to "private"
%                   appended EXPERIMENTAL utility, garf_gaps()
%
% 2005.05.23  1.2.2 modify for slang 2 array indexing
%
% 2005.04.05  1.2.1 modify conditional loads for isis vs ciao
%             Ciao 3.2 does not need namespace use and now supports
%             "require/provide".
%
% 2005.03.20    1.2.0  read stat1 file for exposure.  Stat1 has
%                   one record for each unique expno.  Much smaller
%                   file, bins very fast.
%
% 2004.07.02   Add output function.
%              Add mjdref to phase curve structure.

% 2004.07.01  Deem it 1.0.0 and ready for release.
%              Ran tests; updated html docs. Ran demos.

% 2004.06.30 v0.1r7 - modify ephemeris interface
%         - not stored/hidden, but explictly passed.
%         -  Added ephemeris to phase curve structure.

% 2004.05.04 v0.16 - allow cfitsio filters.
% Remove any cfitsio filters (in "[]" in filename).
% fixed small bug in aglc_filter, w/ scalar index "list"
% fixed small error in phase grid; truncate if max(phi) > 1.0

% 2004.05.03  v0.15 - make sherpa compatible.

% message(" version 0.14 has bug in exposure"); % traced to hist1d().---fixed there.

%% 2004.04.15 v0.14 - use histogram module; modify histogram calls.
%%                  ** need to test overflow bin for short phase ranges.
%%                  ** see notes on v0.11

%% 2004.04 v 0.13 add explicit time read; need for gti filtering.

%    2003.09.13 - punt dmextract and do it right.
%                 Use expno instead of times.
%                 Add phase option, w/ input of period and epoch.
%
%   2003.10.01  talked to gea re cc:
%        use READMODE to see if CONTINUOUS vs TIMED
%	or if TIMEDEL<0.2, frametime=510*TIMEDEL.
%        (TIMEDEL could be as small as 0.24104 in TE, if sub-array)
%
% version 0.12 - 2004.02.22 -
%                           
%      Unify naming scheme: agilc -> aglc
%                      change agpc_ to aglc_
%     agpc =>  Acis Grating Phase Curve
%     Make names phase-curve specific, but have aglc prefix for
%     uniformity w/in package.
%
%
% version 0.11 - 2003.12.24 - simplify phase gridding?
%                             Store phases in event structure? (not yet).
%                   To avoid confusion from the overflow bin, 
%                   make all grids explicit lo-hi.
%                   Had a problem w/ phase ranges like: [0.1:0.2:0.01],
%                     since the sum did not give the proper exposure unless
%                     ignoring the last bin. 
%                   All occurrences change w/ phase_grid.
%
% version 0.10 - 2003.12.12- - add reverse histogram option.
%                 define reverse-index variable in light curve struct
%                 return revidx from counts = histogram() statements (2)
%                   Careful to re-index into lev selection
%                   Also need to concatenate revidx over ccd loop.
%
%    NOTE: 2003.12.14: Also need revidx for exposure!!!
%          Needed to re-compute proper exposure after filtering on
%          selected light curve or phase curve bins.
%
%%% Supply reverse indices, based on selections of specific
%%% light curve or phase curve bins.  E.g., given a light curve, we may
%%% wish to select a high-state via where(count_rate>val), then bin a
%%% spectrum from the events those bins reference.  This is trivially done 
%%% externally for few simple time regions, but is more difficult if there
%%% are many.  It is most effective when considering phase, for which a bin
%%% could come from many event times.
%%%
%%% Such a selection effectively defines a new set of time intervals (GTI)
%%% which could be written to a FITS file filter.
%%%
%%% Alternatively, when the bins are selected in the light (or phase) curve,
%%% the exposure is also specified by the sum of the exposure over the bins.
%%%
%%% The reverse indices will be added to the light/phase curve structure.
%%% To apply (externally), the events will have to be read explicitly with
%%% aglc_read_events.  The indices will then point into .the evt1a data.
%
%%% Also add a helper function to reform an Array_Type of arrays into a single
%%%  list --- Integer_Type[] = cat_arrays( Array_Type[] );
%
% version 0.9 - 2003.11.21 - added extraction/bkg region support functions.
%                          - added 3 explicit regions:
%                                lower background
%                                source
%                                upper background
% version 0.8 - cc mode fixes
%
% version 0.7 - 2003.09.19
%               add time filtering; needed for phase support.
%
% version 0.6 - 2003.09.18
%               phase support revisions
%
% version 0.5 - 2003.09.17
%               begin adding phase support:
%
%                 t = expno_to_time(s);
%                    use timedel, timezero.
%                    Ignore differences between ccd's.
%
%                 p = time_to_phase(t, hjd_epoch, period);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ---------- NOTES ON TIME CONVERSION -------------------------------
%
%  cxo time to jd: (tricky,tricky - cxo uses MJD!!! )...
%
%   T_conj_HJD = 2452506.4328;   %(for example)
%   P_day =  0.27831149;         %(for example)
%   sec_day =  86400.0;
%   dmjd = 2400000.5;
%
%   mjdref = fits_read_key("evt1a","MJDREF"); % get from header.
%
%   % t is cxo evt time:
%   nrot = ((t / sec_day + mjdref + dmjd) - T_conj_HJD ) / P_day;
%   phi =  nrot mod 1.0;
% ------------------------------------------------------------
%
%         aglc_set_ephem( hjd_epoch, period );   % deprecate v0.17
%         (hjd_epoch, period) = aglc_get_ephem();
%         Set/get private variables          
%
%         clone aglc, _aglc into
%                  agpc(...);
%                 _agpc(...);
%         check that hjd_epoch and period variables are set.
%         still use tbin in time, but produce phase curve
%         mods in _aglc to convert expno_ to phase before histograms.
%  ----------------------------------------------------------------
%
% version 0.5 - 2003.09.17
%               Change argument parsing to get rid of _aglc as public
%               function.  use __pop_args to test first arg; if struct, 
%               then skip file-reading and call _aglc.

% version: 0.4 - 2003.09.16
%                Fix time.  The first frame is not at TSTART, but 
%                could be some time later.  Noticed 1200s difference from
%                dmextract output.  will have to read time column.
%
% version: 0.3 - rearrange functions so that the light curve can be computed
%                independently of data-read.
% version: 0.2
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   END OF REVISION HISTORY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

%

%% *** revise *** ciao 3.2 does not require this wrapper ...
%% ***        *** ciao 3.2 has require
%%

%%% You must have the histogram module installed.
%%% It is comprised of histogram.sl, and histogram-module.so, which 
%%% can be obtained from
%%% http://space.mit.edu/CXC/software/slang/modules/
%%% (it is not (yet) bundled with ciao).
%%% If your system does not have paths configured to automatically
%%% find it, you will need to  set appropriate environment variables, 
%%% or set paths in the slang interpreter via something like:
%%% 
%%%  set_import_module_path( "blah/lib/slang/modules:" + get_import_module_path ) ; 
%%%  set_slang_load_path(    "blah/slsh/local_packages:" + get_slang_load_path );
%%% 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% global data

%%% re-form source and background extraction region info into a structure.
%%%  NOTE: this still only supports rectangles, and not the "bow-tie"
%%%
private variable ext_regions =
struct { s_min,
s_max,
backscale,
src_backscale,
bkg_backscale,
b_lo_min,
b_lo_max,
b_hi_min,
b_hi_max
} ;
%%%%%

% Default grating source region, cross-dispersion:
%  Redefine limits so bkg region lower and upper can be discontinuous
%  from source region:


private variable DEF_s_min = -6.6e-4,
DEF_s_max =  6.6e-4,
DEF_b_lo_min = -6.0e-03,
DEF_b_lo_max = DEF_s_min, 
DEF_b_hi_min =  DEF_s_max,
DEF_b_hi_max =  6.0e-03;

% Phase out these variables.................use the struct instead ***
%
% static variable d_min = DEF_d_min,                 % ***
%                d_max = DEF_d_max ;                 % ***

% static variable max_bkg_tgd = DEF_b_up_max,        % ***
%                 min_bkg_tgd = DEF_b_low_min ;      % ***

%
%    BACKSCAL is the ratio of bkg region width to src region width, and the
%         divisor for the counts to scale to src region size.
%

% static variable backscale = 1.0;    % default for source light curve % ***
% static variable src_backscale = 1.0; % ***
% static variable bkg_backscale = (max_bkg_tgd - min_bkg_tgd) / (d_max - d_min) - 1.0 ; % ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STATUS_FILTER=1 will cause the events to be filtered on status==0.
%  If this is not set, and status != 0 is detected, a warning is issued.
%
private variable FILTER_STATUS = 0 ; 
define aglc_set_status_filter( flag )  %{{{
%!%+
%\function{aglc_set_status_filter}
%\synopsis{Set a flag to specify if the grating events should be filtered on STATUS=0.}
%\usage{aglc_set_status_filter( flag );}
%\description
%    By default, the status filter is zero, meaning all good
%    events.  Different status bit fields qualify attributes of "bad"
%    pixels.  If, for some reason, the grating events have not been
%    filtered on status, but should be, then setting this flag causes
%    all events with non-zero status to be ignored.
%
%    If flag=1, then ignore events with non-zero status.
%    If flag=0, then accept all events.
%\seealso{aglc, aglc_phased}
%!%-
{
    FILTER_STATUS = flag and 1 ;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
private define calc_backscales()  %{{{
{
    %    print(ext_regions); %%%% debug ***
    ext_regions.src_backscale = 1.0 ;
    ext_regions.bkg_backscale =
    (
    ( ext_regions.b_hi_max - ext_regions.b_hi_min )
    + ( ext_regions.b_lo_max - ext_regions.b_lo_min)
    )
    / (ext_regions.s_max - ext_regions.s_min)  ;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
define aglc_set_regs( s_min, s_max, b_lo_min, b_lo_max, b_hi_min, b_hi_max )  %{{{
%!%+
%\function{aglc_set_regs}
%\synopsis{Set the spatial binning regions (cross-dispersion) for the source
%    and backgrounds on both sides, and compute the background scaling factors.}
%\usage{aglc_set_regs( s_min, s_max, b_lo_min, b_lo_max, b_hi_min, b_hi_max );}
%\description
%   Limits are given in cross-dispersion coordinates, tg_d, in units of degrees.\n
%   \code{s_min} = source minumum tg_d.\n
%   The center of the source region is defined as tg_d = 0.\n
%   \code{s_max} = source region maximum tg_d.\n
%   \code{b_lo_min} = background minimum, on the "low" side (tg_d < 0).\n
%   \code{b_lo_max} = background maxmimum, on the "low" side (tg_d < 0).\n
%   \code{b_hi_min} = background minimum, on the "high" side (tg_d < 0).\n
%   \code{b_hi_max} = background maxmimum, on the "high" side (tg_d < 0).
%
%   The limits follow the constraint that
%      \code{b_lo_min < b_lo_max <= s_min < s_max <= b_hi_min < b_hi_max}.
%
%   Default values are the same as the default spectral extraction
%   regions of tgextract:\n
%      \code{s_min    = -6.6e-04}  [ deg ]\n
%      \code{s_max    =  6.6e-04}  [ deg ]\n
%      \code{b_lo_min = -6.0e-03}  [ deg ]\n
%      \code{b_lo_max =  s_min}    [ deg ]\n
%      \code{b_hi_min =  s_max}    [ deg ]\n
%      \code{b_hi_max =  6.0e-03}  [ deg ]\n
%\seealso{aglc_reset_regs, aglc_get_regs}
%!%-
{
    if (     ( s_min >= s_max )
    or ( b_lo_min >= b_lo_max )
    or ( b_lo_max > s_min )
    or ( b_hi_min < s_max )
    or ( b_hi_min >= b_hi_max )
    )
    {
	error("Bkg/Src limits inconsistent. Order must be: b_lo_min < b_lo_max <= s_min < s_max <= b_hi_min < b_hi_max");
	return;
    }

    ext_regions.s_min = s_min ;
    ext_regions.s_max = s_max ;

    %    ext_regions.min_bkg_tgd = b_min ;     % ***
    %    ext_regions.max_bkg_tgd = b_max ;     % ***

    ext_regions.b_lo_min = b_lo_min;
    ext_regions.b_lo_max = b_lo_max;
    ext_regions.b_hi_min = b_hi_min;
    ext_regions.b_hi_max = b_hi_max;

    calc_backscales();
    
    %    d_min = s_min ;             % ***
    %    d_max = s_max ;             % ***

    %    min_bkg_tgd = b_min ;       % ***
    %    max_bkg_tgd = b_max ;       % ***
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


aglc_set_regs( DEF_s_min, DEF_s_max, DEF_b_lo_min, DEF_b_lo_max, DEF_b_hi_min, DEF_b_hi_max );

% ext_regions.d_min = d_min;                    % ***
% ext_regions.d_max = d_max;                    % ***
% ext_regions.max_bkg_tgd = max_bkg_tgd ;       % ***
% ext_regions.min_bkg_tgd = min_bkg_tgd ;       % ***

% calc_backscales() ;

%%%%

private variable tg_part_map = Assoc_Type[ Integer_Type ];

tg_part_map["h"] = 1;     % heg
tg_part_map["m"] = 2;     % meg
tg_part_map["l"] = 3;     % leg

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
define aglc_reset_regs()  %{{{
%!%+
%\functon{aglc_reset_regs}
%\synopsis{Reset the source and background binning regions (in cross-dispersion
%    direction) to their defaults.  Calculate and store background scale factors.}
%\usage{aglc_reset_regs;}
%\description
%    Reset to defaults.
%\example
%    print( aglc_get_regs );   % Are they as desired? if not...
%    aglc_reset_regs;
%\seealso{aglc_set_regs, aglc_get_regs}
%!%-
{
    aglc_set_regs( DEF_s_min, DEF_s_max, DEF_b_lo_min, DEF_b_lo_max, DEF_b_hi_min, DEF_b_hi_max );
    %    calc_backscales() ;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
define aglc_get_regs()  %{{{
%!%+
%\function{aglc_get_regs}
%\synopsis{Retrieve stored source and background regions
%    (cross-dispersion limits), and associated BACKSCAL values.}
%\usage{r = aglc_get_regs;}
%\description
%    Retrieves a structure containing the stored values used for binning
%    light curves for source or background.
%\seealso{aglc_set_regs, aglc_reset_regs}
%!%-
{
    return ext_regions;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%% this function from j.davis %%%, w/ slight modification.
%%% returns array of same length as t, with flags where t is in GTI.
%%% Leaves where() to the application (mainly so one can " where( a or b or c)" over many ccdid).
%%
private define gti_flag (g, t)  %{{{
{
    % (from j.davis gtifuns.sl) %
    variable num = length (t);
    variable ok = Int_Type[num];
    variable start = g.start;
    variable stop = g.stop;
    variable n = 0;

    EXIT_BLOCK
    {
	return ok;
    }
    
    _for (0, length(start)-1, 1)
    {
	variable i = ();
	variable s = start[i];
	
	while (t[n] < s)
	{
	    n++;
	    if (n == num)
	    return;
	}
	s = stop[i];

	variable n0 = n;
	while (t[n] < s)
	{
	    n++;
	    if (n == num)
	    break;
	}
	if (n == n0)
	continue;
	
	ok[[n0:n-1]] = 1;
    }
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% apply the evt1a GTI filters to the exp_ref events ccd and expno columns,
%  Since structs are passed by references, changing structure fields will 
%   change in the input parameter.
%
private define aglc_filter_gti( s_evt )  %{{{
{
    %    variable c = where( hist1d( s_evt.ccd, [0:9] ) ); % count ccds, get ids.
    % 1.3.0:
    variable c = where( histogram( s_evt.ccd, [0:9] ) ); % count ccds, get ids.
    variable n = length( c );

    variable i ;
    variable flag = Integer_Type[ length( s_evt.expno ) ] ;

    for ( i=0; i<n; i++ )
    {
	()=printf(" %d", c[i] ); () = fflush(stdout); %%% DEBUG
%%%v-1.3.7	variable g = fits_read_table( sprintf( "%s[GTI%d]", s_evt.fevt_1a, c[i] ) ) ;
%%%v+1.3.7+
	variable g = fits_read_table( sprintf( "%s[GTI%d]", s_evt.fgti, c[i] ) ) ;
%%%v-1.3.7-
	variable lccd = where( s_evt.ccd == c[i] ) ;
	flag[ lccd ]  = flag[ lccd ] or gti_flag( g, s_evt.time[ lccd ] );
    }
    flag = where( flag );

    s_evt.expno = s_evt.expno[ flag ];  
    s_evt.ccd = s_evt.ccd[ flag ];
    s_evt.time = s_evt.time[ flag ];
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
define aglc_read_events ()  %{{{
%!%+
%\function{aglc_read_events}
%\synopsis{Read subset of events from grating file and from exposure file into a structure.}
%\usage{Struct_Type s = aglc_read_events(String_Type tgevt, expno_ref);}
%\description
%    \code{tgevt} should be a Level 1.5 (or 2) grating events file name.
%    \code{expno_ref} should be a Level 1 ``stat'' or events (unfiltered) file name.
%    The returned value is a structure.  The detailed contents of the
%    structure are given below in the example.  While the exposure can
%    be computed from the EXPNO column of the unfiltered event file,
%    use of the `stat1' file is more efficient.
%
%    Definitions for Event Structure Fields:\n
%    - \code{fevt_1a}: File name for grating events.\n
%    - \code{fevt_exp}: File name for exposure reference (unfiltered events or ``stat1'' file)\n
%    - \code{expno[]}: Exposure number column from exposure reference file.\n
%    - \code{ccd}: CCD_ID column from exposure reference file.\n
%    - \code{expno_1a }: Exposure number column from grating event file.\n
%    - \code{ccd_1a}: CCD_ID column from grating event file.\n
%    - \code{tgpart}: TG_PART column from grating event file. (value is 1 for HEG, 2 for MEG, 0 for zero order, 99 for background)\n
%    - \code{order}: TG_M column from grating events file, giving the diffraction order.\n
%    - \code{tgd}: TG_D column from grating events file. This is the cross-dispersion coordinate in degrees.\n
%    - \code{wave}: TG_LAM column from grating events file, giving the wavelength of each event.\n
%    - \code{timedel}: TIMEDEL keyword from grating event file, needed for scaling exposure numbers to time. (See the ahelp on time.)\n
%    - \code{timepixr}: TIMEPIXR keyword from event file. (See the ahelp on time.)\n
%    - \code{frame_exp}: the exposure time per frame (EXPNO). (See the ahelp on time.)\n
%    - \code{mjdref}: Modified Julian Day reference time for Chandra observations, from the event file header.\n
%    - \code{tstart}: TSTART, from the event file header, is the observaton start time in seconds since MJDREF.\n
%    - \code{status}: Event status column, from the grating events file. (See the definition of ACIS status bits.)\n
%    - \code{time}: The TIME column from the exposure reference event file.\n
%    - \code{cycle}: unused.\n
%\seealso{aglc_filter, aglc, aglc_phased}
%!%-
{
    % file_1a is "Level-1.5" or "-1a", with grating coordinates.
    %
    % file_1  is "Level-1" - could be same as file_1a, but it MUST be
    %         unfiltered (have bad status).
    %
    %   Often, the 1a or Level 2 files have bad status removed.
    %   If the 1a file has not been filtered, it can be used for both args.
    %   The "bad status" file is needed merely to occupy all frames exposed.
    %

%%%v-1.3.7    variable file_1a, file_1;
%%%v+1.3.7+
    variable file_1a, file_1, gtifile;
%%%v+1.3.7-

%%%v-1.3.7    if (_NARGS != 2)
%%%v-1.3.7    {
%%%v-1.3.7	message("USAGE:  s = aglc_read_events( tgevt, expno_ref )");
%%%v+1.3.7+	
    switch (_NARGS)
    {
	case 2:
	(file_1a, file_1) = ();
	gtifile = NULL;
    }
    {
	case 3:
	(file_1a, file_1, gtifile) = ();
    }
    {
	message("USAGE:  s = aglc_read_events( tgevt, expno_ref[, gtifile])");
%%%v+1.3.7-

	message("     tgevt should be a Level 1.5 (or 2) grating events file name.");
	message("     expno_ref should be a stat1 or Level 1 events (unfiltered) file name;");
	message("        (stat1 is more efficient)." ) ; 
	message("     The returned value is a structure.");
	message("See also: aglc(), aglc_phased().");
	return -1;
    }

%%%v-1.3.7    file_1 = ();
%%%v-1.3.7    file_1a = ();

    variable s = struct
    {
	fevt_1a,
	filt_1a,
%%%v+1.3.7+
        fgti,
%%%v+1.3.7-
	fevt_exp,
	filt_exp,
	expno,
	ccd,
	expno_1a,
	ccd_1a,
	tgpart,
	order,
	tgd,
	wave,
	timedel,
	timepixr,
	frame_exp,
	mjdref,
	tstart,
	status,
	time,
	cycle,
	READ_GRP_PER_EXPNO
    }
    ;

    %    variable expno, ccdid, tgpart, order, tgd, wave, estat, etime ;
    
    vmessage("%% Reading files %s, %s ...", file_1a, file_1 );

    (s.expno_1a, s.ccd_1a, s.tgpart, s.order, s.tgd, s.wave, s.status) =
    fits_read_col (file_1a,
    "expno",
    "ccd_id",
    "tg_part",
    "tg_m",
    "tg_d",
    "tg_lam",
    "status");

    vmessage("%% Read %d events.", length( s.expno_1a ) );

    variable tmp_names;

    tmp_names = strchop(file_1a, '[', 0 ) ;

    s.fevt_1a =  tmp_names[0] ; % truncate any cfitsio filter.
    if ( length(tmp_names) > 1 )   s.filt_1a =  "[" + tmp_names[1] ; % store any cfitsio filter.

%%%v+1.3.7+
    if (gtifile == NULL)
      gtifile = s.fevt_1a;
   
    s.fgti = gtifile;
%%%v+1.3.7-

    tmp_names = strchop(file_1, '[', 0 ) ;
    s.fevt_exp = tmp_names[0]  ;  % truncate any cfitsio filter.
    if ( length(tmp_names) > 1 ) s.filt_exp = "[" + tmp_names[1]  ;  % store any cfitsio filter.

    s.timedel  = fits_read_key (file_1a, "TIMEDEL");
    s.timepixr = fits_read_key (file_1a, "TIMEPIXR");

    %% v0.8 cc-mode fix:
    if ( fits_read_key (file_1a, "READMODE") == "TIMED")
    {
	s.READ_GRP_PER_EXPNO = 1 ; 
	s.frame_exp = s.timedel - 0.04104;
    }
    else
    {
	s.READ_GRP_PER_EXPNO = 512;
	s.frame_exp = s.timedel  * s.READ_GRP_PER_EXPNO ; 
    }
    
    s.mjdref = fits_read_key (file_1a, "MJDREF");

    %%% *** could define/set for 1a list:
    %%%    s.time = s.expno * s.frame_exp + s.frame_exp*s.timepixr  %%% ***
    %
    %% v 0.13 add explicit time read; need for gti filtering.

    if (file_1a == file_1)   % all in one file - don't read twice
    {
	s.expno = s.expno_1a;
	s.ccd = s.ccd_1a;
    }
    else    % have separate unfiltered file
    {
	(s.expno, s.ccd) = fits_read_col(file_1, "expno", "ccd_id");
	vmessage("%% Read %d exposure reference records.", length(s.expno) );
	%	s.expno = expno;
	%	s.ccd = ccdid;
	%	s.time = etime;
    }
    s.time = fits_read_col(file_1, "time");

    % Get a time-stamp from the minimum time present in the file and correct it for its exposure number
    % -- or even compute the mean for all times (though this will take way longer).
    % while there could be different min times for each ccd (and will be),
    % it can only differ by a few seconds.  So for >100 s bin light curves,
    % it will be moot. (CC grating timing will be a seperate story).

    % read times from the big file, keeping only the minimum:
    % (only read the first row; the file is time-sorted)

    %%% need to read either an EVENTS or EXPSTATS extension. 

  % s.tstart =      s.time[0] - s.expno[0] * s.timedel * s.READ_GRP_PER_EXPNO - s.frame_exp * s.timepixr ;  % only consider first time
    s.tstart = mean(s.time    - s.expno    * s.timedel * s.READ_GRP_PER_EXPNO - s.frame_exp * s.timepixr);

    % DEBUG:
    () = printf("%% Applying gti filters..."); () = fflush(stdout);
    % DEBUG:

    aglc_filter_gti( s ); % use evt1a GTI table to filter expref data.

    message("");

    return s;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
private define cons_event_flags( s, do_bkg, orders, tg, wmin, wmax )  %{{{
{
    %
    % construct event filter:

    variable i;
    variable n_evt = length( s.expno_1a ) ; 
    variable tmp_flags = Integer_Type[ n_evt ] ;
    variable evt_flags = Integer_Type[ n_evt ] ;    

    variable r = ext_regions;

    if (do_bkg)   % filter on events outside source tg_d region:
    {
        evt_flags = 
	( (s.tgd >= r.b_lo_min ) and (s.tgd < r.b_lo_max ) )
	or ( (s.tgd >= r.b_hi_min ) and (s.tgd < r.b_hi_max ) ) ;

    }
    else  % source events: filter on source tg_d region
    {
	evt_flags = (s.tgd > r.s_min) and (s.tgd <= r.s_max) ; 
    }

    tmp_flags *= 0 ; 
    for (i=0; i<length(orders); i++)
    {
	tmp_flags = tmp_flags or ( s.order == orders[i] ) ;
    }
    evt_flags = evt_flags and tmp_flags ; 

    tmp_flags *= 0 ; 
    for (i=0; i<length(tg); i++)
    {
	tmp_flags = tmp_flags or (s.tgpart == tg_part_map[tg[i]]) ; 
    }
    evt_flags = evt_flags and tmp_flags ; 

    tmp_flags *= 0 ; 
    for (i=0; i<length(wmin); i++)
    {
	tmp_flags = tmp_flags or ((s.wave>wmin[i] and s.wave<=wmax[i] ));
    }
    evt_flags = evt_flags and tmp_flags ;

    if (FILTER_STATUS == 1)
    {
	tmp_flags = (s.status == 0);
	evt_flags = evt_flags and tmp_flags ;
    }
    else
    {
	% ignore afterglow, but check for other bits...

% v1.3.9 - looks like a bug - too many bytes in the next line:
%	if ( max( (s.status & 0xFFFF0FFFF )>0) ) 
%
% According to http://space.mit.edu/ASC/docs/memo_event_status_bits_2.3.pdf
% only bit 16 is used to flag afterglow, while bits 17-19 are unused.
% Want to ignore  bits 16-19 altogether (counting from 0 at the LSb)
%
	if ( max( (s.status & 0xFFF0FFFF )>0) ) 
	{
	    vmessage("%% WARNING: non-zero event status detected.");
	    vmessage("%%   If this isn't desired, pre-filter events");
	    vmessage("%%   or, set via:  aglc_set_status_filter(1);");
	}
    }

    return evt_flags ;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
private define aglc_usage()  %{{{
{
    message("%% USAGE: lc = aglc(tgevt, expno_ref, tbin, wmin, wmax, tg, orders[, bkg]);");
    message("%% USAGE: lc = aglc(evt_struct, tbin, wmin, wmax, tg, orders[, bkg]);");
    message("%% USAGE:  2nd form: use evt_struct = aglc_read_events(tgevt, expno_ref)" );
    message("%%  tgevt grating event file (Level 1.5)");
    message("%%  expno_ref: Exposure reference, either stat1 file (most efficient) or unfiltered events.");
    message("%%  tbin = time bin length, in seconds");
    message("%%  wmin, wmax: arrays of wavelength region limits.");
    message("%%  tg: grating types array; [\"heg\",\"meg\"]; \"leg\"; \"meg\"");
    message("%%  orders: array of orders to bin");
    message("%%  bkg: if 1, then bin background region");
}
%}}}

private define aglc_phased_usage()  %{{{
{
    message("%% USAGE: pc = aglc_phased(tgevt, expno_ref, phase_info, ephem, wmin, wmax, tg, orders[, bkg]);");
    message("%% USAGE: pc = aglc_phased(evt_struct, phase_info, ephem, wmin, wmax, tg, orders[, bkg]);");
    message("%% USAGE:  2nd form: use evt_struct = aglc_read_events(tgevt, expno_ref)" );
    message("%%  tgevt: grating event file.");
    message("%%  expno_ref: stat1 or unfiltered event file.");
    message("%%  phase_info = [phase_min, phase_max, phase_bin]");
    message("%%  ephem = [hjd_phase_0, period_days]");
    message("%%  wmin, wmax: arrays of wavelength region limits.");
    message("%%  tg: grating types array; [\"heg\",\"meg\"]; \"leg\"; \"meg\"");
    message("%%  orders: array of orders to bin");
    message("%%  bkg: if 1, then bin background region");
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
private define aglc_par_check(tbin, wmin, wmax, tg, orders)  %{{{
{
    variable i;

    if ( length( where(orders==0 or orders==99) ) > 0 )
    {
        message("orders: must not include 0 or 99");
	return 0;
    }

    for (i=0; i<length(tg); i++) tg = strlow(substr(tg[i],1,1));
    if ( length(where(tg=="h" or tg=="m" or tg=="l")) == 0 )
    {
        message("tg: invalid grating part; must be \"h\", \"m\", or \"l\"");
	return 0;
    }

    % minimal check on wavelength regions
    if (
    ( min(wmin) <0 )  or
    ( min(wmax) <0 )  or
    ( min( (wmax-wmin) )<0 )  or
    ( length(wmin) != length(wmax) )
    )
    {
        message("wmin,wmax error: wavelengths<0, or wmax<wmin or different length arrays.");
	return 0;
    }

    if (tbin<0)
    {
	message("tbin: must be >0");
	return 0;
    }

    return 1;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
private define aglc_phased_par_check(phases, wmin, wmax, tg, orders)  %{{{
{
    variable i;

    if ( length( where(orders==0 or orders==99) ) > 0 )
    {
        message("orders: must not include 0 or 99");
	return 0;
    }

    for (i=0; i<length(tg); i++) tg = strlow(substr(tg[i],1,1));
    if ( length(where(tg=="h" or tg=="m" or tg=="l")) == 0 )
    {
        message("tg: invalid grating part; must be \"h\", \"m\", or \"l\"");
	return 0;
    }

    % minimal check on wavelength regions
    if (
    ( min(wmin) <0 )  or
    ( min(wmax) <0 )  or
    ( min( (wmax-wmin) )<0 )  or
    ( length(wmin) != length(wmax) )
    )
    {
        message("wmin,wmax error: wavelengths<0, or wmax<wmin or different length arrays.");
	return 0;
    }

    if (phases[0]<0.0 or
    phases[0]>1.0 or
    phases[1]<0.0 or
    phases[1]<phases[0] or
    phases[1]>1.0 or
    phases[2]<0.0 or
    phases[2]>1.0)
    {
	message("phases invalid:  phases -> phase_min, phase_max, phase_step");
	return 0;
    }

    return 1;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
private define _aglc( s, tbin, wmin, wmax, tg, orders, do_bkg )  %{{{
{
    variable i, j;

    variable evt_flags = cons_event_flags( s, do_bkg, orders, tg, wmin, wmax );

    % quick test for null selection:
    if (length(where(evt_flags)) == 0)
    {
	message("Null filter. Check selection and obs. params.");
	return 1;
    }
    
    % Determine which ccds have been selected.
    %
    %    variable ccd = where( hist1d( s.ccd_1a[ where(evt_flags)], [0:9] ) );
    % 1.3.0:
    variable ccd = where( histogram( s.ccd_1a[ where(evt_flags)], [0:9] ) );
    variable nccd = length(ccd);

    % To make sure each ccd's light curve is commensurate with the others,
    % we must define a common grid.  To avoid aliasing on the time grid,
    % the specified time bin (tbin) will be adjusted to the nearest integer
    % number of frames, of length TIMEDEL (but with effective exposure per
    % frame of TIMEDEL - 0.04104)..

    variable frames, all_frames, min_expno, max_expno, expno_grid, dexpno;

    min_expno = min( s.expno );
    max_expno = max( s.expno );
    all_frames = [ min_expno : max_expno ] ;
    dexpno = nint( tbin / s.frame_exp );
    expno_grid = [min_expno : max_expno : dexpno ] ;

    variable time_step = s.timedel * dexpno * s.READ_GRP_PER_EXPNO ;
    variable ontime_per_bin = dexpno * s.frame_exp  ;
    variable npts = length(expno_grid);

    vmessage("%% Frames per tbin = %d", dexpno );    
    vmessage("%% time_step = %0.3e", time_step);     
    vmessage("%% ontime per bin = %0.3e", ontime_per_bin );

    variable c = struct
    {
	time,
	time_min,
	time_max,
	counts,
	count_rate,
	stat_err,
	exposure,
	timezero,
	mjdref,
	revidx1a,   % reverse indices of counts histogram bins
	revidx      % reverse indices for exposure histogram bins
    }
    ;

    c.time     =   Double_Type[npts];
    c.time_min =   Double_Type[npts];
    c.time_max =   Double_Type[npts];
    c.counts   =   Integer_Type[npts];
    c.count_rate = Double_Type[npts];
    c.stat_err =   Double_Type[npts];
    c.exposure =   Double_Type[npts];
    c.timezero =   s.tstart;
    c.mjdref   =   s.mjdref;
    c.revidx1a   =   Array_Type[npts];  % one array for every counts bin
    c.revidx =       Array_Type[npts];  % one array for every exposure bin

    variable exposure, count_rate, counts ; 
    variable revidx1a, revidx ;

    % need to initialize each element of c.revidx1a to Integer_Type[0]
    %  so they can be accumulated via concatenation.    
    %
    c.revidx1a[*] = Integer_Type[0];
    c.revidx[*]   = Integer_Type[0];

    () = printf("%% Computing rates for ccd_id = ");

    for (i=0; i<nccd; i++)
    {
	() = printf("%d ", ccd[i] );
	() = fflush(stdout);

	variable lev = where( evt_flags and s.ccd_1a==ccd[i] );
	%	counts = hist1d( s.expno_1a[lev], expno_grid, &revidx1a ) ;
	% 1.3.0: use isis histogram to avoid external dependency:
	counts = histogram( s.expno_1a[lev], expno_grid,, &revidx1a ) ;
	c.counts += counts ;

	% Compute the exposure from the unfiltered (evt1) file, which has
	% bad grades, etc, and probably something in every frame:
	% To compute the exposed frames, we have to use the exposure number
	% filtered ONLY by the ccd_id:

	variable frame_count, frames_exposed, l_ccd, l_exp;
	
	l_ccd = where(s.ccd==ccd[i]) ;

	% 1.3.0:
	%	frame_count = hist1d( s.expno[ l_ccd ], all_frames ) ;
	frame_count = histogram( s.expno[ l_ccd ], all_frames ) ;

	l_exp = where( frame_count ) ;
	frames_exposed = all_frames[ l_exp ] ;

	%%DEBUG: ***  defined some globals just to save data...; kludgey.
	%LEXP=l_exp;
	%FEXP=frames_exposed;
	%FCOUNT=frame_count;
	%ALLFRAMES=all_frames;
	%LCCD=l_ccd;
	%%DEBUG: ***


	% 1.3.0:
	%	exposure = hist1d( frames_exposed, expno_grid ) * s.frame_exp;
	exposure = histogram( frames_exposed, expno_grid ) * s.frame_exp;
	c.exposure += exposure ;

	%% For exposure reverse indices, 
	%%  compute throw-away histogram of expno on desired grid.
	%%  (Most of the exposure computation is to determine *which*
	%%  frames were exposed, not how many event are in each frame.)

	% 1.3.0:
	%	() = hist1d( s.expno[ l_ccd ], expno_grid, &revidx );
	() = histogram( s.expno[ l_ccd ], expno_grid,, &revidx );

	% Accumulate the reverse indices for exposure.  Since we indexed into
	% s.expno_1a with lev, we need to un-index to get the "raw" indices
        % from the full evt1a list.  That means for each ccd, we want
	% lev[revidx[j]], where j is an index into expno_grid.

	% To concatenate over ccd index i, we can do something like
	% c.revidx1a[j] = [c.revidx1a[j], lev[revidx1a[j]]]  for all j.

	for (j=0; j<npts; j++)
	{
	    c.revidx1a[j] = [ c.revidx1a[j],  lev[ revidx1a[j] ] ] ;
	    c.revidx[j] =   [ c.revidx[j],  l_ccd[ revidx[j] ] ] ;
	}
    }

    () = printf("\n");

    c.exposure /= nccd ;         % mean exposure time
    j = where( c.exposure > 0 );
    c.count_rate[j] = c.counts[j] / c.exposure[j] ;
    c.stat_err = sqrt( c.counts );


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % v 1.3.4 - bug fix in c.time_min:      ( dph 2007.06.12)
    % v 1.3.5 -- NOT FIXED FOR CC
    % v 1.3.6 --- FIX IT: (dph 2007.07.05); cc time is *510
    %
    %
    %    c.time_min = expno_grid * s.frame_exp + s.frame_exp*s.timepixr ;
    % c.time_min = expno_grid * s.timedel   + s.frame_exp*s.timepixr ;
    %
    % v1.3.6:
    c.time_min = expno_grid * s.timedel * s.READ_GRP_PER_EXPNO + s.frame_exp*s.timepixr ;
    %
    % Inputs:
    %    min_expno = min( s.expno );
    %    max_expno = max( s.expno );
    %    all_frames = [ min_expno : max_expno ] ;
    %    s.frame_exp = s.timedel - 0.04104;
    %    dexpno = nint( tbin / s.frame_exp );
    %    expno_grid = [min_expno : max_expno : dexpno ] ;
    %     time_step = s.timedel * dexpno ;
    %    ontime_per_bin = dexpno * s.frame_exp  ;
    %
    % EXPLANATION:
    % - dexpno is nearest integer number of frames per requested tbin
    % - tbin is input by user
    % - time_step is unused except for info
    % - s.timedel is from the evt header, and is the frame time plus
    %    0.04104. (flush time)
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %    c.time_max = c.time_min + time_step ;
    %    c.time = c.time_min + time_step / 2.0 ;

#iftrue
    if (npts > 1 ) c.time_max = make_hi_grid( c.time_min ) ;
    else
    {
% 1.3.8 experimental:    2009.02.23 --- seems to work.
%	message("%% aglc-1.3.8.sl    experimental .........");
	c.time_max = c.time_min + time_step ;
    }
%
#endif
    %c.time_max = make_hi_grid( c.time_min ) ;
    c.time = ( c.time_min + c.time_max ) / 2.0 ;

    vmessage("%% min time = %f sec", c.time_min[0]);
    vmessage("%% max time = %f sec", (c.time_max[[-1:-1]])[0]);

    if (do_bkg)
    {
	variable bkg_backscale = ext_regions.bkg_backscale ;      % ***
	vmessage("%% Scaling background by 1./%f", bkg_backscale );
	c.stat_err = sqrt( c.counts ) / bkg_backscale ; 
	c.counts /= bkg_backscale ;	
	c.count_rate /= bkg_backscale ;
    }

    return c ;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
private define _aglc2(s, tbin, wmin, wmax, tg, orders, do_bkg)  %{{{
{
  % While _aglc computes the mean count rate as
  %     ( sum_{ccd} counts[ccd] ) / [ ( sum_{ccd} exposure[ccd] )/N_{ccd} ].
  % I suggest to use
  %     sum_{ccd} ( counts[ccd] / exposure[ccd] ).
  %
  % Manfred Hanke, 2010-05-17

  variable evt_flags = cons_event_flags( s, do_bkg, orders, tg, wmin, wmax );

  % quick test for null selection:
  if (length(where(evt_flags)) == 0)
  {
    message("Null filter. Check selection and obs. params.");
    return 1;
  }

  % Determine which ccds have been selected.
  variable i = where(evt_flags);
  variable ccd = where([any(s.ccd_1a[i]==0), any(s.ccd_1a[i]==1), any(s.ccd_1a[i]==2), any(s.ccd_1a[i]==3), any(s.ccd_1a[i]==4),
                        any(s.ccd_1a[i]==5), any(s.ccd_1a[i]==6), any(s.ccd_1a[i]==7), any(s.ccd_1a[i]==8), any(s.ccd_1a[i]==9)]);
  variable nccd = length(ccd);

  % To make sure each ccd's light curve is commensurate with the others,
  % we must define a common grid.  To avoid aliasing on the time grid,
  % the specified time bin (tbin) will be adjusted to the nearest integer
  % number of frames, of length TIMEDEL (but with effective exposure per
  % frame of TIMEDEL - 0.04104).
  variable min_expno = min(s.expno);
  variable max_expno = max(s.expno);
  variable all_frames = [min_expno : max_expno];
  variable dexpno = nint(tbin/(s.timedel * s.READ_GRP_PER_EXPNO));  % dexpno is nearest integer number of frames per requested tbin
  variable expno_grid = [min_expno : max_expno : dexpno];
  variable time_step = s.timedel * dexpno * s.READ_GRP_PER_EXPNO;  % time_step is unused except for info
                     % s.timedel is from the evt header, and is the frame time plus 0.04104. (flush time)
  variable npts = length(expno_grid);
  vmessage("%% Frames per tbin = %d", dexpno );
  vmessage("%% time_step = %0.3e", time_step);
  vmessage("%% ontime per bin = %0.3e", dexpno * s.frame_exp);

  variable c = struct {
      time,
      time_min = expno_grid * s.timedel * s.READ_GRP_PER_EXPNO + s.frame_exp*s.timepixr,
      time_max,
      ccd_counts = Integer_Type[10,npts],
      ccd_exposure = Double_Type[10,npts],
      counts = 0,
      count_rate = 0,
      count_rate_err = 0,
      stat_err,
      exposure = 0,
      timezero = s.tstart,
      mjdref = s.mjdref,
    };
  c.time_max = (npts>1 ? make_hi_grid(c.time_min) : c.time_min + time_step);
  c.time = 0.5*(c.time_min + c.time_max);
  vmessage("%% min time = %f sec", c.time_min[0]);
  vmessage("%% max time = %f sec", (c.time_max[[-1:-1]])[0]);

  variable skip_rev = qualifier_exists("skiprev");
  ifnot(skip_rev)
  {
    c = struct_combine(c, struct {
        revidx1a    = Array_Type[npts], % reverse indices of counts histogram bins
        revidx      = Array_Type[npts]  % reverse indices for exposure histogram bins
      });
    % need to initialize each element of c.revidx*
    % so they can be accumulated via concatenation
    c.revidx1a[*] = Integer_Type[0];
    c.revidx[*]   = Integer_Type[0];
  }

  () = printf("%% Computing rates for ccd_id = ");
  foreach ccd (ccd)
  {
    () = printf("%d ", ccd);
    () = fflush(stdout);

    variable lev = where(evt_flags and s.ccd_1a==ccd);
    variable revidx1a, counts = histogram(s.expno_1a[lev], expno_grid,, &revidx1a);
    c.ccd_counts[ccd, *] += counts;
    c.counts += counts;  % will not be used

    % Compute the exposure from the unfiltered (evt1) file, which has
    % bad grades, etc, and probably something in every frame:
    % To compute the exposed frames, we have to use the exposure number
    % filtered ONLY by the ccd_id:
    variable l_ccd = where(s.ccd==ccd);
    variable frames_exposed = all_frames[ where( histogram(s.expno[ l_ccd ], all_frames) ) ];
    variable exposure = histogram(frames_exposed, expno_grid) * s.frame_exp;

    c.ccd_exposure[ccd, *] += exposure;
    c.count_rate           += counts/exposure;  % contribution to the total count rate
    c.count_rate_err       += counts/exposure^2;  % contribution to the square of (the total count rate error = sqrt(counts)/exposure)

    ifnot(skip_rev)
    {
      % For exposure reverse indices,
      % compute throw-away histogram of expno on desired grid.
      % (Most of the exposure computation is to determine *which*
      % frames were exposed, not how many event are in each frame.)
      variable revidx;
      () = histogram(s.expno[ l_ccd ], expno_grid,, &revidx);

      % Accumulate the reverse indices for exposure.  Since we indexed into
      % s.expno_1a with lev, we need to un-index to get the "raw" indices
      % from the full evt1a list.  That means for each ccd, we want
      % lev[revidx[j]], where j is an index into expno_grid.
      variable j;
      _for j (0, npts-1, 1)
      {
	c.revidx1a[j] = [ c.revidx1a[j], lev[ revidx1a[j] ] ];
	c.revidx[j] =   [ c.revidx[j], l_ccd[ revidx[j] ] ];
      }
    }
  }
  () = printf("\n");
  c.stat_err       = sqrt(c.counts);
  c.count_rate_err = sqrt(c.count_rate_err);

  % 2010.08.04 dph  v-1.4.0:
  % self-consistent exposure, defined by  counts / rate:
  c.exposure  =  c.counts / c.count_rate ; 

  if(do_bkg)
  {
    variable bkg_backscale = ext_regions.bkg_backscale;  % ***
    vmessage("%% Scaling background by 1./%f", bkg_backscale);
    c.stat_err   /= bkg_backscale;
    c.counts     /= bkg_backscale;
    c.count_rate /= bkg_backscale;
    c.count_rate_err /= bkg_backscale;
  }
  return c;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
define aglc() % ACIS Grating Light Curve  %{{{
%!%+
%\function{aglc}
%\synopsis{Bin a light curve from ACIS grating events.}
%\usage{lc = aglc(tgevt, expno_ref, tbin, wmin, wmax, tg, orders[, bkg]);}
%\altusage{lc = aglc(   evt_struct,    tbin, wmin, wmax, tg, orders[, bkg]);}
%
%\description
%    Given an event file name (\code{tgevt}) and an exposure reference file
%    (unfiltered events or ``stat1'') name (\code{expno_ref}), bin a light curve
%    for the specified time bin in seconds (\code{tbin}), wavelength ranges
%    specified by \code{wmin}, \code{wmax}, in Angstroms.  If \code{wmin} and \code{wmax} are arrays,
%    then they must be the same length and represent low-high pairs of
%    wavelength regions.  The argument, \code{tg}, is a scalar or array of
%    grating names, and should be one or more of \code{"HEG"} and \code{"MEG"}, or \code{"LEG"}
%    (case-insensitive); only the first character is necessary.  The
%    argument \code{orders} should be an array of integers specifying the
%    diffraction orders to bin (excluding zero).  If the last argument is
%    present, then events are binned from the background region instead of
%    the source region.
%
%    In the second form, an event structure as returned by
%    \code{aglc_read_events} is used instead of two file names.  This is
%    more efficient for multiple calls, since it avoids multiple file
%    reads.
%
%    The two files required in the first form are the grating coordinates
%    event file, probably filtered of bad events; i.e., typically the file
%    from which a spectrum would be binned ("Level 1.5" or "Level 2").
%    The second file, the exposure reference file, should be unfiltered
%    events or the ``stat1'' file.  It is used to count the exposed frames
%    to determine the exposure; any event - cosmic ray, bad pixel, photon
%    - will suffice to mark a frame.  Use of the ``stat1'' file is more
%    efficient, since it has only one entry for each unique frame.
%
%    Standard binning regions are applied for source and background
%    events.   They may be changed with \code{aglc_set_regs}.
%
%    The return value is a structure of the form\n
%       \code{time = Double_Type[]}        % event time, bin center, since timezero.\n
%       \code{time_min = Double_Type[]}    % lower edge of time bin, seconds since timezero.\n
%       \code{time_max = Double_Type[]}    % upper edge of time bin, seconds since timezero.\n
%       \code{counts = UInteger_Type[]}    % counts per time bin.\n
%       \code{count_rate = Double_Type[]}  % Counts per second ( counts / exposure ).\n
%       \code{stat_err = Double_Type[]}    % Statistical error ( sqrt(counts) ).\n
%       \code{exposure = Double_Type[]}    % Exposure per bin, averaged over all chips included, in seconds.\n
%       \code{timezero = Double_Type}      % reference time, in seconds since MJDREF.\n
%       \code{mjdref = Integer_Type}       % Modified Julian Day reference point of Chandra data (from event header)\n
%       \code{revidx1a = Array_Type[]}     % reverse index array for the grating events.\n
%       \code{revidx = Array_Type[]}       % reverse index array for the exposure reference events.\n
%    The times are in seconds since timezero.  Timezero is the number of
%    seconds since 1998.0, which is also the reference MJD.
%
%    The \code{count_rate} is per second, and is equivalent to counts/exposure.
%    The exposure is computed properly for event selections spanning
%    multiple CCDs with possibly different GTI tables.
%
%    The reverse indices, \code{revidx1a}, are returned by the \code{histogram}
%    function; for each bin of the light curve they point to
%    the items in the event list which have been binned.  This facilitates
%    subsequent operations on events in specific bins, especially when
%    selected on non-time criteria. (see \code{aglc_filter}).
%
%    \code{revidx} is like \code{revidx1a}, but for the exposure record event list.
%\example
%     Compute the light curve for the sum of Ne X 12A and O VIII 19A:\n
%     \code{wlo = [12.1, 18.8];}\n
%     \code{whi = [12.2, 19.1];}\n
%     \code{g = ["H", "M"];}\n
%     \code{o = [-1,1];}\n
%     \code{c = aglc( "evt2.fits", "evt1.fits", 1000, wlo, whi, g, o );}\n
%     \code{hplot(c.time_min, c.time_max, c.counts);}
%\seealso{aglc_read_events, aglc_filter, aglc_set_regs}
%!%-
{
    %   USAGE: lc = aglc(fevt1a, fevt1, tbin, wmin, wmax, tg, orders[, bkg]);");
    %   USAGE: lc = aglc(evt_struct, tbin, wmin, wmax, tg, orders[, bkg]);");

    % 1st form: 7 or 8 args.
    % 2nd form: 6 or 7 args.

    variable args = __pop_args(_NARGS) ;

    variable s, fevt1a, fevt1, tg, orders, wmin, wmax, tbin, do_bkg=0;
    variable do_read = 0;
    variable i;

    if ( (_NARGS < 6) or (_NARGS > 8) )
    {
	aglc_usage();
	return 1;
    }

    if ( typeof(args[0].value) == Struct_Type )
    do_read = 0;
    else
    do_read = 1;

    __push_args(args);

    if ( (_NARGS == 8) or (_NARGS==7 and not do_read) )
    {  
	do_bkg = ();
	if (do_bkg > 0) ext_regions.backscale = ext_regions.bkg_backscale;
    }
    
    orders = ();

    tg = ();

    % only the 1st char of "tg" matters, as "h", "l", "m"
    tg = [tg] ;   % force to array type, if not already.
    for (i=0; i<length(tg); i++)  tg[i] = strlow(substr(tg[i],1,1));

    wmax = ();
    wmin = ();
    tbin = ();

%%%v+1.3.7+
    variable gtifile;
%%%v+1.3.7-

    if (do_read)
    {
	fevt1 = ();
	fevt1a = ();
%%%v+1.3.7+
       gtifile = qualifier ("gti", fevt1a);
%%%v+1.3.7-
    }
    else
    {
	s = ();
    }

    !if (aglc_par_check(tbin, wmin, wmax, tg, orders) )
    {
	aglc_usage();
	return 1;
    }

    %  command args OK - read file:
    if (do_read)
    {
%%%v-1.3.7	s = aglc_read_events( fevt1a, fevt1 ) ;
%%%v+1.3.7+
	s = aglc_read_events( fevt1a, fevt1, gtifile ) ;
%%%v+1.3.7-
    }

    if(qualifier_exists("aglc1"))
      return _aglc(s, tbin, wmin, wmax, tg, orders, do_bkg);
    else
      return _aglc2(s, tbin, wmin, wmax, tg, orders, do_bkg;; __qualifiers);
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%....................................................................
%....................................................................
%%%               aglc_phased: Acis Gratings Phase Curve
%....................................................................
%....................................................................

%%%%  global information:

private variable  aglc_hjd_epoch = NULL,
aglc_days_period = NULL,
sec_day = 86400.0,
d_mjd = 2400000.5; % definition of MJD = JD - d_mjd

% sometimes want a time filter when doing phase curves:
% Use units of seconds since expno=0 (t=0)
%
private variable  aglc_trange = struct {tmin, tmax};
aglc_trange.tmin = 0.0; 
aglc_trange.tmax = NULL;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Elementary time conversion functions:
%
private define aglc_set_ephem()  %{{{
{
    variable hjd, pd;

    if (_NARGS != 2)
    {
	message("USAGE:  aglc_set_ephem( HJD_zero_phase, Period_in_days )");
    }
    else
    {
	aglc_days_period = ();
	aglc_hjd_epoch = ();
    }
} %}}}

define aglc_get_ephem()  %{{{
%!%+
%\function{aglc_get_ephem}
%\synopsis{Retrieve a stored ephemeris, the last one used.}
%\usage{(jd0, pd) = aglc_get_ephem;}
%\description
%    jd0 will be the Julian day of zero phase.
%    pd  will be the period in days.
%\seealso{aglc_pr_ephem, aglc_phased}
%!%-
{
    %
    % NOTE: tests broken: cannot test NULL against 0.
    %       Use switch statement instead?               *** fix ***
    %  
    if ( aglc_hjd_epoch == NULL or
    aglc_days_period == NULL or
    aglc_hjd_epoch <=0 or
    aglc_days_period <= 0 )
    error("ERROR: Invalid ephemeris. (Not set, or bad values.)");

    return  aglc_hjd_epoch, aglc_days_period;
} %}}}

define aglc_pr_ephem()  %{{{
%!%+
%\function{aglc_pr_ephem}
%\synopsis{Print the stored ephemeris used in the last phase-curve binning.}
%\usage{aglc_pr_ephem}
%\description
%    Retrieves the ephemeris stored by aglc_phased and prints to terminal.
%\seealso{aglc_get_ephem, aglc_phased}
%!%-
{
    vmessage("Epoch[JD] = %14.6f, Period[day] = %10.6f", aglc_get_ephem );
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
define aglc_set_trange()  %{{{
%!%+
%\function{aglc_set_trange}
%\synopsis{Set a simple time range filter to be applied to a light curve
%    before extracting a phase-binned curve. This is useful for
%    excluding flares, which seem to predominantly occur at the
%    beginning or end of an observation.}
%\usage{aglc_set_trange( tmin, tmax );}
%\description
%    \code{tmin, tmax} are relative times in seconds, since the start of the
%    observation.  The interval specifies the times of interest to be included
%    in phase binning. \code{tmax==NULL} means to the end of the observation.
%\example
%    \code{aglc_set_trange( 0, 2000 );   %} first 2ks will be included in phase binning.\n
%     \code{aglc_set_trange( 5000, NULL);  %} from 5ks to the end will be selected.
%\seealso{aglc_get_trange, aglc_pr_trange}
%!%-
{
    if (_NARGS != 2)
    {
	message("USAGE:  aglc_set_trange( tmin, tmax )");
	message("     tmin,tmax in relative (elapsed) time [sec].");
    }
    else
    {
	aglc_trange.tmax = ();
	aglc_trange.tmin = ();
    }
} %}}}

define aglc_get_trange()  %{{{
%!%+
%\function{aglc_get_trange}
%\synopsis{Retrieve the time filter which will be applied in phase-binning.}
%\usage{(tmin, tmax) = aglc_get_trange;}
%\description
%    tmin,tmax are relative times in seconds, since the start of the
%    observation.
%\seealso{aglc_set_trange, aglc_pr_trange;}
%!%-
{
    if (aglc_trange.tmax == NULL)
    {
	if ( aglc_trange.tmin <0)
	error("ERROR: Invalid tmin. NULL tmax (unfiltered)");
    }
    else
    {
	if ( (aglc_trange.tmin < 0) or
	(aglc_trange.tmin > aglc_trange.tmax) or
	(aglc_trange.tmax < 0) )
	error("ERROR: Invalid trange.");
    }
    return  aglc_trange.tmin, aglc_trange.tmax ;
} %}}}

define aglc_pr_trange()  %{{{
%!%+
%\function{aglc_pr_trange}
%\synopsis{Print to the terminal the current time filter.}
%\usage{aglc_pr_trange;}
%\description
%    Prints the min and max time filter used in binning phase curves.
%\seealso{aglc_set_trange, aglc_get_trange;}
%!%-
{
    vmessage("tmin = %S, tmax = %S [sec since timezero]", aglc_get_trange );
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define aglc_tobs_to_jd()  %{{{
%!%+
%\function{aglc_tobs_to_jd}
%\synopsis{Convert Chandra obervation times, given in seconds since MJDREF, to Julian day.}
%\usage{jd = aglc_tobs_to_jd( t_obs, mjdref );}
%\description
%    \code{t_obs} is a scalar or array of Chandra times in seconds since \code{mjdref}.
%    \code{mjdref} is the Modified Julian Day reference, found in Chandra
%    headers, or in the aglc event structure.
%\seealso{aglc_jd_to_rotnum, aglc_jd_to_phase, aglc_tobs_to_phase, aglc_read_events}
%!%-
{
    % Convert Chandra t_obs = seconds since mjdref to JD. (NOT MJD!!!)
    % Chandra uses Modified Julian Day reference.
    % MJDREF can be found in and event file header (or from aglc_read_events)

    variable t_obs, mjdref;

    if (_NARGS !=2 )
    {
	message("USAGE:  jd = aglc_tobs_to_jd( t_obs, mjdref );");
	return -1;
    }
    mjdref = ();
    t_obs = ();
    
    return  (t_obs / sec_day) + mjdref + d_mjd ;
} %}}}

%define agpc_expno_to_time( expno, timedel, tstart )   %% **** changed....
private define aglc_expno_to_time( expno, frametime, timepixr, tstart )  %{{{
{
    % convert (approximately) the exposure number to time in seconds
    %   since mjdref (chandra's definition of time).
    % This is approximate because only one tstart is used for all
    % CCDs.  EXPNO is simply scaled by the TIMEDEL value.
    % timezero is the time of the first frame.
    % NOTE: this is not the same as the exposure time! TIMEDEL is the 
    %       time between successive frame reads, nominally 3.24104 seconds,
    %       of which 0.04104 is for frame-shift.  But TIMEDEL could be shorter.
    % NOTE: aglc_read_events returns a structure containing
    %        timedel and timezero, as well as mjdref, timepixr

    %    return expno * timedel + tstart ;    %**
    % v0.11 - use frametime = s.frame_exp, not timedel (for cc)    
    return expno * frametime + frametime*timepixr + tstart ; 
} %}}}

%%% **** fix; isn't tstart needed in the inverse?      ***** FIX???
%define agpc_time_to_expno( t, timedel )
% v0.11 - not timedel, but frametime = s.frame_exp
private define aglc_time_to_expno( t, frametime, timepixr )  %{{{
{
    % convert (approximately) the RELATIVE time (elapsed) in sec  to
    % approx expno.

    %    return int( t / timedel ) ; 
    return int( (t-frametime*timepixr) / frametime ) ; 
} %}}}

%%% v0.11 change from timedel to frametime...
private define aglc_get_expno_filt_range( expno, frametime, timepixr )  %{{{
{
    % given the expno array and the timedel, retrieve the stored
    % time filter min,max, and compute equivalent expno limits.
    % If time is outside the expno range, use the expno limit.

    variable expno_filt_min, expno_filt_max;
    variable tmin, tmax ;
    (tmin, tmax) = aglc_get_trange;

    if (tmax == NULL)
    {
	expno_filt_max = max(expno);
    }
    else
    {
	expno_filt_max = min( [ [aglc_time_to_expno( tmax, frametime, timepixr )],
	[max(expno)] ] );
    }

    if (tmin <= 0.0 )
    {
	expno_filt_min = min(expno);
    }
    else
    {
	expno_filt_min = max( [ [aglc_time_to_expno( tmin, frametime,timepixr )],
	[min(expno)] ] ) ;
    }

    return expno_filt_min, expno_filt_max ;
} %}}}


define aglc_jd_to_rotnum()  %{{{
%!%+
%\function{aglc_jd_to_rotnum}
%\synopsis{Convert Julian days to rotation number.}
%\usage{rotation_number = aglc_jd_to_rotnum( t_jd, hjd_epoch, period_days );}
%\description
%     \code{rotation_number} = number of full cycles plus fractional phase, given an ephemeris.\n
%     \code{t_jd}        = times, in Julian day numbers.\n
%     \code{hjd_epoch}   = epoch of zero-phase, in HJD\n
%     \code{period_days} = period, in days.
%\seealso{aglc_tobs_to_jd, aglc_jd_to_phase, aglc_tobs_to_phase, aglc_phased, aglc}
%!%-
{
    %   t_jd is julian day
    %   nrot = ((t / sec_day + mjdref + dmjd) - T_conj_HJD ) / P_day;

    variable t_jd, hjd_epoch, days_period;

    if ( _NARGS != 3 )
    {
	message("USAGE:  rotation_number = aglc_jd_to_rotnum( t_jd, hjd_epoch, period_days );");
	return -1;
    }

    days_period=();
    hjd_epoch = ();
    t_jd = ();

    return ( ( t_jd - hjd_epoch ) / days_period ) ;
} %}}}


define aglc_jd_to_phase()  %{{{
%!%-
%\function{aglc_jd_to_phase}
%\synopsis{Convert a list of times to phase, given an ephemeris.}
%\usage{phase = aglc_jd_to_phase( t_jd, hjd_epoch, days_period );}
%\description
%    phase       = rotation_number modulo 1;
%                  fractional phase, given an ephemeris.
%
%    t_jd        = times, in Julian day numbers.
%    hjd_epoch   = epoch of zero-phase, in HJD
%    period_days = period, in days.
%
%    This can be useful for plotting multple cycles without binning on
%    phase.
%
%    This is functionally equivalent to  aglc_jd_to_rotnum() mod 1.
%\seealso{aglc_jd_to_rotnum, aglc_tobs_to_phase, aglc, aglc_phased}
%!%-
{
    variable  t_jd, hjd_epoch, days_period ;

    %   % t is cxo evt time:
    %   nrot = ((t / sec_day + mjdref + dmjd) - T_conj_HJD ) / P_day;
    %   phi =  nrot mod 1.0;

    if (_NARGS != 3 )
    {
	message("USAGE:  phase = aglc_jd_to_phase(t_jd, hjd_epoch, days_period);");
	return -1;
    }

    days_period = ();
    hjd_epoch = ();
    t_jd = ();

    return aglc_jd_to_rotnum( t_jd, hjd_epoch, days_period) mod 1.0 ; 
} %}}}

%define agpc_expno_to_phase( expno, timedel, tstart, mjdref )
% v0.11 *** FIX - not timedel, but frametime...
%
private define aglc_expno_to_phase( expno, frametime, timepixr, tstart, mjdref )  %{{{
{
    % put conversion functions together;
    %  (could use the structure,
    %   s = aglc_read_events(f1a, f1);
    % which has time reference info, but leave explicit here)

    variable t = aglc_expno_to_time( expno, frametime, timepixr, tstart );
    variable jd = aglc_tobs_to_jd( t, mjdref );
    variable jd0, pd;

    (jd0, pd) = aglc_get_ephem();

    variable phi = aglc_jd_to_phase( jd, jd0, pd ) ;
    if (min(phi)<0)
    {
	variable l = where(phi<0);
	phi[l] =  1.0 + phi[l];
    }
    
    return phi;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% v0.17 - added ephem to interface
%
define aglc_tobs_to_phase()  %{{{
%!%-
%\function{aglc_tobs_to_phase}
%\synopsis{Convert Chandra observation times to phase, given an ephemeris.}
%\usage{phase = aglc_tobs_to_phase( tobs, mjdref, ephem );}
%\description
%    phase  =  phase for given times and stored ephemeris.
%    tobs   =  observed times, in seconds since mjdref
%    mjdref =  Reference MJD (from Chandra header or aglc event  structure)
%    ephem  =  Two-element array specifying ephemeris.
%              ephem[0] = Epoch JD of phase 0.00.
%              ephem[1] = Period in days.
%\seealso{aglc_jd_to_rotnum, aglc_jd_to_phase, aglc_tobs_to_jd,  aglc_read_events, aglc, aglc_phased}
%!%-
{
    variable  tobs, mjdref, ephem ;

    if (_NARGS != 3 )
    {
	message("USAGE: phase = aglc_tobs_to_phase( tobs, mjdref, ephem[] );");
	return -1;
    }
    
    ephem  = () ;   % two element array, jd0, pd_days
    mjdref = ();
    tobs = ();
    
    variable jd = aglc_tobs_to_jd( tobs, mjdref );
    variable jd0, pd;
    %    (jd0, pd) = aglc_get_ephem();  % v0.17 (I should use cvs...)
    jd0 = ephem[0];               % v0.17
    pd  = ephem[1];               % v0.17
    aglc_set_ephem( jd0, pd ) ;   % v0.17 for future ref only.

    return aglc_jd_to_phase( jd, jd0, pd ) ; 
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Elementary time conversions can now be used in phase-curve binning
%  functions.  Copy aglc() and _aglc(), and convert expno-grid binning to
%  phase-grid binning.
%
private define _aglc_phased( s, phases, wmin, wmax, tg, orders, do_bkg )  %{{{
{
    variable i, j;
    variable evt_flags = cons_event_flags( s, do_bkg, orders, tg, wmin, wmax );

    variable phase_min = phases[0],
    phase_max = phases[1],
    dphase    = phases[2],
    tbin;

    % quick test for null selection:
    if (length(where(evt_flags)) == 0)
    {
	message("Null filter. Check selection and obs. params.");
	return 1;
    }
    
    % Determine which ccds have been selected.
    %
    % 1.3.0:
    %    variable ccd = where( hist1d( s.ccd_1a[ where(evt_flags)], [0:9] ) );
    variable ccd = where( histogram( s.ccd_1a[ where(evt_flags)],   [0:9] ) ); %%%***
    variable nccd = length(ccd);

    % To make sure each ccd's light curve is commensurate with the others,
    % we must define a common grid.  To avoid aliasing on the time grid,
    % the specified time bin (tbin) will be adjusted to the nearest integer
    % number of frames, of length TIMEDEL (but with effective exposure per
    % frame of TIMEDEL - 0.04104)..

    variable frames, all_frames, min_expno, max_expno, dexpno;
    variable phase_grid;
    variable jd0, period;
    variable tfilt_min, tfilt_max, min_expno_tfilt, max_expno_tfilt ;  % if a time-filter given

    (jd0, period) = aglc_get_ephem();

    %    (min_expno_tfilt, max_expno_tfilt) =
    %           agpc_get_expno_filt_range( s.expno, s.timedel );
    % v0.11 *** change..........
    (min_expno_tfilt, max_expno_tfilt) =
        aglc_get_expno_filt_range( s.expno, s.frame_exp, s.timepixr );

    %    min_expno = min( s.expno );
    %    max_expno = max( s.expno );

    % Constrain min,max by possible time filter:
    % (These are already constrained to the range of s.expno
    %   by agpc_get_expno_filt_range().)
    %
    min_expno = min_expno_tfilt;
    max_expno = max_expno_tfilt;

    all_frames = [ min_expno : max_expno ] ;


    %%% *** fix *** don't use dexpno. but should adjust dphase to integral expno.
    tbin = dphase * period * sec_day ;

%%%
%%% 2007.07.05 *** BROKEN FOR CC-mode if dexpno < 1
%%%

    dexpno = nint( tbin / s.frame_exp );  % integral # frames per tbin.

    % trial adjustment for cc-mode, short bins:  *** TEST 1.3.6
    if ( dexpno < 1 )     dexpno = ( tbin / s.frame_exp );

    % convert integral number back to dphase:
    dphase = dexpno * s.frame_exp / period / sec_day ; 

    phase_grid = [ phase_min : phase_max : dphase ] ;

    vmessage("%% Frames per phase bin = %S",    dexpno );    
    vmessage( "%% Phase bin adjusted to %10.4f", dphase );


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% *** Slang-2 dependency on indexing?  ***

    variable phase_grid_hi = NULL ;

    if ( ( _slang_version / 10000) == 1 )
    {
	phase_grid_hi = [ phase_grid[[1:-1]], phase_grid[[-1:-1]]+dphase];%***v0.11
    }
    else
    {
	phase_grid_hi = [ phase_grid[[1:]], ( phase_grid[[-1:-1]]) + dphase ]; % v1.2.2/slang2
    }
    %%% ***

    variable npts = length( phase_grid );

    %%%+ 2004.05.22....
    if ( phase_grid_hi[npts-1] > 1.0 )   % truncate if max(phi) > 1
    {
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%% *** Slang-2 dependency on indexing?  ***
	if ( (_slang_version /10000) == 1 )
	{
	    phase_grid    = phase_grid[ [0:-2] ];
	    phase_grid_hi = phase_grid_hi[ [0:-2] ];
	}
	else
	{
	    phase_grid    = phase_grid[ [:-2] ];
	    phase_grid_hi = phase_grid_hi[ [:-2] ];
	}
	%%% ***
	npts -= 1;
    }
    %%%- 2004.05.22....
    
    %%% 2004.06.30 --- add ephemeris fields to struct:

    variable c = struct   %%% ***
    {
	phase,
	phase_min,
	phase_max,
	counts,
	count_rate,
	stat_err,
	exposure,
	mjdref, 
	revidx1a,        % for evt1a
	revidx,           % for all frames
	epoch,           % JD of phase=0.000
	period           % period in days.
    }
    ;

    c.phase      = Double_Type[npts];
    c.phase_min  = Double_Type[npts];
    c.phase_max  = Double_Type[npts];
    c.counts     = Integer_Type[npts];
    c.count_rate = Double_Type[npts];
    c.stat_err   = Double_Type[npts];
    c.exposure   = Double_Type[npts];
    c.mjdref     = s.mjdref ; 
    c.revidx1a   = Array_Type[npts];  % one array for every counts bin
    c.revidx     = Array_Type[npts];  % one array for every exposure bin
    c.epoch      = jd0;               
    c.period     = period;

    variable exposure, count_rate, counts ; 
    variable revidx1a, revidx;

    % need to initialize each element of c.revidx1a to Integer_Type[0]
    %  so they can be accumulated via concatenation.    
    %
    c.revidx1a[*] = Integer_Type[0] ;
    c.revidx[*]   = Integer_Type[0] ;

    () = printf("%% Computing rates for ccd_id = ");
    for (i=0; i<nccd; i++)
    {
	() = printf("%d ", ccd[i] );
	() = fflush(stdout);

	% constrain selection by any time-filter:
	%
	variable lev = where( evt_flags
	and (s.ccd_1a==ccd[i])
	and (s.expno_1a >= min_expno)
	and (s.expno_1a <= max_expno) );

	%---------------------------------------------------------------------
	if (length(lev)==0) %%% should do something else here ***** FIX
	{
	    vmessage("WARNING: Null selection on cdd=%d. Check the trange filter.", ccd[i]);
	    continue;
	}
	%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	% dither is necessary to anti-alias the expno grid transformation to phase grid.
	%
	variable dither_frames = urand(length(lev)) ;

	%%% v0.11 *** changed call.......................
	%%% v0.14 **** changed back - need to test for case of filtered phase grid.
	% 1.3.0:
	% 	counts = hist1d(
	% 	   aglc_expno_to_phase( s.expno_1a[lev]+dither_frames,
	% 	                        s.frame_exp,
	% 	                        s.timepixr,
	% 	                        s.tstart,
	% 	                        s.mjdref
	% 	                      ),
	% 	                      phase_grid,
	% %	                      phase_grid_hi,   % *** v0.11
	% 	                      &revidx1a ) ; 

	% v 1.3.6: (dph 2007.07.05) FIX for CC; time is timedel*510

%%% ***
	counts = histogram(
            aglc_expno_to_phase( s.expno_1a[lev]+dither_frames,
	%	s.frame_exp,  % v 1.3.5: CHANGE TO TIMEDEL????
%		s.timedel,    %%% 1.3.5 IS THIS CORRECT??? what about elsewhere???
		s.timedel * s.READ_GRP_PER_EXPNO,    %%% 1.3.6 CHECK
		s.timepixr,
		s.tstart,
		s.mjdref
		),
		phase_grid,,
		%	                      phase_grid_hi,   % *** v0.11
		&revidx1a ) ; 
	c.counts += counts ; 

	% Compute the exposure from the unfiltered (evt1) file, which has
	% bad grades, etc, and probably something in every frame:
	% To compute the exposed frames, we have to use the exposure number
	% filtered ONLY by the ccd_id:

	variable frame_count, frames_exposed, lexp, l_ccd;

	l_ccd = where(s.ccd==ccd[i]) ;
	% 1.3.0:
	%	frame_count = hist1d( s.expno[ l_ccd ], all_frames ) ;
	frame_count = histogram( s.expno[ l_ccd ], all_frames ) ;

	lexp = where( frame_count );
	frames_exposed = all_frames[ lexp ] ;

	dither_frames = urand(length(frames_exposed)) ;

	%%% v0.11 *** changed call...............................
	%%% v0.14 *** changed back - need to check in detail...
	% 1.3.0:
	% 	exposure = hist1d(
	% 	  aglc_expno_to_phase( frames_exposed+dither_frames,
	% 	                       s.frame_exp,
	% 	                       s.timepixr,
	% 	                       s.tstart,
	% 	                       s.mjdref
	% 	                     ),
	% 	                      phase_grid,
	% %	                      phase_grid_hi         % v0.11 ***
	%                              ) * s.frame_exp;
%%% ***
	exposure = histogram(
	   aglc_expno_to_phase( frames_exposed+dither_frames,
	   s.frame_exp,
	   s.timepixr,
	   s.tstart,
	   s.mjdref
	   ),
	   phase_grid,,
	   %	                      phase_grid_hi         % v0.11 ***
	   ) * s.frame_exp;
	c.exposure += exposure ;

	%% For exposure reverse indices, 
	%%  compute throw-away histogram of expno on desired grid.
	%%  (Most of the exposure computation is to determine *which*
	%%  frames were exposed, not how many event are in each frame.)

	%%% v0.11 *** changed.....................................
	%%%%v0.14 *** changed back --- need to test.
	% 1.3.0:
	% 	() = hist1d(
	% 	     aglc_expno_to_phase( s.expno[ l_ccd ],
	% 	                          s.frame_exp,
	% 	                          s.timepixr,
	% 	                          s.tstart,
	% 	                          s.mjdref
	% 	                         ),
	% 	                         phase_grid,
	% %	                         phase_grid_hi,  % *** v0.11
	%                                  &revidx );
	() = histogram(	aglc_expno_to_phase( s.expno[ l_ccd ],
	s.frame_exp,
	s.timepixr,
	s.tstart,
	s.mjdref
	),
	phase_grid,,
	%	                         phase_grid_hi,  % *** v0.11
	&revidx );

	% Accumulate the reverse indices for counts 
	% Since we indexed into counts w/ lev,
	% un-index to get the "raw" indices
	% from the full lists.  That means for each ccd, we want
	% lev[revidx[j]], where j is an index into expno_grid.

	% To concatenate over ccd index i, we can do something like
	% c.revidx1a[j] = [c.revidx1a[j], lev[revidx1a[j]]]  for all j.

	for (j=0; j<npts; j++)
	{
	    c.revidx1a[j] = [ c.revidx1a[j],    lev[ revidx1a[j] ] ];
	    c.revidx[j] =   [   c.revidx[j],  l_ccd[ revidx[j] ] ];
	}
    }  
    %----------------- for (i=0; i<nccd; i++)
    () = printf("\n");
    
    c.exposure /= nccd ;         % mean exposure time   %%% ***
    j = where( c.exposure > 0 );
    c.count_rate[j] = c.counts[j] / c.exposure[j] ;     %%% ***
    c.stat_err = sqrt( c.counts );

%%% *** rate error

    c.phase_min = phase_grid ;
    c.phase_max = c.phase_min + dphase ;
    c.phase = c.phase_min + dphase / 2.0 ;

    if (do_bkg)
    {
	variable bkg_backscale = ext_regions.bkg_backscale ; % ***
	vmessage("%% Scaling background by 1./%f", bkg_backscale );
	c.stat_err = sqrt( c.counts ) / bkg_backscale ; 
	c.counts /= bkg_backscale ;	
	c.count_rate /= bkg_backscale ;
    }

    return c ;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%% ***** 1020.08.04  dph
% make changes to fix the rate and exposure computation for multiple
% chips w/ different dropped frames.  Follow Manfred's changes to
% _aglc() in _aglc2().
%
private define _aglc_phased2( s, phases, wmin, wmax, tg, orders, do_bkg )  %{{{
{
    variable j;
    variable evt_flags = cons_event_flags( s, do_bkg, orders, tg, wmin, wmax );

    variable
      phase_min = phases[0],
      phase_max = phases[1],
      dphase    = phases[2],
      tbin;

    % quick test for null selection:
    if (length(where(evt_flags)) == 0)
    {
	message("Null filter. Check selection and obs. params.");
	return 1;
    }
    
    % Determine which ccds have been selected.
    %
    % 1.3.0:
    %    variable ccd = where( hist1d( s.ccd_1a[ where(evt_flags)], [0:9] ) );
    variable i = where( evt_flags );
    variable ccd = where([any(s.ccd_1a[i]==0), any(s.ccd_1a[i]==1), any(s.ccd_1a[i]==2), any(s.ccd_1a[i]==3), any(s.ccd_1a[i]==4),
                        any(s.ccd_1a[i]==5), any(s.ccd_1a[i]==6), any(s.ccd_1a[i]==7), any(s.ccd_1a[i]==8), any(s.ccd_1a[i]==9)]);
    variable nccd = length( ccd );

    % To make sure each ccd's light curve is commensurate with the
    % others, we must define a common grid.  To avoid aliasing on the
    % time grid, the specified time bin (tbin) will be adjusted to the
    % nearest integer number of frames, of length TIMEDEL (but with
    % effective exposure per frame of TIMEDEL - 0.04104)..

    variable frames, all_frames, min_expno, max_expno, dexpno;
    variable phase_grid;
    variable jd0, period;
    variable tfilt_min, tfilt_max, min_expno_tfilt, max_expno_tfilt ;  % if a time-filter given

    (jd0, period) = aglc_get_ephem();

    %    (min_expno_tfilt, max_expno_tfilt) =
    %           agpc_get_expno_filt_range( s.expno, s.timedel );
    % v0.11 *** change..........
    (min_expno_tfilt, max_expno_tfilt) =
        aglc_get_expno_filt_range( s.expno, s.frame_exp, s.timepixr );

    %    min_expno = min( s.expno );
    %    max_expno = max( s.expno );

    % Constrain min,max by possible time filter:
    % (These are already constrained to the range of s.expno
    %   by agpc_get_expno_filt_range().)
    %
    min_expno = min_expno_tfilt;
    max_expno = max_expno_tfilt;
    all_frames = [ min_expno : max_expno ] ;

    %%% *** fix *** don't use dexpno. but should adjust dphase to integral expno.
    tbin = dphase * period * sec_day ;

%%%
%%% 2007.07.05 *** BROKEN FOR CC-mode if dexpno < 1
%%%

    dexpno = nint( tbin / s.frame_exp );  % integral # frames per tbin.

    % trial adjustment for cc-mode, short bins:  *** TEST 1.3.6
    if ( dexpno < 1 )     dexpno = ( tbin / s.frame_exp );

    % convert integral number back to dphase:
    dphase = dexpno * s.frame_exp / period / sec_day ; 

    phase_grid = [ phase_min : phase_max : dphase ] ;

    vmessage("%% Frames per phase bin = %S",    dexpno );    
    vmessage( "%% Phase bin adjusted to %10.4f", dphase );

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% *** Slang-2 dependency on indexing?  ***

    variable phase_grid_hi = NULL ;

    if ( ( _slang_version / 10000) == 1 )
    {
	phase_grid_hi = [ phase_grid[[1:-1]], phase_grid[[-1:-1]]+dphase];%***v0.11
    }
    else
    {
	phase_grid_hi = [ phase_grid[[1:]],  phase_grid[-1] + dphase ]; % v1.2.2/slang2
    }
    %%% ***

    variable npts = length( phase_grid );

    %%%+ 2004.05.22....
    if ( phase_grid_hi[npts-1] > 1.0 )   % truncate if max(phi) > 1
    {
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%% *** Slang-2 dependency on indexing?  ***
	if ( (_slang_version /10000) == 1 )
	{
	    phase_grid    = phase_grid[ [0:-2] ];
	    phase_grid_hi = phase_grid_hi[ [0:-2] ];
	}
	else
	{
	    phase_grid    = phase_grid[ [:-2] ];
	    phase_grid_hi = phase_grid_hi[ [:-2] ];
	}
	%%% ***
	npts -= 1;
    }
    %%%- 2004.05.22....
    
    %%% 2004.06.30 --- add ephemeris fields to struct:

    variable c = struct   %%% ***
    {
	phase          = Double_Type[npts], 
	phase_min      = Double_Type[npts],
	phase_max      = Double_Type[npts],
	ccd_counts     = Integer_Type[10,npts],
	ccd_exposure   = Double_Type[10,npts],
	counts         = Integer_Type[ npts ],
	count_rate     = Double_Type[npts],
	stat_err       = Double_Type[npts],
	count_rate_err = Double_Type[npts],
	exposure       = Double_Type[npts],
	mjdref         = s.mjdref, 
	revidx1a       = Array_Type[npts],    % for evt1a
	revidx         = Array_Type[npts],    % for all frames
	epoch          = jd0,                 % JD of phase = 0.000
	period         = period               % period in days.
    }
    ;

    variable exposure, count_rate, counts ; 
    variable revidx1a, revidx;

    % need to initialize each element of c.revidx1a to Integer_Type[0]
    %  so they can be accumulated via concatenation.    
    %
    c.revidx1a[*] = Integer_Type[0] ;
    c.revidx[*]   = Integer_Type[0] ;

    () = printf("%% Computing rates for ccd_id = ");
    for (i=0; i<nccd; i++)
    {
	() = printf("%d ", ccd[i] );
	() = fflush(stdout);

	% constrain selection by any time-filter:
	%
	variable lev = where( evt_flags
  	           and ( s.ccd_1a==ccd[i])
	           and ( s.expno_1a >= min_expno)
	           and ( s.expno_1a <= max_expno) );

	%---------------------------------------------------------------------
	if (length(lev)==0) %%% should do something else here ***** FIX
	{
	    vmessage("WARNING: Null selection on cdd=%d. Check the trange filter.", ccd[i]);
	    continue;
	}
	%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	% dither is necessary to anti-alias the expno grid transformation to phase grid.
	%
	variable dither_frames = urand( length( lev ) ) ;

	%%% v0.11 *** changed call.......................
	%%% v0.14 **** changed back - need to test for case of filtered phase grid.
	% 1.3.0:
	% 	counts = hist1d(
	% 	   aglc_expno_to_phase( s.expno_1a[lev]+dither_frames,
	% 	                        s.frame_exp,
	% 	                        s.timepixr,
	% 	                        s.tstart,
	% 	                        s.mjdref
	% 	                      ),
	% 	                      phase_grid,
	% %	                      phase_grid_hi,   % *** v0.11
	% 	                      &revidx1a ) ; 

	% v 1.3.6: (dph 2007.07.05) FIX for CC; time is timedel*510

%%% ***
	counts = histogram(
            aglc_expno_to_phase( s.expno_1a[ lev ] + dither_frames,
	%	s.frame_exp,  % v 1.3.5: CHANGE TO TIMEDEL????
%		s.timedel,    %%% 1.3.5 IS THIS CORRECT??? what about elsewhere???
		s.timedel * s.READ_GRP_PER_EXPNO,    %%% 1.3.6 CHECK
		s.timepixr,
		s.tstart,
		s.mjdref
		),
%		phase_grid,,
		phase_grid, phase_grid_hi,
		%	                      phase_grid_hi,   % *** v0.11
		&revidx1a ) ; 

	c.counts += counts ;
	c.ccd_counts[ ccd[i], * ] += counts ; 

	% Compute the exposure from the unfiltered (evt1) file, which has
	% bad grades, etc, and probably something in every frame:
	% To compute the exposed frames, we have to use the exposure number
	% filtered ONLY by the ccd_id:

	variable frame_count, frames_exposed, lexp, l_ccd;

	l_ccd = where(s.ccd==ccd[i]) ;
	% 1.3.0:
	%	frame_count = hist1d( s.expno[ l_ccd ], all_frames ) ;

	frame_count = histogram( s.expno[ l_ccd ], all_frames ) ;
	lexp = where( frame_count );
	frames_exposed = all_frames[ lexp ] ;
	dither_frames = urand(length(frames_exposed)) ;

	%%% v0.11 *** changed call...............................
	%%% v0.14 *** changed back - need to check in detail...
	% 1.3.0:
	% 	exposure = hist1d(
	% 	  aglc_expno_to_phase( frames_exposed+dither_frames,
	% 	                       s.frame_exp,
	% 	                       s.timepixr,
	% 	                       s.tstart,
	% 	                       s.mjdref
	% 	                     ),
	% 	                      phase_grid,
	% %	                      phase_grid_hi         % v0.11 ***
	%                              ) * s.frame_exp;
%%% ***
	exposure = histogram(
	   aglc_expno_to_phase( frames_exposed + dither_frames,
%	   s.frame_exp,
	   s.timedel * s.READ_GRP_PER_EXPNO,    %%% 1.5.0 *** CHECK
	   s.timepixr,
	   s.tstart,
	   s.mjdref
	   ),
%	   phase_grid,,
	   phase_grid, phase_grid_hi,
	   %	                      phase_grid_hi         % v0.11 ***
	   ) * s.frame_exp;

	c.exposure += exposure ;  %%% *** will be overwritten; as is, is WEIGHTED and may not make sense.
	c.ccd_exposure[ ccd[i], * ] += exposure ; 

	c.count_rate     += counts / exposure;   % contribution to the total count rate
	c.count_rate_err += counts / exposure^2; % contribution to the square of (the total count rate error = sqrt(counts)/exposure)

	%% For exposure reverse indices, 
	%%  compute throw-away histogram of expno on desired grid.
	%%  (Most of the exposure computation is to determine *which*
	%%  frames were exposed, not how many event are in each frame.)

	%%% v0.11 *** changed.....................................
	%%%%v0.14 *** changed back --- need to test.
	% 1.3.0:
	% 	() = hist1d(
	% 	     aglc_expno_to_phase( s.expno[ l_ccd ],
	% 	                          s.frame_exp,
	% 	                          s.timepixr,
	% 	                          s.tstart,
	% 	                          s.mjdref
	% 	                         ),
	% 	                         phase_grid,
	% %	                         phase_grid_hi,  % *** v0.11
	%                                  &revidx );
	() = histogram(	aglc_expno_to_phase( s.expno[ l_ccd ],
	s.frame_exp,
	s.timepixr,
	s.tstart,
	s.mjdref
	),
%	phase_grid,,
	phase_grid, phase_grid_hi,
	%	                         phase_grid_hi,  % *** v0.11
	&revidx );

	% Accumulate the reverse indices for counts 
	% Since we indexed into counts w/ lev,
	% un-index to get the "raw" indices
	% from the full lists.  That means for each ccd, we want
	% lev[revidx[j]], where j is an index into expno_grid.

	% To concatenate over ccd index i, we can do something like
	% c.revidx1a[j] = [c.revidx1a[j], lev[revidx1a[j]]]  for all j.

	for (j=0; j<npts; j++)
	{
	    c.revidx1a[j] = [ c.revidx1a[j],    lev[ revidx1a[j] ] ];
	    c.revidx[j] =   [   c.revidx[j],  l_ccd[ revidx[j] ] ];
	}
    }  
    %----------------- for (i=0; i<nccd; i++)
    () = printf("\n");
    
    c.exposure /= nccd ;         % mean exposure time  (w/ possibly bad weighting) %%% ***

    c.stat_err       = sqrt( c.counts ) ;
    c.count_rate_err = sqrt( c.count_rate_err ) ; 
    c.exposure       = c.counts  / c.count_rate ; 

%%% *** rate error

    c.phase_min = phase_grid ;
    c.phase_max = c.phase_min + dphase ;
    c.phase     = c.phase_min + dphase / 2.0 ;

    if (do_bkg)
    {
	variable bkg_backscale = ext_regions.bkg_backscale ; % ***
	vmessage("%% Scaling background by 1./%f", bkg_backscale );
	c.counts     /= bkg_backscale ;	
	c.stat_err   /= bkg_backscale ; 
	c.count_rate /= bkg_backscale ;
	c.count_rate_err /= bkg_backscale ; 
    }

    return c ;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% v0.17 explicitly add ephem to interface
% 
define aglc_phased()  % ACIS Grating Phase Curve  %{{{
%!%+
%\function{aglc_phased}
%\synopsis{Bin a phased light curve.}
%\usage{pc = aglc_phased(tgevt, expno_ref, phase_info, ephem, wmin, wmax, tg, orders[, bkg]);
%\altusage{pc = aglc_phased(   evt_struct   , phase_info, ephem, wmin, wmax, tg, orders[, bkg]);}
%}
%\description
%    Arguments are similar to those in \code{aglc}, with the exception of
%    \code{phase_info} and \code{ephem}.  For other arguments, see \code{aglc}.
%
%    \code{phase_info}  = a 3-element array giving the phase minimum, maximum,
%                  and bin size desired for the resultant phased light
%                  curve.
%    \code{ephem} = a two-element array giving the JD of zero phase (NOT MJD!)
%            and the period in days.
% 
%    Definitions for Phase Curve Structure Fields
%    The phase curve fields are the same as for the light curve, with the exception
%    of phase replacing time and the addition of the ephemeris. The new fields are:\n
%    1. \code{phase}: Value of phase at the bin center.\n
%    2. \code{phase_min}: Value of phase at the low edge of the bin.\n
%    3. \code{phase_max}: Value of phase at the high edge of the bin.\n
%    4. \code{epoch}: Epoch of the ephemeris, in Julian Days (NOT MJD!).\n
%    5. period: Period of the ephemeris, in days.
%\seealso{aglc, aglc_filter, aglc_read_events}
%!%-
{
    %   USAGE: ephem = [ jd0, period_days ];
    %   USAGE: bin_info = [phase_min, phase_max, step];
    %   USAGE: c = aglc_phased(fevt1a, fevt1, bin_info, ephem, wmin, wmax, tg, orders[, bkg]);");
    %   USAGE: c = aglc_phased(evt_struct,    bin_info, ephem, wmin, wmax, tg, orders[, bkg]);");

    % 1st form: 8 or 9 args.
    % 2nd form: 7 or 8 args.

    variable args = __pop_args(_NARGS) ;

    variable s, fevt1a, fevt1, tg, orders, wmin, wmax, phases, ephem, do_bkg=0;
    variable do_read = 0;
    variable i;

    if ( (_NARGS < 7) or (_NARGS > 9) )
    {
	aglc_phased_usage;
	return -1;
    }

    if ( typeof(args[0].value) == Struct_Type )
    do_read = 0;
    else
    do_read = 1;

    __push_args(args);


    if ( (_NARGS == 9) or (_NARGS==8 and not do_read) )
    {  
	do_bkg = ();
	%	if (do_bkg > 0) backscale = bkg_backscale;    % ***
	if (do_bkg > 0) ext_regions.backscale = ext_regions.bkg_backscale;
    }
    
    orders = ();

    tg = ();

    % only the 1st char of "tg" matters, as "h", "l", "m"
    tg = [tg] ;   % force to array type, if not already.
    for (i=0; i<length(tg); i++)  tg[i] = strlow(substr(tg[i],1,1));

    wmax = ();
    wmin = ();
    ephem = () ; 

    if (length(ephem) !=2)
    {
	usage;
	return -1;
    }

    aglc_set_ephem( ephem[0], ephem[1] ) ;  % store in static vars.

    phases = ();

    if (length(phases) !=3)
    {
	usage;
	return -1;
    }

    if (do_read)
    {
	fevt1 = ();
	fevt1a = ();
    }
    else
    {
	s = ();
    }

    !if (aglc_phased_par_check(phases, wmin, wmax, tg, orders) )
    {
	usage;
	return -1;
    }

    %  command args OK - read file:

    if (do_read)
    s = aglc_read_events( fevt1a, fevt1 ) ;

    if( qualifier_exists("aglc1") )
      return _aglc_phased( s, phases, wmin, wmax, tg, orders, do_bkg );
    else
      return _aglc_phased2( s, phases, wmin, wmax, tg, orders, do_bkg;; __qualifiers );
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% take a 1D reverse index array, and create a single vector of indices.
%%   NOTE: this only works for the specific case of all the Array_Type[k]
%%   being the same type, namely, Integer_Type.
%%   
%
private define reform_revidx( rev )  %{{{
{
    % Example:   if c is the return value from aglc, then
    %            a = reform_revidx( c.revidx );
    %    will result in "a" being a 1D list of all the elements indexed
    %    by revidx.  This can be useful because then c.wave[a] will be the
    %    subset list of wavelengths of events binned into the light curve
    %    

    variable i;
    variable a = Integer_Type[0];

    for (i=0; i<length(rev); i++)	a = [a, rev[ i ] ] ;

    return a ;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Given an array of time bin indices, use the reverse indices in the 
%  light or phase curve structure to filter events in the event structure,
%  ev_struct.  
%  Returns a new event structure, which can then be processed w/ aglc or aglc_phased
%  to make new light or phase curves.
%
%  NOTE: One should only use the full curve data to filter, 
%        not already filtered structures, since all info is not in the 
%        filtered result.
%
define aglc_filter()  %{{{
%\function{aglc_filter}
%\synopsis{Apply a time or phase filter specified to the event structures.}
%\usage{s = aglc_filter( c_struct, ev_struct, c_bin_list );}
%\description
%    Given an index list, c_bin_list, derived from a light or phase
%    curve histogram, use the reverse histogram indices in the curve
%    structure, c_struct, and filter the events to include only the
%    events binned into the index list.  Return a new event structure,
%    s, suitable for input to aglc() or aglc_phased().
%
%    The input c_struct is as returned by aglc() or aglc_phased().  The reverse
%    indices are saved by the histogram functions and keep lists of all
%    indices contributing to a bin value.
%
%    The input ev_struct is an event structure as returned by
%    aglc_read_events().
%\example
%   s = aglc_read_events( fevt_1a, fevt );
%   ephem = [ 2452506.4328, 0.27831149 ] ;
%   p = aglc_phased( s, [0.0, 1.0, 0.02], ephem, 1.7, 25, ["H","M"], [-1,1] );
%   % Select events from a phase range and filter:
%   s_new = aglc_filter( p, s, where(p.phase_min > 0.5) );
%\seealso{aglc_read_events, aglc, aglc_phased}
%!%-
{
    if (_NARGS != 3 )
    {
	()=printf("\nUSAGE:  s = aglc_filter( c_struct, ev_struct, c_bin_list );");
	()=printf("\n   Apply a time or phase filter specified by the time or phase");
	()=printf("\n    bin list, c_bin_list, to the event structure, ev_struct, ");
	()=printf("\n    using reverse histogram indices in c_struct.");
	()=printf("\n   Return a new event structure, s, suitable for input to");
	()=printf("\n    aglc() or aglc_phased().");
	()=printf("\n\nNOTE: c_struct can be as returned by aglc() or aglc_phased().");
	()=printf("\n\nEXAMPLE: ");
	()=printf("\n  s = aglc_read_events( fevt_1a, fevt );");
	()=printf("\n  ephem = [ 2452506.4328,0.27831149 ] ;"); % v0.17
	()=printf("\n  p = aglc_phased( s, [0.0, 1.0, 0.02], ephem, 1.7, 25, [\"H\",\"M\"], [-1,1] );");
	()=printf("\n  s_new = aglc_filter( p, s, where(p.phase_min > 0.5) );\n");

	return -1;
    }

    variable time_bin_indices = ();
    variable ev_struct = ();
    variable lc_struct = ();

    variable l, l_1a, s ;

    if ( length( time_bin_indices ) == 1 )  % need to force to vector.
    time_bin_indices = [time_bin_indices];

    l_1a = reform_revidx( lc_struct.revidx1a[ time_bin_indices ] ) ;
    l    = reform_revidx( lc_struct.revidx[   time_bin_indices ] );

    s = @ev_struct;

    s.expno    = s.expno[ l ];
    s.expno_1a = s.expno_1a[ l_1a ] ;
    s.ccd      = s.ccd[ l ];
    s.ccd_1a   = s.ccd_1a[ l_1a ];
    s.tgpart   = s.tgpart[ l_1a ];
    s.order    = s.order[ l_1a ];
    s.tgd      = s.tgd[ l_1a ];
    s.wave     = s.wave[ l_1a ];
    s.status   = s.status[ l_1a ];

    return s;
} %}}}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%
%%%%  provide functions to write rudimentary FITS files.
%%%%%   Partially CXC-compliant, in extension keywords.
%%%%%   NULL primary only has required header keywords.
%
% Function Courtesy of John Houck:
% (http://space.mit.edu/CXC/ISIS/examples/ex_write_bintable.sl)
%
% This function summarizes the basics of writing a FITS bintable with
% a single HDU
%
private define write_bintable (filename, extname, data_struct, keyword_struct, history)  %{{{
{
    variable fp = fits_open_file (filename, "c");
    if (fp == NULL)
    {
	vmessage ("Failed to create file %s", filename);
	return -1;
    }

    fits_write_binary_table (fp, extname, data_struct, keyword_struct);
    () = _fits_write_history (fp, history);

    fp = NULL;
    return 0;
} %}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
define aglc_write_curve()  % ( fout, f_ref_hdr, c[, history ] )  %{{{
%!%+
%\function{aglc_write_curve}
%\synopsis{Write a light or phase curve to a FITS bintable file}
%\usage{aglc_write_curve( outfile, hdr_ref_file, curve_struct [, history_string ] );" );}
%\description
%    \code{outfile} = name of output file ( \code{String_Type}).\n
%    \code{hdr_ref_file} =  Reference file for copying of header info ( \code{String_Type}).\n
%    \code{curve_struct} =  The light or phase curve structure, as created by \code{aglc} or  \code{aglc_phased}.\n
%    \code{history_string} = arbitrary note (\code{String_Type}).
%\seealso{aglc, aglc_phased}
%!%-
{
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % fout = String_Type, output file name
    %
    % f_hdr_ref = String_Type, grating event file name, for header info.
    %     (Can use event struct fevt_1a field:   s.fevt_1a )
    %
    % c = Struct_Type, and is the output of aglc() or aglc_phased().
    %
    % history = String_Type  arbitrary history, notes, comment string.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if (_NARGS < 3 )
    {
	message("");
	message("%% Write a light or phase curve to a FITS bintable file.");
	message( "%% USAGE: aglc_write_curve( outfile, hdr_ref_file, curve_struct [, history_string ] );" );
	message("%%    outfile: String_Type; name of output file.");
	message("%%    hdr_ref_file: Reference file for copy of header info.");
	message("%%    curve_struct:  light curve structure, as created by aglc() or aglc_phased().");
	message("%%    history_string: string field to record arbitrary note.");
	message("");
	return ; 
    }

    variable fout, f_ref_hdr, c, history ;
    history = "aglc_write_curve";            % default note.
    if (_NARGS == 4 ) history = ();
    c = ();
    f_ref_hdr = ();
    fout = ();

    % define header fields:
    %
    variable hdr =  struct {
	date,
	creator,
	mission,
	telescop,
	instrume,
	detnam,
	grating,
	content,
	extname,
	hduname,
	hduclass,
	hduclas1,
	object,
	obs_id,
	exposure,
	mjdref,
	timezero,
	aglc_epoch,
	aglc_period,
	backscal
    }
    ;
    
    variable extname, ctmp ;

    % define output structure conditionally on type of curve:
    %
    if ( struct_field_exists( c, "phase" ) )
    {
	extname = "PHASECURVE" ;
	hdr.extname  = extname ; 
	hdr.aglc_epoch    = c.epoch ;
	hdr.aglc_period   = c.period ;
	hdr.timezero = 0 ;
	
	ctmp = struct
	{
	    phase,
	    phase_min,
	    phase_max,
	    counts,
	    count_rate,
	    stat_err,
	    error,
	    exposure
	}
	;
	
	ctmp.phase     = c.phase ;
	ctmp.phase_min = c.phase_min ;
	ctmp.phase_max = c.phase_max ;	
    }
    else
    {
	extname      = "LIGHTCURVE" ;
	hdr.extname  = extname ; 
	hdr.aglc_epoch    = -1 ;
	hdr.aglc_period   = -1 ;
	hdr.timezero = c.timezero ;

	ctmp = struct	{
	    time,
	    time_min,
	    time_max,
	    counts,
	    count_rate,
	    stat_err,
	    error,
	    exposure
	}
	;
	
	ctmp.time     = c.time ;
	ctmp.time_min = c.time_min ;
	ctmp.time_max = c.time_max ;
    }

    % Copy remaining structure fields to output structure: 

    %    ctmp.counts     = c.counts ;
    ctmp.counts     = int( c.counts ) ;  % 1.3.1, to please cfitsio.
    ctmp.count_rate = c.count_rate ;
    ctmp.error      = c.count_rate_err ; 
    ctmp.stat_err   = c.stat_err ;
    ctmp.exposure   = c.exposure ;

    % Fill in header fields from curve structure or reference file header:

    hdr.hduname  = extname ;
    hdr.content  = extname ; 
    hdr.hduclass = "OGIP" ;
    hdr.hduclas1 = extname ;

%    hdr.exposure = sum( c.exposure ) ;
    hdr.exposure = sum( c.exposure[where(not isnan(c.exposure))] ) ;   % *** 
    hdr.mjdref   = c.mjdref ;
    hdr.object   = fits_read_key ( f_ref_hdr, "object" );
    hdr.obs_id   = fits_read_key ( f_ref_hdr, "obs_id" );

    hdr.mission  = fits_read_key ( f_ref_hdr, "mission" );
    hdr.telescop = fits_read_key ( f_ref_hdr, "telescop" );
    hdr.instrume = fits_read_key ( f_ref_hdr, "instrume" );
    hdr.detnam   = fits_read_key ( f_ref_hdr, "detnam" );
    hdr.grating  = fits_read_key ( f_ref_hdr, "grating" );

    hdr.creator = sprintf("aglc-%s", aglc_version_string );

    % 2008.04.12
    hdr.backscal = 1.0 ;  % by definition. IF background, also scaled.

    % construct the DATE created string
    %
    variable t = localtime( _time ) ; 
    hdr.date = sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
    t.tm_year + 1900,
    t.tm_mon + 1,
    t.tm_mday, 
    t.tm_hour,
    t.tm_min,
    t.tm_sec )
    ;

    % output:
    () = write_bintable (fout, extname, ctmp, hdr, history);
} %}}}




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
provide("aglc"); 

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%vmessage("%% aglc version %s loaded.", aglc_version_string);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

%%%% EXPERIMENTAL CODE %%%%


define aglc_truncate_events( s, l )  %{{{
{
    variable k = get_struct_field_names( s ) ;
    variable n = length( s.wave ) ;

    foreach ( k )
    {
	variable f = () ; 
	variable x = get_struct_field ( s, f ) ;
	if ( length( x ) == n )  set_struct_field( s, f,  x[ l ] ) ;
    }
} %}}}

define aglc_truncate_wave( s, wlo, whi )  %{{{
{
    variable i ;
    variable n = length( wlo ) ;

    variable l = Integer_Type[ length( s.wave ) ] ; 
    l *= 0 ; 

    for ( i=0; i<n; i++ )
    l = l or ( (s.wave > wlo[i]) and (s.wave <= whi[i] ) );

    aglc_truncate_events( s, where(l) ) ; 
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%; File: garf_gaps.sl
%; Author: D. Huenemoerder
%; Original version: 2004.07.19
%;====================================================================
% version 1.1 - 2004.12.17 - rob found bug... 
%
% version 1  - 2004.12.17 mod for ciao 3.2
% version: 0.2
%
% purpose: return wavelength regions in acis chip gaps, given an arf and order.
%
% method: use the fracexpo column, which is <1 if in a gap or near edge.
%         use the TG_M keyword to scale to desired order, for given
%         grating, and sign of order from header.

private define garf_gaps_usage()  %{{{
{
    message("");
    message("%% Struct_Type = garf_gaps( f_arf[, order_desired] );" ) ;
    message("");
    message("%% Given a grating arf file name, f_arf, return arrays of low and high");
    message("%%  wavelengths marking regions dithered into gaps.");
    message("%%  If order_desired is not specified, order is taken from the arf header.");
    message("%%  Restrictions: Due to geometric constraints, order_desired is");
    message("%%    forced to have the same sign as the arf header's order (TG_M).");
    message("");
} %}}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define garf_gaps()  % (f_arf, tg_m_desired)  %{{{
{
    variable f_arf = NULL;
    variable tg_m_desired = NULL ;
    variable r = struct{ low, high, type } ; 

    variable EPS = 0.003;   % some numerical noise in FRACEXPO;

    switch (_NARGS)

    {
	case 0:
	garf_gaps_usage;
	return NULL ; 
    }
    {
	case 1:
	f_arf = () ;
    }
    {
	case 2:
	tg_m_desired = () ;
	f_arf = () ;
    }
    {
	garf_gaps_usage;
	return NULL ; 
    }

    variable fexp, wlo, whi, tgm, l ; 

    (fexp, wlo, whi) = fits_read_col( f_arf, "FRACEXPO", "BIN_LO", "BIN_HI" ) ;

    % use ascending order arrays:
    wlo = reverse(wlo);
    whi = reverse(whi);
    fexp = reverse(fexp);

    tgm =  fits_read_key( f_arf, "TG_M" ) ;
    if ( tg_m_desired == NULL )  tg_m_desired = tgm ;

    % scale wavelengths to desired order: 
    wlo = wlo * abs( tgm / tg_m_desired ) ; 
    whi = whi * abs( tgm / tg_m_desired ) ; 

    % find the min and max indices of the regions...
    l =  fexp < (1.0-EPS) ;    % array l = 1 in the gaps. Find starts and stops.

    % differential: dl = -1 in bin before gap starts. +1 in last of gap.
    %               Edge effect: never(?) starts in a gap.
    %          2004.12.17: WRONG. Rob has one. Is bug.
    %                            always(?) ends in a gap (chip edge).    
    %
    % Complication: bad pixels create regions where FRACEXPO<1.
    %               Need to find chunks where FRACEXPO<1 and min(region)<0.6.
    %
    %    For MEG, the chip gaps make high-low > 0.6
    %    For HEG,                             > 0.3
    %              (but so can badpix in either case)

    if (l[0] == 1 ) l[0] = 0 ; %%% hack edge effect - starting in gap.

    variable dl;
    dl = l - shift(l,1);
    r.low  = wlo[ where( dl == -1 ) + 1 ] ;
    r.high = whi[ where( dl == 1 ) ] ;

    %
    % try to classify regions based on depth:
    %
    r.type = Integer_Type[ length( r.low ) ] ;
    variable i ;

    for ( i=0; i<length(r.low); i++ )
    {
	variable ll ;
	ll = where ( (wlo >= r.low[i])  and  (whi <= r.high[i] ) ) ; 

	if ( min( fexp[ll] ) < 0.5 )
	{
	    r.type[i] = 1 ;
	}
	else
	{
	    r.type[i] = 0 ;
	}
    }
    
    return r ;
} %}}}


define pr_garf_gaps( r )  %{{{
{
    variable i ;
    variable typ = ["badpix", "gap"];

    () = printf("%2s %8s %8s %8s %s\n",
    "n", "wmin", "wmax", "dw", "type" );

    for (i=0; i<length(r.low); i++)
    {
	() = printf("");
	() = printf("%2d %8.3f %8.3f %8.3f %s\n",
	i, r.low[i], r.high[i], r.high[i]-r.low[i], typ[r.type[i]] ) ;
	() = printf("");
    }
} %}}}

define plt_garf_gaps( r, typ, yra, sty, col ) %{{{
{
    % overplot styled rectangle at gap and bpix ranges.
    % r is a structure as returned by garf_gaps
    % typ is the type of gap to draw: "gap" or "badpix"
    % yra is array giving ymin, ymax of box to plot
    % sty is a pgplot fill style (1-4);
    % col is a pgplot color index

    variable styp = ["badpix", "gap"] ;

    variable l = where( styp[ r.type ] == typ ) ;

    if ( length(l) == 0 ) error("%% plt_garf_gaps: Bad type.");

    _pgsfs( sty ) ;
    _pgsci( col ) ; 

    variable i ;
    for (i=0; i<length(l); i++)
    {
	variable n = l[ i ] ; 
	_pgrect( r.low[ n ], r.high[ n ], yra[0], yra[1] );
    }
} %}}}

provide("garf_gaps");
provide("pr_garf_gaps");


%use it via:
%
% s = aglc_read_events( evt1a, evt0 ) ; 
% g = garf_gaps ( garf ) ;  % external; finds chip gaps low, high wavelengths.
% aglc_truncate_events( s, g.low, g.high ) ; % remove gaps from events.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
