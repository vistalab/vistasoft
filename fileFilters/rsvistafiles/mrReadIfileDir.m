function mr = mrReadIfileDir(ifileDir);
% Read a directory of GE I-files into an mr struct.
%
% mr = mrReadIfileDir(ifileDir);
%
% ras, 07/05.

% allow either a directory, or the path to one I-file, to be entered:
[p f ext] = fileparts(ifileDir);
if ~isempty(ext)  % path to a single I-file: take directory
	ifileDir = fileparts(ifileDir);
end

% initialize mr struct
mr = mrCreateEmpty;
mr.pth = ifileDir;
mr.name = f;
mr.format = 'ifile';

[mr.data hdr1 hdr2] = loopOverMRFiles(ifileDir,'I*','mrReadIfile'); 
mr.hdr = hdr1;

% mr.voxelSize = [mr.hdr.image.imatrix_Y/mr.hdr.image.dfov ...
%                 mr.hdr.image.imatrix_X/mr.hdr.image.dfov ...
%                 mr.hdr.image.slthick];
mr.voxelSize = double([mr.hdr.image.pixsize_Y mr.hdr.image.pixsize_X ...
           mr.hdr.image.slthick]);
mr.dims = size(mr.data);
mr.spaces = mrStandardSpaces(mr);
mr.dimUnits = {'mm' 'mm' 'mm' 'sec'};
mr.dataUnits = 'T1-Weighted Intensity';

try
    mr.info.scanner = char(mr.hdr.exam.hospname');
    mr.info.subject = char(mr.hdr.exam.patname');
    sex = {'not entered' 'female' 'male'};
    mr.info.subjectSex = sex{mr.hdr.exam.patsex};
    mr.info.subjectAge = mr.hdr.exam.patage;
    mr.info.subjectSpecies = 'human'; % may not always be the case, find field
    mr.info.date = datestr(parseGEDate(mr.hdr.series.se_datetime));
    mr.info.scanStart = datestr(parseGEDate(mr.hdr.image.im_actual_dt));
    mr.info.examNum = mr.hdr.exam.ex_no;
    mr.info.protocol = char(mr.hdr.series.prtcl');
    mr.info.coil = mr.hdr.image.cname;
    mr.info.magnetStrength = mr.hdr.exam.magstrength/10000;
catch
    disp('Couldn''t get subject info')
end

% get coordinates of 3 corners of the last image and
% express in R|A|S coords:
tmp = mr.hdr.image;
mr.info.cornerCoords = [tmp.tlhc_R tmp.trhc_R tmp.brhc_R; ...
                        tmp.tlhc_A tmp.trhc_A tmp.brhc_A; ...
                        tmp.tlhc_S tmp.trhc_S tmp.brhc_S];
tmp = hdr2.image;
mr.info.cornerCoords = [mr.info.cornerCoords; ...
                        tmp.tlhc_R tmp.trhc_R tmp.brhc_R; ...
                        tmp.tlhc_A tmp.trhc_A tmp.brhc_A; ...
                        tmp.tlhc_S tmp.trhc_S tmp.brhc_S];    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use the corner coords to estimate transform into  %
% scanner space:                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% first, get the coordinates of the corners of the last slice
% in pixel coords:
tlhc = [1 1 mr.dims(3)]'; % top left-hand-corner
trhc = [1 mr.dims(2:3)]'; % top right-hand-corner
brhc = [mr.dims]';        % bottom right-hand-corner
pixCorners = [tlhc trhc brhc];

% now build a space defining the scanner coords, where the
% xform maps from the pixCorners to the R|A|S coords of the
% the three corners from the header:
w = dir(fullfile(ifileDir,'I*'));
firstIfile = fullfile(ifileDir,w(1).name);
mr.spaces(end+1).name = 'Scanner';
mr.spaces(end).xform = inv(affineScanner2Pixels(firstIfile));
mr.spaces(end).dirLabels = {'L <--> R' 'P <--> A'  'I <--> S'};
mr.spaces(end).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
mr.spaces(end).units = 'mm';
mr.spaces(end).coords = [];
mr.spaces(end).indices = [];
                            
% also update the direction labels on the pixel and L/R flipped spaces,
% using the header info:
dirs = mrIfileDirections(ifileDir);
for i=1:3, mr.spaces(i).dirLabels = dirs; end
mr.spaces(3).dirLabels{2} = dimFlip(mr.spaces(3).dirLabels{2});

return
% /-----------------------------------------------------------------/ %




% /-----------------------------------------------------------------/ %
function dirText = dimFlip(dirText);
% flip direction 'a <--> b' to read 'b <--> a'.
I = findstr(dirText, ' <--> ');
if isempty(I), return; end
lhs = dirText(1:I);
rhs = dirText(I+5:end);
dirText = [rhs '<-->' lhs];
return

