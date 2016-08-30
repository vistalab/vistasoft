function [nodes, edges, grayPath] = loadGrayNodes(hemisphere, grayPath, numLayers)
%
% [nodes, edges, grayPath] = loadGrayNodes(hemisphere, [grayPath], [numLayers])
%
% Loads gray nodes from specified gray class file. 
% If the file is not fully specified, opens dialog box to get it from the user.
%
% hemisphere: 'right' or 'left'
% grayPath: path string to file
%    If not specified, opens dialog box to have user find the file below:
%       /usr/local/mri/anatomy/<subject>/<hemisphere>
%
% djh, 8/98
%
% 022699 - Get anatomy path from getAnatomyPath - WAP
% 061899	- Browse with uigetfile - arw
% 080299 - fixed bug with returned restofpath, 
%          change into correct directory before browsing - arw
% 080800 - allowed returning null nodes and edges if restofpath is sent in null -- djh, bw
% 120100 - fixed bug in which when restofPath was sent in it was never
%          appended to grayPath.  BW
% 120100 - AW reorganised the logic a little. Exits immediately if restOfPath
%          is null. 
% 2/5/2001, djh - cleaned this up (major rewrite)
%          wrote getPathStrDialog.m to get the code for that outta this function
%          dumped restOfPath, replaced it with full grayPath
% 2008.01.?? RFD: added code to automatically grow gray matter in given a class file.
% 2008.02.04 RFD: when growing from a class file, we now prompt for the number of layers
%            if it isn't provided, rather than using a hard-coded default.


global mrSESSION

% Open dialog box to find gray class file
if notDefined('grayPath')
    
    % default initial directory: anatomy dir / hemisphere 
    Hemi = hemisphere; Hemi(1) = upper(Hemi(1)); % e.g., left -> Left
    startDir = fullfile(getAnatomyPath(mrSESSION.subject), Hemi);
    % if 'Left' dir does not exist go back to top dir
    if ~exist(startDir,'dir')
	  startDir = getAnatomyPath(mrSESSION.subject);
    end

    filterspec = {'*.nii.gz;*.nii', 'NIFTI class file'; '*.*', 'All files'};
    grayPath = getPathStrDialog(startDir, 'Select class file', filterspec);
end 

if exist(grayPath, 'file')
    disp(['Building gray graph from: ', grayPath]);
    class = readClassFile(grayPath, 0, 0, hemisphere);
    if(~exist('numLayers','var')||isempty(numLayers))
        a = inputdlg('Number of gray layers:','Gray Layers',1,{'5'});
        if(isempty(a)), error('user canceled.'); end
        numLayers = str2double(a{1});
    end
    [nodes,edges] = mrgGrowGray(class,numLayers);
elseif isempty(grayPath)
    fprintf('No file selected, so no coords loaded. \n');
    nodes = [];
    edges = [];
    
else
    myWarnDlg(['File ',grayPath,' does not exist. No gray nodes loaded']);
    nodes=[];
    edges=[];
end

return;

