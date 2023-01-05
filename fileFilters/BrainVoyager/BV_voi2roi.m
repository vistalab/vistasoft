function [view,hdr] = BV_voi2roi(view,voiFile,unTalFlag,talPath);
% BV_voi2roi: converts a brain voyager .voi file into
% an ROI in a mrLoadRet volume.
%
% Usage: [view,hdr] = BV_voi2roi(view,[voiFile,unTalFlag,talPath]);
%
% Args: 
%       voiFile: path of Brain Voyager .voi file. If not passed in,
%       provides a dialog to select it.
%
%       unTalFlag: flag (set to 0 or 1) which causes the VOI/ROIs to be
%       converted from Talairach coords (saved that way in BV) to unTalled
%       coords (in mrLoadRet). Defaults to 1, do untal. NOTE: even if
%       manually set to 0, if the BV .voi file specifies the file type as
%       'TAL', it will automatically set unTalFlag to 1.
%
%       talPath: for when unTalFlag==1, the location of a .mat file,
%       created using computeTalairach.m, which contains the transform
%       information for going between tal and untal space. If unspecified,
%       checks the vANATOMYPATH directory, and, failing that, prompts the
%       user.
%
% Dependencies: BV_tal2untal
%
% ras 03/03
mrGlobals;

% right now I'm just making this work with volume views --
% bow out if it's another type of view
if ~isequal(view.viewType,'Volume') & ~isequal(view.viewType,'Gray')
    fprintf('Sorry, but this only works with Volume/Gray views right now.\n');
    return
end

if ~exist('unTalFlag','var')    unTalFlag = 1;      end

% prompt for BV .voi file if it's not passed in
if ~exist('voiFile','var') | isempty(voiFile)
    msg = ['Choose a Brain Voyager .voi file...'];
    startDir = fullfile(RAID,'3Danat','BV_vmr');
    if ~exist(startDir)
        startDir = pwd;
    end
    voiFile = getPathStrDialog(startDir,msg,'*.voi');
end

if ~exist(voiFile,'file')
    error(['File ' voiFile ' is not a valid file.']);
end

% prompt for a BV .tal file containing talairach information
if unTalFlag==1 & ~exist('talPath','var')

    % make an educated guess as to where the talPath might be
    guess = fullfile(fileparts(vANATOMYPATH),'vAnatomy_talairach.mat');
    
    if exist(guess,'file')
        talPath = guess;
    else
        disp('Choose a .mat file containing the talairach points for this volume');
        disp('(See ''help computeTalairach'' if you are unsure of what this is.)');
        msg = ['Choose a .mat file from coputeTalairach...'];
        talPath = getPathStrDialog(pwd,msg,'*.mat');
    end
 end

% Get the volume size - for flipping one of the dimensions to preserve L/R
volAnatSize=size(view.anat);

% open the voi file
[fid message] = fopen(voiFile,'r');
if fid==-1
    error(message);
end

%%%%% read the header
blank = fgetl(fid);
ignoretxt = fscanf(fid,'%s',1);
hdr.FileVersion = fscanf(fid,'%i',1);
blank = fgetl(fid);
blank = fgetl(fid);
ignoretxt = fscanf(fid,'%s',1);
hdr.CoordsType = fscanf(fid,'%s',1);
if isequal(hdr.CoordsType,'TAL')
    unTalFlag = 1;
end
blank = fgetl(fid);
blank = fgetl(fid);
blank = fgetl(fid);
ignoretxt = fscanf(fid,'%s',1);
hdr.numVOIs = fscanf(fid,'%i',1);
blank = fgetl(fid);
blank = fgetl(fid);

%%%%% loop through ROIs, reading them in
for voi = 1:hdr.numVOIs
    
    % read VOI/ROI name, num voxels in brainvoyager coords
    ignoretxt = fscanf(fid,'%s',1);
    hdr.VOInames{voi} = fscanf(fid,'%s',1);
    blank = fgetl(fid);
    blank = fgetl(fid);
    ignoretxt = fscanf(fid,'%s',1);
    hdr.numBVVoxels(voi) = fscanf(fid,'%i',1);
    blank = fgetl(fid);    
   
    % init ROI substruct
    ROIs(voi).color = 'b'; % default color is blue
    ROIs(voi).coords = [];
    ROIs(voi).name = hdr.VOInames{voi};
    ROIs(voi).viewType = view.viewType;
    
    % read coordinates of VOI
    voiCoords = [];
    for vxl = 1:hdr.numBVVoxels(voi)
        voiCoords(vxl,1) = fscanf(fid,'%i',1);
        voiCoords(vxl,2) = fscanf(fid,'%i',1);
        voiCoords(vxl,3) = fscanf(fid,'%i',1);
    end
    blank = fgetl(fid);    
    blank = fgetl(fid);    

	if unTalFlag
        voiCoords = BV_tal2unTal(voiCoords,talPath);
    end 
    
    ROIs(voi).coords = round(voiCoords');    
    
    fprintf('%s \n',ROIs(voi).name);
end

%%%%% read linked VTC files at the end; put info in hdr
blank = fgetl(fid);    
ignoretxt = fscanf(fid,'%s',1);
hdr.numLinkedVTCs = fscanf(fid,'%i',1);
blank = fgetl(fid);    
for vtc = 1:hdr.numLinkedVTCs
    hdr.VTCs{vtc} = fgetl(fid);
end

% close the file
fclose(fid);

% append ROIs to current view
view.ROIs = [view.ROIs ROIs];

% let the user know it worked
fprintf('Converted %i ROIs from the BV file %s.\n',length(ROIs),voiFile);

% refresh ROIs
r = view.selectedROI;
if r > 0
    view = selectROI(view,r);
else
	view = selectROI(view,1);
end

return