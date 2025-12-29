%!%+
%\function{_pgaxis}
%\synopsis{draw a labelled graph axis}
%\usage{_pgaxis(opt, x1, y1, x2, y2, v1, v2, step, nsub, dmajl dmajr, fmin, disp, orient);}
%\description
%    Besides \code{String_Type opt} and \code{Integer_Type nsub},
%    all parameters are of \code{Double_Type}.\n
%    \code{_pgaxis} draws an axis from world-coordinate position (\code{x1},\code{y1}) to (\code{x2},\code{y2}).
%
%    Normally, this routine draws a standard linear axis with equal subdivisions.
%    The quantity described by the axis runs from \code{v1} to \code{v2}.
%    If the '\code{L}' option is specified, the routine draws a logarithmic axis.
%    In this case, the quantity described by the axis runs from \code{10^v1} to \code{10^v2}.
%    A log. axis always has major, labeled, tick marks spaced by one or more decades.
%    If the major tick marks are spaced by one decade (as specified by the \code{step} argument),
%    then minor tick marks are placed at 2, 3, ..., 9 times each power of 10;
%    otherwise minor tick marks are spaced by one decade.  If the axis spans
%    less than two decades, numeric labels are placed at 1, 2, and 5 times each
%    power of ten.  If the axis spans less than one decade, or if it spans many decades,
%    it is preferable to use a linear axis labeled with log(quantity of interest).
%
%    Arguments:\n
%    \code{opt}    : a string containing single-letter codes for various options.\n
%             The options currently recognized are:\n
%             \code{L} : draw a logarithmic axis\n
%             \code{N} : write numeric labels\n
%             \code{1} : force decimal labelling, instead of automatic choice\n
%             \code{2} : force exponential labelling, instead of automatic.\n
%    \code{x1}, \code{y1} : world coordinates of one endpoint of the axis.\n
%    \code{x2}, \code{y2} : world coordinates of the other endpoint of the axis.\n
%    \code{v1}     : axis value at first endpoint.\n
%    \code{v2}     : axis value at second endpoint.\n
%    \code{step}   : major tick marks are drawn at axis value \code{0.0} plus or minus
%             integer multiples of step.  If \code{step==0.0}, a value is chosen automatically.\n
%    \code{nsub}   : minor tick marks are drawn to divide the major divisions into \code{nsub} equal
%             subdivisions (ignored if \code{step==0.0}).   If \code{nsub <= 1},
%             no minor tick marks are drawn. \code{nsub} is ignored for a logarithmic axis.\n
%    \code{dmajl}  : length of major tick marks drawn to left of axis
%             (as seen looking from first endpoint to second),
%             in units of the character height.\n
%    \code{dmajr}  : length of major tick marks drawn to right of axis,
%             in units of the character height.\n
%    \code{fmin}   : length of minor tick marks, as fraction of major.\n
%    \code{disp}   : displacement of baseline of tick labels to right of axis,
%             in units of the character height.\n
%    \code{orient} : orientation of label text, in degrees;
%             angle between baseline of text and direction of axis (0-360 deg).
%\seealso{http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGAXIS}
%!%-

%!%+
%\function{_pgbox}
%\synopsis{annotate the viewport with frame, axes, numeric labels, etc.}
%\usage{_pgbox(xopt, xtick, nxsub,  yopt, ytick, nysub);}
%\description
%    \code{x}/\code{yopt}: string of options for X (horizontal) / Y (vertical) axis of plot.
%            Options are single letters, and may be in any order:\n
%            "A": draw Axis (X axis is horizontal line Y=0, Y axis is vertical line X=0).
%            "B": draw bottom (X) or left (Y) edge of frame.
%            "C": draw top (X) or right (Y) edge of frame.
%            "G": draw Grid of vertical (X) or horizontal (Y) lines.
%            "I": Invert the tick marks; ie draw them outside the viewport instead of inside.
%            "L": label axis Logarithmically (see below).
%            "N": write Numeric labels in the conventional location
%                 -- below the viewport (X) or to the left of the viewport (Y).
%            "P": extend ("Project") major tick marks outside the box
%                 (ignored if option I is specified).
%            "M": write numeric labels in the unconventional location
%                 -- above the viewport (X) or to the right of the viewport (Y).
%            "T": draw major Tick marks at the major coordinate interval.
%            "S": draw minor tick marks (Subticks).
%            "V": orient numeric labels Vertically. This is only applicable to Y.
%                 The default is to write Y-labels parallel to the axis.
%            "1": force decimal labelling, instead of automatic choice (see PGNUMB).
%            "2": force exponential labelling, instead of automatic.
%
%    \code{x}/\code{ytick}: world coordinate interval between major tick marks on X/Y axis.
%             If \code{x}/\code{ytick==0}, the interval is chosen by _pgbox,
%             so that there will be at least 3 major tick marks along the axis.
%
%    \code{n}\{\code{x}/\code{y}\}\code{sub}: number of subintervals to divide the major coordinate interval into.
%               If \code{x}/\code{ytick==0} or \code{nx/ysub==0},the number is chosen by _pgbox.
%
%    To get a complete frame, specify BC in both \code{xopt} and \code{yopt}.
%    Tick marks, if requested, are drawn on the axes or frame or both,
%    depending which are requested. If none of ABC is specified,
%    tick marks will not be drawn.
%
%    For a logarithmic axis, the major tick interval is always 1.0.
%    The numeric label is 10^x where x is the world coordinate at the tick mark.
%    If subticks are requested, 8 subticks are drawn between each major tick at equal logarithmic intervals.
%\seealso{http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGBOX}
%!%-

%!%+
%\function{_pgsls (set line style)}
%\synopsis{set the line style attribute for subsequent plotting}
%\usage{_pgsls(Integer_Type linestyle);}
%\description
%    This attribute affects line primitives only;
%    it does not affect graph  markers, text, or area fill.
%    Five different line styles are available, with the following codes:
%    1 (full line), 2 (dashed), 3 (dot-dash-dot-dash), 4 (dotted),
%    5 (dash-dot-dot-dot). The default is 1 (normal full line).
%!%-
