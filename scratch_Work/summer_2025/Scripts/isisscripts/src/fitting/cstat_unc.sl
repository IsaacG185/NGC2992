define kaastra_cstat_goodness() 
%!%+
%\function{kaastra_cstat_goodness}
%\synopsis{computes the theoretical Cash-statistics for a Poisson process}
%\usage{(Array_Type ce, Array_Type cn) = kaastra_cstat_goodness(Array_Type mu);}
%\description
% Given an array of predicted counts, mu, this function uses the
% expressions given by Kaastra (2017, A&A 605, A51) to compute the expected
% value of the contribution to the C-statistic for this bin, ce, and its
% variance, cn.
%
% This can be used to evaluate the expected value of the C-statistic of
% a fit (see function cstat_goodness()), or to show the expected model
% contribution in a plot of the cash statistics residuals.
%
% The function uses Kaastra's approximation to the exact formulae (his
% Eqs. 8-22), which are better than a few times 1e-4. Use the exact
% qualifier if you cannot live with this (it is unclear why you would
% want to do this).
% 
%\qualifiers{
%\qualifier{exact}{use Kaastra's exact equations 4-6 (slow; use only
%                    for testing, not necessary for practical work)}
%}
% 
%\seealso{cstat_goodness}
%!%-
{
    variable mu=();

    variable ce, cn, sn;
    variable k,pmu,argu,ndx;

    if (qualifier_exists("exact")) {
        %
        % Implementation of Kaastra's exact equations
        % Slow, but - well - exact...
        %

        
        % stop the loop once the relative change of ce and sn is
        % less than relmin
        % (typically still needs up to 800 passages through the loop...
        variable relmin=qualifier("relmin",1e-4);
        % k=0
        pmu=exp(-mu);
        argu=mu;
        ce=pmu*argu;
        sn=ce*argu;

        variable marel=1.;
        k=1;

        variable susu={};

        while (marel>relmin) {
            pmu*=mu/k;
            argu=mu+k*(log(k/mu)-1.);
            variable f1=pmu*argu;
            variable f2=f1*argu;
            ce+=f1;
            sn+=f2;
            marel=max([max(f1/ce),max(f2/sn)]);
            k++;
        }

        ce*=2.;
        sn*=4.;
        cn=sn-ce*ce;

        return(ce,cn);
    }

    %
    % Kaastra approximations (Eq. 8--22)
    %

    ce=Double_Type[length(mu)];
    cn=Double_Type[length(mu)];
    
    ndx=where(mu==0);
    if (length(ndx)>0) {
        ce[ndx]=0.;
    }
    ndx=where(0<mu<=0.5);
    if (length(ndx)>0) {
        ce[ndx]=((-0.25*mu[ndx]+1.38)*mu[ndx]-2*log(mu[ndx]))*mu[ndx];
    }
    ndx=where(0.5<mu<=2.);
    if (length(ndx)>0) {
        ce[ndx]=((((-0.00335*mu[ndx]+0.04259)*mu[ndx]-0.27331)*mu[ndx]+1.381)*mu[ndx]-2*log(mu[ndx]))*mu[ndx];
    }
    ndx=where(2.<mu<=5.);
    if (length(ndx)>0) {
        ce[ndx]=1.019275+0.1345*mu[ndx]^(0.461-0.9*log(mu[ndx]));
    }
    ndx=where(5.<=mu<10.);
    if (length(ndx)>0) {
        ce[ndx]=1.00624+0.604*mu[ndx]^(-1.68);
    }
    ndx=where(10.<mu);
    if (length(ndx)>0) {
        ce[ndx]=(0.226/mu[ndx]+0.1649)/mu[ndx]+1;
    }

    ndx=where(0.<=mu<=0.1);
    if (length(ndx)>0) {
        variable j;
        pmu=exp(-mu[ndx]);
        sn=pmu*mu[ndx]*mu[ndx];
        _for k(1,4) {
            pmu*=mu[ndx]/k;
            argu=mu[ndx]+k*(log(k/mu[ndx])-1.);
            sn+=pmu*argu*argu;
        }
        cn[ndx]=4.*sn-ce[ndx]^2.;
    }
    ndx=where(0.1<mu<=0.2);
    if (length(ndx)>0) {
        cn[ndx]=(((-262.*mu[ndx]+195.)*mu[ndx]-51.24)*mu[ndx]+4.34)*mu[ndx]+0.77005;
    }
    ndx=where(0.2<mu<=0.3);
    if (length(ndx)>0) {
        cn[ndx]=(4.23*mu[ndx]-2.8254)*mu[ndx]+1.12522;
    }
    ndx=where(0.3<mu<=0.5);
    if (length(ndx)>0) {
        cn[ndx]=((-3.7*mu[ndx]+7.328)*mu[ndx]-3.6926)*mu[ndx]+1.20641;
    }
    ndx=where(0.5<mu<1.);
    if (length(ndx)>0) {
        cn[ndx]=(((1.28*mu[ndx]-5.191)*mu[ndx]+7.666)*mu[ndx]-3.5446)*mu[ndx]+1.15431;
    }
    ndx=where(1.<mu<=2.);
    if (length(ndx)>0) {
        cn[ndx]=(((0.1125*mu[ndx]-0.641)*mu[ndx]+0.859)*mu[ndx]+1.0914)*mu[ndx]-0.05748;
    }
    ndx=where(2.<mu<=3.);
    if (length(ndx)>0) {
        cn[ndx]=((0.089*mu[ndx]-0.872)*mu[ndx]+2.8422)*mu[ndx]-0.67539;
    }
    ndx=where(3.<mu<=5.);
    if (length(ndx)>0) {
        cn[ndx]=2.12336+0.012202*mu[ndx]^(5.717-2.6*log(mu[ndx]));
    }
    ndx=where(5.<mu<=10.);
    if (length(ndx)>0) {
        cn[ndx]=2.05159+0.331*mu[ndx]^(1.343-log(mu[ndx]));
    }

    ndx=where(mu>10.);
    if (length(ndx)>0) {
        variable mu1=1./mu[ndx];
        cn[ndx]=((12.*mu1+0.79)*mu1+0.6747)*mu1+2.;
    }

    return (ce,cn);
}

define cstat_goodness() 
%!%+
%\function{cstat_goodness}
%\synopsis{computes the theoretical Cash-statistics and its
%uncertainty for the current data and model}
%\usage{Struct_Type ctheo = cstat_goodness();}
%\description
% This function computes the theoretical Cash statistics for the
% currently set data, using the expressions given by Kaastra
% (2017, A&A 605, A51). These values are returned in the tags
% cstat_theory and c_variance. The tag n_bins contains the number
% of bins entering these values, it should be the same as that
% obtained with eval_stat_counts().
%
% The values can be used to compute the goodness of the fit by
% comparing its best fit statistics (obtained with eval_stat_counts())
% with cstat_theory and the variance. The "f-sigma" probability for
% the best fit cash statistic is the range cstat_theory - f *c_variance
% to cstat_theory + f * c_variance.
%
%\qualifiers{
%\qualifier{quiet}{if set, the function will not complain if the fit
%                    statistics is not set to Cash or if there are bins without counts.}
%\qualifier{data}{if set, uses the measured counts in the computation
%                   (the default is the expected counts in the bin)}
%}
% 
%\seealso{kaastra_cstat_goodness,eval_stat_counts,set_fit_statistic}
%
%!%-
{
    variable ids=all_data(1); % all data sets with noticed bins
    if (typeof(ids)==Null_Type) {
        throw UsageError,sprintf("%s: No data sets with noticed bins have been defined.",_function_name());
    }

    variable st=strsplit(get_fit_statistic(),";");
    if (st[0]!="cash") {
	if(not qualifier_exists("quiet")) {
	    ()=fprintf(stderr,"%s: Warning: fit statistic is %s and not cash!\n",_function_name(),st[0]);
	}
    }
    
    variable ii;
    variable csum=0.;
    variable cvar=0.;
    variable nnoti=0;


    _for ii(0,length(ids)-1,1) {
	variable mu;
	if (qualifier_exists("data")) {
	    mu=(get_data_counts(ids[ii])).value;
	} else {
	    mu=(get_model_counts(ids[ii])).value;
	}
	
        variable noti=(get_data_info(ids[ii])).notice;
        variable cn,sn;

	mu=mu[where(noti==1)]; % noticed data only

	variable ndx=where(mu==0);
	if (length(ndx)!=0) {
	    if(not qualifier_exists("quiet")) {
		()=fprintf(stderr,"%s: Warning: Dataset %i contains valid bins with 0 counts.\n",_function_name(),ids[ii]);
	    }
	}

	
        % we're guaranteed that there's at least one noticed bin here
        (cn,sn)=kaastra_cstat_goodness(mu);
	
        csum+=sum(cn);
        cvar+=sum(sn);
	nnoti+=int(sum(length(where(noti))));
    }

    return struct {cstat_theory=csum,c_variance=sqrt(cvar),num_bins=nnoti};
}

%
% comparison plot for  Kaastra

% variable mumin=1e-7;
% variable mumax=500;
% variable npts=1000;

% variable mu=exp(log(mumin)+[0:(npts)-1]*log(mumax/mumin)/npts);

% variable ce,cn;
% (ce,cn)=kaastra_cstat_goodness(mu;exact,relmin=1e-3);


% variable p=xfig_plot_new(15,10);

% p.world(1e-7,100,0,1.6;xlog);

% p.plot(mu,ce;color="red",depth=100);
% p.plot(mu,sqrt(cn);color="blue",depth=150);

% variable ce1,cn1;
% (ce1,cn1)=kaastra_cstat_goodness(mu);

% p.plot(mu,ce1;color="black",line=1,depth=99);
% p.plot(mu,sqrt(cn1);color="black",line=1,depth=149);

% p.render("cstat.pdf");
