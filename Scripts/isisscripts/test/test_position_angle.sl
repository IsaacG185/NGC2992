#!/usr/bin/env isis

require("./share/isisscripts");

% the position angle should go N->E->S->W

variable ra_ref=hms2deg(5,0,0);
variable dec_ref=dms2deg(+0,0,0);

% slight offsets to the N, E, S, and W
variable ra_cmp=[ra_ref,ra_ref+1e-7,ra_ref,ra_ref-1e-7];
variable dec_cmp=[dec_ref+1e-7,dec_ref,dec_ref-1e-7,dec_ref];

variable pa=position_angle(ra_cmp,dec_cmp,ra_ref,dec_ref;deg);

variable pacmp=[0.,90.,180.,270.];

variable ndx=where(abs(pa-pacmp)>1e-6);

if (length(ndx)==0) {
    exit(0);
} else {
    vmessage("Position angle: Error in computation of PA");
    exit(1);
}