private define h_akritas(i,j,k,l,idat,dat)
{
    variable cj1, cj2;    
    cj1 = - idat[j,k];

    if (dat[i,k] < dat[j,k])	
    {
	cj1=idat[i,k];
    }

    cj2 = - idat[j,l];
    if(dat[i,l] < dat[j,l]) 
    {
	cj2=idat[i,l];
    }
    
    return cj1*cj2;
}

private define tau_kendall(k,l,ntot,idat,dat)
{
    variable sum = 0.0;
    variable i,j;
    variable ac = 2.0/(ntot*(ntot-1));

    _for j (0, ntot-1,1)
    {
	_for i (0,ntot-1,1)
	{
	    if (i >= j)
	    {
		break;
	    }
	    sum = sum + h_akritas(i,j,k,l,idat,dat);
	}
    }
    return sum * ac;
}

private define tau_kendall_partial(ntot,k1,k2,k3,idat,dat)
{
    return (tau_kendall(k1,k2,ntot,idat,dat)-tau_kendall(k1,k3,ntot,idat,dat)*
    tau_kendall(k2,k3,ntot,idat,dat)) / 
    sqrt((1.0-tau_kendall(k1,k3,ntot,idat,dat)^2)*
    (1.0-tau_kendall(k2,k3,ntot,idat,dat)^2));
}

