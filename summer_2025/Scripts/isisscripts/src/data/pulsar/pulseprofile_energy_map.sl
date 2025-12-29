% -*- mode: slang; mode: fold -*-

require("gsl","gsl"); 
require("xfig"); 
require("gcontour");
require("png");

% TODO
% - detailed help is missing for all functions!
%   add examples, for after-editing of plots as well
% - allow user phase-grids (code already done, but needs to be
%   activated once pfold accepts user phase-grids)
% - if two maps are provided (Struct_Type[2]?) to the plotting
%   routine, it will plot these side by side and skip showing
%   one map twice (one can plot a raw- vs. interpolated-map)
% - plotting routine allows mutiple maps for different
%   detectors (= energy ranges) to be given (List_Type?)
% - include energy shift (lag) of the spectra (y-direction) in
%   the xfig plot (qualifier e_lag)
% - put the color scale to the top of the plot if needed
% - adaptive energy grid
% - check spectrum interpolation (y-direction!): how to
%   interpolate a histogram properly? what about the edges?
% - instead of lag calculate relative difference to reference
%   like sum(abs(current/reference - 1))

%%%%%%%%%%%%%%%%%%%%%
define pulseprofile_energy_normalize()
%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{pulseprofile_energy_normalize}
%\synopsis{normalize a given pulse profile, spectrum, or pulseprofile-energy-map}
%\usage{Double_Type[] pulseprofile_energy_normalize(
%       Double_Type[] profile_or_spectrum,
%       String_Type method
%     );}
%\altusage{Double_Type[egrid,pgrid] pulseprofile_energy_normalize(
%          Double_Type[egrid,pgrid] map,
%          String_Type method,
%          Char_Type dimension
%          );}
%\description
%    A function to normalize either a 1D array representing a pulse profile or
%    spectrum, or a 2D pulse profile energy map. In the latter case the dimension
%    the normalization should apply to has to be specified, as the normalization
%    is performed in 1D, i.e., either for each phase normalize the energies
%    (dim = 'e') or for each energy normalize the pulse profile (dmi = 'p').
%    
%    Following normalization methods are available:
%
%       "sdev": Substracts the mean value and devides by the standard deviation:
%               isis> mom = moment( value );
%               isis> normvalue = ( value - mom.ave ) / mom.sdev;
%
%     "minmax": Substracts the min. value and deviedes by the min-max range.
%               isis> normvalue = ( value - min(value) ) / (max(value)-min(value));
%    
%\example
%\seealso{pulseprofile_energy_map}
%!%-
{
  variable value, method, dim = NULL;
  switch (_NARGS)
    { case 2: (value, method) = (); }
    { case 3: (value, method, dim) = (); }
    { help(_function_name); return; }

  value = COPY(value);
  variable shape = array_shape(value), tmp;
  switch (length(shape))
  % single array (profile or spectrum) given
  { case 1:
    switch (method)
    { case "sdev": 
      tmp = moment(value);
      return (value - tmp.ave) / tmp.sdev;
    }
    { case "minmax":
      return (value - min(value)) / (max(value)-min(value));
    }
    % { case "pfrac":
    % 	return (value - min(value)) / (max(value)-min(value));
    % }

    { vmessage("error(%s): method '%s' not known!", _function_name, method); return; }
  }
  % map given
  { case 2:
    variable i, idx, idy;
    dim = wherefirst(dim == ['p','e']);
    if (dim == NULL) { vmessage("error(%s): dimension has to be either 'p' oder 'e'", _function_name); return; }
    switch (method)
	    { case "sdev":
      _for i (0, shape[dim]-1, 1) {
	(idy, idx) = dim == 0 ? ([i],[*]) : ([*],[i]);
	tmp = moment(value[idy,idx]);
	value[idy,idx] = (value[idy,idx] - tmp.ave) / tmp.sdev;
      }
    }
    { case "minmax":
      _for i (0, shape[dim]-1, 1) {
        (idy, idx) = dim == 0 ? ([i],[*]) : ([*],[i]);
        value[idy,idx] = (value[idy,idx] - min(value[idy,idx])) / (max(value[idy,idx])-min(value[idy,idx]));
      }
    }
    { vmessage("error(%s): method '%s' not known!", _function_name, method); return; }    
  }
  % error
  { vmessage("error(%s): either single profile/spectrum nor map given!", _function_name); return; }

  return value;
} %}}}


