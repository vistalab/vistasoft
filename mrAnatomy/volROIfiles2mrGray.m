function volROIfiles2mrGray(roiFilename, writeDir)
%
% volROIfiles2mrGray(roiFilename, [writeDir])
% 
% PURPOSE:  Read ROI.mat files (mrLoadRet format) and write
% out the ROIs in a format that mrGray can read. The new files
% will have the same file name as the ROI files and will be 
% written to writeDir (defaults to pwd).
%
% roiFilename can either be a single filename string, a cell
% array of file names, or a single directory name (in which
% case all .mat files in the dir will be converted).
%
% 
% HISTORY:  
%   2002.01.11 RFD (bob@white.stanford.edu) wrote it.
% 

if(~iscell(roiFilename))
		 d = dir(roiFilename);
		 if(length(d)==1 & d.isdir==0)
		     roiFilename = {roiFilename};
		 else
		     % It's a directory- get all .mat files
         p = roiFilename;
         roiFilename = {};
         for(ii=1:length(d))
             if(~d(ii).isdir & length(d(ii).name)>3 ...
                   & strcmpi(d(ii).name(end-3:end), '.mat'))
               roiFilename{end+1} = fullfile(p,d(ii).name);
             end
         end
     end
end

for(ii=1:length(roiFilename))
    roi = load(roiFilename{ii});
    [p, n, e] = fileparts(roiFilename{ii});
    if(exist('writeDir', 'var'))
        p = writeDir;
    end
    outName = [n,'.roi'];
    disp(['Writing ',outName,' to ',p,'.']); 
    volROI2mrGray(outName, roi.ROI, p);
end

return;

