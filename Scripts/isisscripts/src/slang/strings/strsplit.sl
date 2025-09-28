define strsplit()
%!%+
%\function{strsplit}
%\synopsis{split a string at a separator and return contents as an array}
%\usage{Array_Type strsplit(String_Type s, String_Type separator);}
%\description
%This routine takes a string s and splits it into parts separated by
%a separator character.
%\example
%variable ra="12:34:56.78";
%variable rastr,hh,mm,ss;
%rastr=strsplit(ra,":");
%hh=atof(rastr[0]); mm=atof(rastr[1]); ss=atof(rastr[2]);
%ra=hms2deg(hh,mm,ss);
%!%-
{
    variable s,separator;
    switch(_NARGS)
    { case 2: (s,separator) = (); }
    { return help(_function_name()); }

    if (length(separator)!=1) {
	throw RunTimeError,sprintf("%s: Separator must be exactly one character\n",_function_name());
    }
    variable retarr={};
    variable str=s;
    variable pos=is_substr(str,separator);
    while ( pos != 0 ) {
	list_append(retarr,substr(str,1,pos-1));
	str=substr(str,pos+1,strlen(str)-pos);
	pos=is_substr(str,separator);
    }
    list_append(retarr,str);

    return list_to_array(retarr);
}
