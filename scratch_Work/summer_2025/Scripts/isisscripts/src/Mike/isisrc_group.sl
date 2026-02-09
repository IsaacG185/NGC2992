
% Last Updated: June 4, 2010

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% These have been superseded by:

%  use_file_group   (replaces apply_x2i_grp)

%  regroup_file     (replaces apply i2x_grp)

% Public Functions in This File.  Usage message (almost always) when 
% function is called without arguments.

% i2x_grp       : Turn an ISIS grouping into a GRPPHA/XSPEC one 
% write_x_grp   : ... take that grouping and apply it to a file
% apply_i2x_grp : Do the above two in one fell swoop
% x2i_grp       : Turn an XSPEC/GRPPHA grouping into an ISIS one
% apply_x2i_grp : ... and apply it in one fell swoop
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define i2x_grp()
{
   switch(_NARGS)
   {
    case 1:
      variable i, lb, ub, id, gdi, lgdi, iw, liw;

      id = ();
      gdi = [reverse(get_data_info(id).rebin),5];
      lgdi = length(gdi)-1;

      variable grp = Integer_Type[lgdi];

      iw = [where( shift(gdi,-1) != gdi )];
      liw = length(iw);
      iw[liw-1] = lgdi;

      grp[iw[[0:liw-2]]] = 1;

      foreach i ([0:liw-2])
      {
         lb = iw[i];
         ub = iw[i+1]-1;
         if(ub>lb)
         {
            grp[[lb+1:ub]] = -1;
         }
      }
      
      return grp;
   }
   {
      variable fp=stderr;
      () = fprintf(fp, "\n%s\n", %%%{{{
+" grouping = i2x_grp(id);\n"
+" \n"
+"   For any dataset, id, grouped in ISIS, create an *energy ordered*\n"
+"   grouping vector that follows the grppha conventions.  (ISIS groups\n"
+"   flagged with 0, however, become *noticed* groups of 1.)\n"); %%%}}}
      return;
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define write_x_grp()
{
   switch(_NARGS)
   {
    case 2:
      variable id, grouping, file, fp, colnum;

      (id, grouping) = ();
      file = get_data_info(id).file;

      fp = fits_open_file(file+"[SPECTRUM]","w");
      () = _fits_get_colnum(fp, "grouping", &colnum);
      () = _fits_write_col(fp,colnum,1,1,grouping);
      fits_close_file(fp);

      return;
   }
   {
      variable fpe=stderr;
      () = fprintf(fpe, "\n%s\n", %%%{{{
+" write_x_grp(id,grouping);\n"
+" \n"
+"   Write an XSPEC style grouping to the *file* associated with id.\n"
+"   *Grouping vector must follow grppha conventions and be energy ordered.*\n"
+" \n"
+"   See: grouping = i2x_grp(id);\n"); %%%}}}
      return;
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define apply_i2x_grp()
{
   switch(_NARGS)
   {
    case 1:
      variable id, grp;

      id = ();
      grp = i2x_grp(id);
      write_x_grp(id,grp);

      return;
   }
   {
      variable fpe=stderr;
      () = fprintf(fpe, "\n%s\n", %%%{{{
+" apply_i2x_grp(id);\n"
+" \n"
+"   Take the ISIS defined grouping from dataset id, create an XSPEC style\n"
+"   grouping based upon that, and then write that grouping to the\n"
+"   associated file.\n"
+"   *** Superseded by the ISIS intrinsic regroup_file(id); ***\n"); %%%}}}
      return;
   }
}

%%%%%%%%%%%%%%%%%%%%%%%

public define x2i_grp()
{
   switch(_NARGS)
   {
    case 1:
      variable id, file, grp, lgrp, iw, liw, sn, i;

      id = ();
      file = get_data_info(id).file;
      grp = fits_read_col(file,"grouping");

      lgrp = length(grp);
      iw = where(grp == 1);
      liw = length(iw);
      iw = [iw,lgrp];

      sn = 1;
      foreach i ([0:liw-1])
      {
         grp[[iw[i]:max([iw[i],iw[i+1]-1])]] = sn;
         sn = -1*sn;
      }

      return reverse(grp);
   }
   {
      variable fpe=stderr;
      () = fprintf(fpe, "\n%s\n", %%%{{{
+" grouping = x2i_grp(id);\n"
+" \n"
+"   Read an XSPEC style *energy ordered* grouping, associated with the\n"
+"   dataset indicated by id, and convert it to a *wavelength ordered* ISIS\n"
+"   style grouping suitable for use in rebinning, i.e., \n"
+"      isis> rebin_data(indx,grouping);\n"); %%%}}}
      return;
   }
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

public define apply_x2i_grp()
{
   switch(_NARGS)
   {
    case 1:
      variable id, grp; 

      id = ();
      grp = x2i_grp(id);
      rebin_data(id,grp);

      return;
   }
   {
      variable fpe=stderr;
      () = fprintf(fpe, "\n%s\n", %%%{{{
+" apply_x2i_grp(id);\n"
+" \n"
+"   Take the XSPEC style grouping from the *file* associated with\n"
+"   dataset id, convert it to an ISIS style, wavelength ordered\n"
+"   grouping, and apply it to dataset id.\n"
+"   *** Superseded by the ISIS intrinsic use_group_file(id); ***\n"); %%%}}}
      return;
   }
}

