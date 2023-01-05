%Run one participant: normalize full brain tractography set (not just mori).
%Two-stage procedure: first, generate a mori set and initialize the solution. Second, throw in the rest of the fibers and normalize them, too.

%Assumes each dti folder already contains safe brain mask, bvals/bvecs averages & contrack parameter files.
%See dti_Longitude_NormalizeMoriFibersDensity.m for an example how to set up a batch process to generate those. 
%In face, use dtiRawAverage instead of dtiAverageRawAligned function (the fist one is a more general version). 

%ER 07/2009
warning('off'); clear;
addpath(genpath('~/vistasoft'));
addpath(genpath('/usr/local/matlab/toolbox/mri/spm5_r2008/'));

project_folder='/biac3/wandell4/data/reading_longitude/dti_y1234/';
load('/biac3/wandell4/users/elenary/longitudinal/subjectCodesAll4Years');
subjectID=subjectCodes;
numProcessorsAvail=16; %Courtesy max number of processors to be used on Azure without annoying everyone else.
allfibers_prefix='all';
moriFile=fullfile('dti06trilinrt', 'fibers',  [allfibers_prefix 'ConnectingGM_MoriGroups.mat']);
wholebrainGM=fullfile('dti06trilinrt', 'fibers',  [allfibers_prefix 'ConnectingGM.mat']);
wholebrainFibers=fullfile('dti06trilinrt', 'fibers', [allfibers_prefix '.mat']); %Usually we do not save all.mat since blue
%matter only work with fibers that connect gm

compute_allConnectingGM=false; %We already computed allConnectingGM before; only recompute if does not exist
saveAllFibers=false; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
for s=1:size(subjectID, 2)
    
    cd([project_folder subjectID{s}]);
    if exist(moriFile, 'file')
    fprintf('Subject %s already has morifile created \n', num2str(s)); 
    continue;
    end
    
    fprintf(1, 'Working on %s\n', subjectID{s}); 
    dt6File=fullfile(pwd, 'dti06trilinrt', 'dt6.mat');
    dt = dtiLoadDt6(dt6File);
    
    if  compute_allConnectingGM || ~exist(wholebrainGM, 'file')
    %Perform full brain tractography and save results
        faThresh = 0.30;
        opts.stepSizeMm = 1;
        opts.faThresh = 0.15;
        opts.lengthThreshMm = [50 250];
        opts.angleThresh = 50;
        opts.wPuncture = 0.2;
        opts.whichAlgorithm = 1;
        opts.whichInterp = 1;
        opts.seedVoxelOffsets = [0.25 0.75];
        opts.offsetJitter = 0.1;
        fa = dtiComputeFA(dt.dt6);
        fa(fa>1) = 1; fa(fa<0) = 0;
        roiAll = dtiNewRoi(allfibers_prefix);
        mask = dtiCleanImageMask(fa>=faThresh);
        [x,y,z] = ind2sub(size(mask), find(mask));
        clear mask fa;
        roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);
        clear x y z;
        fg = dtiFiberTrack(dt.dt6, roiAll.coords, dt.mmPerVoxel, dt.xformToAcpc, allfibers_prefix, opts);
        clear roiAll
    if saveAllFibers
        dtiWriteFiberGroup(fg, wholebrainFibers); 
    end
    fprintf('Get fibers connecting GM\n');     
    fg=dtiGetFibersConnectingGM(fg, dt);
    dtiWriteFiberGroup(fg, wholebrainGM); %Need to save it once b/c it is fed to dtiFindMoriTracts; overwritten later by a sequence of Mori and Non-Mori (unclassified) fibers.
    end
    
    fprintf('Find Mori Tracts\n');
    
    [fgMoriWithCST, fg_unclassifiedMoriWithCST]=dtiFindMoriTracts(dt6File, moriFile, wholebrainGM);%Note: here we went with default values which included useRoiBasedApproach=[.89 1]. This is a very conservative threshold for minDist (fiber-to-roi). But since we are simply using this moriClassification to generate an initial solution for blue Matter, we'll leave it at that. 
    mergedFG = dtiMergeFiberGroups(fgMoriWithCST, fg_unclassifiedMoriWithCST, allfibers_prefix);
    %Save "Mori-plus-the-rest" file (overwrites/reorders wholebrainGM)
    dtiWriteFiberGroup(mergedFG, wholebrainGM);
    %Save Mori only file
    dtiWriteFiberGroup(fgMoriWithCST, moriFile);
    %Save both of them as PDB
    dtiWriteFibersPdb(mergedFG, dt.xformToAcpc, [wholebrainGM(1:(end-4)) '.pdb']);
    dtiWriteFibersPdb(fgMoriWithCST, dt.xformToAcpc, [moriFile(1:(end-4)) '.pdb']);
    
    %Create initial solution
    [status, result]=system(['ps -U elenary |grep ''trueSA'' |wc|awk ''{print $1}''']); %result=2 if no trueSA by me are running
    if str2num(result)<=(numProcessorsAvail+2)
    display(['starting a trueSA for' subjectID{s}]);  
    SAlogfile=['/azure/scr1/bluematterscratch' filesep subjectID{s} 'dti06trilinrt_' allfibers_prefix 'ConnectingGM_MoriGroups_DN' filesep 'runSAmpi.log']; 
    system(['/biac3/wandell4/users/elenary/density_normalization/scripts/runSAmpi.sh ' project_folder filesep subjectID{s} filesep 'dti06trilinrt  ' [allfibers_prefix 'ConnectingGM_MoriGroups.pdb'] ' ' [allfibers_prefix 'ConnectingGM_MoriGroups_DN.pdb'] ' &>' SAlogfile  '&']);
    else continue
    end
