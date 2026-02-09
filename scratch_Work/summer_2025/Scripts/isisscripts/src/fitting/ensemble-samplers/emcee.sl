% -*- mode: slang; mode: fold; -*- %

require("rand");
require("fork");
require("socket");
require("gsl", "gsl");
%require("select");

% Implementation of the emcee hammer (Foreman-Mackey 2013) with
% the principle idea that multiple nodes (engines) are responsible
% for a part of the walkers. For efficiency the walkers are
% distributed equally to each engine. To keep the statistical
% properties the walkers are seperated in to two groups (see ref)
% where the next step of group one depends on the current position
% of group two and the next step of group two depends on the new
% position of group one. For most efficiency we try to reduce the
% required computations to the minimum possible such that the model
% evaluation plus the necessary communication is everything that
% happens in the main loop.
% 
% To prevent any side effects from the PRNG we let the master
% calculate enough for each step and distribute them to the
% slaves.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

private variable EmceeInitRegister = Assoc_Type[Ref_Type, &NULL];
private variable EmceeStepRegister = Assoc_Type[Ref_Type, &NULL];
private variable EmceeFileRegister = Assoc_Type[Ref_Type, &NULL];
private variable EmceeShipRegister = Assoc_Type[Ref_Type, &NULL];
private variable EmceeProgressRegister = Assoc_Type[Ref_Type, &NULL];

% Engine and Leader %{{{

private variable EmceeEngine = struct {
  % engine numbers
  id, % engine id (master is 0)
  numberEngines, % total number of engines
  numberSteps, % total number of steps

  % arrays and length
  walkers, % walker array for this engine (master has all)
  pivots, % pivot array for this engine (master has all)
  rolls, % random numbers required (master has all)
  update, % update indicator array (master has all)
  stat, % statistic array (master has all)
  totalNumberWalkers, % total number of walkers
  totalNumberSet1, % total number of walkers in set 1
  totalNumberSet2, % total number of walkers in set 2

  % per engine walkers
  numberWalkers, % number of walkers this engine handles
  numberWalkersSet1, % number of walkers this engine handles in set 1
  numberWalkersSet2, % number of walkers this engine handles in set 2

  % selected set
  setOffset, % current set offset (for access in walker array)
  setLength, % current set length

  % fit
  fit, % fit object
  numberParameters, % number of (free) parameters

  gears = NULL, % step, random generators
  leader = NULL, % write buffers etc.
};

private variable EmceeLeader = struct {
  walkersPerSet1, % number of walkers for each engine id in set 1
  walkersPerSet2, % number of walkers for each engine id in set 2
  walkersPerSet, % selected set walkers
  totalOffset, % start of set in walker array
  writeBuffer, % total write buffer array
  inFile, % input file handle
  outFile, % output file handle
  progress, % progress handle
};

private variable EmceeGears = struct {
  upick, % function
  urand, % function

  step, % step interface
};

private define emceeDrawSet (engine, set) %{{{
{
  variable urand = engine.gears.urand;
  variable upick = engine.gears.upick;

  variable totalNumberSet,
    totalNumberComplement,
    totalOffset;

  if (1 == set) {
    totalNumberSet = engine.totalNumberSet1;
    totalNumberComplement = engine.totalNumberSet2;
    engine.setOffset = 0;
    engine.setLength = engine.numberWalkersSet1;
    totalOffset = 0;
    if (0 == engine.id) {
      engine.leader.totalOffset = totalOffset;
      engine.leader.walkersPerSet = engine.leader.walkersPerSet1;
    }
  } else if (2 == set) {
    totalNumberSet = engine.totalNumberSet2;
    totalNumberComplement = engine.totalNumberSet1;
    engine.setOffset = engine.numberWalkersSet1;
    engine.setLength = engine.numberWalkersSet2;
    totalOffset = engine.totalNumberSet1;
    if (0 == engine.id) {
      engine.leader.totalOffset = totalOffset;
      engine.leader.walkersPerSet = engine.leader.walkersPerSet2;
      engine.setOffset = totalOffset;
    }
  }

  % master picks new pivots & randoms
  if (0 == engine.id) {
    variable pick = @upick(0, totalNumberComplement-1, totalNumberSet)+totalOffset;
    variable i;
    _for i (0, totalNumberSet-1)
      engine.pivots[i+totalOffset] = @(engine.walkers[pick[i]]);

    variable numberRandoms = engine.gears.step.numberRandoms;
    engine.rolls[[0:totalNumberSet*numberRandoms-1]+totalOffset*numberRandoms]
      = @urand(totalNumberSet*numberRandoms);
  }
}
%}}}

private define emceeSetupGears (engine, urand, upick, step) %{{{
{
  variable gears = struct { @EmceeGears };
  gears.urand = urand;
  gears.upick = upick;
  gears.step = step;

  % here we can set the rolls
  engine.rolls = Double_Type[length(engine.walkers)*step.numberRandoms];

  engine.gears = gears;
}
%}}}

private define emceeSetupWriteBuffer (leader, numberWalkers, numberSteps) %{{{
{
  % buffer size should ideally be as large as the write routine wants
  % but is limited by the maximum array size and must be at least
  % as large as one iteration requires
  variable size = min([[leader.outFile.cycle, numberSteps]*numberWalkers, INT_MAX-(INT_MAX mod numberWalkers)]);
  variable writeBuffer = struct {
    size = size,
    cycle = size/numberWalkers,
    walkers = Array_Type[size],
    update = Double_Type[size],
    stat = Double_Type[size],
  };

  variable i;
  _for i (0, size-1)
    writeBuffer.walkers[i] = Double_Type[num_free_params()];

  leader.writeBuffer = writeBuffer;
}
%}}}

private define emceeSetupLeader (engine, inFile, outFile, progress) %{{{
{
  if (0 == engine.id) {
    variable nEngines = engine.numberEngines;
    variable id;
    variable leader = @EmceeLeader;
    leader.walkersPerSet1 = Int_Type[nEngines];
    leader.walkersPerSet2 = Int_Type[nEngines];
    leader.inFile = inFile;
    leader.outFile = outFile;
    leader.progress = progress;

    emceeSetupWriteBuffer(leader, engine.totalNumberWalkers, engine.numberSteps);

    variable set1 = engine.totalNumberSet1;
    variable set2 = engine.totalNumberSet2;

    _for id (0, engine.numberEngines-1) {
      leader.walkersPerSet1[id] = set1/nEngines + ((set1 mod nEngines) > (nEngines-id-1));
      leader.walkersPerSet2[id] = set2/nEngines + ((set2 mod nEngines) > (nEngines-id-1));
    }

    engine.leader = leader;
  }
}
%}}}

private define emceeSetupEngine (ship, totalNumberWalkers, totalSteps) %{{{
{
  variable engine = @EmceeEngine;
  ship.engine = engine;

  variable set1 = totalNumberWalkers/2;
  variable set2 = totalNumberWalkers - set1;
  engine.totalNumberSet1 = set1;
  engine.totalNumberSet2 = set2;
  engine.totalNumberWalkers = totalNumberWalkers;
  engine.numberSteps = totalSteps;

  % set sail (get number of engines and set id)
  ship.setSail();

  % divide walkers evenly (remainders are given to highest ids)
  engine.numberWalkersSet1 = set1/engine.numberEngines
    + ((set1 mod engine.numberEngines) > (engine.numberEngines-engine.id-1));
  engine.numberWalkersSet2 = set2/engine.numberEngines
    + ((set2 mod engine.numberEngines) > (engine.numberEngines-engine.id-1));
  engine.numberWalkers = engine.numberWalkersSet1 + engine.numberWalkersSet2;
  engine.numberParameters = num_free_params();
  engine.fit = open_fit();

  % master stores all values
  variable size = engine.id ? engine.numberWalkers : totalNumberWalkers;

  engine.walkers = Array_Type[size];
  engine.pivots  = Array_Type[size];
  % rolls can only be set up after step is known
  % engine.rolls   = Double_Type[size*engine.gears.step.numberRandoms];
  engine.update  = Int_Type[size];
  engine.stat    = Double_Type[size] + DOUBLE_MAX;

  variable j;
  _for j (0, size-1) {
    engine.walkers[j] = Double_Type[engine.numberParameters];
    engine.pivots[j] = Double_Type[engine.numberParameters];
  }
}
%}}}
%}}}

