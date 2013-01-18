function [mr, vanat] = mrReadOldUnfold(flatPath,params);
% Read a mrVista 1.0 Flat file (see mrFlatMesh) and corresponding
% vAnatomy into a mrVista 2.0 mr object.
%
% [mr, vanat] = mrReadOldUnfold(flatPath,[params]);
%
% flatPath: path to coords.mat file for flat view. If not
% specified, defaults to Flat/coords.mat from the current directory.
%
% params: struct with the following fields:
%   hemisphere: choose which hemisphere to load, of 'left' or 'right'.
%               If this is useful, I'll implement 'both' down the line.
%   threshFlag: flag for how to store curvature data. 
%               0 -- keep continuous curvatures as loaded
%               1 -- threshold into ligher and darker bands
%               2 -- threshold binary
%   curvThresh: number from 0 to 1 specifying threshold curvature
%               if the threshFlag is nonzero.
% If omitted, will pop up a dialog for params.
%
% ras, 09/2005.
if notDefined('flatPath')
    % guess that we're in a session directory w/ 
    % a FLAT subdir
    flatPath = fullfile('Flat','coords.mat');
end

[p f ext] = fileparts(flatPath);


% get anat.mat, mrSESSION and gray coords.mat files -- if we
% can't get these, we can't load the unfold:
anatPath = fullfile(p,'anat.mat');
grayPath = fullfile(fileparts(p),'Gray','coords.mat');
mrSessPath = fullfile(fileparts(p),'mrSESSION.mat');
if ~exist(anatPath,'file'), error('No Flat anat.mat file found.'); end
if ~exist(grayPath,'file'), error('No Gray/coords.mat file found.'); end
if ~exist(mrSessPath,'file'), error('No mrSESSION.mat file.');       end

%%%%%%%%%%%%%%%%
% params check %
%%%%%%%%%%%%%%%%
if notDefined('params')
    % pop up dialog
    dlg(1).fieldName = 'hemisphere';
    dlg(1).style = 'popup';
    dlg(1).list = {'left' 'right'};
    dlg(1).string = 'Hemisphere to load?';
    dlg(1).value = 2;
    
    dlg(2).fieldName = 'threshFlag';
    dlg(2).style = 'popup';
    dlg(2).list = {'0: don''t threshold' '1: threshold ranges' ...
                   '2: threshold binary'};
    dlg(2).string = 'Threshold Curvature?';
    dlg(2).value = 2;
    
    dlg(3).fieldName = 'curvThresh';
    dlg(3).style = 'edit';
    dlg(3).string = 'Curvature Threshold?';
    dlg(3).value = 0.5;
    
    params = generalDialog(dlg,'Read mrVista 1.0 Unfold');
    params.threshFlag = cellfind(dlg(2).list,params.threshFlag)-1;
    params.curvThresh = str2num(params.curvThresh);
end

%%%%%%%%%%%%%%%%%
% load the data %
%%%%%%%%%%%%%%%%%
load(anatPath,'anat');
flat = load(flatPath);
gray = load(grayPath);
sess = load(mrSessPath);

% also get the corresponding vAnatomy file as an mr object
if isfield(sess,'vANATOMYPATH')
    vAnatPath = sess.vANATOMYPATH;
else
    vAnatPath = fullfile(fileparts(p),'3DAnatomy','vAnatomy.dat');
end
if ~exist(vAnatPath,'file')
    vAnatPath = mrSelectDataFile(fileparts(p),'r','*.dat',...
                    'Select a vAnatomy for the unfold');
end
vanat = mrLoad(vAnatPath);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% define the flat mr object:
% The base data will be the curvature, replicated by the 
% number of gray levels. Also define the I|P|R space of the vanat
% via a set of indices and coords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mr = vanat;

% find the nodes corresponding to selected hemisphere
if strncmp(lower(params.hemisphere),'left',4), h=1; else, h=2; end
subCoords = flat.grayCoords{h};
[subCoords Igray Iflat] = intersectCols(gray.coords,subCoords);

% get # of gray levels defined by nodes, 
% and max # of flat locations defined in a level
levels = gray.nodes(6,Igray); % level for each node
nLevels = length(unique(levels));
nFlatLocs = sum(levels==1);

% initialize anat and apply any selected thresholding
anat = normalize(mrClipOptimal(anat(:,:,h)),0,1);
if params.threshFlag==1
    % threshold ranges    
    th = params.curvThresh;
    anat(anat<th) = normalize(anat(anat<th), .4, .6);
    anat(anat>=th) = normalize(anat(anat>=th), .7, .8);   
    anat(isnan(anat)) = 0;
elseif params.threshFlag==2
    % binary threshold
    th = params.curvThresh;
    anat(anat<th) = .6;
    anat(anat>=th) = .8;        
    anat(isnan(anat)) = 0;
end

% initialize the mr data to be the curvature data
% (stored in anat), multiplied by the number of levels
mr.data = repmat(anat,[1 1 nLevels]);
mr.dims = [size(mr.data) 1];
mr.extent = mr.voxelSize .* mr.dims;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% define the I|P|R space as a lookup table %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize spaces
mr.spaces = mrStandardSpaces(mr);

mr.spaces(end+1) = mr.spaces(end);
mr.spaces(end).name = 'I|P|R';
mr.spaces(end).dirLabels =  {'' '' ''};
mr.spaces(end).sliceLabels =  {'Rows' 'Columns' 'Levels'};
mr.spaces(end).xform = [];
mr.spaces(end).indices = [];
mr.spaces(end).coords = subCoords;

% find indices in the mr.data field to correspond to each column
% in coords
flatCoords = flat.coords{h}; 
flatCoords = [flatCoords(:,Iflat); levels];
flatCoords = round(flatCoords);
indices = sub2ind(mr.dims,flatCoords(1,:),flatCoords(2,:),flatCoords(3,:));
mr.spaces(end).indices = indices;


return