end
return
%Since we could not launch all trueSAs, launch'em here
a=1;
while a
try
    a=(size(findstr('allConnectingGM_MoriGroups_DN.ind', ls([project_folder filesep '*' filesep 'dti06trilinrt' filesep 'fibers' filesep allfibers_prefix  'ConnectingGM_MoriGroups_DN.ind'])), 2)<108); 
catch
    %in no *.ind yet
    a=1;
end
for s=1:size(subjectID, 2)
    s
     cd([project_folder subjectID{s}]);
        [status, result]=system('ps -U elenary -u elenary |grep ''trueSA'' |wc|awk ''{print $1}''');
    if (~exist([moriFile(1:(end-4)) '_DN.TMP'], 'file')) && str2num(result)<=(numProcessorsAvail+2) && (~exist([moriFile(1:(end-4)) '_DN.ind'], 'file')) && (exist(moriFile, 'file'))
        display(['starting a trueSA for ' subjectID{s}]);  
        SAlogfile=['/azure/scr1/bluematterscratch' filesep subjectID{s} 'dti06trilinrt_' allfibers_prefix 'ConnectingGM_MoriGroups_DN' filesep 'runSAmpi.log']; 
    mkdir(fileparts(SAlogfile));
        system(['/biac3/wandell4/users/elenary/density_normalization/scripts/runSAmpi.sh ' project_folder filesep subjectID{s} filesep 'dti06trilinrt  ' [allfibers_prefix 'ConnectingGM_MoriGroups.pdb'] ' ' [allfibers_prefix 'ConnectingGM_MoriGroups_DN.pdb'] ' &>' SAlogfile '&']);
        else
   
        
    end
pause(10);     
end

end

return
%%%%%%%%%%% RUN AFTER ALL TRUESA and VALIDATION JOBS DONE -- this step
%%%%%%%%%%% is not required to continue on with full  brain BM
%%%%%%%%%%% normalization. This step is required for quality checks though.
%%%%%%%%%%% 
%Tranform ind to mat
for s=1:size(subjectID, 2)
    cd([project_folder subjectID{s}]);
    dt6File=fullfile('dti06trilinrt', 'dt6.mat');
	
    %Get the pdb back to mat, incorporating the indices
    fg=dtiLoadFiberGroup(moriFile);
    try
    fid=fopen(fullfile(fileparts(dt6File), 'fibers', [allfibers_prefix  'ConnectingGM_MoriGroups_DN.ind']));
    fprintf( subjectID{s});
    %TrueSA solution are indices of fibers to keep--in the space of allConnectingGM_MoriGroups. PLUS1!!! (those indices count from 0)
    DN_ind=textscan(fid, '%d');DN_ind=DN_ind{1}; fclose(fid);
    dtiWriteFibersSubset(moriFile, DN_ind+1, fullfile(fileparts(dt6File), 'fibers', [allfibers_prefix  'ConnectingGM_MoriGroups_DN.mat']), 'allConnectingGM_MoriGroups_DN', fg.subgroup(DN_ind+1), fg.subgroupNames);
   
    catch
        fprintf('Not converged yet'); 
    end
