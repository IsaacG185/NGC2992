% test for documentation of accessible functions
%   No documentation -> No publication

variable status = 0;

% I wish that would work, to many not documented
#if$BUILDCHECK

% get slang internal package
require("slshhelp");
require("setfuns");

% get everything known from global ns and other packages required
variable file = "./share/isisscripts.sl";
variable fp = fopen(file,"r");
variable mat,si,s;
variable modules = {};
variable line;

foreach line (fp) using ("line")
{
  mat = string_matches(line,"try[ ]*{[ ]*\(require.*\)}"R);
  if (length(mat) > 1)
  {
    si = strchop(mat[1],';',0);
    foreach s(si)
    {
      mat = string_matches(s,".*require(.*\"\(.*\)\".*)"R);
      if (length(mat) > 1)
      {
	list_append(modules, mat[1]);
      }
    }
  }
}

if (length(modules))
  modules = list_to_array(modules);
else
  modules = NULL;
modules = modules[unique(modules)];
variable m;
foreach m (modules)
  try { require(m); } catch AnyError;

variable knowns = [_apropos("Global", "", 1 | 2), _apropos(current_namespace(), "", 1 | 2)];

% import packages to seperate namespaces
variable ns = "isisscripts_test";
% load isisscript to new ns
require(file, ns);

variable Local_Functions, Global_Functions;
variable name;
variable nodoc_globals = 0;
variable nodoc_locals = 0;

% iterate over all functions, and check if we get a help
Local_Functions = _apropos(ns, "", 1 | 2);
Global_Functions = _apropos("Global", "", 1 | 2);

variable Local_Undoc = {};
if (Int_Type != typeof(Local_Functions)) {
  % remove everything that comes from slang and associated packages
  Local_Functions = Local_Functions[complement(Local_Functions, knowns)];
  foreach name (Local_Functions) {
    if (NULL == slsh_get_doc_string(name)) { % no help!
      nodoc_locals++;
      list_append(Local_Undoc, name);
    }
  }
} else {
  Local_Functions = {};
}

variable Global_Undoc = {};
if (Int_Type != typeof(Global_Functions)) {
  % remove everything that comes from slang and associated packages
  Global_Functions = Global_Functions[complement(Global_Functions, knowns)];
  foreach name (Global_Functions) {
    if (NULL == slsh_get_doc_string(name)) { % no help!
      nodoc_globals++;
      list_append(Global_Undoc, name);
    }
  }
} else {
  Global_Functions = {};
}

vmessage(`
ISISSCRIPTS defines
  Global functions: %d,  %d undocumented
   Local functions: %d,  %d undocumented
`,
	 length(Global_Functions), nodoc_globals,
	 length(Local_Functions), nodoc_locals);

if (nodoc_globals) {
  vmessage("%s Undocumented Globals %s", ("=")[[0:14]/15], dup());
  variable sym;
  foreach sym (Global_Undoc)
    vmessage("  %s", sym);
}

if (nodoc_locals) {
  vmessage("%s Undocumented Locals %s", ("=")[[0:14]/15], dup());
  foreach sym (Local_Undoc)
    vmessage("  %s", sym);
}

status = nodoc_globals || nodoc_locals

vmessage("");
#endif

exit(status);
