% dtiTrackAllHemisphereFibers
%
% This script can be used to track all fibers in each hemisphere of a selected group of subjects 
% (subs) in a given directory (baseDir) and intersect those fibers with the corpus callosum. 
% 
% The script assumes that you have the file structure given by running
% dtiRawPreprocess--- i.e., subDir -> dti(dirs) -> fibers
%
% Edit this script to set the base directory, provide a list of the subject's directories, and set the
% number of directions (e.g., 06, or 40). 
% Tracking parameters can also be adjusted within.
%
% 05/05/2008: R.F.D wrote it.
% 05/08/2008: L.M.P wrote the loop and added the ability to process
% multiple subjects through multiple years. Also added multiple display strings to keep the user
% updated on the status of the tracking. 
% 07/03/2008: L.M.P. added the function dtiWriteFibersPdb to write the groups in
% .pdb format recognized by CINCH.
% 07/22/2008: L.M.P. added the fileFormat flag to determine which format the
% fiber groups should be written as [0=.m, 1=.pdb] 
% 6/16/2010 LMP Uses dtiFiberMidSagSegment clip fibers that cross into the other hemisphere. 
% 07.21.2011 LMP - Many changes: Added clip option that is a flag for dtiFiberMidSagSegment. Added fileFormat flag for mat or pdb. Added a doAll option that will track all the fibers and create an AlLFG file - not just left and right. 


%% directory structure
baseDir = '/biac3/wandell4/data/reading_longitude'; % (e.g., /biac3/wandell4/data/reading_longitude)
yr      = {'dti_y1'}; % Used for the longitudinal data (e.g., dti_y1)
dirs 	= 'dti06'; % This is the name of the folder that contains the dt6.mat file (e.g., dti06)
subs 	= {''}; % Ex: {'ab','aab'};


%% Tracking Parameters

faThresh = 0.35;
opts.stepSizeMm = 1;
opts.faThresh = 0.25;%0.15;
opts.lengthThreshMm = [20 250];
opts.angleThresh = 60;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [.5]; %[-.25 .25]; %

nPts 	   = 10; 
clip       = 0; % Calls dtiFiberMidSagSegment to sep the L/R fiber groups.
fileFormat = 1; % 0 for .m, 1 for .pdb
doAll 	   = 1; % Tracks whole-brain not each hemisphere.

%% Loops through subs and tracks fibers

for ii=1:length(subs)
    for jj=1:length(yr)
        sub 	= dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        subDir  = fullfile(baseDir,yr{jj},sub.name);
        dt6Dir 	= fullfile(subDir, dirs);
        fiberDir= fullfile(dt6Dir,'fibers');
        roiDir 	= fullfile(dt6Dir,'ROIs');

        disp(['Processing ' subDir '...']);

        if(~exist(fiberDir,'dir')), mkdir(fiberDir); end
        if(~exist(roiDir,'dir')), mkdir(roiDir); end

        dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));
        fa = dtiComputeFA(dt.dt6);
        fa(fa>1) = 1; fa(fa<0) = 0;

        % If there is not a CC.mat ROI one will be created and saved.
        if exist(fullfile(dt6Dir,'ROIs','CC.mat'),'file');
            ccRoi = dtiRoiClean(dtiReadRoi(fullfile(roiDir,'CC.mat')), 3, {'fillHoles','dilate'});
            ccRoi = dtiRoiClean(ccRoi, 3, {'fillHoles','dilate'});
        else
            disp('Finding CC');
            ccCoords = dtiFindCallosum(dt.dt6,dt.b0,dt.xformToAcpc);
            ccRoi = dtiNewRoi('CC','c',ccCoords);
            dtiWriteRoi(ccRoi, fullfile(roiDir,'CC.mat'));
            disp(['Writing ' ccRoi.name ' to ' roiDir]);
        end

        roiAll 	= dtiNewRoi('all');
        mask 	= fa>=faThresh;
        [x,y,z] = ind2sub(size(mask), find(mask));
        roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);
        
        if doAll==1
            fg = dtiFiberTrack(dt.dt6,roiAll.coords,dt.mmPerVoxel,dt.xformToAcpc,'AllFG',opts);
            fg = dtiIntersectFibersWithRoi([], {'not'}, [], ccRoi, fg);
            fg = dtiCleanFibers(fg);
        if clip ==1
            fg = dtiFiberMidSagSegment(fg,nPts,'b');
        end
            if(fileFormat == 0)
                dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
            end
            if(fileFormat == 1)
                dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name));
            end
        end

        % LEFT ROI
        roiLeft = dtiRoiClip(roiAll, [-80 -5]);
        %roiLeft = dtiRoiClean(roiLeft, 3, {'fillHoles', 'removeSat'});

        % RIGHT ROI
        roiRight = dtiRoiClip(roiAll, [5 80]);
        %roiRight = dtiRoiClean(roiRight, 3, {'fillHoles', 'removeSat'});

        clear roiAll;

        % Track Fibers
        disp('Tracking Left Hemisphere Fibers ...');

        % left hemisphere
        fg = dtiFiberTrack(dt.dt6,roiLeft.coords,dt.mmPerVoxel,dt.xformToAcpc,'LFG',opts);
        fg = dtiIntersectFibersWithRoi([], {'and'}, [], ccRoi, fg);
        fg = dtiCleanFibers(fg);
        
        if clip ==1
            fg = dtiFiberMidSagSegment(fg,nPts,'r');
        end
        
        if(fileFormat == 0)
            dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
        end
        if(fileFormat == 1)
            dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name));
        end


        disp('...');
        disp(['The fiber group ' fg.name ' has been written to ' fiberDir]);
        disp('...');
        disp('Tracking Right Hemisphere Fibers ...');
        clear fg
        % right hemisphere
        fg = dtiFiberTrack(dt.dt6,roiRight.coords,dt.mmPerVoxel,dt.xformToAcpc,'RFG',opts);
        fg = dtiIntersectFibersWithRoi([], {'and'}, [], ccRoi, fg);
        fg = dtiCleanFibers(fg);
        
        if clip ==1
            fg = dtiFiberMidSagSegment(fg,nPts,'l');
        end
        
        if(fileFormat == 0)
            dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
        end
        if(fileFormat == 1)
            dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name));
        end

        disp('...');
        disp(['The fiber group ' fg.name ' has been written to ' fiberDir]);
        disp('...');

        clear fg;
    end
end

disp('*************');
disp('  DONE!');

%%