%{{{ File interface:
%!%+
%\function{emcee--file}
%\synopsis{Set emcee file input and output methods}
%\usage{input="method;options"
%  \altusage{output="method;options"}}
%\description
%  The file input/output methods can be set with the function string
%    "method;parameter"
%
%  Available methods:
%  fits : Fits file interface to write the chain as fits table extension
%    ; filename  : [emcee-<date>.fits] The input/output file name.
%    ; parameter : If given, on read we draw new starting positions from the
%                  parameter settings stored in the file instead of reading
%                  the last iterations.
%
%  mike : Fits file interface (compatible to previous emcee routine)
%    ; filename  : [emcee-<date>.fits] The input/output file name.
%    ; parameter : if given, on read we draw new starting position from the
%                  header
%    ; cycle     : [=50] the number of steps to calculate before writing to
%                  file
%
%  par  : Parameter file interface to draw initial walkers from parameter
%         files.
%    ; filename : [emcee-<data>.fits] Multiple parameter files can be separated
%                 by a semi colon with an optional additional multiplier
%                 (separated by a colon). A string of the form
%                 'file1.par:2;file2.par' means that 2/3 of all walkers are
%                 drawn from file1.par and 1/3 is drawn from file2.par.
%!%-
%      1: create - open new file pointer and write necessary intial values
%      2: open - open existing file for read/write
%      3: read - open file and return n walkers and how many walkers were used
%      4: write - write cycle steps to the file (n)
%      5: close - close open file at end
private variable EMCEE_FILE_READ = 0x1, EMCEE_FILE_WRITE=0x2, EMCEE_FILE_RANGE = 0x4;
private variable EmceeFile = struct {
  create, % function
  open, % function
  read, % function
  write, % function
  close, % function

  mode = 0, % 1 read, 2 write, 4 range bit (read parameter range instead of position)
  has = 0,  % same as mode, but lists all available (if FILE_RANGE is given it means it is the prevered method)
  handle, % file handle
  filename, % full file name
  cycle, % number of steps before file gets written

  % additional private data
};

%{{{ Fits file functions

% Create function %{{{
private define __emceeFitsWriteT1(handle, engine) %{{{
{
  variable dataInfo;
  list_data(&dataInfo);

  variable par = __parameters(engine.fit.object);
  variable params = get_params();
  variable numberTotalParams = length(params);

  %variable parNames = array_map(String_Type, &get_struct_field, get_params(), "name")[par.index-1];

%  fits_create_binary_table(handle, "PARAMETERS", num_free_params(),
%			   ["FREE_PAR", "FREE_PAR_NAME"],
%			   ["J", sprintf("%dA", max(array_map(Int_Type, &strlen, parNames)))],
%			   [" parameter indices", " parameter names"]);
  variable paramsTable = struct {
    name=String_Type[numberTotalParams],
    index=Int_Type[numberTotalParams],
    value=Double_Type[numberTotalParams],
    min=Double_Type[numberTotalParams],
    max=Double_Type[numberTotalParams],
    hard_min=Double_Type[numberTotalParams],
    hard_max=Double_Type[numberTotalParams],
    freeze=Int_Type[numberTotalParams],
    tie=String_Type[numberTotalParams],
    units=String_Type[numberTotalParams],
    fun=String_Type[numberTotalParams],
    free=Int_Type[numberTotalParams], % combines freeze, fun and tie
  };
  variable j;
  _for j (0, numberTotalParams-1) {
    paramsTable.name[j] = params[j].name;
    paramsTable.index[j] = params[j].index;
    paramsTable.value[j] = params[j].value;
    paramsTable.min[j] = params[j].min;
    paramsTable.max[j] = params[j].max;
    paramsTable.hard_min[j] = params[j].hard_min;
    paramsTable.hard_max[j] = params[j].hard_max;
    paramsTable.freeze[j] = params[j].freeze;
    paramsTable.tie[j] = (params[j].tie == NULL) ? "" : params[j].tie;
    paramsTable.units[j] = params[j].units;
    paramsTable.fun[j] = (params[j].fun == NULL) ? "" : params[j].fun;
    paramsTable.free[j] = (not params[j].freeze) and (params[j].fun == NULL) and (params[j].tie == NULL);
  }
  fits_write_binary_table(handle, "PARAMETERS", paramsTable);

  fits_update_key(handle, "MODEL", get_fit_fun(), "model function");
  fits_update_key(handle, "STATISTIC", get_fit_statistic(), " latest fit statistic");
  fits_update_key(handle, "SLOPPY", 0, " sloppy level");

  array_map(&fits_write_comment, handle, strchop(dataInfo, '\n', 0));

  % sort to index order here
%  if (_fits_write_col(handle, fits_get_colnum(handle, "FREE_PAR"), 1, 1, par.index[array_sort(par.index)])
%      && _fits_write_col(handle, fits_get_colnum(handle, "FREE_PAR_NAME"), 1, 1, parNames))
%    throw IOError;
}
%}}}

private define __emceeFitsWriteT2(handle, engine) %{{{
{
  variable par = __parameters(engine.fit.object);

  fits_create_binary_table(handle, "MCMCCHAIN", 0,
			   ["FITSTAT", "UPDATE", array_map(String_Type, &sprintf, "CHAINS%d", par.index)],
			   ["D", "J", ["D"][par.index*0]],
			   [" fit statistics", " update indicator", [" parameter values"][par.index*0]]);
  fits_update_key(handle, "NWALKERS", engine.totalNumberWalkers/engine.numberParameters, " Number of walkers per free parameter");
  fits_update_key(handle, "NFREEPAR", engine.numberParameters, " Number of free parameters");
  fits_update_key(handle, "NSTEPS", engine.numberSteps, " Numer of iteration steps done");
}
%}}}

private define __emceeFitsWriteT3(handle, engine) %{{{
{
  fits_create_binary_table(handle, "CHAINSTATS", 0,
			   ["FRAC_UPDATE", "MIN_STAT", "MED_STAT", "MAX_STAT"], ["D", "D", "D", "D"],
			   [" fraction", [sprintf(" %s", get_fit_statistic)][[0:2]*0]]);
  fits_update_key(handle, "STATISTIC", get_fit_statistic(), " fit statistic");
}
%}}}

private define emceeFileFitsCreate (file, engine) %{{{
{
  file.mode |= EMCEE_FILE_WRITE;
  file.mode &= ~EMCEE_FILE_READ;

  % Create fits file and write headers
  file.handle = fits_open_file(file.filename, "c");

  % write first table
  __emceeFitsWriteT1(file.handle, engine);

  % write second table
  __emceeFitsWriteT2(file.handle, engine);

  % write third table
  %__emceeFitsWriteT3(file.handle, engine);

  % move back to chain table
  () = _fits_movnam_hdu(file.handle, _FITS_BINARY_TBL, "MCMCCHAIN", 0);

  % set write cycle
  () = _fits_get_rowsize(file.handle, &(file.cycle));
  file.cycle = file.cycle/engine.totalNumberWalkers;
  if (file.cycle < 1)
    file.cycle = 1;

  % fits routine customs
  file.numberSteps = 0;
  file.sloppy = 0;
}
%}}}
%}}}

% Open function %{{{

private define __emceeFitsReadChecks (file, engine) %{{{
{
  variable handle = file.handle;
  if (_fits_movnam_hdu(handle, _FITS_BINARY_TBL, "PARAMETERS", 0)) {
    fits_close_file(handle);
    handle = NULL;
    throw IOError, "Not a emcee chain file";
  }

  if (fits_read_key(handle, "MODEL") != get_fit_fun()) {
    fits_close_file(handle);
    handle = NULL;
    throw IsisError, "Current model and chain model do not match";
  }

  variable tab = fits_read_table(handle);
  ifnot (struct_field_exists(tab, "free")
	|| struct_field_exists(tab, "value")) {
    fits_close_file(handle);
    handle = NULL;
    throw IOError, "Not a emcee chain file";
  }

  variable par = __parameters(engine.fit.object);
  if ((length(where(tab.free)) != num_free_params())
      || any(tab.index[where(tab.free)] != par.index[array_sort(par.index)])) {
    fits_close_file(handle);
    handle = NULL;
    throw UsageError, "Free parameters and chain parameters differ";
  }
}
%}}}

private define __emceeFitsWriteChecks (file, engine) %{{{
{
  variable handle = file.handle;
  if (_fits_movnam_hdu(handle, _FITS_BINARY_TBL, "PARAMETERS", 0)) {
    fits_close_file(handle);
    handle = NULL;
    throw IOError, "Not a emcee chain file";
  }

  if ((fits_read_key(handle, "STATISTIC") != get_fit_statistic()) && (file.sloppy<2)) {
    fits_close_file(handle);
    handle = NULL;
    throw UsageError, "Current fit statistic and chain fit statistic differ, increase sloppy level (at least 2) to continue anyway";
  }
  fits_update_key(handle, "STATISTIC", get_fit_statistic());

  if (_fits_movnam_hdu(handle, _FITS_BINARY_TBL, "MCMCCHAIN", 0)) {
    fits_close_file(handle);
    handle = NULL;
    throw IOError, "Not a emcee chain file";
  }

  if ((fits_read_key(handle, "NWALKERS")*fits_read_key(handle, "NFREEPAR")) != length(engine.walkers)
      && (file.sloppy<1)) {
    fits_close_file(handle);
    handle = NULL;
    throw IOError, "Number of walkers differs from number used in chain file, increase sloppy level to continue";
  }
}
%}}}

private define emceeFileFitsOpen (file, engine) %{{{
{
  file.mode |= EMCEE_FILE_READ | EMCEE_FILE_WRITE;

  file.handle = fits_open_file(file.filename, "w");

  __emceeFitsReadChecks(file, engine);
  __emceeFitsWriteChecks(file, engine);

  if (_fits_movnam_hdu(file.handle, _FITS_BINARY_TBL, "MCMCCHAIN", 0)) {
    fits_close_file(file.handle);
    file.handle = NULL;
    throw IOError, "Not a emcee chain file";
  }

  () = _fits_get_rowsize(file.handle, &(file.cycle));
  file.cycle = file.cycle/length(engine.walkers);
  if (file.cycle < 1)
    file.cycle = 1;

  file.numberSteps = fits_get_num_rows(file.handle);
}
%}}}
%}}}

% Read function %{{{
private define emceeFileFitsRead (file, engine, numberWalkers) %{{{
{
  file.mode |= EMCEE_FILE_READ;
  file.mode &= ~EMCEE_FILE_WRITE;

  file.handle = fits_open_file(file.filename, "r");

  __emceeFitsReadChecks(file, engine);

  if (file.mode & EMCEE_FILE_RANGE) {
    if (_fits_movnam_hdu(file.handle, _FITS_BINARY_TBL, "PARAMETERS", 0)) {
      fits_close_file(file.handle);
      file.handle = NULL;
      throw IOError, "Not a emcee chain file";
    }

    variable params = fits_read_table(file.handle);
    return [struct {
      weight = 1,
      name = params.name,
      value = params.value,
      min = params.min,
      max = params.max
    }], numberWalkers;
  } else {
    if (_fits_movnam_hdu(file.handle, _FITS_BINARY_TBL, "MCMCCHAIN", 0)) {
      fits_close_file(file.handle);
      file.handle = NULL;
      throw IOError, "Not a emcee chain file";
    }

    variable totalNumberWalkers = fits_read_key(file.handle, "NWALKERS")
      *fits_read_key(file.handle, "NFREEPAR");
    variable numberParameters = fits_get_num_cols(file.handle);
    variable totalNumberRecords = fits_get_num_rows(file.handle);
    variable walkerDistribution; % this has to be an array of arrays with the parameter distribution in each
    () = _fits_read_cols(file.handle,
			 [3:numberParameters],
			 max([0, totalNumberRecords-numberWalkers]),
			 numberWalkers,
			 &walkerDistribution);

    fits_close_file(file.handle);

    return walkerDistribution, totalNumberWalkers;
  }
}
%}}}
%}}}

% Write function %{{{
private define emceeFileFitsWrite (file, engine, numberWalkersSteps) %{{{
{
  if (numberWalkersSteps > engine.leader.writeBuffer.size)
    throw InternalError, "Trying to write more than accessible";

  variable par = __parameters(engine.fit.object);
  variable npar = engine.numberParameters;

  %variable walkersPerCycle = engine.leader.writeBuffer.size; % total_walkers*steps_per_cycle
  variable i,j;
  variable firstIndex = fits_get_num_rows(file.handle)+1; % first index of this cycle
  variable parCycle = Double_Type[numberWalkersSteps];

  _for j (0, npar-1, 1) {
    _for i (0, numberWalkersSteps-1, 1)
      parCycle[i] = engine.leader.writeBuffer.walkers[i][j];
    () = _fits_write_col(file.handle,
			 fits_get_colnum(file.handle, sprintf("CHAINS%d", par.index[j])),
			 firstIndex,
			 1,
			 parCycle);
  }
  () = _fits_write_col(file.handle,
		       fits_get_colnum(file.handle, "FITSTAT"),
		       firstIndex,
		       1,
		       engine.leader.writeBuffer.stat[[:numberWalkersSteps-1]]);
  () = _fits_write_col(file.handle,
		       fits_get_colnum(file.handle, "UPDATE"),
		       firstIndex,
		       1,
		       engine.leader.writeBuffer.update[[:numberWalkersSteps-1]]);
}
%}}}
%}}}

% Close function %{{{
private define emceeFileFitsClose (file, engine) %{{{
{
  % todo: write fitstat table
  variable nHDUs = fits_get_num_hdus(file.handle);
  variable i;

  if (file.mode & EMCEE_FILE_WRITE) {
    _for i (1, nHDUs) {
      () = _fits_movabs_hdu(file.handle, i);
      fits_write_chksum(file.handle);
    }
  }

  fits_close_file(file.handle);
}
%}}}
%}}}
%}}}
private define emceeFileFits () %{{{
{
  variable file = struct { @EmceeFile, numberSteps, sloppy };
  file.create = &emceeFileFitsCreate;
  file.open = &emceeFileFitsOpen;
  file.read = &emceeFileFitsRead;
  file.write = &emceeFileFitsWrite;
  file.close = &emceeFileFitsClose;

  file.filename = qualifier("filename", strftime("emcee-%Y%m%d-%H%M%S.fits"));
  file.mode |= qualifier_exists("parameter") ? EMCEE_FILE_RANGE : 0;
  file.has |= EMCEE_FILE_READ | EMCEE_FILE_WRITE;
  file.cycle = 1;

  file.numberSteps = 0;
  file.sloppy = 0;

  return file;
}
%}}}
EmceeFileRegister["fits"] = &emceeFileFits;

%{{{ Mikes file format (similar to fits, but contains a third table with some stats)

% Create function %{{{
private define emceeFileMikeCreate (file, engine) %{{{
{
  file.mode |= EMCEE_FILE_WRITE;
  file.mode &= ~EMCEE_FILE_READ;

  % Create fits file and write headers
  file.handle = fits_open_file(file.filename, "c");

  % write first table
  __emceeFitsWriteT1(file.handle, engine);

  % write second table
  __emceeFitsWriteT2(file.handle, engine);

  % write third table
  __emceeFitsWriteT3(file.handle, engine);

  % move back to chain table
  () = _fits_movnam_hdu(file.handle, _FITS_BINARY_TBL, "MCMCCHAIN", 0);

  % set write cycle
  () = _fits_get_rowsize(file.handle, &(file.cycle));
  file.cycle = file.cycle/engine.totalNumberWalkers;
  if (file.cycle < 1)
    file.cycle = 1;

  % fits routine customs
  file.numberSteps = 0;
  file.sloppy = 0;
}
%}}}
%}}}

% Open function %{{{
private define __emceeMikeWriteChecks (file, engine) %{{{
{
  variable handle = file.handle;
  if (_fits_movnam_hdu(handle, _FITS_BINARY_TBL, "PARAMETERS", 0)) {
    fits_close_file(handle);
    handle = NULL;
    throw IOError, "Not a emcee chain file";
  }

  if ((fits_read_key(handle, "STATISTIC") != get_fit_statistic())) {
    fits_close_file(handle);
    handle = NULL;
    throw UsageError, sprintf("Current fit statistic (%s) and chain fit statistic (%s) differ.", fits_read_key(handle, "STATISTIC"), get_fit_statistic());
  }

  if (_fits_movnam_hdu(handle, _FITS_BINARY_TBL, "CHAINSTATS", 0)) {
    fits_close_file(handle);
    handle = NULL;
    throw IOError, "Not a emcee chain file";
  }

  if (_fits_movnam_hdu(handle, _FITS_BINARY_TBL, "MCMCCHAIN", 0)) {
    fits_close_file(handle);
    handle = NULL;
    throw IOError, "Not a emcee chain file";
  }

  if ((fits_read_key(handle, "NWALKERS")*fits_read_key(handle, "NFREEPAR")) != length(engine.walkers)) {
    fits_close_file(handle);
    handle = NULL;
    throw IOError, "Number of walkers differs from number used in chain file";
  }
}
%}}}

private define emceeFileMikeOpen (file, engine) %{{{
{
  file.mode |= EMCEE_FILE_READ | EMCEE_FILE_WRITE;

  file.handle = fits_open_file(file.filename, "w");

  if (_fits_movnam_hdu(file.handle, _FITS_BINARY_TBL, "MCMCCHAIN", 0)) {
    fits_close_file(file.handle);
    file.handle = NULL;
    throw IOError, "Not a emcee chain file";
  }

  __emceeFitsReadChecks(file, engine);
  __emceeMikeWriteChecks(file, engine);

  if (file.cycle < 0)
    file.cycle = 50; % default to 50 cycles per write

  file.numberSteps = fits_get_num_rows(file.handle);
}
%}}}
%}}}

% Read function %{{{
% use the fits read function
%}}}

% Write function %{{{
private define emceeFileMikeWrite (file, engine, numberWalkersSteps) %{{{
{
  if (numberWalkersSteps > engine.leader.writeBuffer.size)
    throw InternalError, "Trying to write more than accessible";

  variable par = __parameters(engine.fit.object);
  variable npar = engine.numberParameters;

  variable i,j;
  variable firstIndex = fits_get_num_rows(file.handle)+1; % first index of this cycle
  variable parCycle = Double_Type[numberWalkersSteps];
  variable stat_min, stat_med, stat_max, frac_update;
  stat_min = Double_Type[numberWalkersSteps/engine.totalNumberWalkers];
  stat_med = Double_Type[numberWalkersSteps/engine.totalNumberWalkers];
  stat_max = Double_Type[numberWalkersSteps/engine.totalNumberWalkers];
  frac_update = Double_Type[numberWalkersSteps/engine.totalNumberWalkers];

  _for j (0, npar-1, 1) {
    _for i (0, numberWalkersSteps-1, 1)
      parCycle[i] = engine.leader.writeBuffer.walkers[i][j];
    () = _fits_write_col(file.handle,
			 fits_get_colnum(file.handle, sprintf("CHAINS%d", par.index[j])),
			 firstIndex,
			 1,
			 parCycle);
  }
  () = _fits_write_col(file.handle,
		       fits_get_colnum(file.handle, "FITSTAT"),
		       firstIndex,
		       1,
		       engine.leader.writeBuffer.stat[[:numberWalkersSteps-1]]);
  () = _fits_write_col(file.handle,
		       fits_get_colnum(file.handle, "UPDATE"),
		       firstIndex,
		       1,
		       engine.leader.writeBuffer.update[[:numberWalkersSteps-1]]);

  () = _fits_movnam_hdu(file.handle, "CHAINSTATS", _FITS_BINARY_TBL, 0);
  firstIndex = fits_get_num_rows(file.handle)+1;
  _for j (0, numberWalkersSteps/engine.totalNumberWalkers-1) {
    stat_min[j] = min(engine.leader.writeBuffer.stat[[0:engine.totalNumberWalkers-1]+j*engine.totalNumberWalkers]);
    stat_med[j] = median(engine.leader.writeBuffer.stat[[0:engine.totalNumberWalkers-1]+j*engine.totalNumberWalkers]);
    stat_max[j] = max(engine.leader.writeBuffer.stat[[0:engine.totalNumberWalkers-1]+j*engine.totalNumberWalkers]);
    frac_update[j] = sum(engine.leader.writeBuffer.update[[0:engine.totalNumberWalkers-1]+j*engine.totalNumberWalkers])/engine.totalNumberWalkers;
  }
  () = _fits_write_col(file.handle, fits_get_colnum(file.handle, "FRAC_UPDATE"), firstIndex, 1, frac_update);
  () = _fits_write_col(file.handle, fits_get_colnum(file.handle, "MIN_STAT"), firstIndex, 1, stat_min);
  () = _fits_write_col(file.handle, fits_get_colnum(file.handle, "MED_STAT"), firstIndex, 1, stat_med);
  () = _fits_write_col(file.handle, fits_get_colnum(file.handle, "MAX_STAT"), firstIndex, 1, stat_max);

  () = _fits_movnam_hdu(file.handle, "MCMCCHAIN", _FITS_BINARY_TBL, 0);
}
%}}}
%}}}

% Close function %{{{
% use fits close
%}}}
%}}}
private define emceeFileMike () %{{{
{
  variable file = struct { @EmceeFile, numberSteps };
  file.create = &emceeFileMikeCreate;
  file.open = &emceeFileMikeOpen;
  file.read = &emceeFileFitsRead;
  file.write = &emceeFileMikeWrite;
  file.close = &emceeFileFitsClose;

  file.filename = qualifier("filename", strftime("emcee-%Y%m%d-%H%M%S.fits"));
  file.mode |= qualifier_exists("parameter") ? EMCEE_FILE_RANGE : 0;
  file.has |= EMCEE_FILE_READ | EMCEE_FILE_WRITE;
  file.cycle = qualifier("cycle", 50);

  file.numberSteps = 0;

  return file;
}
%}}}
EmceeFileRegister["mike"] = &emceeFileMike;

%{{{ Par file functions
%{{{ create function
%}}}

%{{{ open function
%}}}

%{{{ read function
private define emceeFileParRead (file, engine, numberWalkers) %{{{
{
  % we read a number of par files (eventually with multipliers)
  variable file_list = strchop(file.filename, ';', 0);
  variable params = Struct_Type[length(file_list)];  
  variable weight;
  variable i, j, s, p;

  _for i (0, length(file_list)-1) {
    s = strchop(file_list[i], ':', 0);
    if (length(s)>1) weight = atoi(s[1]); % zero, if error, effectively disabling that file
    else weight = 1;

    p = read_par(s[0]);
    if (weight>0) {
      params[i] = struct {
	weight = weight,
	name = String_Type[length(p)],
	value = Double_Type[length(p)],
	min = Double_Type[length(p)],
	max = Double_Type[length(p)],
      };
      _for j (0, length(p)-1) {
	params[i].name = p[j].name;
	params[i].value = p[j].value;
	params[i].min = p[j].min;
	params[i].max = p[j].max;
      }
    }
  }

  return params, numberWalkers;
}
%}}}
%}}}

%{{{ write function
%}}}

%{{{ close function
%}}}
%}}}
private define emceeFilePar () %{{{
{
  variable file = struct { @EmceeFile };
  file.create = &NULL;
  file.open = &NULL;
  file.read = &emceeFileParRead;
  file.write = &NULL;
  file.close = &NULL;

  file.filename = qualifier("filename", strftime("emcee-%Y%m%d-%H%M%S.par"));
  % there is no other mode
  file.mode = EMCEE_FILE_READ | EMCEE_FILE_RANGE;
  file.has = EMCEE_FILE_READ | EMCEE_FILE_RANGE;
  file.cycle = 1;

  return file;
}
%}}}
EmceeFileRegister["par"] = &emceeFilePar;
%}}}

