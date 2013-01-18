function mr = mrReadDicomDir(ifileDir)
% Read a directory of GE I-files into an mr struct.
%
% mr = mrReadDicomDir(ifileDir);
%
% ras, 07/05.

% initialize mr struct
[p f ext] = fileparts(ifileDir);
if isequal(ext, '.dcm')
    % oops -- accidentally included an I-file in the path: chop this off:
    ifileDir = p;
    [p f] = fileparts(ifileDir); %#ok<ASGLU>
end

mr = mrCreateEmpty;
mr.pth = ifileDir;
mr.name = f;
mr.format = 'dicom';

[mr.data hdr1 hdr2] = loopOverMRFiles(ifileDir,'*.dcm','mrReadIfile'); 
mr.hdr = hdr1;

mr.voxelSize = double([mr.hdr.image.pixsize_Y mr.hdr.image.pixsize_X ...
                       mr.hdr.image.slthick]);
mr.dims = size(mr.data);
mr.spaces = mrStandardSpaces(mr);
mr.dimUnits = {'mm' 'mm' 'mm' 'sec'};
mr.dataUnits = 'T1-Weighted Intensity';

mr.info.scanner = char(mr.hdr.exam.hospname');
mr.info.subject = char(mr.hdr.exam.patname');
sex = {'female' 'male'};
mr.info.subjectSex = sex{mr.hdr.exam.patsex+1};
mr.info.subjectAge = mr.hdr.exam.patage;
mr.info.subjectSpecies = 'human'; % may not always be the case, find field
mr.info.date = datestr(parseGEDate(mr.hdr.series.se_datetime));
mr.info.scanStart = datestr(parseGEDate(mr.hdr.image.im_actual_dt));
mr.info.examNum = mr.hdr.exam.ex_no;
mr.info.protocol = char(mr.hdr.series.prtcl');
if checkfields(mr, 'hdr', 'image', 'cname')
    mr.info.coil = mr.hdr.image.cname;
else
    mr.info.coil = 'unknown coil';
end
mr.info.magnetStrength = mr.hdr.exam.magstrength/10000;

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
% % first, get the coordinates of the corners of the last slice
% % in pixel coords: (Using code Bob wrote, below)
% tlhc = [1 1 mr.dims(3)]'; % top left-hand-corner
% trhc = [1 mr.dims(2:3)]'; % top right-hand-corner
% brhc = [mr.dims]';        % bottom right-hand-corner
% pixCorners = [tlhc trhc brhc];

% now build a space defining the scanner coords, where the
% xform maps from the pixCorners to the R|A|S coords of the
% the three corners from the header:
w = dir(fullfile(ifileDir,'*.dcm'));
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
function dirText = dimFlip(dirText)
% flip direction 'a <--> b' to read 'b <--> a'.
I = strfind(dirText, ' <--> ');
if isempty(I), return; end
lhs = dirText(1:I);
rhs = dirText(I+5:end);
dirText = [rhs '<-->' lhs];
return
