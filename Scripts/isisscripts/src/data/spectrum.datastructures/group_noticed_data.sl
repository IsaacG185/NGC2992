%%%%%%%%%%%%%%%%%%%%%%%%%
define group_noticed_data()
%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{group_noticed_data}
%\synopsis{groups previously noticed spectral bins by an integer factor}
%\usage{group_noticed_data(Integer_Type id, Integer_Type factor);}
%\seealso{group_data}
%!%-
{
  variable ids, factor;
  switch(_NARGS)
  { case 2: (ids, factor) = (); }
  { help(_function_name()); }

  variable id;
  foreach id ([ids])
  {
    variable notice = get_data_info(id).notice;
    variable len = length(notice);
    variable ind = @notice;
    variable new_ignore_list = Integer_Type[0];
    variable i, new_i=0, nr=0, sgn=+1;
    _for i (0, len-1, 1)
    {
%    ()=printf("notice(%d) = %2d", i, notice[i]);
      if(notice[i]==0)
      { if(i>0 && notice[i-1]!=0) { sgn *= -1; new_i++; new_ignore_list = [new_ignore_list, new_i]; }
        if(i==0)  new_ignore_list = [new_ignore_list, new_i];
        ind[i] = sgn;
%      ()=printf(" => %2d [%d]\n", ind[i], new_i);
      }
      else
      { if(i>0 && notice[i-1]==0) { nr=0; sgn *= -1; new_i++; }
        nr++;
        ind[i] = sgn;
%      ()=printf(" => %2d [%d]\n", ind[i], new_i);
        if(nr==factor && i+1<len && notice[i+1]!=0) { nr=0; sgn *= -1; new_i++; }
      }
    }
%  print(new_ignore_list);

    rebin_data(id, ind);
    ignore_list(id, new_ignore_list);
  }
}
