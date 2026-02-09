require( "png" );

define ad_colormap_norm_col(array) {
   return int(array/max(array)*255.99999999999);
}

define ad_colormap_gauss(x, mu, Delta)
{ return exp(-((x-mu)/Delta)^2);
}

%%%%%%%%%%%%%%%%%%
% TD, 10/06/2010
%%%%%%%%%%%%%%%%%%
define ad_create_colormap(img,alp,gmax) {
%%%%%%%%%%%%%%%%%%
%!%+
%\function{ad_create_colormap}
%\synopsis{creates a redshift-colormap, where yellow is exactly at
%where(img==1)}
%\usage{g_br = ad_create_colormap(img,alp,gmax);}
%!%-
   variable R = [0:255]*0.;
   variable G = [0:255]*0.;
   variable B = [0:255]*0.;
   
   variable RI = Integer_Type[256];
   variable GI = Integer_Type[256];
   variable BI = Integer_Type[256];
   
   variable g_br;
   if (gmax <= 1) {
      g_br = 256;
   } else {
      % where is redshift == 1?
      g_br = int(1./gmax*255.999999999);
   }
   
   
   
      %% colors before g=1
   
   variable i1 = [0:g_br-1];
   R[i1] = i1^(1./2.2);
   RI[i1] = ad_colormap_norm_col(R[i1]);


   BI[i1] = 0;

   G = ad_colormap_gauss([0:255],g_br,g_br/2.5);

   %% color after g=1
   if (gmax > 1) {
      variable i2 = [g_br:255];
      variable i21= [g_br:g_br+(255-g_br)/2];
      variable i22 = [max(i21)+1:255];

      R[i21] = (sqrt(max(i21)-i21))^(2.);
      RI[i21] = ad_colormap_norm_col(R[i21]);
      R[i22] = ((i22-min(i22))/(1.*max(i22)-min(i22)))^(1.1);
      RI[i22] = ad_colormap_norm_col(R[i22])/3*2;

      B[i21] = ((i21-g_br)/(max(i21)*1.-g_br)*1.)^(1.);
      BI[i21] = ad_colormap_norm_col(B[i21]);

      B[i22] = ad_colormap_gauss(i22,min(i22),(255-g_br)/2.);
      BI[i22] = ad_colormap_norm_col(B[i22]);

      G[i21] = (sqrt(max(i21)-i21)/sqrt(255-g_br))^(2.);
      GI[i21] = ad_colormap_norm_col(G[i21]);
      G[i22] = 0.;%(sqrt(255-i2)/sqrt(255-g_br))^(2.);
   }
   GI[i1] = ad_colormap_norm_col(G[i1]);

     
   png_add_colormap("redshift", ((RI << 16) | (GI << 8) | BI ));
   
      
   %% PLOT COLOR-SCHEME ???
   if (qualifier_exists("plot")) {
      variable x = [0:255];
      color(2);
      plot(x,RI);oplot(x,GI);oplot(x,BI);
   }
   
   return g_br;
}

