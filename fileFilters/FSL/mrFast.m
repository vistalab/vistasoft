function mrFast(iFilePathName, outputPathBase)
%
%Author: Ian Spiro
%Date:   7/25/02
%
%Given the path to an iFile and the base name for output, function
%will optionally create vAnatomy and perform the entire
%segmentation process.  First the iFiles are converted to analyze
%format, then BET is run to strip the skull, then FAST is run to 
%perform the actual segmentation.  Finally, the output analyze file 
%is converted to a .Class file for use in mrGray.
%
%

fsl_path = '/usr/local/matlab/toolbox/fsl/';
bet = [fsl_path 'bin/bet'];
fast = [fsl_path 'bin/fast'];

button = questdlg('Choose Operation:',...
'Choose','Create vAnatomy','Fast Segmentation','Both','Both');
if strcmp(button,'Cancel')
   return;
end

if ~exist('iFilePathName','var') | isempty(iFilePathName)
   [fname, path] = uigetfile('*.*', 'Select one of the I-files...');
   % the following will leave us with just the filename, with no extension.
     iFilePathName = fullfile(path, fname);
[junk,fname,junk] = fileparts(fname);
iFilePathName = fullfile(path,fname);
end

fulliFilePathName = [iFilePathName '.001'];

if strcmp(button,'Create vAnatomy') %Just create the vAnatomy and quit
   createVolAnat(fulliFilePathName);
   return;
end
 
if ~exist('outputPathBase','var') | isempty(outputPathBase)
   [fname, path] = uiputfile('untitled', 'Pick base name and location for output files...');
   outputPathBase = [path fname];
end

if strcmp(button,'Both')
   createVolAnat(fulliFilePathName);
end

makeAnalyzeFromIfiles(iFilePathName,outputPathBase);

bet_cmd = [bet ' ' outputPathBase '.hdr ' outputPathBase '_brain -f .1'];
fast_cmd = [fast ' ' outputPathBase '_brain.hdr'];
seg_path = [outputPathBase '_brain_seg.hdr'];
class_path = [outputPathBase '.Class'];

dos(bet_cmd);
dos(fast_cmd);

fast2mrGrayClass(seg_path, class_path);

return;
