
define line_intersect() 
%!%+
%\function{line_intersect}
%\synopsis{Calculate the intersection of two lines defined by
%          two points each}
%\usage{res=line_intersect(P0,P1,P2,P3,&alphaP,&alphaQ);}
%\altusage{res=line_intersect(P0x,P0y,P1x,P1y,P2x,P2y,P3x,P3y,&alphaP,&alphaQ);}
%\description
% This function implements a fast line intersection algorithm
% based on 
% https://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
% between the line segments P=P0--P1 and Q=P2--P3, where the points Pi 
% are defined as structures of the type struct {x,y} or through 
% coordinates P0x,P0y, etc.
%
% The function returns 1 if an intersection exists and 0 if not.
%
% If an intersection exists, the function returns the relative position
% of the intersection point on the segments in variables alphaP and alphaQ.
%!%-
{
    variable P0,P1,P2,P3,alphaP,alphaQ;

    if (_NARGS==6) {
	(P0,P1,P2,P3,alphaP,alphaQ)=();
    } else {
	if ( _NARGS==10 ) {
	    variable P0x,P0y,P1x,P1y,P2x,P2y,P3x,P3y;
	    (P0x,P0y,P1x,P1y,P2x,P2y,P3x,P3y,alphaP,alphaQ)=();
	    P0=struct{x=P0x,y=P0y};
	    P1=struct{x=P1x,y=P1y};
	    P2=struct{x=P2x,y=P2y};
	    P3=struct{x=P3x,y=P3y};
	} else {
	    help(_function_name());
	}
    }
    
    variable S10x=P1.x-P0.x;
    variable S10y=P1.y-P0.y;
    variable S32x=P3.x-P2.x;
    variable S32y=P3.y-P2.y;

    variable denom=S10x*S32y-S32x*S10y;
    if (denom==0.) {
	return 0; % colinear - we define segments to be not intersecting in this case
    }

    variable denomPositive=(denom>0.);

    variable S02x=P0.x-P2.x;
    variable S02y=P0.y-P2.y;

    variable snumer=S10x*S02y-S10y*S02x;

    if ((snumer<0)==denomPositive) {
	return 0; % no intersection
    }

    variable tnumer=S32x*S02y-S32y*S02x;
    if ((tnumer<0.)==denomPositive) {
	return 0; % no intersection
    }

    if (((snumer>denom)==denomPositive) or ((tnumer>denom)==denomPositive)) {
	return 0; % no intersection
    }

    @alphaP=tnumer/denom;
    @alphaQ=snumer/denom;
    return 1;
}

private define new_greiner_vertex() {
    %
    % private function: define a new vertex point for the
    % Greiner and Hormann algorithm
    %
    variable x,y,id,alpha,inter;
    inter=0;
    alpha=0.;
    if (_NARGS==3) {
	(x,y,id)=();
    }
    if (_NARGS==4) {
	(x,y,id,alpha)=();
	inter=1;
    }
    
    return struct {
        x=x,       % x-coordinate
	y=y,       % y-coordinate
        id=id,     % identifier
	next=NULL, % pointer to next vertex point
	prev=NULL, % pointer to current vertex point
	intersect=inter, % 0 not an intersect, 1 intersect
	neighbor=NULL, % pointer to this point in other array
	alpha=alpha, % storage for distance from last non-intersection point
	entry=-1,  % 1 if entry point, 0 if not, -1 undefined
	processed=0 % true if vertex has been taken care of
    };
}

private define new_greiner_vertexlist(P) {
    % build up a vertex list for the Greiner-Hormann algorithm
    variable i;
    variable sstart=new_greiner_vertex(P.x[0],P.y[0], P.id[0]);
    variable ssold=sstart;
    _for i(1,length(P.x)-1,1) {
	variable ssnew=new_greiner_vertex(P.x[i],P.y[i], P.id[i]);
	ssnew.prev=ssold;
	ssold.next=ssnew;
	ssold=ssnew;
    }
    sstart.prev=ssold;
    ssnew.next=sstart;
    return sstart;
}

private define greiner_insert_between(P,Q,ins) {
    % insert vertex np between non-intersecting points P and Q
    % nb: does not check that P, Q are non intersection points
    % for speed reasons

    % np must be an intersection vertex with alpha set
    
    % find correct insertion segment
    variable pp=P;
    while (pp.next != Q && pp.next.alpha<ins.alpha) {
	pp=pp.next;
    }
    
    ins.prev=pp;
    ins.next=pp.next;
    ins.next.prev=ins;
    pp.next=ins;
}