%%%%%%%%%%%%%%%%%%%%%
define pulseprofile_energy_map(); % recursion needed for background calculation
define pulseprofile_energy_map()
%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{pulseprofile_energy_map}
%\synopsis{sorts the given events into a pulsephase-energy-histogram}
%\usage{Double_Type[egrid,phigrid] pfold_event_energy_map(
%      Double_Type[] events, energies, Double_Type pulse_period;
%      gti = Struct_Type, egrid = Struct_Type, pgrid = Struct_Type
%    );}
%\description
%\example
%\seealso{pfold}
%!%-
{
  variable events, energies, p0, backevts = NULL, backenerg = NULL;
  switch (_NARGS)
    { case 3: (events, energies, p0) = (); }
    { case 5: (events, energies, p0, backevts, backenerg) = (); }
    { help(_function_name); return; }

  % sanity checks
  if (typeof(events) != Array_Type || typeof(energies) != Array_Type) {
    vmessage("error(%s): 'events' and 'energies' have to be an array of doubles!", _function_name);
    return;
  }
  if (length(events) != length(energies)) {
    vmessage("error(%s): 'events' and 'energies' have to be of equal length!", _function_name);
  }
  
  % define energy grid
  variable e;
  variable egrid = qualifier("egrid", NULL);
  if (typeof(egrid) != Struct_Type) {
    e = typeof(egrid) == Integer_Type ? egrid : 16; % number of energy bins
    egrid = struct { bin_lo, bin_hi };
    (egrid.bin_lo, egrid.bin_hi) = log_grid(min(energies), max(energies), e);
  }

  % define phase grid
  variable pgrid = qualifier("pgrid", NULL);
  if (typeof(pgrid) != Struct_Type) {
    e = typeof(pgrid) == Integer_Type ? pgrid : 16; % number of phase bins
    pgrid = struct { bin_lo, bin_hi };
    (pgrid.bin_lo, pgrid.bin_hi) = linear_grid(0., 1., e);
  }

  % create pulse profile map
  variable map = Double_Type[length(egrid.bin_lo),length(pgrid.bin_lo)];
  variable countmap = @map; % total count map
  variable t0 = qualifier("t0", NULL);
  if (t0 == NULL) {
    t0 = events[0];
    vmessage("warning(%s): no reference time given, setting t0 = %f", _function_name, t0);
  }
  _for e (0, length(egrid.bin_lo)-1, 1) {
    variable nents = where(egrid.bin_lo[e] <= energies < egrid.bin_hi[e]);
    if (length(nents) > 1) {
      variable pp = pfold(
        events[where(egrid.bin_lo[e] <= energies < egrid.bin_hi[e])], p0;;
% once pfold can handle user phase grids      struct_combine(struct { t0 = t0, phigrid = pgrid }, __qualifiers)
        struct_combine(struct { t0 = t0, nbins = length(pgrid.bin_lo) }, __qualifiers)
      );
      map[e,*] = pp.value;
      countmap[e,*] = pp.value*pp.ttot; % total number of events in each pixel
    }
  }

  % initialize return structure
  variable ret = struct {
    map, counts, signalquality, egrid = egrid, pgrid = pgrid
  };

  ifnot (qualifier_exists("isbackground")) {
    % eventually calculate background map and subtract it
    if (backevts == NULL) {
      vmessage("!!!\n!!! warning(%s): please provide background events!\n!!!", _function_name);
    } else {
      variable backmap = pulseprofile_energy_map(
          backevts, backenerg, p0;; struct_combine(__qualifiers, struct {
          egrid = egrid, pgrid = pgrid, t0 = t0, isbackground
        })
      );
      ifnot (qualifier_exists("dontsubtract")) {
        map -= backmap.map;
        %countmap -= backmap.counts;
      }
      ret = struct_combine(ret, struct {
        backmap = backmap
      });
    }

    % calculate signal-to-noise (including background)
    ret.signalquality =
      (countmap - (backevts == NULL ? 0 : backmap.counts))
      / (backevts == NULL ? sqrt(countmap) : backmap.counts);
    
    % normalize
    variable norm = qualifier("norm", "sdev");
    variable dim = qualifier("normdim", 'p');
    if (norm != NULL) {
      map = pulseprofile_energy_normalize(map, norm, dim);
    }
  }
  ret.map = map;
  ret.counts = countmap;
  
  return ret;
} %}}}


