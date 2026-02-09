require("curl");
require("expat");
require("pcre");


% Accessing http://plpsipp1v.stsci.edu/cgi-bin/ps1cutouts via curl, parsing
% the output and dowloading the images. The usage of the exposed function
% is supposed to mimic the usage of the gui available on the page itself

% After I wrote this entire mechanism I discovered that there is additional
% information about an easier API in the lower sections on
% https://outerspace.stsci.edu/display/PANSTARRS/PS1+Image+Cutout+Service
% but well ...

% The base URL of the page itself
private variable __panstarrsBase = "http://ps1images.stsci.edu/cgi-bin/ps1cutouts";

% The following three variable represent the options available on the page
% They can be used as options in the URL
private variable __panstarrsFilters = ["g", "r", "i", "z", "y"];
private variable __panstarrsFiletypes = ["stack", "warp"];
private variable __panstarrsAuxiliary = ["data", "mask", "wt", "exp", "expwt", "num"];

% Pixel scale in "/px
private variable __panstarrsScale = 0.25;

% Irrelevant for the curl based query, but has to be set
private variable __panstarrsOutputSize = 256;
private variable __panstarrsVerbose = 0;
private variable __panstarrsAutoscale = 99.5;

% Callback for curl data retrieval
% Just appends the data which is supposed to be a BString to the string
% ref is pointing to
private define __panstarrsDownloadCallback(ref, data) {
  @ref += data;
  return strlen(data) + 1;
}

% Callback for durl cata retrieven
% Write the content to a filepointer
private define __panstarrsDownloadWriteCallback(ref, data) {
  if ( -1 == fwrite(data, @ref) ) {
    variable errsv = errno;
    throw RunTimeError, sprintf("Error writing to file: %s", errno_string(errsv));
  }
  return strlen(data) + 1;
}

% Pick the qualifiers apart to get the valid options for the query
private define __panstarrsGetOptions(pos, size) {
  variable filters = {}, fileTypes = {}, auxiliaries = {};
  variable filter, fileType, auxiliary;

  if ( qualifier_exists("color") ) {
    throw UsageError, "Combined color images can not be downloaded";
  }

  foreach filter(__panstarrsFilters) {
    if ( qualifier_exists(filter) ) {
      list_append(filters, filter);
    }
  }
  !if (length(filters)) {
    throw UsageError, "At least one filter is required for PanSTARRS image queries";
  }

  foreach fileType(__panstarrsFiletypes) {
    if ( qualifier_exists(fileType) ) {
      list_append(fileTypes, fileType);
    }
  }
  !if ( length(fileTypes) ) {
    throw UsageError, "At least one file type is required for PanSTARRS image queries" +
      "\n(did you mean \"stack\"?)";
  }

  foreach auxiliary(__panstarrsAuxiliary) {
    if ( qualifier_exists(auxiliary) ) {
      list_append(auxiliaries, auxiliary);
    }
  }
  !if ( length(auxiliaries) ) {
    throw UsageError, "At least one auxiliary type is required for PanSTARRS image queries" +
      "\n(did you mean \"data\"?)";
  }
  return (filters, fileTypes, auxiliaries);
}

%!%+
%\function{__assemblePanstarrsUrl}
%\synopsis{Assemble a URL for the PanSTARRS image cutout server}
%\usage{String_Type __assemblePanstarrsUrl(String_Type position, Integer_Type size)}
%\description
%    position is either a set of coordinates of the form "ra+/-dec"
%    (e.g. "124.45+34") or a string which is used by the cutout server itself
%    to perform a simbad query.
%    size is the pixel number along the edge of the square image.
%    The qualifiers for the function are the set of options for filter, filetype,
%    and auxiliary data given in __panstarrsFilters, __panstarrsFiletypes, and
%    __panstarrsAuxiliary
%!%-
private define __assemblePanstarrsUrl(pos, size, filters, fileTypes, auxiliaries) {
  variable options;
  variable filter, fileType, auxiliary;

  options = {
    sprintf("pos=%s", pos),
    sprintf("size=%d", size),
    sprintf("output_size=%d", __panstarrsOutputSize),
    sprintf("verbose=%d", __panstarrsVerbose),
    sprintf("autoscale=%f", __panstarrsAutoscale),
    "catlist="
  };
  foreach filter(filters) {
    list_append(options, sprintf("filter=%s", filter));
  }
  foreach fileType(fileTypes) {
    list_append(options, sprintf("filetypes=%s", fileType));
  }
  foreach auxiliary(auxiliaries) {
    list_append(options, sprintf("auxiliary=%s", auxiliary));
  }
  options = list_to_array(options);
  return __panstarrsBase + "?" + strjoin(options, "&");
}

