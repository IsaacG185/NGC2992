define clip_polyline_polygon(polyline,polygon)
%!%+
%\function{clip_polyline_polygon}
%\usage{clipped=clip_polyline_polygon(line,polygon)}
%\qualifiers{
%\qualifier{evenodd}{use the crossing number method}
%\qualifier{crossing}{use the crossing number method}
%\qualifier{winding}{use the winding number method (the default)}
%}
%\description
% This function clips a polyline defined by line=struct{x=[],y=[]},
% where x and y are the points connected by the polyline, against
% a closed polygon=struct{x=[],y=[]}, where again x and y are the points
% connected by the polygon and where x[0]==x[-1] and y[0]==y[-1].
%
% The function returns a list of polylines that contain the segments
% of the line that are inside of the polygon. This list can be empty if
% there is no overlap.
%
% For complex polygons with intersecting segments, the qualifier defines
% what constitues the inside of the polygon.
%
% If you want to clip against a simple rectangle, use clip_polyline_rectangle
% for a faster algorithm.
%
%\seealso{point_in_polygon,clip_polyline_rectangle,clip_points_polygon}
%!%-
{
    variable evenodd=(qualifier_exists("crossing") || qualifier_exists("evenodd"));


    %
    % intersect each segment of poly with all segments of
    % the polygon
    % FIXME: this is ok for polygons and polylines with a small number
    % of segments. For polygons with a large number of segments we still
    % need to implement a version of the function that is based on
    % a binary search tree.
    %
    variable i,j;

    variable outpolyx={};
    variable outpolyy={};
    variable state={};

    variable crossing=2;
    variable oldpt=1;

    variable npolygon=length(polygon.x);
    variable nline=length(polyline.x);
    %
    % search for intersections of the segments of the polyline with
    % all segments of the polygon (so this can be expensive)
    %
    % we generate a new temporary polyline, outpoly, that contains
    % the points of the polyline and all crossing points,
    % remembering whether we're dealing with a new crossing point or
    % not
    %
    % FIXME: this can be memory intensive, since we're temporarily
    % duplicating polyline. A better approach might be to remember
    % the alphalists for each polyline segment (see below) and then
    % use these in the polyline splitting step that follows. This is a
    % bit more complicated to implement and up to now I have not
    % encountered real memory problems that have forced me to takle
    % this
    %
    _for i(0,nline-2) {
        list_append(outpolyx,polyline.x[i]);
        list_append(outpolyy,polyline.y[i]);
        list_append(state,oldpt);

        variable alphalist={};
        _for j(0,npolygon-2) {
            variable alphap,alphaq;
            variable res=line_intersect(polyline.x[i],polyline.y[i],polyline.x[i+1],polyline.y[i+1],
            polygon.x[j],polygon.y[j],polygon.x[j+1],polygon.y[j+1],&alphap,&alphaq);
            if (res==1) {
                list_append(alphalist,alphap);
            }
        }

        % if there are intersections: add them in ordered form (i.e., in the
        % direction of the polyline) to the outpoly
        if (length(alphalist)>0) {
            alphalist=list_to_array(alphalist);
            variable ndx=array_sort(alphalist);
            foreach alphap ( alphalist[ndx] ) {
                variable xx=polyline.x[i]+alphap*(polyline.x[i+1]-polyline.x[i]);
                variable yy=polyline.y[i]+alphap*(polyline.y[i+1]-polyline.y[i]);
                list_append(outpolyx,xx);
                list_append(outpolyy,yy);
                list_append(state,crossing);
            }
        }
    }

    % don't forget the last point
    list_append(outpolyx,polyline.x[-1]);
    list_append(outpolyy,polyline.y[-1]);
    list_append(state,oldpt);

    outpolyx=list_to_array(outpolyx);
    outpolyy=list_to_array(outpolyy);
    
    %
    % second step: walk along the polyline and cut it apart.
    %
    % This is easy in the case of the even odd rule, but a bit
    % more complex in the case of the winding number/crossing method
    %

    % determine whether the first point is inside or outside
    % (__qualifiers given to ensure that evenodd is taken into account)
    % this gives the "state" of the current segment
    variable inside=point_in_polygon(outpolyx[0],outpolyy[0],polygon.x,polygon.y;;__qualifiers());

    % this is where the individual segments will end up
    variable polypieces={};

    % coordinates of the current segment
    variable segx={};
    variable segy={};

    _for i(0,length(outpolyx)-2) {
        if (inside) {
            list_append(segx,outpolyx[i]);
            list_append(segy,outpolyy[i]);
        }
    
        variable newseg=0; % 1 if we start a new segment
        if (state[i]==crossing) {
            if (evenodd) {
                % even odd rule: the state of the segment changes with each crossing
                newseg=1;
            } else {
                % winding number rule: it is possible to either remain inside or go outside.
                % Test this by looking at the location of the middle point between point i and i+1,
                % to avoid round (the point in the middle is guaranteed not to be on a crossing,
                % after all)
                %
                variable xm=(outpolyx[i]+outpolyx[i+1])/2.;
                variable ym=(outpolyy[i]+outpolyy[i+1])/2.;
                % no need for qualifiers: the default of point_in_polygin is the
                % winding number/crossing number
                variable segpt=point_in_polygon(xm,ym,polygon.x,polygon.y);
                % a new segment starts if the state changes
                % (remember that inside=0 is outside)
                newseg=(segpt!=inside);
            }

            %
            % if we're starting a new segment, save the polygon or start a new one
            %
            if (newseg) {
                if (inside) {
                    % we're leaving the polygon, so save the current
                    % segment and start a new one
                    list_append(polypieces,struct{x=list_to_array(segx),y=list_to_array(segy)});
                    inside=0;
                    segx={};
                    segy={};
                } else {
                    % we're entering the polygon
                    inside=1;
                    list_append(segx,outpolyx[i]);
                    list_append(segy,outpolyy[i]);
                }
            }
        }
    }
        
    % the last point is never a crossing point, so the state can't change
    if (inside) {
        list_append(segx,outpolyx[-1]);
        list_append(segy,outpolyy[-1]);
        list_append(polypieces,struct{x=list_to_array(segx),y=list_to_array(segy)});
    }

    % and we're done
    return polypieces;
}