%{{{ Init interface
%!%+
%\function{emcee--init}
%\synopsis{Set emcee initialization function}
%\usage{init="method;parameters";}
%\description
%  The initialization method can be set with the function string
%    "method;parameter"
%  Initialization methods that read from file use the defined input
%  method (default: fits).
%
%  Available methods:
%  uniform : Draw initial walker positions from a uniform distribution
%            within the parameter ranges.
%    ; width : [=1.0] Sub range used for initialization (must be <= 1).
%                     The initiale cube center coincides as much as
%                     possible with the current parameter values.
%
%  gauss   : Draw initial walker positions from a gaussian distribution
%            within parameter ranges.
%    ; sigma : [=0.1] Sigma of the gauss function in terms of the
%                     parameter range. I.e, sigma=1 is the full parameter
%                     range. Allowed range between 1e-3 and 2 (outside will
%                     be cliped).
%
%  file    : Load initial walkers from a valid chain file created by the
%            emcee method. This is used with 'continue'. The parameter ranges
%            can be different compared to a previous run. This is also true
%            for the number of walkers. In order to truely continue a chain
%            those have to be set equal to the previous run.
%
%  chain   : Draw initial walkers from an approximated CDF of an existing
%            chain file.
%    ; steps : [=10] The number of steps to concider for constructing the CDF
%                 (from the end of the chain)
%    ; rng   : [=&rand_uniform] uniform random number generator
%
%!%-
%      1: pick - get walkers from parameters and distribution or file
private variable EmceeInit = struct {
  pick, % function

  % private data
};

private define __emcee_params (par, feed, total) %{{{
{
  variable params = Assoc_Type[UInt_Type, 0]; % need full information to match names == index
  variable n = UInt_Type[length(feed)];
  variable eparams = Struct_Type[length(feed)];
  variable c = 0, cc = 0;
  variable i,j,w,p;

  _for i (0, length(feed)-1) {
    if (feed[i] == NULL) continue;
    ifnot (struct_field_exists(feed[i], "name")) % current set, weight = 1
      c++;
    else
      c += (feed[i].weight>0) ? feed[i].weight : 0;
  }

  foreach p (get_params)
    params[p.name] = p.index;

  _for i (0, length(feed)-1) {
    if (feed[i] == NULL) continue;
    eparams[i] = @Struct_Type(get_struct_field_names(par)); % as prototype
    eparams[i].value = Double_Type[length(par.index)];
    eparams[i].min = Double_Type[length(par.index)];
    eparams[i].max = Double_Type[length(par.index)];

    % use current set of parameters
    ifnot (struct_field_exists(feed[i], "name")) {
      eparams[i].value = par.value;
      eparams[i].min = par.min;
      eparams[i].max = par.max;
      n[i] = int(round(1./c*total));
      w = where((eparams[i].min == -DOUBLE_MAX) and (eparams[i].max == DOUBLE_MAX));
      if (length(w))
      {
	variable s = "[";
	_for j (0, length(w)-1) s += sprintf("%d,", w[j]);
	throw UsageError, sprintf("Unspecified ranges for parameters %s]", s[[:-2]]);
      }
    } else {
      _for j (0, length(par.index)-1) {
	w = where(par.index[j] == params[feed[i].name]);
	if (length(w) != 1) % also errors if for whatever reason the parameter is twice in feed
	  throw UsageError, sprintf("Unspecified parameter %d", par.index[j]);
	w = w[0];
	if ((par.min[j] > feed[i].min[w]) || (par.max[j] < feed[i].max[w]))
	  throw UsageError, sprintf("Parameter ranges for paramter %d not enclosed", par.index[j]);
	if ((feed[i].min[w] == -DOUBLE_MAX) || (feed[i].max[w] == DOUBLE_MAX))
	  throw UsageError, sprintf("Unspecified ranges for parameter %d", par.index[j]);

	eparams[i].value[w] = feed[i].value[j];
	eparams[i].min[w] = feed[i].min[j];
	eparams[i].max[w] = feed[i].max[j];
      }

      n[i] = int(round(1.*feed[i].weight/c*total));
    }

    cc += n[i];
  }

  n[0] += cc-total;
  return eparams, n;
}
%}}}

%{{{ Uniform initialization function
% pick random parameter values within the boundaries
private define emceeInitUniformPick (init, engine) %{{{
{
  variable i, j, k, feed;
  variable c, p;
  variable file = engine.leader.inFile;
  variable par = __parameters(engine.fit.object);
  variable numParameter = length(par.value);
  variable minb, maxb;

  if (file.mode & EMCEE_FILE_RANGE)
    (feed, ) = file.read(engine, engine.totalNumberWalkers);
  else
    feed = @par;

  minb = _max(par.min, par.value-init.width*0.5*(par.max-par.min));
  maxb = _min(par.max, par.value+init.width*0.5*(par.max-par.min));

  (p,c) = __emcee_params(par, feed, engine.totalNumberWalkers);

  k = 0;
  _for i (0, length(c)-1) {
    _for j (0, c[i]-1)
      engine.walkers[j+k] = _max(p[i].min, _min(p[i].max, rand_uniform(numParameter)*(maxb-minb)+minb));
    k += c[i];
  }
}
%}}}
%}}}
private define emceeInitUniform () %{{{
{
  variable init = struct { @EmceeInit, width };
  init.pick = &emceeInitUniformPick;
  init.width = _min(_max(qualifier("width", 1.0), 1e-3), 1.0);

  return init;
}
%}}}
EmceeInitRegister["uniform"] =  &emceeInitUniform;

%{{{ Gauss initialization function
private define rand_gauss_cut (sigma, v, bmin, bmax) %{{{
{
  variable mu = (v-bmin)/(bmax-bmin);
  variable alpha = -mu/sigma/sqrt(2);
  variable beta = (1.0-mu)/sigma/sqrt(2);
  variable phia = 0.5*(1+gsl->erf(alpha));
  variable phib = 0.5*(1+gsl->erf(beta));
  variable k = phia+rand_uniform(length(v))*(phib-phia);

  return _min(bmax,_max(bmin,gsl->cdf_gaussian_Pinv(k, sigma)*sigma*(bmax-bmin)+v));
}
%}}}

private define emceeInitGaussPick (init, engine) %{{{
{
  variable i,j,k,feed;
  variable c,p;
  variable file = engine.leader.inFile;
  variable par = __parameters(engine.fit.object);
  variable numParameter = length(par.value);

  if (file.mode & EMCEE_FILE_RANGE)
    (feed, ) = file.read(engine, engine.totalNumberWalkers);
  else
    feed = @par;

  (p,c) = __emcee_params(par, feed, engine.totalNumberWalkers);

  k = 0;
  _for i (0, length(c)-1) {
    _for j (0, c[i]-1) {
      engine.walkers[j+k] = rand_gauss_cut(init.sigma, p[i].value, p[i].min, p[i].max);
    }
    k += c[i];
  }
}
%}}}
%}}}
private define emceeInitGauss () %{{{
{
  variable init = struct { @EmceeInit, sigma };
  init.pick = &emceeInitGaussPick;
  init.sigma = _max(_min(qualifier("sigma", 0.1), 2.0), 1e-3);

  return init;
}
%}}}
EmceeInitRegister["gauss"] = &emceeInitGauss;

%{{{ File initialization function
private define fisher_yates (have, want) %{{{
% perform a Fisher Yates shuffle of the
% available walkers. Repeat pattern if more
% are requested.
{
  vmessage("Shuffling and drawing %d from %d", want, have);
  variable p = [0:have-1];
  variable i,j;
  _for j (0, have-2) {
    i = rand_int(j, have-1);
    if (i != j)
      array_swap(p, j, i);
  }

  return p[[0:want-1] mod have];
}
%}}}

private define emceeInitFilePick (init, engine) %{{{
{
  variable file = engine.leader.inFile;
  variable walkerDistribution, readNumber;

  (walkerDistribution, readNumber) = file.read(engine, engine.totalNumberWalkers);

  variable i,j;
  variable par = __parameters(engine.fit.object);
  variable parV = Double_Type[engine.numberParameters];
  variable valid = Int_Type[length(walkerDistribution[0])];
  % filter to walkers in par range
  _for i (0, length(valid)-1)
  {
    _for j (0, length(parV)-1)
    {
      ifnot (par.min[j]<=walkerDistribution[j][i]<=par.max[j])
	break;
      else if (j==(length(parV)-1))
	valid[i] = 1;
    }
  }
  valid = where(valid);
  if (length(valid)<2*engine.numberParameters)
    throw DataError, "Not enough walkers in current parameter range";

  % randomize (and bootstrap if necessary)
  variable randomize = fisher_yates(length(valid), length(engine.walkers));
  _for i (0, length(engine.walkers)-1) {
    _for j (0, length(parV)-1)
      parV[j] = walkerDistribution[j][valid[randomize[i]]];
    engine.walkers[i] = @parV;
  }
}
%}}}
%}}}
private define emceeInitFile () %{{{
{
  variable init = struct { @EmceeInit };
  init.pick = &emceeInitFilePick;

  return init;
}
%}}}
EmceeInitRegister["file"] = &emceeInitFile;

%{{{ Chain initialization function
define empiric_cdf_inverse (p, a, amin, amax) %{{{
{
  variable s = array_sort(p);

  if (p[s][0]<0 || p[s][-1]>=1)
    throw DomainError, "not in range 0<=p<1";

  a = a[array_sort(a)];
  a = a[where(amin<=a<=amax)]; % restrict to cdf in range

  if (length(a)==0) % nothing in par range, fallback to uniform
    a = [0.5*(amin+amax)];

  variable u = unique(a);
  variable ecdf = [u/1./length(a), 1.];
  variable lo = [amin, a[u]];
  variable hi = [a[u], amax];

  variable r = Double_Type[length(p)];
  variable k, i = 0;
  variable m = .5*([(ecdf[[1:]]-ecdf[[:-2]])/(lo[[1:]]-lo[[:-2]]), 0.]
		   +[0., (ecdf[[1:]]-ecdf[[:-2]])/(hi[[1:]]-hi[[:-2]])]);

  variable hitsmin = (amin == a[0]); % gives NaN if true and p == 0
  _for k (0, length(p)-1) {
    while (p[s[k]] > ecdf[i+1]) i++;
    if (hitsmin && p[s[k]]==0)
      r[s[k]] = amin;
    else
      r[s[k]] = (p[s[k]]-ecdf[i])/m[i]+lo[i];
    if (r[s[k]]>amax)
      r[s[k]] = amax;
  }

  return r;
}
%}}}

private define emceeInitChainPick (init, engine) %{{{
{
  variable file = engine.leader.inFile;
  variable walkerDistribution, numberSteps;
  (walkerDistribution, numberSteps) = file.read(engine, init.steps);
  variable par = __parameters(engine.fit.object);;

  variable parRand;
  variable i,j;
  _for i (0, engine.numberParameters-1) {
    parRand = empiric_cdf_inverse(@(init.rng)(engine.totalNumberWalkers),
				  walkerDistribution[i],
				 par.min[i],
				 par.max[i]);
    _for j (0, engine.totalNumberWalkers-1)
      engine.walkers[j][i] = parRand[j];
  }
}
%}}}
%}}}
private define emceeInitChain () %{{{
{
  variable init = struct { @EmceeInit, rng, steps };
  init.pick = &emceeInitChainPick;
  init.rng = qualifier("rng", &rand_uniform);
  init.steps = qualifier("steps", 10);

  return init;
}
%}}}
EmceeInitRegister["chain"] = &emceeInitChain;
%}}}

