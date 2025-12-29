# ISISscripts

## How to use the ISISscripts

-   Load the single S-Lang script *isisscripts.sl*,
    which contains all functions of this package
    and which is located in its *share/* directory,  with

    ```c
    require("/path/to/isisscripts/share/isisscripts");
    ```
    or
    ```c
    ()=evalfile("/path/to/isisscripts/share/isisscripts.sl");
    ```

-   If you use the ISISscripts frequently, it may be convenient
    to add the command

    ```c
    add_to_isis_load_path("/path/to/isisscripts/share/");
    ```

    to your personal *~/.isisrc* startup file (or the system-wide
    */path/to/isis/etc/local.sl*, if you have access to that.)
    With such a setup, it is sufficient to run:

    ```c
    require("isisscripts");
    ```

-   The file *isisscripts.txt* contains documentation
    of most of the functions in the ISISscripts package.
    If it is in the same directory as *isisscripts.sl*,
    it will be automatically added to ISIS' interactive help.

## How to obtain the ISISscripts

-   If you only want to **use** the ISISscripts, it is sufficient to
    download *isisscripts.sl* (and possibly *isisscripts.txt*),
    e.g., from

     * http://www.sternwarte.uni-erlangen.de/isis/download/isisscripts.sl
     * http://www.sternwarte.uni-erlangen.de/isis/download/isisscripts.txt

    and store them somewhere, but in the same directory (see above).

-   The complete repository can be obtained with git:
    ```
    git clone http://www.sternwarte.uni-erlangen.de/gitlab/remeis/isisscripts.git
    ```
    or
    ```
    git clone git@serpens.sternwarte.uni-erlangen.de:remeis/isisscripts.git
    ```
    This requires that you have an gitlab account and that you have added the SSH
    key of your machine to your profile.

## How to cite the ISISscripts

-   If you find a function (or a set of functions) from the ISISscripts
    particularly helpful for your data analysis with ISIS, and therefore
    want to acknowledge the package, you can add a sentence like

    >This research has made use of ISIS functions
    >provided by ECAP/Remeis observatory and MIT
    >(http://www.sternwarte.uni-erlangen.de/isis/).

-   If you want to thank the specific developers, find out from the git
    repository's version history who has contributed to the function(s).


## How to modify the ISISscripts

-   The code of each individual function is located in a separate file
    below *src/* in a (more or less well organized) directory structure.
    (In principle, neither the splitting into single files nor the structure
    is needed, but both have proven useful to organize the source code.)

-   The *Makefile* in the repository's root directory runs a sequence of
    scripts from *bin/*, and *doc/bin/*, to create *share/isisscripts.sl*,
    respectively *share/isisscripts.txt*, from all _*.sl_ files below *src/*.
    A change in the source code will therefore only become effective after

    ```
    make
    ```

    was run (successfully). Specifically:

-   *bin/makestatic* searches for all function definitions in all files
    below *src/*. It also identifies all packages external to the
    isisscripts that might have to be required. It has knowledge about
    most external packages common in astronomy, but please contact
    joern.wilms@sternwarte.uni-erlangen.de if further packages should be
    needed.  

    The isisscripts also contain definitions of many functions which
    were not present in older versions of isis/slang (e.g., sincos,
    wherefirstmax and so on). makestatic checks for these functions, you
    do not need to define them in your own code if you want to use them.
    If further functions need to be added, please let us know.

-   The documentation is maintained in the form of text macros that
    can be processed with tmexpand (git://git.jedsoft.org/git/tmexpand.git).
    tmexpand is part of the ISISscripts repository.
    *doc/bin/tm-strip* extracts the text macro documentation from the _src/*.sl_
    files that is included between the markers _%!%+_ and _%!%-_.
    *doc/bin/tmexpand* expands the text macros, e.g., in S-Lang's internal
    documentation format for the interactive help. However, the text macros
    could, in principle, also be converted to, e.g., LaTeX or HTML output.

-   To make your contributions publicly available it is necessary that all 
    changes you want to publish are in a separate branch. Use
    ```
    git checkout -b <branch-name>
    ```
    to create and switch to a new branch.  
    After you commited your changes push with
    ```
    git push origin <branch-name>
    ```
    and create a merge request afterwards.
    
    __Note:__ Per default you are not allowed to push to the project repository
    unless you are a member of the project or the remeis group.
    To gain access, please visit the [remeis group](www.sternwarte.uni-erlangen.de/gitlab/remeis)
    page click on _request access_.

Short summary for users at the Dr. Karl Remeis observatory, Bamberg:
--------------------------------------------------------------------

0.  Clone the ISISscripts repository with the following command
    *git clone ssh://git@serpens.sternwarte.uni-erlangen.de:remeis/isisscripts*.
    If you keep your local working directory, you only have to run this 
    step once.

0.  Update your local working directory using *git pull*.

1.  Create new branch with *git checkout -b <new-branch>*

2.  Locate the file(s) below *src/* that contain the function(s) to be changed.
    UNIX tools like *find src -name ...* or *grep ... -R src/* may prove useful.

3.  Apply your change(s).

4.  Run *make*. It creates the isisscripts.{sl,txt} and also runs tests
    to check whether you broke something.

5.  If everything is okay, commit your changes using *git add* and *git commit*,
    or *git commit -a*.

6.  Push your commits to *www.sternwarte.uni-erlangen/gitlab/remeis/isisscripts.git*
    using *git push origin <branch-name>*. (This step requires that you 
    have added the SSH key of your machine to your gitlab account.)  

7.  Create a merge request in *gitlab* to get your changes reviewed and published.

--------------------------------------------------------------------

## Short note on documentation

Many of the provided isisscript functions are documented in a text file.
To display the help for a specific function try one of the following:

* function();       % call without arguments
* function(; help); % pass the help qualifier
* help function     % search with the help function

If you add a new function to the isisscripts which is meant to be used by others,
please provide at least minimal information on how to use it. A description of how
help texts are added can be found under [wiki/documentation-instructions](www.sternwarte.uni-erlangen.de/gitlab/remeis/isisscripts/wikis/documentation-instructions) TBD

More information can be found in the [remeis wiki](www.sternwarte.uni-erlangen.de/wiki)
also concerning general isis/slang problems and other softwarte.

If you find yourself challenched by a certain problem and you found a nice solution think
about writing a short article in the [remeis wiki](www.sternwarte.uni-erlangen.de/wiki)

If your new isisscript functions are so complicated that you want to provide more
complex examples. The best place to put them is in the [project wiki](www.sternwarte.uni-erlangen.de/gitlab/remeis/isisscripts/wikis/).
Do not forgett to place a link in the functions help text.
TBD (also more details on how to do it)