%!%+
%\function{__panstarrsRetrieveSite}
%\synopsis{Download a html page of the PanSTARRS cutout server}
%\usage{String_Type __panstarrsRetrieveSite(String_Type URL)}
%\description
%    Simply takes a url and downloads the html content of the site using curl,
%    returning it as a string. Throws an exception upon error.
%!%-
private define __panstarrsRetrieveSite(url) {
  variable c = curl_new(url);
  variable str = "";
  curl_setopt(c, CURLOPT_WRITEFUNCTION, &__panstarrsDownloadCallback, &str);
  curl_perform(c);
  return str;
}

% XML parser character handler
private define __panstarrsXMLCharHandler(p, data) {
  p.userdata.currentText = data;

  % we just entered a new image section in the table
  if ( p.userdata.currentElement == "th" ) {
    % Store the name of the current image (e.g. stack 2469.010 g, ...)
    p.userdata.currentThing = data;
  }
}

% XML parser start element handler
private define __panstarrsXMLStartElementHandler(p, element, attrs) {
  variable ind;
  p.userdata.currentElement = element;
  p.userdata.currentAttrs = attrs;

  % Array of struct -> struct of array
  attrs = struct {
    names = array_map(String_Type, &get_struct_field, attrs, "name"),
    values = array_map(String_Type, &get_struct_field, attrs, "value")
  };
  ind = where(attrs.names == "title");
  variable titleAttrs = struct_filter(attrs, ind; copy);
  ind = where(titleAttrs.values == "Download FITS cutout");
  !if ( length(ind) ) {
    % Here is not a fits cutout
    % Important: There are no colored cutouts available, only single band images
    return;
  }
  if ( length(ind) > 1 ) {
    % Two "Download FITS cutout" in one table entry, that's very wrong
    throw DataError, "Found multiple cutouts for one image";
  }
  ind = where(attrs.names == "href");
  variable key = p.userdata.currentThing;
  if ( assoc_key_exists(p.userdata.images, key) ) {
    throw DataError, "Found multiple images for " + key;
  }
  p.userdata.images[key] = attrs.values[ind[0]];
}

% Insert a stack only match
private define __panstarrsInsertStackMatch(assoc, col, url) {
  !if ( assoc_key_exists(assoc, "stack") ) {
    assoc["stack"] = Assoc_Type[Assoc_Type];
  }
  !if ( assoc_key_exists(assoc["stack"], "colors") ) {
    assoc["stack"]["colors"] = Assoc_Type[String_Type];
  }
  assoc["stack"]["colors"][col] = url;
}

% Insert a stack and auxiliary data match
private define __panstarrsInsertStackAuxMatch(assoc, aux, col, url) {
  !if ( assoc_key_exists(assoc, "stack") ) {
    assoc["stack"] = Assoc_Type[Assoc_Type];
  }
  !if ( assoc_key_exists(assoc["stack"], "aux") ) {
    assoc["stack"]["aux"] = Assoc_Type[Assoc_Type];
  }
  !if ( assoc_key_exists(assoc["stack"]["aux"], aux) ) {
    assoc["stack"]["aux"][aux] = Assoc_Type[String_Type];
  }
  assoc["stack"]["aux"][aux][col] = url;
}

% Insert a warp only match
private define __panstarrsInsertWarpMatch(assoc, col, field, url) {
  !if ( assoc_key_exists(assoc, "warp") ) {
    assoc["warp"] = Assoc_Type[Assoc_Type];
  }
  !if ( assoc_key_exists(assoc["warp"], "colors") ) {
    assoc["warp"]["colors"] = Assoc_Type[Assoc_Type];
  }
  !if ( assoc_key_exists(assoc["warp"]["colors"], col) ) {
    assoc["warp"]["colors"][col] = Assoc_Type[String_Type];
  }
  assoc["warp"]["colors"][col][field] = url;
}

