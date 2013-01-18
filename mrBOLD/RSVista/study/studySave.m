function studyPath = studySave(studies);
% Save a set of studies in the local studies.mat file.
%   
% studyPath = studySave(studies);
%
% Returns the path to the updated studies file. This should reside
% in the same directory as the study-related MATLAB functions. mrVista 2
% is intended to have a unique set of studies for each copy of the code, 
% in order to be unambiguous and minimize the selection of files. (If it's 
% decide to change this, these functions will needed to be significantly
% expanded.)
%
% ras, 07/06
if nargin<1, error('Not enough input args.'); end

parentDir = fileparts(which(mfilename)); % parent directory of this M-file.
studyPath = fullfile(parentDir, 'studies.mat');

save(studyPath, 'studies');

return
