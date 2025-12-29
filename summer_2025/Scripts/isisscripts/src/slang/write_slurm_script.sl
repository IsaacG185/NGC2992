%%%%%%%%%%%%%%%
define write_slurm_script(){
%%%%%%%%%%%%%%%
%!%+
%\function{write_slurm_script}
%\synopsis{writes a slurm job script, which can be submitted with squeue}
%\usage{write_slurm_script(file,jobname,walltime,cmds);}
%\qualifiers{
%\qualifier{queue}{set the queue (remeis by default)}
%\qualifier{silent}{do not show any output}
%\qualifier{serial}{instead of parallel, execute commands one after the other}
%\qualifier{option}{setting commands or environment variables before executing the actual commands}
%\qualifier{ntaks}{[=1] number of tasks per CPU}
%\qualifier{memory}{[=1000] MByte in memory allocated (--mem-per-cpu in slurm)}
%\qualifier{output}{output logfile name}
%\qualifier{error}{error logfile name}
%\qualifier{account}{if the selected queue needs a specific account set this qualifier accordingly}
%\qualifier{dir}{[=getcwd()] absolut path where the script should be run (default is cwd)}
%}
%\description
%    Writing a slurm job script, which can be submitted with squeue.
%    The function might yet not include all options and works best for
%    simple cases. The cmds variable is a String_Type array, with each
%    field being one command line. The 
%\example
%    % define your commands
%    variable cmds = 
%      [ "echo 123" , "echo 456" ]; 
%    % call the function
%    variable file = "slurmscript.slurm";
%    variable jobname = "script";
%    variable walltime = "00:30:00";
%    write_slurm_script(file,jobname,walltime,cmds);
%!%-

   variable file,name,walltime,cmds;
   switch (_NARGS)
   { case 4: (file,name,walltime,cmds) = (); }
   { help(_function_name); return; }

   variable fp = fopen(file,"w+");

   variable queue = qualifier("queue","remeis");
   
   () = fprintf(fp,"#!/bin/bash");
   () = fprintf(fp,"\n#SBATCH --partition %s",queue);
   if (qualifier_exists("account")) {
      fprintf(fp,"\n#SBATCH --account %s",qualifier("account","") );
   }
   () =  fprintf(fp,"\n#SBATCH --job-name %s",name);
   () = fprintf(fp,"\n#SBATCH --ntasks=%i",qualifier("ntasks",1));
   () = fprintf(fp,"\n#SBATCH --time %s",walltime);
   () = fprintf(fp,"\n#SBATCH --mem-per-cpu=%i",nint(qualifier("memory",1000.0)));
   () = fprintf(fp,"\n#SBATCH --output %s",qualifier("output",getcwd+name+".out-%a"));
   () = fprintf(fp,"\n#SBATCH --error %s",qualifier("error",getcwd+name+".err-%a"));
   if (not qualifier_exists("serial")){      
      () = fprintf(fp,"\n#SBATCH --array 0-%i",length(cmds)-1);
   }

   if (qualifier_exists("option")){
      () = fprintf(fp,"\n\n### general settings ###\n%s \n",qualifier("option"));
   }

   
   () = fprintf(fp,"\n\ncd %s \n",qualifier("dir",getcwd()));
   
   variable ii;

   %%% do we want to do it in parallel or in serial mode %%%
   if (qualifier_exists("serial")){      
      _for ii(0,length(cmds)-1){
	 () = fprintf(fp,"srun %s\n",cmds[ii]);
      }	   
   } else {
      _for ii(0,length(cmds)-1){
	 () = fprintf(fp,"\nCOMMAND[%i]=\"%s\"",ii,cmds[ii]);
      }	   
      () = fprintf(fp,"\n\nsrun ${COMMAND[$SLURM_ARRAY_TASK_ID]} \n");
   }
   fclose(fp);      


   ifnot (qualifier_exists("silent")){
      () = system("cat "+file);
   }
   
   return;
}
