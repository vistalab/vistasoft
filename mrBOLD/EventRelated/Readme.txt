ABOUT EVENT-RELATED TOOLS FOR MRLOADRET-3.0

This folder collects a set of tools for mrLoadRet-3.0 that aid in analyzing event-related
(both long trial and rapid trial) fMRI experiments. The bulk of the (older) tools are essentially 
calls to functions used by the FS-FAST analysis program (see 
http://surfer.nmr.mgh.harvard.edu/fsfast/). (Now the majority of this has been 
rewritten from scratch -- much of it is duplicated in the GLM folder.)
Other tools, such as the time course UI, are written entirely by Rory
and fall completely under the GPL of mrVISTA.

Note that this tool set is different from the Analysis/EventAnalysis tools in mrLoadRet-2.5.

What these tools allow you to do:
	* Visualize time courses from ROIs, across arbitrary sets of scans, a number
	  of different ways, taking into account the sequence of conditons for the experiment
	  (works also with block-design and cyclical expts);
	* Deconvolve rapid event-related time courses into a mrLoadRet 'Deconvolved' data type;
	* Calculate contrast maps, comparing one condition to another, as param maps

What you need:
	* mrLoadRet 3.0
	* a 'stim' directory within the MRI session directory(incidentally useful for containing
	  the version of stimulus code used during that scanning session);
	* a 'stim/parfiles' subdirectory, containing .par files specifying the condition order of
	  your scans. Parfiles should end with a .par extension and be tab-delimited text files with
	  the following two columns: [onset of trial in seconds] [TAB] [condition number for this trial].
	 You may also add a third column of text containing labels of each trial. 

The main tool to use is eventMenu, which adds a menu to your mrLoadRet view for calling these
tools. For more info, also type:
	help eventMenu
	help glm
	help er_selxavg
	help computeContrastMap
	help timeCourseUI

For some more info on the Time Course UI, see: http://white/~sayres/mrvista/TimeCourseUI/,
or email me at [mylastname] AT stanford DOT edu.

Good luck!

-Rory Sayres, 3/10/2004
08/2005 -- added a few updates to these comments (not that it matters...)
	