%%%%%%%%%%%%%%%%%%%%%
define pulseprofile_energy_interpolate()
%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{pulseprofile_energy_interpolate}
%\synopsis{interpolates a pulsephase-energy-histogram to a finer grid}
%\usage{Double_Type[egrid*e_interp,phigrid*p_interp] pulseprofile_energy_interpolate(
%      Struct_Type map, Integer_Type p_interp, Integer_Type e_interp
%    );}
%\description
%\example
%\seealso{pulseprofile_energy_map}
%!%-
{
  variable map, p_interp, e_interp;
  switch (_NARGS)
    { case 3: (map,p_interp,e_interp) = (); }
    { help(_function_name); return; }

  variable p_ref = qualifier("p_ref", NULL);
  variable e_ref = qualifier("e_ref", NULL);
  
  variable shape, nmap = map.map, i, ngrid, tcmap, tsmap;
  % interpolate map - in phase direction
  if (p_interp > 1) {
    shape = array_shape(map.map);
    nmap = Double_Type[shape[0], shape[1]*p_interp];
    ngrid = struct {
      bin_lo = 1.*[0:shape[1]*p_interp-1] / (shape[1]*p_interp),
      bin_hi = 1.*[1:shape[1]*p_interp] / (shape[1]*p_interp),
    };		    
    _for i (0, shape[0]-1, 1) {
      nmap[i,*] = gsl->interp_cspline_periodic( % profile is periodic!
        .5*(ngrid.bin_lo + ngrid.bin_hi),
	.5*([map.pgrid.bin_lo[-1]-1,map.pgrid.bin_lo,map.pgrid.bin_lo[0]+1]+[map.pgrid.bin_hi[-1]-1,map.pgrid.bin_hi,map.pgrid.bin_hi[0]+1]),
	[map.map[i,-1], map.map[i,*], map.map[i,0]]
      );
    }
     % interpolat reference profile
    if (p_ref != NULL) {
      @p_ref = gsl->interp_cspline_periodic(
        .5*(ngrid.bin_lo + ngrid.bin_hi),
	.5*([map.pgrid.bin_lo[-1]-1,map.pgrid.bin_lo,map.pgrid.bin_lo[0]+1]+[map.pgrid.bin_hi[-1]-1,map.pgrid.bin_hi,map.pgrid.bin_hi[0]+1]),
	[(@p_ref)[-1], @p_ref, (@p_ref)[0]]
      );
    }
    map.map = nmap;
    map.pgrid = ngrid;

    % enlarge counts- and signalquality-maps
    tcmap = Double_Type[shape[0], shape[1]*p_interp]; tsmap = @tcmap;
    _for i (0, p_interp-1) {
      tcmap[*,[i::p_interp]] = map.counts;
      tsmap[*,[i::p_interp]] = map.signalquality;
    }
    map.counts = tcmap;
    map.signalquality = tsmap;
  }

  % interpolate map - in energy direction
  if (e_interp > 1) {
    shape = array_shape(map.map);
    variable l = shape[0]*e_interp-2;
    ngrid = gsl->interp_polynomial(
      1.*[0:l]/l,
      1.*[0:shape[0]-1]/(shape[0]-1),
      .5*(map.egrid.bin_lo+map.egrid.bin_hi)
    );
    ngrid = struct { bin_lo = ngrid[[:-2]], bin_hi = ngrid[[1:]] };
    nmap = Double_Type[l, shape[1]]; % l -> l+2 for edge extrapolation
    _for i (0, shape[1]-1, 1) {
      nmap[*,i] = gsl->interp_linear( % spectrum is non-periodic (it better is!)
        .5*(ngrid.bin_lo + ngrid.bin_hi), % [*,i] -> [1:l],i for edge extrapolation
        .5*(map.egrid.bin_lo + map.egrid.bin_hi),
     	map.map[*,i]
      );
      % % extrapolate edges (either: edge raw flux half, or: missing edge flux)
      % variable totraw = sum(map.map[*,i]*(map.egrid.bin_hi-map.egrid.bin_lo));
      % variable totint = sum(nmap[[1:l],i]*(ngrid.bin_hi-ngrid.bin_lo));
      % variable left  = [
      % 	map.map[0,i]*(map.egrid.bin_hi[0]-map.egrid.bin_lo[0])/2,
      %   map.map[0,i]*(map.egrid.bin_hi[0]-map.egrid.bin_lo[0])-nmap[1,i]*(ngrid.bin_hi[0]-ngrid.bin_lo[0])
      % ];
      % variable right = [
      % 	map.map[-1,i]*(map.egrid.bin_hi[-1]-map.egrid.bin_lo[-1])/2,
      % 	map.map[-1,i]*(map.egrid.bin_hi[-1]-map.egrid.bin_lo[-1])-nmap[-2,i]*(ngrid.bin_hi[-1]-ngrid.bin_lo[-1])
      % ];
      % % which method results in better flux conversation?
      % variable w = where_min(abs(totraw - (totint+left+right)));
      % totint += (left[w]+right[w]);
      % nmap[0,i]  = left[w];
      % nmap[-1,i] = right[w];
      % % vmessage("warning(%s): interpolated flux differs by %.3f%%", _function_name, (totint/totraw-1)*100);
    }
    % add bins at the edges
    % ngrid.bin_lo = [map.egrid.bin_lo[0], ngrid.bin_lo, ngrid.bin_hi[-1]];
    % ngrid.bin_hi = [ngrid.bin_lo[1], ngrid.bin_hi, map.egrid.bin_hi[-1]];
    % % correct bin integrated flux in edges
    % nmap[0,*]  /= (ngrid.bin_hi[0] -ngrid.bin_lo[0] );
    % nmap[-1,*] /= (ngrid.bin_hi[-1]-ngrid.bin_lo[-1]);
    
    % interpolat reference spectrum
    if (e_ref != NULL) {
      @e_ref = gsl->interp_cspline(
        .5*(ngrid.bin_lo + ngrid.bin_hi),
        .5*(map.egrid.bin_lo + map.egrid.bin_hi),
    	@e_ref
      );
    }
    map.map = nmap;
    map.egrid = ngrid;

    % enlarge counts- and signalquality-maps
    tcmap = Double_Type[shape[0]*e_interp, shape[1]]; tsmap = @tcmap;
    _for i (0, e_interp-1, 1) {
      tcmap[[i::e_interp],*] = map.counts;
      tsmap[[i::e_interp],*] = map.signalquality;
    }
    map.counts = tcmap[[1:l],*]; % remove for edge extrapolation
    map.signalquality = tsmap[[1:l],*]; % remove for edge extrapolation
  }
  
  return map;
} %}}}


