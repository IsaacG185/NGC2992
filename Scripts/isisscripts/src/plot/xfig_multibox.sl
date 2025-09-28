require( "xfig" );

define xfig_multibox()
%!%+
%\function{xfig_multibox}
%\synopsis{combines M x N xfig-objects in one box}
%\usage{pl = xfig_multibox(XFig_Plot_Type pl[M,N] [, Double_Type spacing])}
%\qualifiers{
%\qualifier{rotate}{switch the meaning of M and N}
%}
%\seealso{xfig_new_vbox_compound, xfig_new_hbox_compound}
%!%-
{

   variable pl,dx=0.0;
   switch(_NARGS)
   { case 1:  pl      = (); }
   { case 2:  (pl,dx)      = (); }
   { help(_function_name()); return; }

   variable ind = array_shape(pl);
   
   if (length(ind)==1)
   {
      if (qualifier_exists("rotate"))
	reshape(pl, [1,ind[0]]);
      else
	reshape(pl, [ind[0],1]);
   }
   else if (length(ind)==2 && qualifier_exists("rotate"))
     transpose(pl);

   ind = array_shape(pl);

   if (length(ind)!=2)  % check if the array has now reasonable shape
     return pl;

   variable m = ind[0], n=ind[1];
   variable i,j,pl_rows=Struct_Type[m];

   variable li_rows,li_sum;

   li_sum={};
   _for j(0,m-1,1)
   {
      li_rows={};
      _for i(0,n-1,1)
	list_append(li_rows,pl[j,i]);
      pl_rows[j]=xfig_new_hbox_compound(__push_list(li_rows),dx);
      list_append(li_sum,pl_rows[j]);
   }
   variable pl_sum = xfig_new_vbox_compound(__push_list(li_sum),dx);
   
   return pl_sum;
}
