% -*- mode:slang; mode:fold -*-

private variable Fmt_Colheads, Fmt_Params;
Fmt_Colheads = " idx%-*stie-to  freeze         value         min         max";
Fmt_Params   = "%3u  %-*s  %2d    %2d   %14.7g  %10.7g  %10.7g  %s%s";
private define param_string (p, len) %{{{
{
  return sprintf (Fmt_Params, p.index, len, p.name,
		  p.tie, p.freeze, p.value, p.min, p.max, p.units, p.fun);
}
%}}}
private define back_fun_string (i) %{{{
{
  variable s = _isis->_get_instrumental_background_hook_name(i);
  if (s == NULL) return "";
  return sprintf ("# [bgd %d] = %s", i, strtrim(s));
}
%}}}
private define massage_param_structs (pars) %{{{
{
  variable len = 0;

  foreach (pars)
  {
    variable p = ();

    len = max([len, strlen(p.name)]);

    if (p.tie != NULL)
    {
      p.tie = _get_index(p.tie);
    }
    else p.tie = 0;

    if (p.fun != NULL)
    {
      p.fun = sprintf ("\n#=>  %s", strtrim(p.fun));
    }
    else p.fun = "";

    if (andelse
      {p.min == -_isis->DBL_MAX}
	{p.max ==  _isis->DBL_MAX})
    {
      p.min = 0;
      p.max = 0;
    }
  }

  return len;
}

%}}}
private define is_free (p) %{{{
{
  return (p.tie == NULL and p.freeze == 0 and p.fun == NULL);
}
%}}}

private define list_par_string_pattern (pat) %{{{
{
  variable s = get_fit_fun();
  s = (s == NULL) ? String_Type[0] : [strtrim(s)];

  variable datasets = all_data();
  if (datasets != NULL)
  {
    variable bs = array_map (String_Type, &back_fun_string, datasets);
    bs = bs[where(bs != "")];
    s = [s, bs];
  }

  variable p, _i, i = Integer_Type[0];
  foreach p ([pat])
  {
    _i = _get_index(p);
    if( typeof(_i) == Array_Type )
      i = [i, _i ];
  }
  
  variable ps = String_Type[0];
  
  variable pars = get_params(i);
  if (pars != NULL)
  {
    variable len = massage_param_structs (pars);
    
    variable colheads;
    colheads = sprintf (Fmt_Colheads, len, "  param");
    ps = array_map (String_Type, &param_string, pars, len);
    
    s = strjoin ([s, colheads, ps], "\n");
  }
  
  if (length(s) == 0)
    return NULL;
  else if (length(s) == 1 && typeof(s) == Array_Type)
    s = s[0];

  return s;
}
%}}}

define List_par()
%!%+
%\function{List_par}
%\synopsis{list current fit function and parameters}
%\usage{List_par ([arg])}
%\altusage{List_par ( String_Type[] pattern )}
%\description
%   The optional argument is used to redirect the output.  If arg
%   is omitted, the output goes to stdout.  If arg is of type
%   Ref_Type, it the output string is stored in the referenced
%   variable.  If arg is a file name, the output is stored in that
%   file.  If arg is a file pointer (File_Type) the output is
%   written to the corresponding file.
%
%   If the given argument is a String pattern, only parameter matching
%   this pattern are listed!
%
%   The parameter listing looks like this:
%
%   gauss(1) + poly(1)
%     idx  param        tie-to  freeze    value      min          max
%      1  gauss(1).area     0     0       103.6        0            0
%      2  gauss(1).center   0     0        12.1       10           13
%      3  gauss(1).sigma    0     0       0.022    0.001          0.1
%      4  poly(1).a0        0     0       1.2e4        0            0
%      5  poly(1).a1        0     1           0        0            0
%      6  poly(1).a2        0     1           0        0            0
%
%    The first line defines the form of the fit-function. The
%    parameter index idx may be used to refer to individual fit
%    parameters (see set_par).  freeze = 1 (0) indicates that the
%    corresponding parameter value is frozen (variable).  If two
%    parameter values are tied together, the connection is indicated
%    in the tie-to column.  For example, if parameter 1 has tie-to =
%    5, that means the value of parameter 1 is tied to the value of
%    parameter 5; if parameter 5 changes, parameter 1 will follow
%    the change exactly.  If min=max=0, the corresponding parameter
%    value is unconstrained.
%
%    In input parameter files (see load_par), lines beginning with a
%    '#' are mostly ignored and may be used to include comments.
%    Exceptions to this rule are "special" comment lines which are
%    used to support additional functionality such as, e.g. writing
%    some parameters as functions of other parameters (see
%    set_par_fun).  Note that, aside from these special cases,
%    comment lines are not loaded by load_par and will not be
%    preserved if file is later overwritten by save_par.
%
%\seealso{list_free, edit_par, set_par, get_par, save_par, set_par_fun}
%!%-
{
  variable pat;
  switch( _NARGS )
  { case 0 : list_par;return; }
  { case 1 : pat = ();}
  { help(_function_name()); return; }

  if ( _typeof(pat) == String_Type ){
    _isis->put_string (NULL, _function_name, list_par_string_pattern (pat) );

    % % get par list as string array (lines)
    % variable l;
    % list_par(&l);
    % l = strtok( l, "\n" );
    % % get line indices matching the 'pat'
    % variable pnames = String_Type[0];
    % variable p;
    % _for p ( 2, length(l)-1, 1 ){
    %   pnames = [ pnames, strtok(l[p])[1] ];
    % }
    % variable idx = where( is_substr( pnames, pat ) != 0 ) + 2;

    % sprintf( strjoin( l[[0,1,idx]], "\n" ) );
  }
  else
    list_par( pat );
  return;
}
