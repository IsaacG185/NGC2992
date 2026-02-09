private variable open_plot_ps2eps_cmd = "";

define open_plot_ps2eps()
%!%+
%\function{open_plot_ps2eps}
%\synopsis{opens a plot and saves .ps filename for latter use of ps2eps}
%\usage{Integer_Type id = open_plot_ps2eps(device[, nxpanes[, nypanes]]);}
%\description
%    \code{open_plot_ps2eps} passes its arguments to \code{open_plot}.
%    If used together with \code{close_plot_ps2eps}, an .eps file
%    is finally produced from an usual PGPLOT .ps output
%    through the external tool ps2eps. Therefore, \code{device} has to be
%    a \code{.ps} file with \code{/}[\code{v}][\code{c}]\code{ps} specification.
%\qualifiers{
%\qualifier{ps2epsopt}{ [="-R=+ -B -f"]: option for ps2eps}
%\qualifier{noremoveps}{the .ps file will not be removed after conversion}
%\qualifier{pre_enlargeBB}{enlarge bounding box by specified value [=1, if none specified] before ps2eps}
%\qualifier{pre_run_cmd=cmd}{command to run before ps2eps.
%                       The ps-file is passed to \code{cmd} as an argument.
%                       \code{cmd} is expected to write the modified ps file to \code{stdout}.}
%\qualifier{enlargeBB}{enlarge bounding box by specified value [=1, if none specified] after ps2eps}
%}
%\seealso{open_plot, close_plot_ps2eps}
%!%-
{
  variable device, nxpanes=1, nypanes=1;
  switch(_NARGS)
  { case 1: device = (); }
  { case 2: (device, nxpanes) = (); }
  { case 3: (device, nxpanes, nypanes) = (); }
  { help(_function_name()); return; }

  variable filename = string_matches(device, `\(.*\)\.ps/`, 1);
  if(filename==NULL)
    vmessage(`warning (%s): device "%s" does not contain a .ps file`, _function_name(), device);
  else
  {
    filename = filename[1];
    open_plot_ps2eps_cmd = "";
    variable delta;
    if(qualifier_exists("pre_enlargeBB"))
    {
      delta = string(qualifier("pre_enlargeBB"));
      if(delta=="NULL")  delta = "1";
      open_plot_ps2eps_cmd = "/usr/bin/awk '"+
	                     + `$1=="%%BoundingBox:" && $2!="(atend)" { $2-=`+delta+"; $3-="+delta+"; $4+="+delta+"; $5+="+delta+"; }"
                             + "{ print; }"
	                     +"' $filename.ps > $filename.ps.tmp; mv $filename.ps.tmp $filename.ps; "$;
    }

    variable pre_run_cmd = qualifier("pre_run_cmd");
    if(pre_run_cmd!=NULL)
      open_plot_ps2eps_cmd += "$pre_run_cmd $filename.ps > $filename.ps.tmp; mv $filename.ps.tmp $filename.ps; "$;

    open_plot_ps2eps_cmd += "ps2eps "+qualifier("ps2epsopt", "-R=+ -B -f")+" $filename.ps"$;

    ifnot(qualifier_exists("noremoveps"))
      open_plot_ps2eps_cmd += "; /bin/rm $filename.ps"$;

    if(qualifier_exists("enlargeBB"))
    {
      delta = string(qualifier("enlargeBB"));
      if(delta=="NULL")  delta = "1";
      open_plot_ps2eps_cmd += "; /usr/bin/awk '"+
	                     +  `$1=="%%BoundingBox:" && $2!="(atend)" { $2-=`+delta+"; $3-="+delta+"; $4+="+delta+"; $5+="+delta+"; }"
                             +  "{ print; }"
	                     +"' $filename.eps > $filename.eps.tmp; mv $filename.eps.tmp $filename.eps"$;
    }
  }
  return open_plot(device, nxpanes, nypanes);
}


define close_plot_ps2eps()
%!%+
%\function{close_plot_ps2eps}
%\synopsis{closes a plot calls ps2eps}
%\usage{close_plot_ps2eps();}
%\seealso{close_plot, close_plot_ps2eps}
%!%-
{
  close_plot();
  if(open_plot_ps2eps_cmd != "")
  {
    if(qualifier_exists("verbose"))  message(open_plot_ps2eps_cmd);
    ()=system(open_plot_ps2eps_cmd);
    open_plot_ps2eps_cmd = "";
  }
}
