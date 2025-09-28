% Last Updated: Aug. 25, 2005

% Force the Appending of semi-colons
% Isis_Append_Semicolon=0;

% Make sure filenames and background file names get printed in list functions
% Isis_List_Filenames=1;

% For reading in radio data.  Make sure minimum allowable error damned
% near 0, since I *think* `Ideal ARFs' do *not* take input from set_data_exposure.
% Minimum_Stat_Err = 1.e-30;

try { require("xspec"); require( "gsl", "gsl" ); }
catch AnyError: { };

static variable path = "";

% A message function I'll use a lot below

public define msg(str_array)
{
   () = printf("\n");
   foreach(str_array)
   {
      variable str = ();
      () = printf(" %s\n", str);
   }
   () = printf("\n");
   return;
}