% Insert a warp and auxiliary data match
private define __panstarrsInsertWarpAuxMatch(assoc, aux, col, field, url) {
  !if ( assoc_key_exists(assoc, "warp") ) {
    assoc["warp"] = Assoc_Type[Assoc_Type];
  }
  !if ( assoc_key_exists(assoc["warp"], "aux") ) {
    assoc["warp"]["aux"] = Assoc_Type[Assoc_Type];
  }
  !if ( assoc_key_exists(assoc["warp"]["aux"], aux) ) {
    assoc["warp"]["aux"][aux] = Assoc_Type[Assoc_Type];
  }
  !if ( assoc_key_exists(assoc["warp"]["aux"][aux], col) ) {
    assoc["warp"]["aux"][aux][col] = Assoc_Type[String_Type];
  }
  assoc["warp"]["aux"][aux][col][field] = url;
}

% Parse the names of the images and sort the accordingly
% The names are named according to this scheme:
%
% stack \d+\.\d+ (g|i|r|y|z)
% stack\.(exp|expwt|mask|num|wt) \d+\.\d+ (g|i|r|y|z)
% warp \d+\.\d+ (g|i|r|y|z) \d+\.\d+
% warp.(mask|wt) \d+\.\d+ (g|i|r|y|z) \d+\.\d+
%
% where the first \d+\.\d+ should always have the same values but the second
% \d+\.\d+ for the warps can differ and give a lot of results. Due to this reason
% the first sets of digits will be removed but the second one will stay.
% The regex for the colors and the auxiliary types is assembled dynamically from
% __panstarrsFilters and __panstarrsAuxiliary
% Returns an assoc of the form:
%assoc
%├── stack
%│   ├── aux
%│   │   ├── exp
%│   │   │   ├── g=url
%│   │   │   ├── ...
%│   │   ├── expwt
%│   │   │   ├── g=url
%│   │   │   ├── ...
%│   │   ├── mask
%│   │   │   ├── g=url
%│   │   │   ├── ...
%│   │   ├── num
%│   │   │   ├── g=url
%│   │   │   ├── ...
%│   │   └── wt
%│   │       ├── g=url
%│   │       ├── ...
%│   └── colors
%│       ├── g=url
%│       ├── ...
%└── warp
%    ├── aux
%    │   ├── mask
%    │   │   ├── g
%    │   │   │   └── 55275.32206=url
%    │   │   ├── i
%    │   │   │   └── 57035.57214=url
%    │   │   ├── r
%    │   │   │   └── 56303.54493=url
%    │   │   ├── y
%    │   │   │   └── 55903.56165=url
%    │   │   └── z
%    │   │       └── 55932.46071=url
%    │   └── wt
%    │       ├── g
%    │       │   └── 55275.32281=url
%    │       ├── i
%    │       │   └── 57035.57214=url
%    │       ├── r
%    │       │   └── 55268.34759=url
%    │       ├── y
%    │       │   └── 55903.57351=url
%    │       └── z
%    │           └── 56618.57846=url
%    └── colors
%        ├── g
%        │   ├── 55238.43916=url
%        │   ├── ...
%        ├── i
%        │   ├── 55259.45618=url
%        │   ├── ...
%        ├── r
%        │   ├── 55268.33816=url
%        │   ├── ...
%        ├── y
%        │   ├── 55521.60728=url
%        │   ├── ...
%        └── z
%            ├── 55546.50549=url
%            ├── ...
%#p-
%#v-
% Where all nodes are Assoc_Type[Assoc_Type] except each deepst leave which is
% an Assoc_Type[String_Type]. Note that not all of the branches might be there,
% depending on what has been asked for to query and what is actually available
private define __panstarrsSortUrls(urls) {
  variable names = assoc_get_keys(urls), name;
  variable colorCaptureRegex = "(" + strjoin(__panstarrsFilters, "|") + ")";
  variable auxCaptureRegex = "(" + strjoin(__panstarrsAuxiliary, "|") + ")";
  variable numDotNumCaptureRegex = `(\d+\.\d+)`;
  variable stackRegexStr = "^" + strjoin(["stack", numDotNumCaptureRegex,
      colorCaptureRegex], `\s+`) + "$";
  variable stackAuxRegexStr = "^" + strjoin(["stack\." + auxCaptureRegex,
      numDotNumCaptureRegex, colorCaptureRegex], `\s+`) + "$";
  variable warpRegexStr = "^" + strjoin(["warp", numDotNumCaptureRegex,
      colorCaptureRegex, numDotNumCaptureRegex], `\s+`) + "$";
  variable warpAuxRegexStr = "^" + strjoin(["warp\." + auxCaptureRegex,
      numDotNumCaptureRegex, colorCaptureRegex, numDotNumCaptureRegex], `\s+`) + "$";
  variable stackRegex = pcre_compile(stackRegexStr);
  variable stackAuxRegex = pcre_compile(stackAuxRegexStr);
  variable warpRegex = pcre_compile(warpRegexStr);
  variable warpAuxRegex = pcre_compile(warpAuxRegexStr);
  variable colorName, auxName, fieldName;
  variable ret = Assoc_Type[Assoc_Type];
  foreach name(names) {
    if ( pcre_exec(stackRegex, name ) ) {
      colorName = pcre_nth_substr(stackRegex, name, 2);
      __panstarrsInsertStackMatch(ret, colorName, urls[name]);
    } else if ( pcre_exec(stackAuxRegex, name) ) {
      auxName = pcre_nth_substr(stackAuxRegex, name, 1);
      colorName = pcre_nth_substr(stackAuxRegex, name, 3);
      __panstarrsInsertStackAuxMatch(ret, auxName, colorName, urls[name]);
    } else if ( pcre_exec(warpRegex, name) ) {
      colorName = pcre_nth_substr(warpRegex, name, 2);
      fieldName = pcre_nth_substr(warpRegex, name, 3);
      __panstarrsInsertWarpMatch(ret, colorName, fieldName, urls[name]);
    } else if ( pcre_exec(warpAuxRegex, name) ) {
      auxName = pcre_nth_substr(warpAuxRegex, name, 1);
      colorName = pcre_nth_substr(warpAuxRegex, name, 3);
      fieldName = pcre_nth_substr(warpAuxRegex, name, 4);
      __panstarrsInsertWarpAuxMatch(ret, auxName, colorName, fieldName, urls[name]);
    } else {
      vmessage("Warning: Skipping unrecognized image type: %s", name);
    }
  }
  return ret;
}

