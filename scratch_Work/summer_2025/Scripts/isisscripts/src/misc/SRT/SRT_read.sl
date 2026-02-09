define SRT_read()
%!%+
%\function{SRT_read}
%\synopsis{reads SRT data structures from a SRT .rad file}
%\usage{Struct_Type data[] = SRT_read(String_Type filename);}
%\qualifiers{
%\qualifier{verbose}{}
%\qualifier{onechunk}{read all data into one structure instead of an array
%                (default if file has no comments)}
%\qualifier{bins_to_cut}{[=8]: number of bad bins at high and low frequencies}
%\qualifier{position}{[lat,longw] position of the SRT
%                (default: lat=49.90 and longw=349.10)}
%}
%\seealso{SRT_spectrum, SRT_image}
%!%-
{
  variable filename = ();

  variable verbose = qualifier_exists("verbose");
  variable onechunk = qualifier_exists("onechunk");

  variable F = fopen(filename, "r");
  variable lines = fgetslines(F);
  ()=fclose(F);

  lines = lines[ onechunk ? [0, wherenot(array_map(Integer_Type, &string_match, lines, "^*"))]
		          : where(lines!="* ERROR communicating with radio\x0D\n")
	       ];
  variable nlines = length(lines);

  variable position = qualifier("position", [49.9, 349.1]);  % [lat, longw] @ Remeis

  variable lat, longw;
  if(   2!=sscanf(lines[0], "* STATION LAT= %f DEG LONGW= %f", &lat, &longw)
     || qualifier_exists("position") )
  {
    (lat, longw) = (position[0], position[1]);
  }

  variable i, nchunks=0;
  _for i (0, length(lines)-1, 1)
    if(lines[i][0] == '*')
      nchunks++;

  variable data = Struct_Type[max([1,nchunks])];
  variable ichunk = -1,  % index of current chunk
           n = 0;  % number of lines in current chunk
  variable tsys = NULL;
  _for i (0, nlines, 1)
    if(i<nlines && lines[i][0]!='*')
      n++;  % one more line belonging to current chunk
    else
    {
      % read tsys for this chunk or set it to previous
      if ((i < nlines) && string_match(lines[i], "tsys \\([0-9]+[.0-9]*\\)")) {
	variable pos, len;
	(pos, len) = string_match_nth (1);
	tsys = atof(lines[i][[pos:pos+len]]);
      }
      
      ichunk++;
      if(i<nlines || nchunks==0)  % start a new chunk
        data[ichunk] = struct { description=(i<nlines ? lines[i][[2:strlen(lines[i])-3]] : "no comment"),
				lat=lat, longw=longw,
				Y, D, H, M, S, MJD,
				az, el, azoff, eloff, RA, dec, glon, glat,
				f0, df, mode, nbins, spec, avflux,
				vLSR, tsys=tsys
			      };
      ifnot(nchunks)  ichunk++;  % pretend that another chunk was finished, since first chunk will never finish if file does not contain comments
      if(ichunk>0)
      { % allocate arrays for previous chunk (now that we know its length)
	data[ichunk-1].Y     = Short_Type [n];
	data[ichunk-1].D     = Short_Type [n];
	data[ichunk-1].H     = Char_Type  [n];
	data[ichunk-1].M     = Char_Type  [n];
	data[ichunk-1].S     = Char_Type  [n];
	data[ichunk-1].MJD   = Double_Type[n];

	data[ichunk-1].az    = Float_Type [n];
	data[ichunk-1].el    = Float_Type [n];
	data[ichunk-1].azoff = Float_Type [n];
	data[ichunk-1].eloff = Float_Type [n];
	data[ichunk-1].RA    = Float_Type [n];
	data[ichunk-1].dec   = Float_Type [n];
	data[ichunk-1].glon  = Float_Type [n];
	data[ichunk-1].glat  = Float_Type [n];

	data[ichunk-1].f0    = Float_Type [n];
	data[ichunk-1].df    = Float_Type [n];
	data[ichunk-1].mode  = Char_Type  [n];
	data[ichunk-1].nbins = UChar_Type [n];
	data[ichunk-1].spec  = Array_Type [n];
	data[ichunk-1].avflux= Float_Type [n];

	data[ichunk-1].vLSR  = Float_Type [n];
	if(verbose)  vmessage("chunk %2d: %4d lines after '%s'", ichunk-1, n, data[ichunk-1].description);
      }
      n = 0;
    }

  ichunk = nchunks>0 ? -1 : 0; % The previous version 'ichunk = -(nchunk>0)' caused an un-intended typecast to Char_Type
  i = 0;
  variable line, Y,D,H,M,S, az, el, azoff, eloff, f0, df, mode, nbins;
  foreach line (lines)
    ifnot(sscanf(line, "%d:%d:%d:%d:%d %f %f %f %f %f %f %d %d", &Y,&D,&H,&M,&S, &az, &el, &azoff, &eloff, &f0, &df, &mode, &nbins))
    {
      ichunk++;
      i = 0;
    }
    else
    {
      data[ichunk].Y     [i] = Y;
      data[ichunk].D     [i] = D;
      data[ichunk].H     [i] = H;
      data[ichunk].M     [i] = M;
      data[ichunk].S     [i] = S;
      variable MJD = 40587 + UTC2UNIXtime(Y, 1, 0, H, M, S)/86400. + D-1;  % 1970-01-01 = MJD 40587
      data[ichunk].MJD   [i] = MJD;

      data[ichunk].az    [i] = az;
      data[ichunk].el    [i] = el;
      data[ichunk].azoff [i] = azoff;
      data[ichunk].eloff [i] = eloff;

      variable RA, dec; (RA, dec) = RAdec_from_AzEl(az, el, MJD, longw, lat);
      data[ichunk].RA    [i] = RA;
      data[ichunk].dec   [i] = dec;
     (data[ichunk].glon  [i],
      data[ichunk].glat  [i]) = galLB_from_RAdec(RA, dec);

      data[ichunk].f0    [i] = f0;
      data[ichunk].df    [i] = df;
      data[ichunk].mode  [i] = mode;
      data[ichunk].nbins [i] = nbins;
      variable spec = array_map(Float_Type, &atof, strtok(line, " \x0D\n")[[9:]]);
      if(length(spec)<nbins)
	vmessage("spectrum has only %d bins, but expecting %d. Ignoring line:\n'%s'", length(spec), nbins, line);
      else
      {
	variable s = spec[[0:nbins-1]];
	data[ichunk].spec  [i] = s;
	variable bins_to_cut = qualifier("bins_to_cut", 8);
	data[ichunk].avflux[i] = mean(s[[bins_to_cut:nbins-1-bins_to_cut]]);

	data[ichunk].vLSR[i] = length(spec)>nbins ? spec[-1]
				                  : _NaN;
	i++;
      }
    }

  return onechunk || nchunks==0 ? data[0] : data;
}