%{{{ Ship interface:
%!%+
%\function{emcee--driver}
%\synopsis{Set emcee parallel computation method}
%\usage{driver="method;options"}
%\description
%  The driver method can be set with the function string
%    "method;parameter"
%
%  Available methods:
%  serial : The serial driver. No parallelization at all
%
%  fork : The fork (& socket) parallel driver. Per default uses
%          _num_cpus many tasks.
%    ; tasks : [=_num_cpus] Number of total processes used
%
%  mpi : The mpi parallel driver using as many nodes as registered
%        in an mpi environment
%!%-
%      1: setSail - set id for engines and how many there are
%      2: leader_send - leader sends to members
%      3: member_send - members send to leader
%      4: leader_receive - leader receives members
%      5: member_receive - member receive leader
%      6: enterHarbor - cleanup if necessary
%      7: abort - cleanup handler if SIGTERM is received
private variable EmceeShip = struct {
  setSail, % function
  leaderSend, % function
  memberSend, % function
  leaderReceive, % function
  memberReceive, % function
  enterHarbor, % function
  abort = &NULL, % function, has a default

  engine, % the working horse

  % private data
};

%{{{ serial ship functions
private define void () %{{{
{
  variable args = __pop_list(_NARGS);
}
%}}}

private define emceeSerialInit (ship) %{{{
{
  ship.engine.numberEngines = 1;
  ship.engine.id = 0;
}
%}}}
%}}}
private define emceeShipSerial () %{{{
{
  variable ship = struct { @EmceeShip };
  ship.setSail = &emceeSerialInit;
  ship.leaderSend = &void;
  ship.memberSend = &void;
  ship.leaderReceive = &void;
  ship.memberReceive = &void;
  ship.enterHarbor = &void;

  return ship;
}
%}}}
EmceeShipRegister["serial"] = &emceeShipSerial;

%{{{ fork ship functions
private define elementType (t) %{{{
{
  switch (t)
  { case Char_Type:    "c"; }
  { case UChar_Type:   "C"; }
  { case Short_Type:   "h"; }
  { case UShort_Type:  "H"; }
  { case Int_Type:     "i"; }
  { case UInt_Type:    "I"; }
  { case Long_Type:    "l"; }
  { case ULong_Type:   "L"; }
  { case LLong_Type:   "m"; }
  { case ULLong_Type:  "M"; }
  { case Int16_Type:   "j"; }
  { case UInt16_Type:  "J"; }
  { case Int32_Type:   "k"; }
  { case UInt32_Type:  "K"; }
  { case Int64_Type:   "q"; }
  { case UInt64_Type:  "Q"; }
  { case Float_Type:   "f"; }
  { case Double_Type:  "d"; }
  { case Float32_Type: "F"; }
  { case Float64_Type: "D"; }
  { case String_Type:  "s"; }
  { case Null_Type:    "x"; }
}
%}}}

private define writeArray (fp, array) %{{{
{
  variable bytes, msg, fmt;
  fmt = sprintf("%s%d", elementType(_typeof(array)), length(array));
  msg = pack(fmt, array);
  bytes = write(fp, msg);
  return bstrlen(msg)-bytes;
}
%}}}

private define readArray (fp, array) %{{{
{
  variable i, bytes=0, msg=""B, fmt;
  fmt = sprintf("%s%d", elementType(_typeof(array)), length(array));
  variable missing = sizeof_pack(fmt);
  variable total = ""B;
  if (length(array)) {
    while (missing) {
      bytes = read(fp, &msg, missing);
      if (-1 == bytes)
	throw InternalError;
      total += msg;
      missing -= bytes;
    }
    array[*] = unpack(fmt, total);
  }

  return bstrlen(msg);
}
%}}}

private define reap_childs (sig) {
  while (NULL != waitpid(-1, WNOHANG));
}

private define term_process_list (plist) %{{{
{
  variable pid;
  foreach pid (plist) {
    if (pid > 0)
      () = kill(pid, SIGTERM);
  }
}
%}}}

private define emceeForkSetSail (ship) %{{{
{
  variable sockRead, sockWrite;
  variable pid=-1, cid=0, t;
  variable flags;
  variable ppid = getpid();
  variable pids = Int_Type[ship.tasks];
  variable sock = FD_Type[ship.tasks];
  signal(SIGCHLD, &reap_childs);

  _for t (1, ship.tasks-1) {
    (sockRead, sockWrite) = socketpair(AF_UNIX, SOCK_STREAM, 0);
    cid++;
    pid = fork();
    if (pid ==  -1) {
      % need to reap all processes thus far
      term_process_list(pids);
      throw InternalError, sprintf("Unable to fork engine %d", cid);
    } else if (pid == 0) {
      () = close(sockWrite);
      ship.socket = sockRead;
      signal(SIGTERM, SIG_DFL); % make sure term is not disguised
      ship.pids = ppid;
      break;
    } else { % set master pipes
%      flags = fcntl_getfd(sockWrite);
%      fcntl_setfd(sockWrite, flags | O_NONBLOCK);
      sock[cid] = sockWrite;
      () = close(sockRead);
      pids[t] = pid;
    }
  }

  if (0 == pid) {
    ship.engine.id = cid;
  } else {
    ship.pids = pids;
    ship.socket = sock;
    ship.engine.id = 0;
  }

  ship.engine.numberEngines = ship.tasks;
}
%}}}

private define emceeForkLeaderSend (ship) %{{{
{
  variable walkers,
    pivots,
    rolls;
  variable engine = ship.engine;
  variable totalOffset = engine.leader.totalOffset;
  variable walkersPerSet = engine.leader.walkersPerSet;

  variable i,j;
  variable firstIndex = walkersPerSet[0];
  _for i (1, engine.numberEngines-1) {
    % set the walkers for node i
    walkers = engine.walkers[[0:walkersPerSet[i]-1]+firstIndex+totalOffset];
    % pick the pivots for node i
    pivots  = engine.pivots[[0:walkersPerSet[i]-1]+firstIndex+totalOffset];
    % set the randoms for node i
    rolls = engine.rolls[[0:walkersPerSet[i]*engine.gears.step.numberRandoms-1]
			 +(firstIndex+totalOffset)*engine.gears.step.numberRandoms];

    _for j (0, walkersPerSet[i]-1, 1) {
      () = writeArray(ship.socket[i], walkers[j]);
      () = writeArray(ship.socket[i], pivots[j]);
    }
    () = writeArray(ship.socket[i], rolls);
    firstIndex += walkersPerSet[i];
  }
}
%}}}

private define emceeForkMemberSend (ship) %{{{
{
  variable engine = ship.engine;
  variable setOffset = engine.setOffset;
  variable setLength = engine.setLength;

  variable i;
  _for i (0, setLength-1, 1)
    () = writeArray(ship.socket, engine.walkers[i+setOffset]);

  () = writeArray(ship.socket, engine.update[[0:setLength-1]+setOffset]);
  () = writeArray(ship.socket, engine.stat[[0:setLength-1]+setOffset]);
}
%}}}

private define emceeForkLeaderReceive (ship) %{{{
{
  variable walker,
    stat,
    update;

  variable engine = ship.engine;
  variable totalOffset = engine.leader.totalOffset;
  variable walkersPerSet = engine.leader.walkersPerSet;

  variable i,j;
  variable firstIndex = walkersPerSet[0]; % skip master walkers

  walker = Double_Type[engine.numberParameters];
  _for i (1, engine.numberEngines-1) {
    stat   = Double_Type[walkersPerSet[i]];
    update = Int_Type[walkersPerSet[i]];

    _for j (0, walkersPerSet[i]-1, 1) {
      () = readArray(ship.socket[i], walker);
      engine.walkers[j+firstIndex+totalOffset][*] = walker;
    }

    () = readArray(ship.socket[i], update);
    () = readArray(ship.socket[i], stat);

    engine.update[[0:walkersPerSet[i]-1]+firstIndex+totalOffset] = update;
    engine.stat[[0:walkersPerSet[i]-1]+firstIndex+totalOffset]   = stat;

    firstIndex += walkersPerSet[i];
  }
}
%}}}

private define emceeForkMemberReceive (ship) %{{{
{
  variable rolls,
    param;

  variable engine = ship.engine;
  variable setOffset = engine.setOffset;
  variable setLength = engine.setLength; 
  variable nRolls = engine.gears.step.numberRandoms;

  variable j;
  rolls = Double_Type[setLength*nRolls];
  param = Double_Type[engine.numberParameters];
  _for j (0, setLength-1, 1) {
    () = readArray(ship.socket, param);
    engine.walkers[j+setOffset][*] = param;
    () = readArray(ship.socket, param);
    engine.pivots[j+setOffset][*] = param;
  }
  () = readArray(ship.socket, rolls);

  engine.rolls[[0:setLength*nRolls-1]+setOffset*nRolls] = @rolls;
}
%}}}

private define emceeForkEnterHarbor (ship) %{{{
{
  variable id;
  if (ship.engine.id == 0) {
    _for id (1, ship.engine.numberEngines-1)
      () = close(ship.socket[id]);
    term_process_list(ship.pids);
    reap_childs(0);
  } else {
    () = close(ship.socket);
    _exit(0); % no handlers
  }
}
%}}}

private define emceeForkAbort (ship) %{{{
{
  term_process_list(ship.pids);
  reap_childs(0);
}
%}}}
%}}}
private define emceeShipFork () %{{{
{
  variable ship = struct { @EmceeShip, socket, tasks, pids };
  ship.setSail = &emceeForkSetSail;
  ship.leaderSend = &emceeForkLeaderSend;
  ship.memberSend = &emceeForkMemberSend;
  ship.leaderReceive = &emceeForkLeaderReceive;
  ship.memberReceive = &emceeForkMemberReceive;
  ship.enterHarbor = &emceeForkEnterHarbor;
  ship.abort = &emceeForkAbort;
  ship.tasks = qualifier("tasks", _num_cpus());

  return ship;
}
%}}}
EmceeShipRegister["fork"] = &emceeShipFork;

#ifexists rcl_mpi_init
%{{{ MPI Ship functions
private define emceeMPISetSail (ship) %{{{
{
  variable engine = ship.engine;
  engine.id = rcl_mpi_init();
  engine.numberEngines = rcl_mpi_numtasks();
  rcl_init_mpi_request(engine.numberEngines);
}
%}}}

private define emceeMPILeaderSend (ship) %{{{
{
  variable walkers,
    pivots,
    rolls;
  variable engine = ship.engine;
  variable totalOffset = engine.leader.totalOffset;
  variable walkersPerSet = engine.leader.walkersPerSet;

  variable i,j;
  variable firstIndex = walkersPerSet[0]; % skip master walkers

  _for i (1, engine.numberEngines-1) { % loop over the slave nodes and send relevant data
    % set the walkers for node i
    walkers = engine.walkers[[0:walkersPerSet[i]-1]+firstIndex+totalOffset];
    % pick the pivots for node i
    pivots  = engine.pivots[[0:walkersPerSet[i]-1]+firstIndex+totalOffset];
    % set the randoms for node i
    rolls = engine.rolls[[0:walkersPerSet[i]*engine.gears.step.numberRandoms-1]
			 +(firstIndex+totalOffset)*engine.gears.step.numberRandoms];

    _for j (0, walkersPerSet[i]-1, 1) {
      () = rcl_mpi_org_isend_double(walkers[j], length(walkers[j]), i, 0); % send current walkers with tag 0
      () = rcl_mpi_org_isend_double(pivots[j], length(pivots[j]), i, 1); % send pivots from other set with tag 1
    }

    () = rcl_mpi_org_isend_double(rolls, length(rolls), i, 2); % send random numbers with tag 2
    firstIndex += walkersPerSet[i];
  }
}
%}}}

private define emceeMPILeaderReceive (ship) %{{{
{
  variable engine = ship.engine;
  variable totalOffset = engine.leader.totalOffset;
  variable walkersPerSet = engine.leader.walkersPerSet;

  variable i,j;
  variable firstIndex = walkersPerSet[0]; % skip master walkers
  variable buffer, len;
  % Warning: The extra variable 'buffer' seems unecessary (when coming
  % from c) but it is not! Slang creates temporary arrays on the
  % fly using the array access syntax. This causes the main array
  % not getting updated correctly.

  _for i (1, engine.numberEngines-1) {
    _for j (0, walkersPerSet[i]-1, 1) {
      () = rcl_mpi_org_recv_double(engine.walkers[j+firstIndex+totalOffset],
				   length(engine.walkers[j+firstIndex+totalOffset]), i, i);
    }

    len = length(engine.update[[0:walkersPerSet[i]-1]+firstIndex+totalOffset]);
    buffer = Int_Type[len];
    () = rcl_mpi_org_recv_int(buffer, len, i, i);
    engine.update[[0:walkersPerSet[i]-1]+firstIndex+totalOffset] = buffer;

    buffer = Double_Type[len];
    () = rcl_mpi_org_recv_double(buffer, len, i, i);
    engine.stat[[0:walkersPerSet[i]-1]+firstIndex+totalOffset] = buffer;

    firstIndex += walkersPerSet[i];
  }
}
%}}}

private define emceeMPIMemberSend (ship) %{{{
{
  variable engine = ship.engine;
  variable setOffset = engine.setOffset;
  variable setLength = engine.setLength;

  variable i;
  _for i (0, setLength-1, 1) {
    () = rcl_mpi_org_isend_double(engine.walkers[i+setOffset],
				  length(engine.walkers[i+setOffset]), 0, engine.id);
  }

  () = rcl_mpi_org_isend_int(engine.update[[0:setLength-1]+setOffset], setLength, 0, engine.id);
  () = rcl_mpi_org_isend_double(engine.stat[[0:setLength-1]+setOffset], setLength, 0, engine.id);
}
%}}}

private define emceeMPIMemberReceive (ship) %{{{
{
  variable rolls;
  variable engine = ship.engine;
  variable setOffset = engine.setOffset;
  variable setLength = engine.setLength; 
  variable nRolls = engine.gears.step.numberRandoms;

  variable j;
  rolls = Double_Type[setLength*nRolls];
  _for j (0, setLength-1, 1) {
    () = rcl_mpi_org_recv_double(engine.walkers[j+setOffset],
				 length(engine.walkers[j+setOffset]), 0, 0); % receive walkers (tag 0)
    () = rcl_mpi_org_recv_double(engine.pivots[j+setOffset],
				 length(engine.pivots[j+setOffset]), 0, 1); % receive pivot points (tag 1)
  }
  () = rcl_mpi_org_recv_double(rolls,
			       setLength*engine.gears.step.numberRandoms, 0, 2); % receive random numbers (tag 2)

  engine.rolls[[0:setLength*nRolls-1]+setOffset*nRolls] = @rolls;
}
%}}}

private define emceeMPIEnterHarbor (ship) %{{{
{
  
}
%}}}

private define emceeMPIAbort (ship) %{{{
{
#ifexists rcl_mpi_abort
  rcl_mpi_abort(1); % hopefully 0 is allway success
#endif
  throw InternalError;
}
%}}}
%}}}
private define emceeShipMPI () %{{{
{
  variable ship = struct { @EmceeShip };
  ship.setSail = &emceeMPISetSail;
  ship.leaderSend = &emceeMPILeaderSend;
  ship.memberSend = &emceeMPIMemberSend;
  ship.leaderReceive = &emceeMPILeaderReceive;
  ship.memberReceive = &emceeMPIMemberReceive;
  ship.enterHarbor = &emceeMPIEnterHarbor;
  ship.abort = &emceeMPIAbort;

  return ship;
}
%}}}
EmceeShipRegister["mpi"] = &emceeShipMPI;
#endif
%}}}

