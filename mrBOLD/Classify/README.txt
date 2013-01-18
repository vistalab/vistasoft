LIBSVM Classification Toolbox

[Command to get a start:]------------------------------------------------------

	models = svmRun();

This will prompt you for all necessary info, and run by default a leave one out
procedure on your data.  Results will be printed to the console, and a
structure containing output and other relevant data will be returned.

A good play data set to begin with is in on white:
	/biac3/wandell7/data/Words/WordEccentricity/amr091006/

[More advanced usage:]---------------------------------------------------------

	svm = svmInit();
	// Mucking with your data inbetween
	models = svmRun(svm);

If there's something you want to do with the svm data in an intermediate stage,
you should initialize an svm structure and have a peek.  

While two functions exist with the purpose of averaging and relabling data to
perform more advanced classifications, a third is in development to completely
replace the two.  It will be a GUI to make the specification of what to average
far more explicit.

[Other advanced options:]------------------------------------------------------

	svmExportMap(svm, models, [1 2]);

This function will let you export a parameter map to visualize the choices of
the model on the brain.  I'd love input on how to gauge the significance or
insignificance of the types of maps this generates.

[Running searchlights:]-------------------------------------------------------

	searchlight = slInit('path', '/your/mrSESSION/dir', 'processes', 4);
	slRun(searchlight, 'spawnwith', 'manual');
	// execute commands spit out to terminal
	slComplete(searchlight);

Comments, suggestions, and edits are welcome.

[renobowen@gmail.com 2010]
