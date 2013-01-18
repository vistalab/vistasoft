function class = tfi_constructClassFile(wmAnalyzeImg,classFile,gmAnalyzeImg,csfAnalyzeImg);
% class = tfi_constructClassFile(wmAnalyzeImg,[classFile,gmAnalyzeImg,csfAnalyzeImg]);
%
% For FSL / TFI toolboxes: contruct a mrVista/mrGray
% .class file, given ANALYZE format images containing
% a white matter volume (first arg), as well as optional 
% gray / csf volumes (3rd and 4th args).
% 
% Outputs data in a .class file specified in the
% 2nd arg; if omitted, will bring up a dialog. Also
% returns the class struct.
%
% This is intended to be part of a larger segmentation
% process that uses the FSL and TFI (Jonas Larsson's code)
% toolboxes. See tfi_segment for more info, or check out these
% webpages:
%
% http://www.fmrib.ox.ac.uk/fsl/index.html      [FSL]
% 
% http://www.cns.nyu.edu/~jonas/software.html   [TFI]
%
% Written by ras 02/05
if ieNotDefined('classFile')
    [fname parent] = myUiPutFile(pwd,'*.*lass','Save .class file as...');
    classFile = fullfile(parent,fname);
end

if ieNotDefined('gmAnalyzeImg')
    gmAnalyzeImg = [];
end

if ieNotDefined('csfAnalyzeImg')
    csfAnalyzeImg = [];
end

%%%%%%%%%%%%%%%%%%%%%
% load the images   %
%%%%%%%%%%%%%%%%%%%%%
[wm mmpervoxW hdrW] = loadAnalyze(wmAnalyzeImg);

if ~isempty(gmAnalyzeImg)
	[gm mmpervoxG hdrG] = loadAnalyze(gmAnalyzeImg);
else
    gm = zeros(size(wm));
end

if ~isempty(csfAnalyzeImg)
    [csf mmpervoxC hdrC] = loadAnalyze(csfAnalyzeImg);
else
    csf = zeros(size(wm));
end

%%%%%%%%%%%%%%%%%%%%%
% check sizes       %
%%%%%%%%%%%%%%%%%%%%%
if ~isequal(size(wm),size(gm))
    error('Gray matter and white matter must be same size.')
end
if ~isequal(size(csf),size(gm))
    error('CSF and white matter must be same size.')
end

%%%%%%%%%%%%%%%%%%%%%
% merge volumes     %
%%%%%%%%%%%%%%%%%%%%%
type.unknown = 0;
type.csf = 48;
type.gray = 32;
type.white = 16;

data = type.unknown*ones(size(wm));
data(csf>0) = type.csf;
data(gm>0) = type.gray;
data(wm>0) = type.white;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up .class struct     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% flip axes to agree with mrGray conventions
fprintf('Permuting axes to mrGray format...\n');
data = permute(data,[2 3 1]);
data = flipdim(data,1);
data = flipdim(data,2);
% data = flipdim(data,3);

szX = size(data,1);
szY = size(data,2);
szZ = size(data,3);

hdr.version = 2;
hdr.minor = 1;
hdr.voi = [1 szX 1 szY 1 szZ];
hdr.xsize = szX;
hdr.ysize = szY;
hdr.zsize = szZ;
hdr.params = [0 1 240 4 0 0]; % dummy values

[a b] = fileparts(classFile);
class.filename = b;
class.type = type;
class.header = hdr;
class.data = data;

writeClassFile(class,classFile);
fprintf('Wrote file %s.\n',classFile);

return


