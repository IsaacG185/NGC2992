define ext_line_info()
%!%+
%\function{ext_line_info}
%\usage{Struct_Type info = ext_line_info(Integer_Type id);
%\altusage{Struct_Type info = ext_line_info(Integer_Type Z, Integer_Type ion, Integer_Type nr);}
%}
%\seealso{line_info}
%!%-
{
  variable id, Z, ion, nr, l = NULL, A = NULL, g_up = NULL, g_low = NULL, gf = NULL;

  switch(_NARGS)
  { case 1:
      id = ();
      if(id<99000000 or id>99999999)  { require_atoms(); return struct_combine(line_info(id), struct{ nr=-id }); }
      Z   = (id - 99000000)/10000;
      ion = (id - 99000000 - 10000*Z)/100;
      nr  =  id - 99000000 - 10000*Z - 100*ion;
  }
  { case 3: (Z, ion, nr) = (); }
  { help(_function_name()); return NULL; }

  % # K alpha lines  (House, 1969) #
  % Aluminium
  if(Z==13 && ion== 2 && nr== 1)  l = 8.339;
  if(Z==13 && ion== 3 && nr== 1)  l = 8.336;
  if(Z==13 && ion== 4 && nr== 1)  l = 8.332;
  if(Z==13 && ion== 5 && nr== 1)  l = 8.328;
  if(Z==13 && ion== 6 && nr== 1)  l = 8.269;
  if(Z==13 && ion== 7 && nr== 1)  l = 8.203;
  if(Z==13 && ion== 8 && nr== 1)  l = 8.129;
  if(Z==13 && ion== 9 && nr== 1)  l = 8.050;
  if(Z==13 && ion==10 && nr== 1)  l = 7.964;
  if(Z==13 && ion==11 && nr== 1)  l = 7.885;

  % Silicon
  if(Z==14 && ion== 2 && nr== 1)  l = 7.126;
  if(Z==14 && ion== 3 && nr== 1)  l = 7.124;
  if(Z==14 && ion== 4 && nr== 1)  l = 7.121;
  if(Z==14 && ion== 5 && nr== 1)  l = 7.117;
  if(Z==14 && ion== 6 && nr== 1)  l = 7.112;
  if(Z==14 && ion== 7 && nr== 1)  l = 7.063;
  if(Z==14 && ion== 8 && nr== 1)  l = 7.007;
  if(Z==14 && ion== 9 && nr== 1)  l = 6.947;
  if(Z==14 && ion==10 && nr== 1)  l = 6.882;
  if(Z==14 && ion==11 && nr== 1)  l = 6.813;
  if(Z==14 && ion==12 && nr== 1)  l = 6.750;

  % Argon
  if(Z==18 && ion== 2 && nr== 1)  l = 4.193;
  if(Z==18 && ion== 3 && nr== 1)  l = 4.192;
  if(Z==18 && ion== 4 && nr== 1)  l = 4.190;
  if(Z==18 && ion== 5 && nr== 1)  l = 4.189;
  if(Z==18 && ion== 6 && nr== 1)  l = 4.186;
  if(Z==18 && ion== 7 && nr== 1)  l = 4.184;
  if(Z==18 && ion== 8 && nr== 1)  l = 4.180;
  if(Z==18 && ion== 9 && nr== 1)  l = 4.178;
  if(Z==18 && ion==10 && nr== 1)  l = 4.174;
  if(Z==18 && ion==11 && nr== 1)  l = 4.147;
  if(Z==18 && ion==12 && nr== 1)  l = 4.119;
  if(Z==18 && ion==13 && nr== 1)  l = 4.089;
  if(Z==18 && ion==14 && nr== 1)  l = 4.057;
  if(Z==18 && ion==15 && nr== 1)  l = 4.025;
  if(Z==18 && ion==16 && nr== 1)  l = 3.995;

  % Iron K alpha line  (House, 1969) #
  if(Z==26 && ion== 1 && nr== 1)  l = 1.937;
  if(Z==26 && ion== 2 && nr== 1)  l = 1.937;
  if(Z==26 && ion== 3 && nr== 1)  l = 1.937;
  if(Z==26 && ion== 4 && nr== 1)  l = 1.937;
  if(Z==26 && ion== 5 && nr== 1)  l = 1.937;
  if(Z==26 && ion== 6 && nr== 1)  l = 1.937;
  if(Z==26 && ion== 7 && nr== 1)  l = 1.937;
  if(Z==26 && ion== 8 && nr== 1)  l = 1.938;
  if(Z==26 && ion== 9 && nr== 1)  l = 1.938;
  if(Z==26 && ion==10 && nr== 1)  l = 1.938;
  if(Z==26 && ion==11 && nr== 1)  l = 1.937;
  if(Z==26 && ion==12 && nr== 1)  l = 1.936;
  if(Z==26 && ion==13 && nr== 1)  l = 1.934;
  if(Z==26 && ion==14 && nr== 1)  l = 1.933;
  if(Z==26 && ion==15 && nr== 1)  l = 1.931;
  if(Z==26 && ion==16 && nr== 1)  l = 1.930;
  if(Z==26 && ion==17 && nr== 1)  l = 1.928;
  if(Z==26 && ion==18 && nr== 1)  l = 1.927;
  if(Z==26 && ion==19 && nr== 1)  l = 1.917;
  if(Z==26 && ion==20 && nr== 1)  l = 1.907;
  if(Z==26 && ion==21 && nr== 1)  l = 1.897;
  if(Z==26 && ion==22 && nr== 1)  l = 1.886;
  if(Z==26 && ion==23 && nr== 1)  l = 1.875;
  if(Z==26 && ion==24 && nr== 1)  l = 1.865;
  if(Z==26 && ion==25 && nr== 1)  l = 1.855;
  if(Z==26 && ion==26 && nr== 1)  l = ext_line_info(26,26,21).lambda;

  % RRCs  (Pollock, priv. comm.)
  if(Z== 6 && ion== 6 && nr==11)  l = 25.3035;
  if(Z== 7 && ion== 7 && nr==11)  l = 18.5872;
  if(Z== 8 && ion== 8 && nr==11)  l = 14.2281;
  if(Z==10 && ion==10 && nr==11)  l =  9.1019;
  if(Z==12 && ion==12 && nr==11)  l =  6.3172;
  if(Z==13 && ion==13 && nr==11)  l =  5.3810;
  if(Z==14 && ion==14 && nr==11)  l =  4.6381;
  if(Z==16 && ion==16 && nr==11)  l =  3.5483;
  if(Z==18 && ion==18 && nr==11)  l =  2.8012;
  if(Z==26 && ion==26 && nr==11)  l =  1.3364;

  if(Z== 6 && ion== 5 && nr==11)  l = 31.6219;
  if(Z== 7 && ion== 6 && nr==11)  l = 22.4582;
  if(Z== 8 && ion== 7 && nr==11)  l = 16.7709;
  if(Z==10 && ion== 9 && nr==11)  l = 10.3682;
  if(Z==12 && ion==11 && nr==11)  l =  7.0374;
  if(Z==13 && ion==12 && nr==11)  l =  5.9438;
  if(Z==14 && ion==13 && nr==11)  l =  5.0863;
  if(Z==16 && ion==15 && nr==11)  l =  3.8460;
  if(Z==18 && ion==17 && nr==11)  l =  3.0089;
  if(Z==26 && ion==25 && nr==11)  l =  1.4045;

  variable atomdbids = Integer_Type[0];

  % H-like ions: Lyman series
  if( Z==ion && nr>=21 && nr<50 )
  {
    if(Z==1 or Z==2 or Z==6 or Z==7 or Z==8 or Z==10 or Z==12 or Z==13 or Z==14 or Z==16 or Z==18 or Z==20 or Z==26 or Z==28)
    { require_atoms();
      % Ly alpha
      if(nr==21)  atomdbids = where(trans(Z, ion, [ 4,  3], 1));   if(nr==31)  atomdbids = where(trans(Z, ion, [ 3], 1));   if(nr==41)  atomdbids = where(trans(Z, ion, [ 4], 1));
      % Ly beta
      if(nr==22)  atomdbids = where(trans(Z, ion, [ 7,  6], 1));   if(nr==32)  atomdbids = where(trans(Z, ion, [ 6], 1));   if(nr==42)  atomdbids = where(trans(Z, ion, [ 7], 1));
      % Ly gamma
      if(nr==23)  atomdbids = where(trans(Z, ion, [12, 11], 1));   if(nr==33)  atomdbids = where(trans(Z, ion, [11], 1));   if(nr==43)  atomdbids = where(trans(Z, ion, [12], 1));
      % Ly delta
      if(nr==24)  atomdbids = where(trans(Z, ion, [19, 18], 1));   if(nr==34)  atomdbids = where(trans(Z, ion, [18], 1));   if(nr==44)  atomdbids = where(trans(Z, ion, [19], 1));
    }

    if(Z==8) % O VIII
    { if(nr==35)  l = 14.6344;   if(nr==45)  l = 14.6343;
      if(nr==36)  l = 14.5243;   if(nr==46)  l = 14.5242;
      if(nr==37)  l = 14.4538;   if(nr==47)  l = 14.4537;
      if(nr==38)  l = 14.4058;   if(nr==48)  l = 14.4057;
      if(nr==39)  l = 14.3717;   if(nr==49)  l = 14.3716;
    }
    if(Z==10) % Ne X
    { if(nr==35)  l =  9.3617;   if(nr==45)  l =  9.3616;
      if(nr==36)  l =  9.2913;   if(nr==46)  l =  9.2912;
      if(nr==37)  l =  9.2462;   if(nr==47)  l =  9.2461;
      if(nr==38)  l =  9.2155;   if(nr==48)  l =  9.2154;
      if(nr==39)  l =  9.1936;   if(nr==49)  l =  9.1936;
    }
    if(Z==11) % Na XI
    { if(nr==31)  l = 10.0286;   if(nr==41)  l = 10.0232;
      if(nr==32)  l =  8.4603;   if(nr==42)  l =  8.4591;
      if(nr==33)  l =  8.0214;   if(nr==43)  l =  8.0209;
      if(nr==34)  l =  7.8333;   if(nr==44)  l =  7.8331;
      if(nr==35)  l =  7.7349;   if(nr==45)  l =  7.7347;
      if(nr==36)  l =  7.6767;   if(nr==46)  l =  7.6766;
      if(nr==37)  l =  7.6394;   if(nr==47)  l =  7.6393;
      if(nr==38)  l =  7.6140;   if(nr==48)  l =  7.6140;
      if(nr==39)  l =  7.5960;   if(nr==49)  l =  7.5960;
    }
    if(Z==12) % Mg XII
    { if(nr==35)  l =  6.4975;   if(nr==45)  l =  6.4974;
      if(nr==36)  l =  6.4486;   if(nr==46)  l =  6.4486;
      if(nr==37)  l =  6.4173;   if(nr==47)  l =  6.4173;
      if(nr==38)  l =  6.3960;   if(nr==48)  l =  6.3960;
      if(nr==39)  l =  6.3809;   if(nr==49)  l =  6.3809;
    }
    if(Z==13) % Al XIII
    { if(nr==35)  l =  5.5346;   if(nr==45)  l =  5.5344;
      if(nr==36)  l =  5.4929;   if(nr==46)  l =  5.4929;
      if(nr==37)  l =  5.4663;   if(nr==47)  l =  5.4662;
      if(nr==38)  l =  5.4481;   if(nr==48)  l =  5.4481;
      if(nr==39)  l =  5.4352;   if(nr==49)  l =  5.4352;
    }
    if(Z==14) % Si XIV
    { if(nr==35)  l =  4.7705;   if(nr==45)  l =  4.7704;
      if(nr==36)  l =  4.7346;   if(nr==46)  l =  4.7345;
      if(nr==37)  l =  4.7116;   if(nr==47)  l =  4.7116;
      if(nr==38)  l =  4.6960;   if(nr==48)  l =  4.6960;
      if(nr==39)  l =  4.6849;   if(nr==49)  l =  4.6848;
    }
    if(Z==16) % S XVI
    { if(nr==35)  l =  3.6496;   if(nr==45)  l =  3.6496;
      if(nr==36)  l =  3.6221;   if(nr==46)  l =  3.6221;
      if(nr==37)  l =  3.6045;   if(nr==47)  l =  3.6045;
      if(nr==38)  l =  3.5926;   if(nr==48)  l =  3.5926;
      if(nr==39)  l =  3.5841;   if(nr==49)  l =  3.5841;
    }
    if(Z==18) % Ar XVIII
    { if(nr==35)  l =  2.8810;   if(nr==45)  l =  2.8810;
      if(nr==36)  l =  2.8594;   if(nr==46)  l =  2.8594;
      if(nr==37)  l =  2.8455;   if(nr==47)  l =  2.8455;
      if(nr==38)  l =  2.8361;   if(nr==48)  l =  2.8361;
      if(nr==39)  l =  2.8294;   if(nr==49)  l =  2.8294;
    }
    if(Z==20) % Ca XX
    { if(nr==35)  l =  2.3313;   if(nr==45)  l =  2.3313;
      if(nr==36)  l =  2.3138;   if(nr==46)  l =  2.3138;
      if(nr==37)  l =  2.3026;   if(nr==47)  l =  2.3026;
      if(nr==38)  l =  2.2949;   if(nr==48)  l =  2.2949;
      if(nr==39)  l =  2.2895;   if(nr==49)  l =  2.2895;
    }
    if(Z==26) % Fe XXVI
    { if(nr==35)  l =  1.3744;   if(nr==45)  l =  1.3744;
      if(nr==36)  l =  1.3641;   if(nr==46)  l =  1.3641;
      if(nr==37)  l =  1.3575;   if(nr==47)  l =  1.3575;
      if(nr==38)  l =  1.3530;   if(nr==48)  l =  1.3530;
      if(nr==39)  l =  1.3498;   if(nr==49)  l =  1.3498;
    }

    if(nr<30)
      l = ( 0.5*ext_line_info(Z, ion, nr+10).lambda
           +1.0*ext_line_info(Z, ion, nr+20).lambda
          )/1.5;

    g_low = 2;
    if(nr>20 && nr<30)  g_up = [4, 2];
    if(nr>30 && nr<40)  g_up = 2;
    if(nr>40 && nr<50)  g_up = 4;
  }

  % He-like ions: triplet and resonance absorption line series
  if( Z==ion+1 && nr>=19 && nr<50 )
  { if(Z==1 or Z==2 or Z==6 or Z==7 or Z==8 or Z==10 or Z==12 or Z==13 or Z==14 or Z==16 or Z==18 or Z==20 or Z==26 or Z==28)
    { require_atoms();
      % He f
      if(nr==19)  atomdbids = where(trans(Z, ion, [2], 1));
      % He i
      if(nr==20)  atomdbids = where(trans(Z, ion, [5], 1));  % should be a mixture of 5 and 6
      if(nr==30)  atomdbids = where(trans(Z, ion, [6], 1));
      if(nr==40)  atomdbids = where(trans(Z, ion, [5], 1));
      % He alpha
      if(nr==21)  atomdbids = where(trans(Z, ion, [ 7], 1));
      % He beta
      if(nr==22)  atomdbids = where(trans(Z, ion, [13], 1));
      % He gamma
      if(nr==23)  atomdbids = where(trans(Z, ion, [23], 1));
      % He delta
      if(nr==24)  atomdbids = where(trans(Z, ion, [37], 1));
    }
    if(Z==8) % O VII
    { if(nr==25)  l = 17.2000;
      if(nr==26)  l = 17.0860;
      if(nr==27)  l = 17.0092;
      if(nr==28)  l = 16.9584;
      if(nr==29)  l = 16.9223;
    }
    if(Z==10) % Ne IX
    { if(nr==25)  l = 10.6426;
      if(nr==26)  l = 10.5650;
      if(nr==27)  l = 10.5130;
    }
    if(Z==11) % Na X
    { if(nr==19)  l = 11.190 ;  % Mewe et al. (1985, Table 1, p. [14])
      if(nr==20)  l = 11.080 ;   % Mewe et al. (1985, Table 1, p. [14])
      if(nr==21)  l = 11.0027;
      if(nr==22)  l =  9.4330;
      if(nr==23)  l =  8.9828;
      if(nr==24)  l =  8.7884;
      if(nr==25)  l =  8.6862;
      if(nr==26)  l =  8.6257;
      if(nr==27)  l =  8.5869;
      if(nr==28)  l =  8.5605;
      if(nr==29)  l =  8.5417;
    }
    if(Z==12) % Mg XI
    { if(nr==25)  l =  7.2247;
      if(nr==26)  l =  7.1741;
      if(nr==27)  l =  7.1415;
      if(nr==28)  l =  7.1194;
      if(nr==29)  l =  7.1037;
    }
    if(Z==13) % Al XII
    { if(nr==25)  l =  6.1028;
      if(nr==26)  l =  6.0598;
      if(nr==27)  l =  6.0322;
      if(nr==28)  l =  6.0134;
      if(nr==29)  l =  6.0000;
    }
    if(Z==14) % Si XIII
    { if(nr==25)  l =  5.2231;
      if(nr==26)  l =  5.1861;
      if(nr==27)  l =  5.1623;
      if(nr==28)  l =  5.1462;
      if(nr==29)  l =  5.1347;
    }
    if(Z==16) % S XV
    { if(nr==25)  l =  3.9501;
      if(nr==26)  l =  3.9219;
      if(nr==27)  l =  3.9039;
      if(nr==28)  l =  3.8916;
      if(nr==29)  l =  3.8828;
    }
    if(Z==18) % Ar XVII
    { if(nr==25)  l =  3.0950;
    }

    g_low = 1; % 1s^2 ~ ^1S_0
    if(nr==19) g_up = 3;  % He f  ->  1s2s ~ ^3S_1
    if(nr==20) g_up = 3;  % He i  ->  1s2p ~ ^3P_1
    if(nr>20 && nr<30)  g_up = 3;  % He r  ->  1s2p ~ ^1P_1
  }

  if(l==NULL && length(atomdbids)>0) { require_atoms(); l = line_info(atomdbids[0]).lambda; }
  if(A==NULL && length(atomdbids)>0) { require_atoms(); A = array_struct_field( array_map(Struct_Type, &line_info, atomdbids), "A"); }

  % return info structure
  if(l==NULL)  return NULL;
  variable info = struct { Z=Z, ion=ion, nr=nr, lambda=l, A=A, g_up=[g_up], g_low=g_low, gf };
  if(A!=NULL)  info.gf = sum(1.4992e-16*l^2 * g_up * A);

  return info;
}