%!%+
%\function{__parsePanstarrsPage}
%\synopsis{Parse the html of a PanSTARRS cutout server page}
%\usage{Assoc_Type __parsePanstarrsPage(String_Type html)}
%\description
%    Takes the result of __panstarrsRetrieveSite() and parses it in order to
%    determine which images are available and what their specific download
%    URLs are
%!%-
private define __parsePanstarrsPage(str) {
  variable _lines = strsplit(str, "\n");
  variable n = length(_lines);
  variable newstr = "";
  variable ii = 0;

  % Remove the javascript section as it contains invalid XML, e.g. i<inputs.length;
  while ( ii<n ) {
    if ( _lines[ii] == "<script type=\"text/javascript\">" ) {
      while ( _lines[ii] != "</script>" ) {
	ii++;
      }
      ii++;
    }
    newstr += _lines[ii] + "\n";
    ii++;
  }

  % Escape the &
  newstr = strreplace(newstr, "&", "&#038;");

  variable xmlp = xml_new();
  xmlp.userdata = struct {
    images = Assoc_Type[String_Type],
    currentElement,
    currentAttrs,
    currentText,
    currentThing
  };
  xmlp.startelementhandler = &__panstarrsXMLStartElementHandler;
  xmlp.characterdatahandler = &__panstarrsXMLCharHandler;
  xml_parse(xmlp, newstr, 0);
  variable urls = xmlp.userdata.images;
  variable key;
  foreach key(assoc_get_keys(urls)) {
    % Replace the escaped &'s with actual &'s
    variable url = strreplace(urls[key], "&amp;", "&");
    % The resulting URL's have leading // but no http:, so add it
    urls[key] = "http:" + url;
  }
  variable keys = assoc_get_keys(urls);
  return __panstarrsSortUrls(urls);
}