private define an_akritas(ntot,idat,dat,k1,k2,k3)
{
    variable c1 = 16.0/(ntot-1);
    variable c2 = 6.0/((ntot-1)*(ntot-2)*(ntot-3));
    variable asum = 0.0;
    variable ave = 0.0;
    variable aasum = Double_Type[ntot];
    variable i1, i2, j1, j2, i;

    _for i1 (0, ntot-1,1)
    {
	_for j1 (0, ntot-3,1)
	{
	    %%% inner summation with j1<i2<j2 and all != i1
	    if(j1 == i1) 
	    {
		continue;
	    }
	    
	    _for j2(j1+2, ntot-1,1)
	    {
		if(j2 == i1)
		{
		    continue;
		}
		_for i2 (j1+1, j2-1,1)
		{
		    if(i2 == i1)
		    {
			continue;
		    }
		    
		    variable cj1, cj2, cj3, cj4, cj5, cj6, cj7;
		    variable gtsum = 0.0;

		    cj1=- idat[j1,k1];
		    if(dat[i1,k1]<dat[j1,k1]) cj1=idat[i1,k1];
		    cj2=- idat[j1,k2];
		    if(dat[i1,k2]<dat[j1,k2]) cj2=idat[i1,k2];
		    cj3=- idat[j1,k3];
		    if(dat[i1,k3]<dat[j1,k3]) cj3=idat[i1,k3];
		    cj4=- idat[j2,k2];
		    if(dat[i2,k2]<dat[j2,k2]) cj4=idat[i2,k2];
		    cj5=- idat[j2,k3];
		    if(dat[i2,k3]<dat[j2,k3]) cj5=idat[i2,k3];
		    cj6=- idat[i2,k2];
		    if(dat[j2,k2]<dat[i2,k2]) cj6=idat[j2,k2];
		    cj7=- idat[i2,k3];
		    if(dat[j2,k3]<dat[i2,k3]) cj7=idat[j2,k3];
		    gtsum=cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    cj1=- idat[j2,k1];
		    if(dat[i1,k1]<dat[j2,k1]) cj1=idat[i1,k1];
		    cj2=- idat[j2,k2];
		    if(dat[i1,k2]<dat[j2,k2]) cj2=idat[i1,k2];
		    cj3=- idat[j2,k3];
		    if(dat[i1,k3]<dat[j2,k3]) cj3=idat[i1,k3];
		    cj4=- idat[j1,k2];
		    if(dat[i2,k2]<dat[j1,k2]) cj4=idat[i2,k2];
		    cj5=- idat[j1,k3];
		    if(dat[i2,k3]<dat[j1,k3]) cj5=idat[i2,k3];
		    cj6=- idat[i2,k2];
		    if(dat[j1,k2]<dat[i2,k2]) cj6=idat[j1,k2];
		    cj7=- idat[i2,k3];
		    if(dat[j1,k3]<dat[i2,k3]) cj7=idat[j1,k3];
		    gtsum=gtsum+cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    
		    cj1=- idat[i2,k1];
		    if(dat[i1,k1]<dat[i2,k1]) cj1=idat[i1,k1];
		    cj2=- idat[i2,k2];
		    if(dat[i1,k2]<dat[i2,k2]) cj2=idat[i1,k2];
		    cj3=- idat[i2,k3];
		    if(dat[i1,k3]<dat[i2,k3]) cj3=idat[i1,k3];
		    cj4=- idat[j1,k2];
		    if(dat[j2,k2]<dat[j1,k2]) cj4=idat[j2,k2];
		    cj5=- idat[j1,k3];
		    if(dat[j2,k3]<dat[j1,k3]) cj5=idat[j2,k3];
		    cj6=- idat[j2,k2];
		    if(dat[j1,k2]<dat[j2,k2]) cj6=idat[j1,k2];
		    cj7=- idat[j2,k3];
		    if(dat[j1,k3]<dat[j2,k3]) cj7=idat[j1,k3];
		    gtsum=gtsum+cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    
		    cj1=- idat[i1,k1];
		    if(dat[j1,k1]<dat[i1,k1]) cj1=idat[j1,k1];
		    cj2=- idat[i1,k2];
		    if(dat[j1,k2]<dat[i1,k2]) cj2=idat[j1,k2];
		    cj3=- idat[i1,k3];
		    if(dat[j1,k3]<dat[i1,k3]) cj3=idat[j1,k3];
		    cj4=- idat[j2,k2];
		    if(dat[i2,k2]<dat[j2,k2]) cj4=idat[i2,k2];
		    cj5=- idat[j2,k3];
		    if(dat[i2,k3]<dat[j2,k3]) cj5=idat[i2,k3];
		    cj6=- idat[i2,k2];
		    if(dat[j2,k2]<dat[i2,k2]) cj6=idat[j2,k2];
		    cj7=- idat[i2,k3];
		    if(dat[j2,k3]<dat[i2,k3]) cj7=idat[j2,k3];
		    gtsum=gtsum+cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    
		    cj1=- idat[i2,k1];
		    if(dat[j1,k1]<dat[i2,k1]) cj1=idat[j1,k1];
		    cj2=- idat[i2,k2];
		    if(dat[j1,k2]<dat[i2,k2]) cj2=idat[j1,k2];
		    cj3=- idat[i2,k3];
		    if(dat[j1,k3]<dat[i2,k3]) cj3=idat[j1,k3];
		    cj4=- idat[j2,k2];
		    if(dat[i1,k2]<dat[j2,k2]) cj4=idat[i1,k2];
		    cj5=- idat[j2,k3];
		    if(dat[i1,k3]<dat[j2,k3]) cj5=idat[i1,k3];
		    cj6=- idat[i1,k2];
		    if(dat[j2,k2]<dat[i1,k2]) cj6=idat[j2,k2];
		    cj7=- idat[i1,k3];
		    if(dat[j2,k3]<dat[i1,k3]) cj7=idat[j2,k3];
		    gtsum=gtsum+cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    
		    cj1=- idat[j2,k1];
		    if(dat[j1,k1]<dat[j2,k1]) cj1=idat[j1,k1];
		    cj2=- idat[j2,k2];
		    if(dat[j1,k2]<dat[j2,k2]) cj2=idat[j1,k2];
		    cj3=- idat[j2,k3];
		    if(dat[j1,k3]<dat[j2,k3]) cj3=idat[j1,k3];
		    cj4=- idat[i2,k2];
		    if(dat[i1,k2]<dat[i2,k2]) cj4=idat[i1,k2];
		    cj5=- idat[i2,k3];
		    if(dat[i1,k3]<dat[i2,k3]) cj5=idat[i1,k3];
		    cj6=- idat[i1,k2];
		    if(dat[i2,k2]<dat[i1,k2]) cj6=idat[i2,k2];
		    cj7=- idat[i1,k3];
		    if(dat[i2,k3]<dat[i1,k3]) cj7=idat[i2,k3];
		    gtsum=gtsum+cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    
		    cj1=- idat[i1,k1];
		    if(dat[i2,k1]<dat[i1,k1]) cj1=idat[i2,k1];
		    cj2=- idat[i1,k2];
		    if(dat[i2,k2]<dat[i1,k2]) cj2=idat[i2,k2];
		    cj3=- idat[i1,k3];
		    if(dat[i2,k3]<dat[i1,k3]) cj3=idat[i2,k3];
		    cj4=- idat[j2,k2];
		    if(dat[j1,k2]<dat[j2,k2]) cj4=idat[j1,k2];
		    cj5=- idat[j2,k3];
		    if(dat[j1,k3]<dat[j2,k3]) cj5=idat[j1,k3];
		    cj6=- idat[j1,k2];
		    if(dat[j2,k2]<dat[j1,k2]) cj6=idat[j2,k2];
		    cj7=- idat[j1,k3];
		    if(dat[j2,k3]<dat[j1,k3]) cj7=idat[j2,k3];
		    gtsum=gtsum+cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    
		    cj1=- idat[j1,k1];
		    if(dat[i2,k1]<dat[j1,k1]) cj1=idat[i2,k1];
		    cj2=- idat[j1,k2];
		    if(dat[i2,k2]<dat[j1,k2]) cj2=idat[i2,k2];
		    cj3=- idat[j1,k3];
		    if(dat[i2,k3]<dat[j1,k3]) cj3=idat[i2,k3];
		    cj4=- idat[j2,k2];
		    if(dat[i1,k2]<dat[j2,k2]) cj4=idat[i1,k2];
		    cj5=- idat[j2,k3];
		    if(dat[i1,k3]<dat[j2,k3]) cj5=idat[i1,k3];
		    cj6=- idat[i1,k2];
		    if(dat[j2,k2]<dat[i1,k2]) cj6=idat[j2,k2];
		    cj7=- idat[i1,k3];
		    if(dat[j2,k3]<dat[i1,k3]) cj7=idat[j2,k3];
		    gtsum=gtsum+cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    
		    cj1=- idat[j2,k1];
		    if(dat[i2,k1]<dat[j2,k1]) cj1=idat[i2,k1];
		    cj2=- idat[j2,k2];
		    if(dat[i2,k2]<dat[j2,k2]) cj2=idat[i2,k2];
		    cj3=- idat[j2,k3];
		    if(dat[i2,k3]<dat[j2,k3]) cj3=idat[i2,k3];
		    cj4=- idat[j1,k2];
		    if(dat[i1,k2]<dat[j1,k2]) cj4=idat[i1,k2];
		    cj5=- idat[j1,k3];
		    if(dat[i1,k3]<dat[j1,k3]) cj5=idat[i1,k3];
		    cj6=- idat[i1,k2];
		    if(dat[j1,k2]<dat[i1,k2]) cj6=idat[j1,k2];
		    cj7=- idat[i1,k3];
		    if(dat[j1,k3]<dat[i1,k3]) cj7=idat[j1,k3];
		    gtsum=gtsum+cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    
		    cj1=- idat[i1,k1];
		    if(dat[j2,k1]<dat[i1,k1]) cj1=idat[j2,k1];
		    cj2=- idat[i1,k2];
		    if(dat[j2,k2]<dat[i1,k2]) cj2=idat[j2,k2];
		    cj3=- idat[i1,k3];
		    if(dat[j2,k3]<dat[i1,k3]) cj3=idat[j2,k3];
		    cj4=- idat[i2,k2];
		    if(dat[j1,k2]<dat[i2,k2]) cj4=idat[j1,k2];
		    cj5=- idat[i2,k3];
		    if(dat[j1,k3]<dat[i2,k3]) cj5=idat[j1,k3];
		    cj6=- idat[j1,k2];
		    if(dat[i2,k2]<dat[j1,k2]) cj6=idat[i2,k2];
		    cj7=- idat[j1,k3];
		    if(dat[i2,k3]<dat[j1,k3]) cj7=idat[i2,k3];
		    gtsum=gtsum+cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    
		    cj1=- idat[j1,k1];
		    if(dat[j2,k1]<dat[j1,k1]) cj1=idat[j2,k1];
		    cj2=- idat[j1,k2];
		    if(dat[j2,k2]<dat[j1,k2]) cj2=idat[j2,k2];
		    cj3=- idat[j1,k3];
		    if(dat[j2,k3]<dat[j1,k3]) cj3=idat[j2,k3];
		    cj4=- idat[i1,k2];
		    if(dat[i2,k2]<dat[i1,k2]) cj4=idat[i2,k2];
		    cj5=- idat[i1,k3];
		    if(dat[i2,k3]<dat[i1,k3]) cj5=idat[i2,k3];
		    cj6=- idat[i2,k2];
		    if(dat[i1,k2]<dat[i2,k2]) cj6=idat[i1,k2];
		    cj7=- idat[i2,k3];
		    if(dat[i1,k3]<dat[i2,k3]) cj7=idat[i1,k3];
		    gtsum=gtsum+cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    
		    cj1=- idat[i2,k1];
		    if(dat[j2,k1]<dat[i2,k1]) cj1=idat[j2,k1];
		    cj2=- idat[i2,k2];
		    if(dat[j2,k2]<dat[i2,k2]) cj2=idat[j2,k2];
		    cj3=- idat[i2,k3];
		    if(dat[j2,k3]<dat[i2,k3]) cj3=idat[j2,k3];
		    cj4=- idat[j1,k2];
		    if(dat[i1,k2]<dat[j1,k2]) cj4=idat[i1,k2];
		    cj5=- idat[j1,k3];
		    if(dat[i1,k3]<dat[j1,k3]) cj5=idat[i1,k3];
		    cj6=- idat[i1,k2];
		    if(dat[j1,k2]<dat[i1,k2]) cj6=idat[j1,k2];
		    cj7=- idat[i1,k3];
		    if(dat[j1,k3]<dat[i1,k3]) cj7=idat[j1,k3];
		    gtsum=gtsum+cj1*(2.0*cj2 - cj3*(cj4*cj5+cj6*cj7) );
		    
		    aasum[i1]=aasum[i1]+1.0/24.0*gtsum; %
		}
		
		
	    }
	}
	ave = ave + c2*aasum[i1];
    }
    ave=ave/ntot;

    _for i (0,ntot-1,1)
    {
	asum=asum+(c2*aasum[i]-ave)^2;
	
    }
    return asum*c1;
}