%{{{ Step interface:
%!%+
%\function{emcee--step}
%\synopsis{Set emcee step algorithm}
%\usage{step="method;options"}
%\description
%  The step algorithm can be set with the function string
%    "method;parameter"
%
%  Available algorithms:
%  stretch : The stretch move as described in Goodman & Weare 2010
%    ; scale : [=2] Scale for the range of possible moves
%!%-
%      1: move - loop over walkers and update
private variable EmceeStep = struct {
  move, % function

  numberRandoms, % random number required per step

  % private data
};

%{{{ Stretch move functions (Foreman & Mackey)
% define inverse cumulative distribution function for generating
% random numbers following 1/z^2 when z in [1/a, a]
% TODO: should make this an adjustable thing
private define stretchInverseCDF (u, a) %{{{
{
  return (u*(a-1.)+1.)^2./a;
}
%}}}

% stretch move as of Goodman & Weare 2010
% Move must evaluate the fit function
private define emceeStepStretchMove (step, engine) %{{{
{
  variable j;
  variable z;
  variable proposed;
  variable newStat;
  variable startIndex = engine.setOffset;
  variable setLength = engine.setLength;

  _for j (startIndex, startIndex+setLength-1) {
    z = stretchInverseCDF(engine.rolls[j*step.numberRandoms], step.scale);
    proposed = engine.pivots[j] + z*(engine.walkers[j]-engine.pivots[j]);

    engine.update[j] = 0;

    try {
      newStat = engine.fit.eval_statistic(proposed; nocopy);

      % accept or reject dimensionally normalized. Assuming statistic is -2 log likelihood
      if (log(engine.rolls[j*step.numberRandoms+1])
	  <= (log(z)*(engine.fit.num_vary-1)+(engine.stat[j]-newStat)/2.)) {
	engine.stat[j] = newStat;
	engine.walkers[j][*] = proposed;
	engine.update[j] = 1;
      }
    } catch IsisError;
  }
}
%}}}
%}}}
private define emceeStepStretch () %{{{
{
  variable step = struct { @EmceeStep, scale };
  step.move = &emceeStepStretchMove;
  step.numberRandoms = 2;
  step.scale = qualifier("scale", 2);

  return step;
}
%}}}
EmceeStepRegister["stretch"] = &emceeStepStretch;
%}}}