end

return

%After the initial solution has been obtained, use its model.pid to run
%blue matter on the full set arranged as MoriTracts-then-otherTracts.
a=1;
while a
try
    a=(size(findstr('allConnectingGM_DN.ind', ls([project_folder filesep '*' filesep 'dti06trilinrt' filesep 'fibers' filesep allfibers_prefix  'ConnectingGM_DN.ind'])), 2)<112); 
catch
    %in no *.ind yet
    a=1;
end
for s=1:size(subjectID, 2)
    %check that the initial guess job at least finished. system(grep) returns "0" if
    %there is a match found---oukey. (system error codes of 1 or 2 otherwise).. And also see if maybe this job is
    %already running...
        display([subjectID{s}]);    
    
    [status, result]=system('ps -U elenary -u elenary |grep ''trueSA'' |wc|awk ''{print $1}''');
    if(str2num(result)<=(numProcessorsAvail+2)&&~system(['grep "converged" /azure/scr1/bluematterscratch/' subjectID{s} 'dti06trilinrt_' allfibers_prefix 'ConnectingGM_MoriGroups_DN' filesep '*true*']) && ~exist(['/azure/scr1/bluematterscratch/' subjectID{s} 'dti06trilinrt_' allfibers_prefix 'ConnectingGM_DN' filesep 'data_0.SBfloat'], 'file') && (system(['grep "converged" /azure/scr1/bluematterscratch/' subjectID{s} 'dti06trilinrt_' allfibers_prefix 'ConnectingGM_DN' filesep '*true*'])~=0))
   
        display(['Submitting all fibers Blue Matter for ' subjectID{s}]);    
        cd([project_folder subjectID{s}]);
        initialGuess=['/azure/scr1/bluematterscratch/' subjectID{s} 'dti06trilinrt_' allfibers_prefix 'ConnectingGM_MoriGroups_DN' filesep 'pids' filesep 'model.pid'];
        system(['/biac3/wandell4/users/elenary/density_normalization/scripts/runSAmpi.sh ' project_folder filesep subjectID{s} filesep 'dti06trilinrt  ' [allfibers_prefix 'ConnectingGM.pdb'] ' ' [allfibers_prefix 'ConnectingGM_DN.pdb '] initialGuess ' &']);
    end
pause(50)    
end

end

return

%Final solution -- Tranform ind to mat.  allConnectingGM_DN.mat: Mori Labels for the indices correspoinding to
%first N fibers can be obtained from allConnectingGM_MoriGroups, the rest
%should be "0"; 
for s=1:size(subjectID, 2)
    cd([project_folder subjectID{s}]);
    dt6File=fullfile('dti06trilinrt', 'dt6.mat');
	
    %Get the pdb back to mat, incorporating the indices
    fgWholeBrain=dtiLoadFibergroup(wholebrainGM);
    try
    fid=fopen(fullfile(fileparts(dt6File), 'fibers', [allfibers_prefix  'ConnectingGM_DN.ind']));
    fprintf( subjectID{s});
    %TrueSA solution are indices of fibers to keep--in the space of allConnectingGM. PLUS1!!! (those indices count from 0)
    DN_ind=textscan(fid, '%d');DN_ind=DN_ind{1}; fclose(fid);
    dtiWriteFibersSubset(wholebrainGM, DN_ind+1, fullfile(fileparts(dt6File), 'fibers', [allfibers_prefix  'ConnectingGM_DN.mat']), 'allConnectingGM_DN', fgWholeBrain.subgroup(DN_ind+1), fgWholeBrain.subgroupNames);
   
    catch
        fprintf('Not converged yet'); 
    end
end
