% er_sexlavg PROGRAMMING NOTES:
%
% (In the interest of keeping the code not ridiculously long,
% I've broken this off).
%
% Changes from fmri_selxavg:
%
%   * Doesn't use an invollist anymore (that's for bfiles). Instead, takes
%   an inpath list of mrLoadRet scan directories (e.g.,
%   mySession/Inplane/Original/tSeries/Scan1.) Similarly, the
%   outstem list (-o flag) should be the mrLoadRet scan directory to save
%   the tSeries output (generally .../Inplane/Averages/tSeries/Scan#/).
%
%   * New analysis option: -highpass [period]. This causes the code to high-pass
%   filter the data using removeBaseline2 from mrLoadRet before selective
%   averaging. Uses a 60-second cutoff period of low-frequency baseline
%   drift to remove from the time course, expressed in frames of the time
%   series. (This is thought to be better than a linear or quadratic
%   baseline fit for certain types of rapid-event-related designs.)
%
%   * Saving: the obvious change is that this code now saves/loads tSeries
%   instead of b-files. In addition, exactly what gets saved and where is a
%   little different. For fmri_selxavg, the outstem would save the raw
%   deconvolved time courses in 'h_###.bfloat', with mean functional images
%   in 'h-offset_###.bfloat' and percent signal changes was saved only if the user
%   specificed the -psc flag. Now, it saves the % signal change as tSeries
%   by default, saves the h-offset as a mean map (meanMapScan#.mat), and
%   also saves the omnibus contrast as a mean map. The mean maps are
%   located in the data type directory, e.g., mySession/Inplane/Averages/.
%   Raw timecourses (previously the main output) are saved in the same path
%   as the tSeries under the name 'raw_###.mat', but only if the '-raw' or 
%   '-saveraw' flags are set. (Otherwise, doesn't save raw data by default).
%
%   Also, now block-designed (non-deconvolved) scans are handled
%   differently from rapid event-related scans. The outstem is [more]
%
%   * Force saving: entering '-force', '-saveover', or '-override' as an
%   argument will now cause the code to automatically save over any
%   pre-existing files in the destination directory without prompting.
%
%   * Saves the omnibus contrast (p-value from F-test of all non-null 
%   conditions vs. null). If deconvolving, saves it as 'omnibus_scanX.mat'
%   in the Inplane/Averages directory. X is the scan # of the output scan
%   created for the deconvolved data. If fitting a hemodynamic response
%   (block-design, long event-related), saves it as 'omnibus_scanY-Z.mat'
%   in the dataDir of the session -- e.g., Inplane/Originals.
%   Y and Z are the first and last 
%   input scans (if only one input scan, saves as 'omnibus_scanY.mat').
%   This is saved as a parameter map.
%
%   * In general, there are a lot of things that this code can do that I 
%   leave off -- like auto-whitening, fwhm smoothing, etc. Since many of
%   these things are kind of against the philosophy of mrVISTA, I haven't
%   debugged their use in this context. But feel free to try!
%
% 06/18/03 ras: attempt to integrate into mrLoadRet tools
% 03/08/04 ras: Several further updates, inclding compatibiliity with
% block-design expts.
% 04/02/04 ras: saves omnibus contrast as a parameter map now.
% 05/12/04 ras: started cleanup of a lot of the bloat here. Removing
% autowhitening, spatial smoothing options, since we don't really use
% these. If you care about these options, see er_selxavgFull.
%
% For more info on the original selxavg, see $fsfast/docs/selxavg.ps. or:
% merlin.psych.arizona.edu/~dpat/Public/Imaging/MGH/FS-FASTtutorial.pdf 
% '$Id: er_selxavg_notes.m,v 1.1 2005/03/29 21:33:51 sayres Exp $'