%{{{ Progress interface
%!%+
%\function{emcee--progress}
%\synopsis{Set emcee progress report}
%\usage{progress="method;options"}
%\description
%  To get a progress report for the running emcee
%  algorithm use one of the available options.
%
%  Available report methods:
%  none   : Do not report
%  report : Report the number of steps done every n steps
%    ; n : [=50] Report for every n steps.
%    ; overwrite : if given, overwrite last status (useful for
%       interactive sessions).
%    ; format : [="Status: %D/%T (%%P)"] The report format
%       where %D is the current step, %T total steps and %P
%       the percentage.
%!%-
private variable EmceeProgress = struct {
  reporter, % function
  finish, % function

  every = 50, % when to change report

  % private data
};

%{{{ None
private define emceeProgressNone () %{{{
{
  variable progress = struct { @EmceeProgress };
  progress.reporter = &NULL;
  progress.finish = &NULL;
  progress.every = -1;

  return progress;
}
%}}}
%}}}
EmceeProgressRegister["none"] = &emceeProgressNone;

%{{{ Report
private define emceeProgressReportReporter (progress, engine, step)
{
  variable str = strreplace(progress.format, "%D", sprintf("%d", step));
  str = strreplace(str, "%T", sprintf("%d", engine.numberSteps));
  str = strreplace(str, "%P", sprintf("%.02lf", step*100./engine.numberSteps));
  if (engine.numberSteps == step) {
    progress.last_out = printf("%c%s\n", (progress.overwrite ? '\r' : '\0'), str);
    progress.last = 1;
  } else {
    progress.last_out = printf("%c%s%c", (progress.overwrite ? '\r' : '\0'), str, (progress.overwrite ? '\0' : '\n'));
    () = fflush(stdout);
  }
}
private define emceeProgressReportFinish (progress, engine, step)
{
  emceeProgressReportReporter(progress, engine, step);

  () = printf("-- DONE --\n");
}
%}}}
private define emceeProgressReport () %{{{
{
  variable progress = struct { @EmceeProgress, last_out = 0, overwrite, format, last = 0 };
  progress.reporter = &emceeProgressReportReporter;
  progress.finish = &emceeProgressReportFinish;
  progress.every = qualifier("n", 50);
  progress.overwrite = qualifier_exists("overwrite");
  progress.format = qualifier("format", "Status: %D/%T (%%P)");

  return progress;
}
%}}}
EmceeProgressRegister["report"] = &emceeProgressReport;
%}}}

