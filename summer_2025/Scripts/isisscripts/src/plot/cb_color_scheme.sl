require( "xfig" );

private define to_rgb (r, g, b){
          return (r << 16) | (g << 8) | b;
}

xfig_new_color("cb_orange",to_rgb(230,159,0));
xfig_new_color("cb_orange2",to_rgb(242,180,0));
xfig_new_color("cb_skyblue",to_rgb(86,180,233));
xfig_new_color("cb_bluishgreen",to_rgb(0,158,115));
xfig_new_color("cb_yellow",to_rgb(240,228,66));
xfig_new_color("cb_blue",to_rgb(0,114,178));
xfig_new_color("cb_vermillion",to_rgb(213,94,0));
xfig_new_color("cb_vermillion2",to_rgb(230,69,25));
xfig_new_color("cb_reddishpurple",to_rgb(204,121,167));


variable CB_COLOR_SCHEME = ["black","cb_vermillion","cb_blue","cb_orange","cb_bluishgreen",
		"cb_reddishpurple","cb_skyblue","cb_yellow"];
variable CB_COLOR_SCHEME_NB = [CB_COLOR_SCHEME[[1:]],"black"];

variable CB_COLOR_SCHEME_ALT = ["black","cb_vermillion2","cb_blue",
				"cb_orange2","cb_bluishgreen",
		"cb_reddishpurple","cb_skyblue","cb_yellow"];
variable CB_COLOR_SCHEME_ALT_NB = [CB_COLOR_SCHEME_ALT[[1:]],"black"];

variable CB_COLOR_SCHEME2 = ["black","cb_blue","cb_vermillion",
		 "cb_reddishpurple","cb_bluishgreen",
		 "cb_orange",
		  "cb_skyblue","cb_yellow"];
variable CB_COLOR_SCHEME2_NB = [CB_COLOR_SCHEME2[[1:]],"black"];