define greiner_hormann()
%!%+
%\function{greiner_hormann}
%\synopsis{Clipping and logical intersection of two polygons}
%\usage{List_Type polylist= greiner_hormann(src, clp);}
%\altusage{List_Type polylist= greiner_hormann(sx,sy,cx,cy);}
%\qualifiers{
%\qualifier{intersection}{return the intersection of src and clp
%    (i.e., clip src against clp), the default}
%\qualifier{union}{return the union of src and clp}
%\qualifier{without}{remove clp from src}
%\qualifier{perturb}{slightly perturb src to reduce probability of
%    failure of the algorithm (see description below)}
%}
%\description
% This function implements the Greiner-Hormann algorithm for polygon
% intersections (Greiner & Hormann, 1998, ACM Trans. Graph. 17(2), 71-83).
% The polygons are given as structures struct {x=[], y=[]}, other structure
% tags are ignored. The function returns a list of closed polygons of this
% type (which may be empty!). The returned polygons also include a tag
% id which is 0 if the point originates in src, 1 if the point originates in
% clp, and -1 if this is a newly inserted intersection point.
%
% Alternatively, the x- and y-coordinates of the polygon points can be
% given. In this case the return will still be a list of structs.
%
% The polygons must be closed, i.e., src.x[0]==src.x[-1], src.y[0]=src.y[-1],
% and the same for clp. The polygons can self-intersect, there is almost no
% limitation on their shape. In the case of intersection, the determination 
% that a point is inside a polygon is done using the winding number
% (see help for function point_in_polygon).
%
% The Greiner-Horman algorithm has an issue for polygons that have colinear
% overlapping sides. If the qualifier "perturb" is set, the coordinates
% in src are randomly perturbed at a level of 1e-8 to reduce the probability
% of this happening.
% 
%\example
%
% variable p=xfig_plot_new(15,15);
% p.world(-1.,1.,-1.,1.);
%
% variable src,clp;
%
% % a complex polygon
% src=struct {x=[-0.25,0.00,0.25,0.3,0.8,0.5,-0.25],
%             y=[ 0.80,-0.40,0.8,-0.4,0.0,0.8,0.80]};
%
% % a square
% clp=struct {x=[-0.5,0.5,0.5,-0.5,-0.5]+0.2,
%              y=[-0.5,-0.5,0.5,0.5,-0.5]+0.2};
%
% p.plot(src.x,src.y;color="blue",depth=150);
% p.plot(clp.x,clp.y;color="green",depth=150);
%
% variable res=greiner_hormann(src,clp;intersection);
%
% variable i;
% _for i(0,length(res)-1,1) {
%     p.plot(res[i].x,res[i].y;color="red",depth=50);
% }
%
% p.render("polygons.pdf");
%\seealso{point_in_polygon}
%!%-
{
    if (_NARGS != 2 or _NARGS!=4) {
	help(_function_name());
    }

    variable uni=qualifier_exists("union");
    variable inter=qualifier_exists("intersection");
    variable without=qualifier_exists("without");
    variable sm=uni+inter+without;
    
    if (sm>1) {
	throw UsageError,sprintf("Usage error in %s: only one qualifier of union, intersection, and without can be set!\n", _function_name());
    }

    % default: clip S with C (i.e., get the intersection of the polygons)
    if (sm==0) {
	inter=1;
    }

    % build up vertex list of the subject and the clip polygons
    variable S,C;
    if (_NARGS==2) {
        variable Stmp,Ctmp;
	(Stmp,Ctmp)=();
        S=struct { x=@Stmp.x, y=@Stmp.y, id=Char_Type[length(Stmp.x)]};
        C=struct { x=@Ctmp.x, y=@Ctmp.y, id=1+Char_Type[length(Ctmp.x)]};
    } else {
	variable sx,sy,cx,cy;
	(sx,sy,cx,cy)=();
	S=struct { x=sx[*], y=sy[*], id=Char_Type[length(sx)] };
	C=struct { x=cx[*], y=cy[*], id=1+Char_Type[length(cx)] };
    }

    if (S.x[0]!=S.x[-1] || S.y[0]!=S.y[-1] ) {
	throw UsageError,sprintf("Usage error in %s: Source polygon is not closed!\n", _function_name());
    }

    if (C.x[0]!=C.x[-1] || C.y[0]!=C.y[-1] ) {
	throw UsageError,sprintf("Usage error in %s: Clip polygon is not closed!\n", _function_name());
    }

    if (length(S.x)!=length(S.y)) {
        throw UsageError,sprintf("Usage error in %s: Source x and y arrays must be of equal length\n",_function_name());
    }

    if (length(C.x)!=length(C.y)) {
        throw UsageError,sprintf("Usage error in %s: Clip x and y arrays must be of equal length\n",_function_name());
    }

    if (qualifier_exists("perturb")) {
        S.x+=1e-8*urand(length(S.x));
        S.y+=1e-8*urand(length(S.x));

        S.x[-1]=S.x[0];
        S.y[-1]=S.y[0];
    }

    
    variable src=new_greiner_vertexlist(S);
    variable clp=new_greiner_vertexlist(C);

    % we'll be returning a list of polygons
    variable polylist={};

    %
    % Step 1: find all intersection points between the polygons and
    % insert them into the polygons
    %
    variable numinter=0;
    variable ss=src;
    do {
	% find next vortex in src that is not an intersection
	variable snxt=ss;
	do {
	    snxt=snxt.next;
	} while (snxt.intersect==1);

	variable cc=clp;
        do {
	    % find next vortex that is not an intersection
	    variable cnxt=cc;
	    do {
		cnxt=cnxt.next;
	    } while (cnxt.intersect==1);

	    % Is there an intersection?
	    variable alphaP,alphaQ;
	    if (line_intersect(ss,snxt,cc,cnxt,&alphaP,&alphaQ)==1) {
		numinter++;
		% insert new intersection point into both polygons
		variable newx=ss.x+alphaP*(snxt.x-ss.x);
		variable newy=ss.y+alphaP*(snxt.y-ss.y);

		variable np1=new_greiner_vertex(newx,newy,-1,alphaP);
		variable np2=new_greiner_vertex(newx,newy,-1,alphaQ);
		np1.neighbor=np2;
		np2.neighbor=np1;
		greiner_insert_between(ss,snxt,np1);
		greiner_insert_between(cc,cnxt,np2);
	    }
	    cc=cnxt;
	} while (cc!=clp);
	ss=snxt;

    } while (ss!=src);
        
    %
    % Deal with the case that no intersections were found
    %
    if (numinter==0) {
	% is S inside C or outside?
	variable insi=point_in_polygon(S.x[0],S.y[0],C.x,C.y);

	if (insi) {
	    % S is inside C
	    if (uni) {
		list_append(polylist,struct{x=C.x[*],y=C.y[*],id=C.id[*]});
	    }

	    % S without C gives empty list
	    if (inter) {
		list_append(polylist,struct{x=S.x[*],y=S.y[*],id=C.id[*]});
	    }
	} else {
	    % S is outside C

	    % union and without C 
	    if (uni or without) {
		list_append(polylist,struct{x=S.x[*],y=S.y[*],id=S.id[*]});
	    }

	    % intersection gives empty list
	}
	return polylist;
    }
		
    %
    % Phase 2: identify the entry and exit points;
    %   depending on the final operation desired, the
    %   initialization is done in a slightly different way
    %	

    % these different starting values will result in our three
    % cases
    variable sentry,centry;
    if (uni) {
	sentry=0;
	centry=0;
    }
    if (inter) {
	sentry=1;
	centry=1;
    }
    if (without) {
	sentry=0;
	centry=1;
    }

    % is starting point for ss inside of C?
    ss=src;
    variable entry=sentry xor point_in_polygon(ss.x,ss.y,C.x,C.y);	
    while (ss.next!=src) {
	if (ss.intersect) {
	    ss.entry=entry;
	    entry=not entry;
	}
	ss=ss.next;
    }

    % is starting point for cc inside of S?
    cc=clp;
    entry=centry xor point_in_polygon(cc.x,cc.y,S.x,S.y);	
    while (cc.next!=clp) {
	if (cc.intersect) {
	    cc.entry=entry;
	    entry=not entry;
	}
	cc=cc.next;
    }
    
    %
    % Step 3: Go through polygons and build up the new structure
    %
    variable unprocessed=1;
    do {
	
	%
	% go to the first unchecked intersection in the list
	%
	variable xx={};
	variable yy={};
        variable id={};
	
	cc=src;
	while ( (cc.intersect==0 || cc.processed==1) && cc.next!=src) {
	    cc=cc.next;
	}
	do {
	    cc.processed=1;
	    if (cc.entry==1) {
		do {
		    list_append(xx,cc.x);
		    list_append(yy,cc.y);
                    list_append(id,cc.id);
		    cc.processed=1;
		    cc=cc.next;
		} while (cc.intersect==0);
	    } else {
		do {
		    list_append(xx,cc.x);
		    list_append(yy,cc.y);
                    list_append(id,cc.id);
		    cc.processed=1;
		    cc=cc.prev;
		} while (cc.intersect==0);
	    }
	    cc.processed=1;
	    cc=cc.neighbor;
	} while (cc.processed==0);

        % save the current polygon on the output list
        xx=list_to_array(xx);
        yy=list_to_array(yy);
        id=list_to_array(id);    
	list_append(polylist,struct{x=[xx,xx[0]],y=[yy,yy[0]],id=[id,id[0]]});

	cc=src;
	unprocessed=0;
	while (cc.next!=src) {
	    if (cc.intersect==1 && cc.processed==0) {
		unprocessed++;
	    }
	    cc=cc.next;
	}
	    
	% is there still an unprocessed intersection in the list?
	cc=src;
	unprocessed=0;
	while (unprocessed==0 && cc.next!=src) {
	    if (cc.intersect==1 && cc.processed==0) {
		unprocessed=1;
	    }
	    cc=cc.next;
	}
    } while (unprocessed==1);
    
    return polylist;
}