% Download a file from a url and save it as fname
private define __panstarrsDownloadFile(url, fname) {
  if ( stat_file(fname) != NULL ) {
    throw RunTimeError, sprintf("File %s already exists", fname);
  }
  !if ( qualifier_exists("quiet") ) {
    vmessage("Downloading as %s: %s", fname, url);
  }
  variable fptr = fopen(fname, "w");
  if ( fptr == NULL ) {
    variable errsv = errno;
    throw RunTimeError, sprintf("Error opening %s for writing: %s", fname, errno_string(errsv));
  }
  variable c = curl_new(url);
  curl_setopt(c, CURLOPT_WRITEFUNCTION, &__panstarrsDownloadWriteCallback, &fptr);
  curl_perform(c);
  if ( -1 == fclose(fptr) ) {
    throw RunTimeError, sprintf("Error closing file %s: %s", fname, errno_string(errsv));
  }
}

% Download all found stacks
private define __panstarrsDownloadStacks(urls, outdir, colors, assoc) {
  variable filter;
  !if ( assoc_key_exists(urls, "stack") ) {
    return;
  }
  !if ( assoc_key_exists(urls["stack"], "colors") ) {
    return;
  }
  foreach filter(colors) {
    !if ( assoc_key_exists(urls["stack"]["colors"], filter) ) {
      continue;
    }
    variable outfile = sprintf("%sstack_%s.fits", outdir, filter);
    __panstarrsDownloadFile(urls["stack"]["colors"][filter], outfile;; __qualifiers);
    __panstarrsInsertStackMatch(assoc, filter, outfile);
  }
}

% Download all found auxiliary stacks
private define __panstarrsDownloadStacksAux(urls, outdir, auxiliaries, colors, assoc) {
  variable aux, filter;
  !if ( assoc_key_exists(urls, "stack") ) {
    return;
  }
  !if ( assoc_key_exists(urls["stack"], "aux") ) {
    return;
  }
  foreach aux(auxiliaries) {
    !if ( assoc_key_exists(urls["stack"]["aux"], aux) ) {
      continue;
    }
    foreach filter(colors) {
      !if ( assoc_key_exists(urls["stack"]["aux"][aux], filter) ) {
	continue;
      }
      variable outfile = sprintf("%sstack_%s_%s.fits", outdir, aux, filter);
      __panstarrsDownloadFile(urls["stack"]["aux"][aux][filter], outfile;; __qualifiers);
      __panstarrsInsertStackAuxMatch(assoc, aux, filter, outfile);
    }
  }
}

% Download all found warps
private define __panstarrsDownloadWarps(urls, outdir, colors, assoc) {
  variable filter, field;
  !if ( assoc_key_exists(urls, "warp") ) {
    return;
  }
  !if ( assoc_key_exists(urls["warp"], "colors") ) {
    return;
  }
  foreach filter(colors) {
    !if ( assoc_key_exists(urls["warp"]["colors"], filter) ) {
      continue;
    }
    foreach field(assoc_get_keys(urls["warp"]["colors"][filter])) {
      variable outfile = sprintf("%swarp_%s_%s.fits", outdir, filter, field);
      __panstarrsDownloadFile(urls["warp"]["colors"][filter][field], outfile;; __qualifiers);
      __panstarrsInsertWarpMatch(assoc, filter, field, outfile);
    }
  }
}

% Download all found warp auxiliaries
private define __panstarrsDownloadWarpsAux(urls, outdir, auxiliaries, colors, assoc) {
  variable aux, filter, field;
  !if ( assoc_key_exists(urls, "warp") ) {
    return;
  }
  !if ( assoc_key_exists(urls["warp"], "aux") ) {
    return;
  }
  foreach aux(auxiliaries) {
    !if ( assoc_key_exists(urls["warp"]["aux"], aux) ) {
      continue;
    }
    foreach filter(colors) {
      !if ( assoc_key_exists(urls["warp"]["aux"][aux], filter) ) {
	continue;
      }
      foreach field(assoc_get_keys(urls["warp"]["aux"][aux][filter])) {
	variable outfile = sprintf("%swarp_%s_%s_%s.fits", outdir, aux, filter, field);
	__panstarrsDownloadFile(urls["warp"]["aux"][aux][filter][field], outfile;; __qualifiers);
	__panstarrsInsertWarpAuxMatch(assoc, aux, filter, field, outfile);
      }
    }
  }
}

