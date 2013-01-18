function dirs = mrIfileDirections(ifileDir)
% Get direction labels for the rows, columns, and slices from a 
% DICOM or GE I-file header.
%
% dirs = mrIfileDirections(ifileDir);
%
% ifileDir: directory containing at least
%
% dirs: 1x3 cell of labels for the rows, columns, and slices
% of the data in the I-file. This is in scanner space, and so is
% valid only if the subject was lying supine. (If the I-file isn't
% found or read properly, returns {'Rows' 'Columns' 'Slices'}.
%
% For I-files that were prescribed obliquely, chooses the direction
% that most closely matches each data dimension.
%
%
% ras, 11/09/2005.
if ~exist('ifileDir','var') || isempty(ifileDir)
    ifile = mrSelectDataFile('stayput', 'r', 'I*', 'Select an I-file');
    ifileDir = fileparts(ifile);
end

% default response if nothing is successful
dirs = {'Rows' 'Columns' 'Slices'};

% find first and last I-file in directory
%w = dir(fullfile(ifileDir, 'I*')); % since dicom files do not always start
% with 'I', but do always end with '.dcm', let's find the dicoms this way
w = dir(fullfile(ifileDir, '*.dcm'));
ifile1 = fullfile(ifileDir, w(1).name);
ifile2 = fullfile(ifileDir, w(end).name);

% read the I-file header (interested in image header) 
try
    [a b c hdr] = readIfileHeader(ifile1);
catch ME
    warning(ME.identifier, ME.message);
    return
end

% These are the real-world direction labels being used in 
% (right, anterior, superior) coordinate space:
rasDirs = {' Left <--> Right ' ' Posterior <--> Anterior ' ...
           ' Inferior <--> Superior '};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the coordinates of three corner points in real-world %
% (right, anterior, superior) scanner coords:              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (1) top left-hand corner
pt1 = [hdr.tlhc_R hdr.tlhc_A hdr.tlhc_S]; 
% (2) top right-hand corner
pt2 = [hdr.trhc_R hdr.trhc_A hdr.trhc_S]; 
% (3) bottom right-hand corner
pt3 = [hdr.brhc_R hdr.brhc_A hdr.brhc_S]; 

% find the rows direction: difference between point 2 and 
% point 3 (which is the right-hand edge of the slice):
dRows = pt3-pt2;

% the closest matching direction to the rows vector
% is the one whose component is largest:
R = find(abs(dRows)==max(abs(dRows))); R = R(1);

% similarly, find the columns direction from the difference
% between point 1 and point 2 (the top edge of the slice):
dCols = pt2-pt1;
C = find(abs(dCols)==max(abs(dCols))); C = C(1);

% the slices direction is the remaining, unassigned direction:
S = setdiff(1:3, [R C]);

% re-map from R/A/S directions to the new directions
dirs = rasDirs([R C S]);

% account for negative directions: if the difference along each
% dimension is negative, flip that dimension:
if dRows(R)<0, dirs{1} = dimFlip(dirs{1}); end    
if dCols(C)<0, dirs{2} = dimFlip(dirs{2}); end    

% we need to read the second I-file header to parse the
% slices direction:
try
    [a b c hdr2] = readIfileHeader(ifile2);
catch
    return
end
% (1) top left-hand corner
pt4 = [hdr2.tlhc_R hdr2.tlhc_A hdr2.tlhc_S]; 
dSlices = pt4-pt1; % edge connecting tlhc of 2 slices
if dSlices(S)<0, dirs{3} = dimFlip(dirs{3}); end

return
% /-----------------------------------------------------------------/ %




% /-----------------------------------------------------------------/ %
function dirText = dimFlip(dirText)
% flip direction 'a <--> b' to read 'b <--> a'.
I = findstr(dirText, ' <--> ');
if isempty(I), return; end
lhs = dirText(1:I);
rhs = dirText(I+5:end);
dirText = [rhs '<-->' lhs];
return