private define sigma_akritas(ntot,idat,dat,k1,k2,k3)
{
    variable sig2 = an_akritas(ntot,idat,dat,k1,k2,k3)/
    (ntot*(1.0-tau_kendall(k1,k3,ntot,idat,dat)^2)*
    (1.0-tau_kendall(k2,k3,ntot,idat,dat)^2));
    return sqrt(sig2);
}




define partial_correlation (data2)
%!%+
%\function{partial_correlation}
%\synopsis{Tests two luminosities for partial correlation due to redshift}
%\usage{partial_correlations(String_Type filename);}
%\description
%       This function tests if a correlation of two parameters is due to
%       the redshift. Description of method and code adapted from
%       Akritas & Siebert, 1996, MNRAS, 278, 919.
%       Works with FITS and ASCII files.
%
%       The input file needs 6 columns with luminosity1, UL, 
%       luminosity2, UL, redshift, UL. The upper limit columns should 
%       have a 1 for a detection, and a 0 for an upper limit.
%
%\examples
%    partial_correlation("data.txt")
%  
%    partial_correlation("data.fits")
%
%\seealso{}
%!%-
{
    %Get local time
    variable mn_a = localtime(_time).tm_min;
    variable hr_a = localtime(_time).tm_hour;
    
    
    %######################################
    % READ FILE

    variable abc = glob(data2);

    if (length(abc) != 1)
    {
	vmessage("File not found!");
	return 0;
    }

    variable testfits = strchop (abc[0],'.',0);
    if (testfits[1] == "FITS" || testfits[1] == "fits")
    {
	variable data = fits_read_table (data2,
	[{"%F","lum1"},{"%F","lum1_UL"},{"%F","lum2"},{"%F","lum2_UL"},
	{"%F","z"},{"%F","z_UL"}]);
    }
    else
    {
	data = ascii_read_table (data2,
	[{"%F","lum1"},{"%F","lum1_UL"},{"%F","lum2"},{"%F","lum2_UL"},
	{"%F","z"},{"%F","z_UL"}]);
    }


    %######################################
    % SETUP VARIABLES

    variable ntot = length(data.lum1);
    variable dat = Double_Type[ntot,3];
    variable idat = Double_Type[ntot,3];

    variable lumtemp = Struct_Type[3];
    lumtemp[0] = struct {lum = data.lum1};
    lumtemp[1] = struct {lum = data.lum2};
    lumtemp[2] = struct {lum = data.z};
    variable lumultemp = Struct_Type[3];
    lumultemp[0] = struct {lumul = data.lum1_UL};
    lumultemp[1] = struct {lumul = data.lum2_UL};
    lumultemp[2] = struct {lumul = data.z_UL};

    variable p,i;

    _for p (0, ntot-1,1)
    {
	dat[p,0]=-log(data.lum1[p])/log(10);	% CHANGE TO RIGHT CENSORING  
	dat[p,1]=-log(data.lum2[p])/log(10);	% CHANGE TO RIGHT CENSORING
	dat[p,2]=-data.z[p];			% CHANGE TO RIGHT CENSORING
	
	idat[p,0]=data.lum1_UL[p];
	idat[p,1]=data.lum2_UL[p];
	idat[p,2]=data.z_UL[p];
    }

    %######################################
    % COMPUTE PARTIAL CORRELATION COEFFICIENT

    variable k1 = 0;
    variable k2 = 1;
    variable k3 = 2;

    vmessage("\n---COMPUTE PARTIAL CORRELATION COEFFICIENT---");
    vmessage("Tau(1,2): %.2f", tau_kendall(k1,k2,ntot,idat,dat));
    vmessage("Tau(1,3): %.2f", tau_kendall(k1,k3,ntot,idat,dat));
    vmessage("Tau(2,3): %.2f", tau_kendall(k2,k3,ntot,idat,dat));

    variable res = tau_kendall_partial(ntot,k1,k2,k3,idat,dat);
    vmessage("Partial Kendalls tau: %.2f", res);
    vmessage("\n***************************");
    vmessage("Calculating variance...this takes some time...");
    variable s = sigma_akritas(ntot,idat,dat,k1,k2,k3);
    vmessage("Square root of variance (sigma): %.2f", s);

    if(abs(res/s) > 1.96) 
    {
	vmessage("Zero partial correlation rejected at level 0.05\n");
    }
    else 
    {
	vmessage("Null hypothesis cannot be rejected!");
	vmessage("--> No correlation present, if influence of third variable is excluded\n");
    }



    %######################################
    %End time
    variable mn_e = localtime(_time).tm_min;
    variable hr_e = localtime(_time).tm_hour;
    

    if (hr_e-hr_a == 0)
    {
	if (mn_e-mn_a == 0)
	{
	    vmessage("Running: < 1 min");
	}
	else
	{
	    vmessage("Running: "+string(mn_e-mn_a));
	}
    }
    else
    {
	vmessage("Running: "+string(hr_e-hr_a)+":"+string(mn_e-mn_a));
    }
}