% Download the images into a directory and name them
% The directory already must exist
private define __panstarrsDownloadImages(urls, outdir, filters, fileTypes, auxiliaries) {
  variable ret = Assoc_Type[Assoc_Type];
  __panstarrsDownloadStacks(urls, outdir, filters, ret;; __qualifiers);
  __panstarrsDownloadStacksAux(urls, outdir, auxiliaries, filters, ret;; __qualifiers);
  __panstarrsDownloadWarps(urls, outdir, filters, ret;; __qualifiers);
  __panstarrsDownloadWarpsAux(urls, outdir, auxiliaries, filters, ret;; __qualifiers);
  return ret;
}

%!%+
%\function{panstarrsImageDownload}
%\synopsis{Download PanSTARRS image cutouts}
%\usage{Assoc_Type fileNames = panstarrsImageDownload(String_Type position, Double_Type size, String_Type outdir)
%    Assoc_Type fileNames = panstarrsImageDownload(Double_Type ra, Double_Type dec, Double_Type size, String_Type outdir)}
%\qualifiers{
%\qualifier{g}{Download images taken with the g filter}
%\qualifier{r}{Download images taken with the r filter}
%\qualifier{i}{Download images taken with the i filter}
%\qualifier{z}{Download images taken with the z filter}
%\qualifier{y}{Download images taken with the y filter}
%\qualifier{stack}{Download final stacks}
%\qualifier{warp}{Download individual warps (single epoch images)}
%\qualifier{data}{Download main data products}
%\qualifier{mask}{Download masks}
%\qualifier{wt}{Download weight images}
%\qualifier{exp}{Download exposure maps}
%\qualifier{expwt}{Download weighted exposure maps (undocumented)}
%\qualifier{num}{Download num images (undocumented)}
%}
%\notes
%    Please note that PanSTARRS only covers the sky north of DEC=-30 deg.
%    At least one filter is required.
%    At least one of stack or warp is required.
%    At least one of data, mask, wt, exp, expwt or num is required.
%    The function only throws an exception on real runtime errors. If some data
%    just aren't available no exceptions is thrown, the images just don't exist
%    and are therefore not downloaded and not entered into the returned assoc.
%\description
%    Access the PanSTARRS DR1 image cutout server located at
%    http://plpsipp1v.stsci.edu/cgi-bin/ps1cutouts to
%    download different combinations of data products and filters.
%    The usage of this function is analogous to the usage of this website.
%    position can be a generic string which is resolved by the server itself
%    using Simbad or other means. Alternatively RA and DEC can be supplied
%    directly to the function in degrees.
%    outdir must supply a directory where the output files shall be written.
%    The function returns an Assoc_Type which contains the information about
%    the downloaded files. If all options are set the assoc looks like this:
%#v+
%#p+
%    assoc
%    ├── stack
%    │   ├── aux
%    │   │   ├── exp
%    │   │   │   ├── g=path
%    │   │   │   ├── ...
%    │   │   ├── expwt
%    │   │   │   ├── g=path
%    │   │   │   ├── ...
%    │   │   ├── mask
%    │   │   │   ├── g=path
%    │   │   │   ├── ...
%    │   │   ├── num
%    │   │   │   ├── g=path
%    │   │   │   ├── ...
%    │   │   └── wt
%    │   │       ├── g=path
%    │   │       ├── ...
%    │   └── colors
%    │       ├── g=path
%    │       ├── ...
%    └── warp
%        ├── aux
%        │   ├── mask
%        │   │   ├── g
%        │   │   │   ├── 55860.59225=path
%        │   │   │   ├── ...
%        │   │   ├── i
%        │   │   │   ├── 55200.51443=path
%        │   │   │   ├── ...
%        │   │   ├── r
%        │   │   │   ├── 55911.49788=path
%        │   │   │   ├── ...
%        │   │   ├── y
%        │   │   │   ├── 55518.62770=path
%        │   │   │   ├── ...
%        │   │   └── z
%        │   │       ├── 55302.23917=path
%        │   │       ├── ...
%        │   └── wt
%        │       ├── g
%        │       │   ├── 55860.59225=path
%        │       │   ├── ...
%        │       ├── i
%        │       │   ├── 55200.51443=path
%        │       │   ├── ...
%        │       ├── r
%        │       │   ├── 55911.49788=path
%        │       │   ├── ...
%        │       ├── y
%        │       │   ├── 55518.62770=path
%        │       │   ├── ...
%        │       └── z
%        │           ├── 55302.23917=path
%        │           ├── ...
%        └── colors
%            ├── g
%            │   ├── 55860.59225=path
%            │   ├── ...
%            ├── i
%            │   ├── 55200.51443=path
%            │   ├── ...
%            ├── r
%            │   ├── 55911.49788=path
%            │   ├── ...
%            ├── y
%            │   ├── 55518.62770=path
%            │   ├── ...
%            └── z
%                ├── 55302.23917=path
%                ├── ...
%#p-
%#v-
%    The structure should be self explanatory, except the set of numbers at
%    the lowest level of the warps. These are the MJDs when the exposure
%    was completed.
%!%-
define panstarrsImageDownload() {
  variable pos, size, outdir, ra, dec;
  switch(_NARGS)
  { case 3:
    (pos, size, outdir) = ();
  }
  { case 4:
    (ra, dec, size, outdir) = ();
    !if ( typeof(ra) == Integer_Type || typeof(ra) == Double_Type || typeof(ra) == Float_Type ) {
      throw UsageError, "ra needs to be float, double or int";
    }
    !if ( typeof(dec) == Integer_Type || typeof(dec) == Double_Type || typeof(dec) == Float_Type ) {
      throw UsageError, "dec needs to be float, double or int";
    }
    if ( ra < 0. || ra >= 360. ) {
      throw UsageError, "ra must be in [0.0, 360)";
    }
    if ( dec < -90. || dec > 90. ) {
      throw UsageError, "dec must be [90.0, 90.0]";
    }
    if ( dec <= -30. ) {
      throw UsageError, "PanSTARRS is only available at DEC > -30 deg";
    }
    pos = sprintf("%f%+f", ra, dec);
  }
  { throw NumArgsError, "Invalid number of arguments"; }

  !if ( typeof(pos) == String_Type ) {
    throw UsageError, "position needs to be a string";
  }
  !if ( typeof(size) == Integer_Type || typeof(size) == Double_Type || typeof(size) == Float_Type ) {
    throw UsageError, "size needs to be float, double or int";
  }
  !if ( size > 0.0 ) {
    throw UsageError, "size must be larger than 0.0";
  }
  !if ( typeof(outdir) == String_Type ) {
    throw UsageError, "outdir needs to be a string";
  }

  variable dstat = stat_file(outdir);
  if ( dstat == NULL ) {
    if ( -1 == mkdir(outdir) ) {
      variable errsv = errno;
      throw RunTimeError, sprintf("Error creating directory %s: %s",
	  outdir, errno_string(outdir));
    }
  } else {
    !if ( stat_is("dir", dstat.st_mode ) ) {
      throw UsageError, sprintf("File %s exists but is not a directory", outdir);
    }
  }

  !if ( outdir[-1] == '/' ) {
    outdir += "/";
  }

  size = int(ceil(size / __panstarrsScale));
  variable filters, fileTypes, auxiliaries;
  (filters, fileTypes, auxiliaries) = __panstarrsGetOptions(pos, size;; __qualifiers);
  variable url = __assemblePanstarrsUrl(pos, size, filters, fileTypes, auxiliaries);
  variable siteData = __panstarrsRetrieveSite(url);
  variable imageUrls = __parsePanstarrsPage(siteData);
  !if ( length(assoc_get_keys(imageUrls)) ) {
    vmessage("Warning: No images found to downloaded");
  }
  return __panstarrsDownloadImages(imageUrls, outdir, filters, fileTypes, auxiliaries;; __qualifiers);
}
