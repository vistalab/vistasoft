function fg = dtiLoadFDTPaths(dirName,xform)
%
% fdtPath = dtiLoadFDTPaths(filename,xform)
%
% Loads fiber pathways from a series of FDT particle files.  
% Assumes we are given a directory where each file in the directory is a
% pathway to load.
% 
%
% HISTORY:
% 2006.08.17 Written by Anthony Sherbondy

%% Initialization
fg = [];
if ieNotDefined('xform')
    xform = eye(4);
end
if ieNotDefined('dirName')
    dirName = uigetdir('','Select FDT particle directory...');
    if(isnumeric(dirName)); disp('Cancel.'); return; end
end

%% Getting all pathway files
path_files = dir(dirName);
fdtPaths = {};
fCount = 1;
for ff = 1:length(path_files)
    if ~strcmp(path_files(ff).name,'.') &&  ~strcmp(path_files(ff).name,'..')
        % Load file
        pathway = load(fullfile(dirName,path_files(ff).name));
        pathway = pathway';
        % Unsplit the fiber
        seed = pathway(:,1);
        seedRepInd = find( pathway(1,:)==seed(1) & pathway(2,:)==seed(2) & pathway(3,:)==seed(3),1,'last');
        pathway = [pathway(:,end:-1:seedRepInd+1) pathway(:,1:seedRepInd-1)];
        fdtPaths{fCount,1} = pathway;
        fCount=fCount+1;
    end
end


%% Transform all fiber coords
xformToMatlab = [1 0 0 2; 0 1 0 2; 0 0 1 2; 0 0 0 1];
xformFlipX = [-1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1];
xformToAcpc = xformFlipX*xformToMatlab*xform;
fdtPaths = dtiXformFiberCoords(fdtPaths, xformToAcpc);

%% Create fiber group around these paths
fg = dtiNewFiberGroup;
fg.fibers = fdtPaths;
fg.name = 'fdt_paths';
fg.colorRgb = [200 200 100];

return;
