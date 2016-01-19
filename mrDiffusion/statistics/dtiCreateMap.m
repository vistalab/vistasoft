function niMap = dtiCreateMap(dt6File,map,fName,saveMap)
% function niMap = dtiCreateMap([dt6File],[map],[fName],[saveMap=0])
% 
% Computes and saves a Map as a nifti image. By default (if you don't
% specify a map) you will be prompted to enter a value for the map. The
% resulting nifti image will be named [map 'Map.nii.gz'] and will be saved in
% the same directory as the dt6.mat file used to create it ONLY if you set
% saveMap to '1', 'true'. 
% 
% maps: map = 'fa';
%       map = 'md';
%       map = 'rd';
%       map = 'ad';
% 
% INPUTS:
%       dt6File - the path to the dt6.mat file for a given subject
%       map     - the string for the map you wish returned
%       fName   - the fullpath & name for map, set in niMap.fname
%       saveMap - boolean, to save (1) or not to save (0). 
% 
% OUTPUTS:
%       niMap   - niftiStructure containing the map data. 
% 
% Web Resources:
%       mrvBrowseSVN('dtiCreateMap');
% 
% Example Usage:
%       niMap = dtiCreateMap('dt6.mat','fa','faMap.nii.gz',1);
%   OR
%       niMap = dtiCreateMap
%  
% 
%  HISTORY:
%  (C) Stanford Vista 2011 [lmp]
% 
% 

%% Handle the inputs
% 
if notDefined('dt6File') || ~exist(dt6File,'file')
    [a b]  = uigetfile('*.mat','Please select your dt6.mat file.');
    if isempty(a); fprintf('User canceled!\n'); clear dt6File, return; end
    dt6File = [b a];
end

[baseD, ~] = fileparts(dt6File); 

if notDefined('saveMap'), 
    saveMap = 0; 
end

if ~exist('map','var'); 
    map =  f_getMap; 
end

if ~exist('fName','var'); 
    fName = fullfile(baseD, [map 'Map']); 
end



%% Load the dt file and compute the statistics.
% 
dt = dtiLoadDt6(dt6File);
[fa,md,rd,ad] = dtiComputeFA(dt.dt6);

switch lower(map)
    case 'fa'; stat = fa;
    case 'md'; stat = md;
    case 'rd'; stat = rd;
    case 'ad'; stat = ad;
end


%% Return and write out the nifti file 
% 
%niMap      = niftiGetStruct(stat, dt.xformToAcpc);
niMap       = niftiCreate('data', stat, 'qto_xyz', dt.xformToAcpc);
niMap.fname = fName;

if saveMap 
    fprintf('Writing %s...',fName);
    niftiWrite(niMap);
end
fprintf('Done.\n');

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Launches a dialog that will prompt the user to input the arguments we
% need. We're here because map is not passed in. 
function map = f_getMap
% Set options for the dialog prompt
prompt              = {sprintf('Enter a valid map type: fa, md, rd, ad \n'),...
                       sprintf('Save? (0 = no, 1 = yes)\n')};
dlg_title           = 'Choose Map Type';
num_lines           = 1;
defaultanswer       = {'fa','0'};
options.Resize      = 'on';
options.WindowStyle = 'modal';
options.Interpreter = 'tex';

% Launch the dialog and extract the output arguments
inputs = inputdlg(prompt,dlg_title,num_lines,defaultanswer,options);
if isempty(inputs); error('User canceled!'); 
else map = inputs{1}; saveMap = str2double(inputs{2}); end %#ok<NASGU>

return

