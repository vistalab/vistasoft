function sessionGUI_loadSegmentation(ui, loadNodes, recompute)
% Check if a mrVista1 segmentation has been installed for a viewer,
% and if so, load the segmentation from the source files.
%
% sessionGUI_loadSegmentation([ui=cur viewer], [loadNodes=1], [recompute=0]);
%
% This function checks if the file Gray/coords.mat exists relative to the
% current session. If it does, it loads the path specifications for the
% .gray and .class files associated with each hemisphere, and then loads
% a mrViewer segmentation based on this information.
%
% There are a few things to note aboute what this function does:
%
% (1) this function doesn't load the gray matter info from the
% Gray/coords.mat file itself, just the pointer to the original files.
% Thus, this function always loads the entire segmentation, not just
% the portion that overlaps with the current session. 
% (If there are memory reasons to only load part, we can work that in,
% but otherwise it may be cleaner and more useful to always have access to
% the full segmentation.)
%
% (2) the actual info about paths is kept in a small matlab file
% called 'segmentation.mat', which is kept in the same directory as the
% .gray file for a segmentation. 
%
% (3) this still loads things based on the mrGray .gray graphs. I'm aware
% you can also grow the gray nodes directly using mrgGrowGray, but this
% isn't always stable, so I've opted for the older, stable version. 
%
%
% The 'loadNodes' flag determines whether the node information from the
% .gray file is loaded directly or not. Doing so takes up time and memory
% when loading the segmentation, but saves it in the long run if you're
% going to be projecting data onto a mesh often (it makes the projection
% time faster). It defaults to 1.
%
% If 'recompute' is set to 1 [default 0], it will recompute the
% segmentation file even 
%
% ras, 12/2006.
mrGlobals2;

if ~exist('ui', 'var') || isempty(ui), ui = GUI.settings.viewer; end
if ishandle(ui), ui = get(ui, 'UserData'); end

if ~exist('loadNodes', 'var') || isempty(loadNodes), loadNodes = 1; end
if ~exist('recompute', 'var') || isempty(recompute), recompute = 0; end    
    
%% first, check for a segmentation file for each hemisphere. If we find
%% them, load them and we're done.
leftSegPath = fullfile(HOMEDIR, '3DAnatomy', 'Left', 'segmentation.mat');
rightSegPath = fullfile(HOMEDIR, '3DAnatomy', 'Right', 'segmentation.mat');
if exist(leftSegPath, 'file') & exist(rightSegPath, 'file')
	ui = mrViewLoad(ui, leftSegPath, 'segmentation');
	ui = mrViewLoad(ui, rightSegPath, 'segmentation');
	return
end


%% if we get here, check if there are default left and right mrGray files.
grayCoordsPath = fullfile(HOMEDIR, 'Gray', 'coords.mat');

if exist(grayCoordsPath, 'file')
    anatPath = fullpath(vANATOMYPATH);
    
    hwait = mrvWaitbar(0, 'Checking/Installing Segmentation');
    
    load(grayCoordsPath, 'leftClassFile', 'rightClassFile', ...
                         'leftPath', 'rightPath');
             
    mrvWaitbar(.5, hwait);
	
	% for each file, perform a check that the same file name may 
	% exist in a different directory path: because an anatomy directory may
	% be accessed from multiple systems (e.g., mounted on a Samba server),
	% the full path may not be correct, although the relative path may:
	leftClassFile = checkRelPath(leftClassFile, 'left');
	leftPath = checkRelPath(leftPath, 'left');
	rightClassFile = checkRelPath(rightClassFile, 'right');
	rightPath = checkRelPath(rightPath, 'right');	

    %% Right hemisphere
    if exist(rightPath, 'file') && exist(rightClassFile, 'file')
        segDir = fileparts( fullpath(rightPath) );
        segPath = fullfile(segDir, 'segmentation.mat');
		
		% create the segmentation file
		seg = segCreate('Right', rightClassFile, rightPath, anatPath);

		% save a copy of it, if needed (will rely on this file less in the 
		% future, but keep track of current files)
		if ~exist(segPath, 'file') || recompute==1
            % create the segmentation file
            fprintf('Creating small segmentation file %s ...', segPath);
            save(segPath, 'seg');
            fprintf('done.\n');
		end
        
		ui = mrViewSet(ui, 'AddSegmentation', seg);        

		% assign a preferred mesh dir if obvious choices are available
        meshDirA = fullfile(segDir, '3DMeshes');
        meshDirB = fullfile( fileparts(segDir), 'Meshes' );
        if exist(meshDirA, 'dir')
            ui.segmentation(end).params.meshDir = meshDirA;
        elseif exist(meshDirB, 'dir')
            ui.segmentation(end).params.meshDir = meshDirB;                
        end
        set(ui.fig, 'UserData', ui);        
        
        if loadNodes==1
            disp('Loading Right Segmentation...');
            ui.segmentation(end) = segLoadNodes( ui.segmentation(end) );
            set(ui.fig, 'UserData', ui);
        end
    end
        
    mrvWaitbar(1, hwait);

    %% Left hemisphere                     
    if exist(leftPath, 'file') && exist(leftClassFile, 'file')
        segDir = fileparts( fullpath(leftPath) );        
        segPath = fullfile(segDir, 'segmentation.mat');

		% create the segmentation
        seg = segCreate('Left', leftClassFile, leftPath, anatPath); %#ok<NASGU>
		
		% save a copy of it, if needed (will rely on this file less in the 
		% future, but keep track of current files)
		if ~exist(segPath, 'file') || recompute==1
            % create the segmentation file
            fprintf('Creating small segmentation file %s ...', segPath);
            save(segPath, 'seg');
            fprintf('done.\n');
		end
		
		ui = mrViewSet(ui, 'AddSegmentation', seg);        
 
		% assign a preferred mesh dir if obvious choices are available
        meshDirA = fullfile(segDir, '3DMeshes');
        meshDirB = fullfile( fileparts(segDir), 'Meshes' );
        if exist(meshDirA, 'dir')
            ui.segmentation(end).params.meshDir = meshDirA;
        elseif exist(meshDirB, 'dir')
            ui.segmentation(end).params.meshDir = meshDirB;                
        end
        set(ui.fig, 'UserData', ui);        
        
        if loadNodes==1
            disp('Loading Left Segmentation...');
            ui.segmentation(end) = segLoadNodes( ui.segmentation(end) );
            set(ui.fig, 'UserData', ui);
        end
    end        
    
    close(hwait);
end

return
% /---------------------------------------------------------------/ %




% /---------------------------------------------------------------/ %
function pth = checkRelPath(pth, h);
% check if a segmentation file exists relative to a volume anatomy,
% even if it doesn't exist as an absolute path.
if isempty(pth) || exist(pth, 'file')	% no need to check
	return
end

% account for fileseps on unix/windows filesystems: make all \ -> /
pth(pth=='\') = '/';
[p f ext] = fileparts(pth);

anatPath = getAnatomyPath;
if lower(h(1))=='l', hemi = 'Left'; else, hemi = 'Right'; end
testPath = fullfile(anatPath, hemi, [f ext]);

if exist(testPath, 'file')
	pth = testPath;
end

return
