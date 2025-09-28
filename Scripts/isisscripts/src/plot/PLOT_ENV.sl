% This is an extra file for setting global environment variables when the isisscripts are required
% The new build process put these two lines inside of two #ifeval statements which often was not evaluated

putenv("PGPLOT_BACKGROUND=white"); % invert default for better view.
putenv("PGPLOT_FOREGROUND=black");