%%%%%%%%%%%%%%%%%%%%%
define pulseprofile_energy_lag()
%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{pulseprofile_energy_lag}
%\synopsis{calculates a lag (=shift) in a pulsephase-energy-histogram}
%\usage{Double_Type[] pulseprofile_energy_lag(
%      Struct_Type map, 'p' or 'e'[, Double_Type[] reference]
%    );}
%\description
%\example
%\seealso{pulseprofile_energy_map, CCF_1d}
%!%-
{
  variable map, dim, ref = NULL;
  switch (_NARGS)
    { case 2: (map,dim) = (); }
    { case 3: (map,dim,ref) = (); }
    { help(_function_name); return; }

  dim = wherefirst(dim == ['p','e']);
  if (dim == NULL) { vmessage("error(%s): dimension has to be either 'p' oder 'e'", _function_name); return; }

  % collapse map to get the reference (average pulse profile or spectrum)
  variable i;
  if (ref == NULL) {
    vmessage("warning (%s): no reference given, collapsing map", _function_name);
    ref = Double_Type[length(dim == 0 ? map.map[0,*] : map.map[*,0])]; 
    _for i (0, length(ref)-1, 1) {
      ref[i] = sum(dim == 0 ? map.map[*,i] : map.map[i,*]);
    }
  } else { ref = COPY(ref); }

  % shift rerence to avoid jumping around phase 0
  variable sh = qualifier("shift", .5);
  sh = int(length(ref)*sh);
  ref = shift(ref, sh);
  
  % calculate lag
  variable lag = Double_Type[length(dim == 0 ? map.map[*,0] : map.map[0,*])], ccf;
  _for i (0, length(lag)-1, 1) {
    ccf = CCF_1d(dim == 0 ? map.map[i,*] : map.map[*,i], ref);
    lag[i] = mean(where_max(ccf));
  }
  lag = 1.*lag/length(ccf) - 1.*sh/length(ref);

  return struct {
    bin_lo = dim == 0 ? map.egrid.bin_lo : map.pgrid.bin_lo,
    bin_hi = dim == 0 ? map.egrid.bin_hi : map.pgrid.bin_hi,
    lag    = lag
  };
} %}}}


