% Script to make a mrSESSION directory from some analyze data
% You need to fill in many of the parameters below: 
% Note that you need to have converted everything to analyze format before you run this script. See


clear all;

anatomyInplaneDir=43; % This is the location of the IRRARE T1 weighted data

rotateInplanes=1; % Number of 90degree ccw rotations to apply to everything to make it look nice.
% Where are the source files for the data? 
sourceFileBaseDir='/raid/MRI/data/wade/Nikos_Data/Monkey/Spring2003/original/C01.j51/converted/'

sourceSubDirArray=[25:32]; % Scans 38-45 are retinotopy scans and must be analyzed separately.
nFunctionals=length(sourceSubDirArray);

MLR_ScanOffset=0;

M.mrLoadRetVersion=3.0100;
M.sessionCode='032603_C01_Ret'
M.description='MPI: Ret scans C01 Spring 2003'
M.subject='C01'
M.examNum='C01.j51';

% INPLANES
I.FOV=128; % in mm
I.fullSize=[256 256]; % pixels
I.voxelSize=[0.5 0.5 2] % in mm
I.spacing=0
I.nSlices=17
I.examNum=M.examNum
I.crop=[0 0;255 255]; % top left, bottom right coordinates. In this case, no crop.
I.cropSize=[256 256];

M.inplanes=I;


%FUNCTIONALS
F.PfileName=0; % To be filled in later when we loop over the functionals
F.totalFrames=144;
F.junkFirstFrames=12;
F.nFrames=F.totalFrames-F.junkFirstFrames;
F.slices=1:I.nSlices;
F.fullSize=[128 128]; % Resolution, in pixels
F.cropSize=[128 128]
F.crop=[0 0;127 127]
F.voxelSize=[I.FOV./F.fullSize,  I.voxelSize(3)];
F.effectiveResolution=F.voxelSize;
F.framePeriod=6.5; % The length of 1 TR times the number of interleaves

% RECONPARAMS



R.nframes=F.totalFrames;
R.nshots=1;
R.FOV=I.FOV;
R.sliceThickness=I.voxelSize(3);
R.skip=0
R.TR=F.framePeriod;

R.tAcq=806;

R.slquant=I.nSlices;

R.equivMatSize=128;
R.imgsize=128;
F.reconParams=R;

% Now we loop through all the n directories listed in sourceSubDirArray
% We will create a 1xn functionals structure in mrSESSION by copying F a lot. The only thing we'll change will be F.PfileName
% We also create dataTYPES at this point. dataTYPES will be a single structure with some 1xn sub-structures. 
%            scanParams: [1x14 struct]
%            blockedAnalysisParams: [1x14 struct]
%            eventAnalysisParams: [1x14 struct]
% eventAnalysisParams are all 0
% Scan params and blockedAnalysisParams are to be set in the loop by copying in the structures we define next.....
S.annotation='retinotopy-original';
S.nFrames=F.nFrames;
S.framePeriod=F.framePeriod
S.slices=F.slices;
S.cropSize=F.cropSize;

% and blocked analysis params...
B.blockedAnalysis=1;
B.detrend=-1;
B.inhomoCorrect=1;
B.nCycles=11; % For the color expts=4. For the retinotopies, this is 12. For J02 this is 11
B.temporalNormalization=0; % This is essential for the MPG scans

E.eventAnalysis=0;


nScans=length(sourceSubDirArray);

% Assume we run this in the destination dir.
% Make more Dirs


disp('Generating sub directories');

a=mkdir('Inplane'); % Holds data in 'slice' format
a=mkdir('Gray'); % Holds data in 3D restricted to the cortical gray matter
a=mkdir('Volume'); % Barely used. Holds data in 3D 
a=mkdir('Raw'); % Original FID files, IRRARE files etc.
a=mkdir('Inplane/ROIs'); % Regions of interest 
a=mkdir('Inplane/Original');
a=mkdir('Inplane/Original/TSeries');
a=mkdir('Gray/ROIs');

tSerDir=['Inplane/Original/TSeries/'];

% Generate the anat.mat file.
inpIndex=sprintf('%02d',anatomyInplaneDir);
anatFile=fullfile(sourceFileBaseDir,int2str(anatomyInplaneDir),[M.subject,'_',inpIndex])
anat=analyze2mrLoadRetInplanes(fullfile(sourceFileBaseDir,int2str(anatomyInplaneDir),[M.subject,'_',inpIndex]),'./');
[x,y,nSlices]=size(anat);
% Run through the anat matrix and do rotations
for t=1:nSlices
    anat(:,:,t)=rot90(anat(:,:,t),rotateInplanes);
end


save('Inplane/anat.mat','anat');


dataTYPES.name='Original';
    
for t=1:nFunctionals
    F.PfileName=['P_MPI_',int2str(sourceSubDirArray(t))];
    M.functionals(t)=F;
    % Also fill in the dataTYPES structure.
    dataTYPES.blockedAnalysisParams(t)=B;
    dataTYPES.eventAnalysisParams(t)=E;
    dataTYPES.scanParams(t)=S;
    dataTYPES.name='Original';
    
    
end

global mrSESSION;
global dataTYPES;
global HOMEDIR;

mrSESSION=M;

saveSession;


% Now we're ready to import and convert the functional data
disp ('Saved mrSESSION: Now doing function tSeries data...');

for thisScan=1:nFunctionals
    thisTSerDir=fullfile(tSerDir,['Scan',int2str(thisScan+MLR_ScanOffset)])
    a=mkdir(thisTSerDir);
    thisFunc=int2str(sourceSubDirArray(thisScan));
    thisFunc02Padded=sprintf('%02d',sourceSubDirArray(thisScan));
    sourceRoot=fullfile(sourceFileBaseDir,thisFunc,[M.subject,'_',thisFunc02Padded,'_EPI_']);
    
    imStack=analyze2mrLoadRet3TSeries(sourceRoot,thisTSerDir,F.nFrames,F.junkFirstFrames+1,1,1,0);
    fprintf('\nDone scan %d (directory %d)\n',thisScan,sourceSubDirArray(thisScan));
    
end

    