%%% emcee call
private define emceeOption (str) %{{{
{
  variable s = strchop(str, ';', 0);
  return strtrim(s[0]), length(s)>1 ? eval(sprintf("struct {%s}", s[1])) : NULL;
}
%}}}

private variable EMCEE_ABORT = 0;
private variable EMCEE_OLD_HANDLE = SIG_DFL;
private define emceeLoop (ship, step, output) %{{{
{
  variable engine = ship.engine;
  variable s=0, j, set, cycle = 0, leader, size, offset, timer;

  offset = 0;
  tic; % start timer

  if (0 == engine.id) {
    leader = engine.leader;
    if (leader.progress.every > 0)
      leader.progress.reporter(engine, 0);
  }

  try {
    _for s (0, engine.numberSteps-1) {
      if (EMCEE_ABORT) break;
      _for set (1, 2) {
	if (EMCEE_ABORT) break;
	emceeDrawSet(engine, set);

	if (0 == engine.id)
	  ship.leaderSend();
	else
	  ship.memberReceive();

	step.move(engine);

	if (0 == engine.id)
	  ship.leaderReceive();
	else
	  ship.memberSend();
      }
      timer = toc; % get elapsed time

      if (0 == engine.id) {
	size = leader.writeBuffer.size;
	cycle = (s-offset) mod leader.writeBuffer.cycle;

	% write to buffer
	_for j (0, engine.totalNumberWalkers-1) {
	  leader.writeBuffer.walkers[j+cycle*engine.totalNumberWalkers][*] = @(engine.walkers[j]);
	  leader.writeBuffer.stat[j+cycle*engine.totalNumberWalkers] = engine.stat[j];
	  leader.writeBuffer.update[j+cycle*engine.totalNumberWalkers] = engine.update[j];
	}

	if ((leader.progress.every > 0) && not (s mod leader.progress.every))
	  leader.progress.reporter(engine, s+1);

	if (cycle == (leader.writeBuffer.cycle-1)) {
	  output.write(engine, size);
	  output.close(engine); % flush output
	  output.open(engine);
	  offset = 0; % we write full buffer, so no offset at all
	  tic; % restart timer
	} else if (timer >= 6e2) { % write every 10 min
	  output.write(engine, (cycle+1)*engine.totalNumberWalkers);
	  output.close(engine); % flush output
	  output.open(engine);
	  offset = cycle mod leader.writeBuffer.cycle;
	  tic; % restart timer
	}
      }
    }
  }
  catch UserBreakError: % make sure we stop gracefully
  {
    EMCEE_ABORT = 1;
  }

  % write remaining steps
  if (0 == engine.id) {
    if (cycle < (leader.writeBuffer.cycle-1)) {
      output.write(engine, (cycle+1)*engine.totalNumberWalkers);
      if (leader.progress.every > 0)
	leader.progress.reporter(engine, engine.numberSteps);
    }
    output.close(engine);
  }

  if (EMCEE_ABORT && (&NULL != ship.abort))
    ship.abort();
  EMCEE_ABORT=0;

  % set signal handler back
  signal(SIGTERM, EMCEE_OLD_HANDLE);

  if (0 == engine.id) {
    if (leader.progress.every > 0)
      leader.progress.finish(engine, engine.numberSteps);
  }
}
%}}}