%%%%%%%%%%%%%%%%%%%%%
define xfigplot_pulseprofile_energy_map()
%%%%%%%%%%%%%%%%%%%%% %{{{
%!%+
%\function{xfigplot_pulseprofile_energy_map}
%\synopsis{returnes an Xfig plot object containing the pulse-profile-energy-map}
%\usage{Xfig_Object xfigplot_pulseprofile_energy_map(Struct_Type map);}
%\description
%  Struct_Type map = struct{
%     pgrid = struct{ bin_lo = Double_Type[np],
%                     bin_hi = Double_Type[np]
%                   },
%     egrid = struct{ bin_lo = Double_Type[ne],
%                     bin_hi = Double_Type[ne]
%                   },
%     map = Double_Type[ne,np]
%  };
%     
%\example
%\seealso{pulseprofile_energy_map}
%!%-
{
  variable map;
  switch (_NARGS)
    { case 1: (map) = (); }
    { help(_function_name); return; }
  
  variable plag = qualifier("p_lag", NULL),
           elag = qualifier("e_lag", NULL);

  % renorm map
  variable nmap = COPY(map.map);
  variable scalefun = qualifier("scalefun", NULL);
  variable l;
  if (scalefun != NULL) {
    nmap = (@scalefun)(nmap);
    if (struct_field_exists(__qualifiers, "gmin")) {
      __qualifiers.gmin = (@scalefun)([__qualifiers.gmin,map.map])[0];
    }
    if (struct_field_exists(__qualifiers, "gmax")) {
      __qualifiers.gmax = (@scalefun)([__qualifiers.gmax,map.map])[0];
    }
  }
  
  % convert the map (with a known grid) into an image (which has pixels
  % and thus has a *linear* grid by definition) -> we need a fine pixel
  % grid and we have to lookup the color in the original grid.

  % TODO: do that for the signalquality-map as well!
  variable fine   = qualifier("fineness", 10);
  variable shape  = array_shape(nmap)*fine;
  variable pixmap = Double_Type[__push_array(shape)];
  variable pixqual = @pixmap; % fine grid for signalquality
  variable pixgrid = struct { % grid of the pixels
    p = struct { bin_lo, bin_hi }, % pulse phase (always linear here!)
    e = struct { bin_lo, bin_hi }  % energy      (either linear or logarithmic)
  };
  (pixgrid.p.bin_lo, pixgrid.p.bin_hi) = linear_grid(
    map.pgrid.bin_lo[0], map.pgrid.bin_hi[-1], shape[1]
  );
  (pixgrid.e.bin_lo, pixgrid.e.bin_hi) = (@(qualifier_exists("lin") ? &linear_grid : &log_grid))(
    map.egrid.bin_lo[0], map.egrid.bin_hi[-1], shape[0]
  );
  variable x,y,ix,iy;
  _for y (0, shape[0]-1, 1) _for x (0, shape[1]-1, 1) {
    ix = wherefirst(map.egrid.bin_lo <= .5*(pixgrid.e.bin_lo[y]+pixgrid.e.bin_hi[y]) <= map.egrid.bin_hi);
    iy = wherefirst(map.pgrid.bin_lo <= .5*(pixgrid.p.bin_lo[x]+pixgrid.p.bin_hi[x]) <= map.pgrid.bin_hi);
    pixmap[y,x] = nmap[ix,iy];
  }

  % show profile twice
  nmap = Double_Type[shape[0],shape[1]*2];
  nmap[*,[:shape[1]-1]] = pixmap;
  nmap[*,[shape[1]:]]   = pixmap;

  % initialize xfig-plot
  variable W = qualifier("W", 14);
  variable H = qualifier("H", 10);
  variable xlabel = qualifier("xlabel", "Pulse Phase $\varphi$"R );
  variable ylabel = qualifier("ylabel", "Energy (keV)" );
  
  variable pl = xfig_plot_new(W,H);
  pl.xlabel(xlabel);
  pl.ylabel(ylabel);
  pl.world(0, 2, map.egrid.bin_lo[0], map.egrid.bin_hi[-1]);
  ifnot (qualifier_exists("lin")) { pl.yaxis(;log); pl.y2axis(; ticlabels = 0); }
  variable tics = [0,.5,1.0,1.5], ticl = COPY(tics); ticl[where(ticl > 1)] -= 1;
  pl.x2axis(; major = tics, minor = tics+.25, ticlabels = 0,
    major_color = "white", minor_color = "white");
  pl.x1axis(; major = tics, minor = tics+.25, ticlabels = array_map(
    String_Type, &sprintf, "%.1f", ticl
  ));
  % plot the map
  pl.plot_png(nmap;; struct_combine(struct { depth = 100 }, __qualifiers));
  if (qualifier_exists("plotegrid")) {
    _for l (1, length(map.egrid.bin_lo)-1, 1) {
      pl.plot([0,2], [1,1]*map.egrid.bin_lo[l]; color = "white", line = 1);
    }
  }

  %%% SIGNALQUALITY
  % plot a boarder where the signalquality drops below a certain value
  if( qualifier_exists("snthres") ){
    variable snthres = qualifier("snthres",5);
    variable sncols = qualifier("sncols","darkgreen");

    variable snshape  = array_shape(map.signalquality);
    variable snmap = Double_Type[snshape[0],snshape[1]*2];
    snmap[*,[:snshape[1]-1]] = map.signalquality;
    snmap[*,[snshape[1]:]]   = map.signalquality;

    variable sncont   = gcontour_compute( snmap, snthres );

    variable n,i;
    _for n ( 0, length(sncont)-1 ){
      _for i ( 0, length(sncont[n].x_list)-1 ){
	x = sncont[n].x_list[i]/(snshape[1]*2.);
	y = sncont[n].y_list[i]/snshape[0];

	pl.plot( x, y;
		 world00, width=3, depth = 98,
		 color=[sncols][length([sncols])==length(sncont)? n : 0],
		 line=length(sncont)-n-1
	       );
	pl.plot( x, y; world00, width=1, depth = 99 );

      }
    }
  }

  % color scale
  variable cmap_fsize = qualifier("cmapfontsize","scriptsize");
  variable pc = xfig_plot_new(0.333*W, 0.05*H);
  l = length(png_get_colormap(qualifier("cmap", "gray")));
  pc.world(min(map.map),max(map.map),0,1);
  pc.yaxis(; major = 0, minor = 0);
  pc.x1axis(; ticlabel_size = cmap_fsize,maxtics=5);
  pc.x2axis(; major_color = "white", minor_color = "white", ticlabels = 0);
  if (qualifier_exists("cmap_label")) {
    pc.x2label(qualifier("cmap_label"); size = cmap_fsize);
  }
  variable s = [min(map.map):max(map.map):#l];
  if (scalefun != NULL) { s = (@scalefun)(s); }
  pc.plot_png(_reshape(s, [1,l]);;
    struct_combine(struct { depth = 96 }, __qualifiers )
  );
  % draw a white box behind the color scale
  variable x1,x2,y1,y2,x0,y0;
  (x1,x2,y1,y2,,) = pc.get_bbox();
  variable bord = (x2-x1)*.03;
  variable box = xfig_new_rectangle(x2-x1+2*bord, y2-y1+2*bord);
  box.set_area_fill(20); box.set_fill_color("white");
  box.set_depth(97);
  box.translate(vector(x1-bord, y1-bord, 0.));
  pc.add_object(box);
  pl.add_object(pc, .93, .05, .5, -.5; world0);

  % phase lag
  if (plag != NULL) {
    % histogram values in y-direction
    plag = struct_combine(plag, struct { nlag = Double_Type[length(plag.bin_lo)*2], e = Double_Type[length(plag.bin_lo)*2] });
    _for l (0, length(plag.lag)-1, 1) {
      plag.nlag[[2*l,2*l+1]] = [1,1]*plag.lag[l];
      plag.e[[2*l,2*l+1]] = [plag.bin_lo[l], plag.bin_hi[l]];
    }
    % plot
    pc = xfig_plot_new(0.15*W, H);
    pc.world(min(plag.lag), max(plag.lag), plag.bin_lo[0], plag.bin_hi[-1];;
      struct_combine(struct { padx = .15 }, qualifier_exists("lin") ? NULL : struct { ylog })
    );
    pc.xlabel("$\Delta \varphi$"R);
    pc.plot(plag.nlag, plag.e); 
    pc.y1axis(; ticlabels = 0); 
    pc.translate(vector(W,0,0));
    pl.add_object(pc);
  }
  
  return pl;
} %}}}