% catch SIGTERM and set abort flag
private define emceeSignalHandler (sig) %{{{
{
  EMCEE_ABORT = 1;
  signal(SIGTERM, EMCEE_OLD_HANDLE);
}
%}}}

private define file_exists (filename) %{{{
{
  variable s = stat_file(filename);
  if (s == NULL) return 0;
  return not stat_is("dir", s.st_mode);
}
%}}}

private define emceeSetup (ship, steps, options) %{{{
{
  variable leader, size, engine;
  variable j, set, err;
  
  engine = ship.engine;
  if (0 == engine.id) {
    emceeSetupLeader(engine, options.input, options.output, options.progress);
    options.init.pick(engine);
  }

  % set walkers and eval once
  _for set (1, 2) {
    emceeDrawSet(engine, set);

    if (0 == engine.id)
      ship.leaderSend();
    else
      ship.memberReceive();
  }

  _for j (0, length(engine.walkers)-1)
    engine.stat[j] = engine.fit.eval_statistic(engine.walkers[j]; nocopy);

    % set handler
  signal(SIGTERM, &emceeSignalHandler, &EMCEE_OLD_HANDLE);

  if (0 == engine.id) {
    if (get_struct_field(options, "continue"))
    {
      ifnot (file_exists(options.output.filename))
      {
	if (ship.abort != NULL)
	{
	  vmessage("File '%s' does not exist. Aborting", options.output.filename);
	  ship.abort();
	}

	throw ReadError, sprintf("File '%s' does not exist", options.output.filename);
      }
      try (err) {
	options.output.open(engine);
      }
      catch AnyError:
      {
	if (ship.abort != NULL)
	  ship.abort();
	throw err.error, err.message; % forward error, make sure we aborted
      }
    }
    else
    {
      if (file_exists(options.output.filename) && not (options.clobber))
      {
	if (ship.abort != NULL && ship.abort != &NULL)
	{
	  vmessage("File '%s' exists. Refusing to overwrite.", options.output.filename);
	  ship.abort();
	}

	throw WriteError, sprintf("File '%s' exists.", options.output.filename);
      }
      try (err) {
	options.output.create(engine);
      }
      catch AnyError:
      {
	if (ship.abort != NULL && ship.abort != &NULL)
	  ship.abort();
	throw err.error, err.message; % forward error
      }
    }

    leader = engine.leader;

    % write initial walkers to buffer
    _for j (0, length(engine.walkers)-1) {
      leader.writeBuffer.walkers[j] = @(engine.walkers[j]);
      leader.writeBuffer.stat[j] = engine.stat[j];
      leader.writeBuffer.update[j] = 1;
    }

    % if we create new file write initial walkers to it
    ifnot (get_struct_field(options, "continue"))
      options.output.write(engine, engine.totalNumberWalkers);
  }
}
%}}}

private define emceeDefaultFile (file) %{{{
{
  variable default = "fits";
  if (NULL != file) {
    variable ext = path_extname(file);
    if (strlen(ext))
      return ext[[1:]];
  }

  return default;
}
%}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%
define emcee_hammer (steps)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{emcee_hammer}
%\synopsis{Explore parameter space with MCMC method}
%\usage{emcee_hammer (Int_Type);}
%#c%{{{
%\qualifiers{
%  \qualifier{Basic Qualifiers}{}
%  \qualifier{walkers}{[=10]: Number of walkers per parameter}
%  \qualifier{continue}{If given (and possible set to a file) continue chain from this file
%                         (using init="file", file="fits" per default)}
%  \qualifier{cont}{same as 'continue'}
%  \qualifier{infile}{Set the input file name for reading and continuing}
%  \qualifier{outfile}{Set the output file name}
%  \qualifier{clobber}{Ovwerwrite output file if exists}
%  \qualifier{Advanced Qualifiers}{}
%  \qualifier{init}{[="uniform" or "file"] The walker initialization method}
%  \qualifier{driver}{[="mpi"] The parallelization method}
%  \qualifier{step}{[="stretch"] The walker step algorithm}
%  \qualifier{input}{[="fits"] The file reading method}
%  \qualifier{output}{[="fits"] The file writing method}
%  \qualifier{progress}{="none"] Show progres}
%  \qualifier{urand}{[=&rand_uniform] PRNG for uniform numbers (Double_Type[] = urand(Int_Type))}
%  \qualifier{upick}{[=&rand_int] PRNG to chose complement walker (Int_Type[] = upick(Int_Type, Int_Type, Int_Type))}
%}
%
%\description
%  The MCMC parameter space exploration algorithm as described by
%  Foreman-Mackey et al. The function expects that data and a model is loaded.
%  The only input parameter gives the number of iterations the algorithm
%  performs. The resulting walker positions are written to a file which can
%  be set with the "outfile" qualifier.
%
%  The function allows to choose other algorithms for the step proposition,
%  the read and write routines and how the walker ensamble is initialized.
%  To get more information about the methods read 'help emcee_<method>'.
%
%  Per default a new chain is started when the function is called. To continue
%  a chain use the "continue" qualifier. If the intention is to continue a
%  previous chain, make sure the paremter ranges are set to the same values as
%  for the previous run. \code{emcee_hammer} always uses the current settings.
%
%  To set a prior for parameters use the \code{set_fit_constraint} interface.
%  This ensures that the stored fit values are according to the posterior
%  and not just the likelihood.
%
%\seealso{emcee--init, emcee--step, emcee--driver, emcee--input, emcee--file, emcee--progress}
%!%-
{
  % options
  variable oContinue = qualifier("continue", qualifier("cont"));
  variable oInfile = qualifier("infile", oContinue);
  variable oOutfile = qualifier("outfile", oContinue);
  variable oInread = emceeDefaultFile(oInfile);
  variable oOutwrite = emceeDefaultFile(oOutfile);

  % advanced options
  variable shipHandle, shipOption;
  % special case driver: If we are in an MPI environment use the MPI driver per default
#ifexists rcl_mpi_init
  (shipHandle, shipOption) = emceeOption(qualifier("driver", "mpi"));
#else
  (shipHandle, shipOption) = emceeOption(qualifier("driver", "serial"));
#endif

  variable stepHandle, stepOption;
  (stepHandle, stepOption) = emceeOption(qualifier("step", "stretch"));

  variable inputHandle, inputOption;
  (inputHandle, inputOption) = emceeOption(qualifier("input", oInread));
  if (NULL != oInfile) inputOption = struct { @inputOption, filename=oInfile };

  variable progressHandle, progressOption;
  (progressHandle, progressOption) = emceeOption(qualifier("progress", "none"));

  variable outputHandle, outputOption;
  (outputHandle, outputOption) = emceeOption(qualifier("output", oOutwrite));
  if (NULL != oOutfile) outputOption = struct { @outputOption, filename=oOutfile };

  variable totalNumberWalkers = qualifier("walkers", 10)*num_free_params();
  variable ship = @(EmceeShipRegister[shipHandle])(;;shipOption);
  emceeSetupEngine(ship, totalNumberWalkers, steps);

  variable Input = NULL, Output = NULL, Progress = NULL;
  variable Initfile = "uniform";
  if (0 == ship.engine.id) {
    Input = @(EmceeFileRegister[inputHandle])(;;inputOption);
    Output = @(EmceeFileRegister[outputHandle])(;;outputOption);
    Progress = @(EmceeProgressRegister[progressHandle])(;;progressOption);

    if (NULL == Input)
      throw UsageError, sprintf("Input handler '%s' is unknown'", inputHandle);
    if (NULL == Output)
      throw UsageError, sprintf("Output handler '%s' is unknown'", outputHandle);
    if (NULL == Progress)
      throw UsageError, sprintf("Progress handler '%s' is unknown'", progressHandle);

    if ( not (Input.has & EMCEE_FILE_READ)
	 || ( Input.read == &NULL ) )
      throw UsageError, sprintf("File handle '%s' can not be used for input", inputHandle);
    if ( not (Output.has & EMCEE_FILE_WRITE)
	 || ( Output.write == &NULL ) )
      throw UsageError, sprintf("File handle '%s' can not be used for output", outputHandle);

    ifnot (Input.has & EMCEE_FILE_RANGE)
      Initfile = "file";
  }

  variable initHandle, initOption;
  if (NULL != oInfile)
    (initHandle, initOption) = emceeOption(qualifier("init", Initfile));
  else
    (initHandle, initOption) = emceeOption(qualifier("init", "uniform"));

  variable options = @Struct_Type(["init", "step", "output", "input", "urand", "upick", "progress", "continue", "clobber"]);
  
  options.init = @(EmceeInitRegister[initHandle])(;;initOption);
  options.step = @(EmceeStepRegister[stepHandle])(;;stepOption);
  options.output = Output;
  options.input = Input;
  options.urand = qualifier("urand", &rand_uniform);
  options.upick = qualifier("upick", &rand_int);
  options.progress = Progress;
  set_struct_field(options, "continue", qualifier_exists("continue") || qualifier_exists("cont"););
  options.clobber = qualifier_exists("clobber") || qualifier_exists("overwrite");

  emceeSetupGears(ship.engine, options.urand, options.upick, options.step);

  emceeSetup(ship, steps, options);

  emceeLoop(ship, options.step, options.output);

  ship.enterHarbor();
}
%}}}
