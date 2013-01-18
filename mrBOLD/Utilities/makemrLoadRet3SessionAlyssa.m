% Script to make a mrSESSION directory from analyze-format data
% You need to fill in many of the parameters below.
% Note that you need to have converted everything (Inplanes and TSeries) to analyze format before
% you run this script. 
% Assume we run this in the destination dir.


clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up directory info

anatomyInplaneDir=26; % This is the location of the IRRARE T1 weighted data

% Where are the source files for the data? 
% sourceFileBaseDir='/raid/MRI/data/wade/Nikos_Data/Monkey/Spring2003/original/C01.j51/converted/'
% sourceFileBaseDir='//biac1/wandell/data/monkey/retinal-lesion/A01/Ky1/converted/'
 sourceFileBaseDir='G:/data/monkey/retinal-lesion/convertedScans/A01/ky1/converted/'

sourceSubDirArray=[16]; %locations of the functional scans, ex. [1:4];
nFunctionals=length(sourceSubDirArray);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Enter mrSESSION info - you will need to edit many of these parameters
% These steps replace mrInitRet.

MLR_ScanOffset=0;  % mrLoadRet needs scans numbered 1:n; we need to convert from scans numbered 16:25, for example
                   % the offsest lets us start the mrLoadRet numbering at a
                   % different number other than 1, when adding scans to a
                   % previously created directory.

M.mrLoadRetVersion=3.0100;
M.sessionCode='A01_Ky1_Ret'
M.description='MPI: Ret scans A01, session Ky1'
M.subject='A01'
M.examNum='A01_Ky1';

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


% FUNCTIONALS
F.PfileName=0; % To be filled in later when we loop over the functionals
F.totalFrames=132;
F.junkFirstFrames=0;
F.nFrames=F.totalFrames-F.junkFirstFrames;
F.slices=1:I.nSlices;
F.fullSize=[256 256]; % Resolution, in pixels    %%128?
F.cropSize=[256 256]; % no need to crop image    %%128?
F.crop=[0 0;127 127];
F.voxelSize=[I.FOV./F.fullSize,  I.voxelSize(3)];
F.effectiveResolution=F.voxelSize;
F.framePeriod=6.5;  % The length of 1 TR (TR = 'effective frame duration' = tAcq*nshots) times the number of interleaves
                    % for 15 slices, TR = 6; for 17 slices, TR = 6.5

% RECONPARAMS
R.nframes=F.totalFrames;
R.nshots=8;         %check excel file for this
R.FOV=I.FOV;
R.sliceThickness=I.voxelSize(3);
R.skip=0
R.TR=F.framePeriod;

R.tAcq=806;        %tAcq is the actual TR. Multiply this by the number of
                    %shots to get the effective frame duration. This is 8
                    %for 17 slice monkeys - check excel file.

R.slquant=I.nSlices;

R.equivMatSize=256;  %%128?
R.imgsize=128;  %%128?
F.reconParams=R;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now we loop through all the n directories listed in sourceSubDirArray
% We will create a 1xn functionals structure in mrSESSION by copying F a lot. The only thing we'll change will 
% be F.PfileName We also create dataTYPES at this point. dataTYPES will be a single structure with some 
% 1xn sub-structures. 
%            scanParams: [1x14 struct]
%            blockedAnalysisParams: [1x14 struct]
%            eventAnalysisParams: [1x14 struct]
% eventAnalysisParams are all 0
% Scan params and blockedAnalysisParams are to be set in the loop by copying in the structures we define next.....

%SCAN PARAMETERS
S.annotation='retinotopy';
S.nFrames=F.nFrames;
S.framePeriod=F.framePeriod
S.slices=F.slices;
S.cropSize=F.cropSize;

%BLOCKED ANALYSIS PARAMETERS
B.blockedAnalysis=1;
B.detrend=1;      % -1 = linear detrend; 1 = high pass filter; varied opinions on which is better.
B.inhomoCorrect=1;
B.nCycles=11; % For the color expts=4. For the retinotopies, this is 12??? For J02 this is 11; 
                
B.temporalNormalization=0; % This is essential for the MPG scans that were converted brucker to analyze with the BUG. 
                           % For all good/normal scans set this to 0.

E.eventAnalysis=0;

nScans=length(sourceSubDirArray);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make more Dirs. Be sure to run makemrLoadRet3Session in the destination
% directory.

disp('Generating sub directories');

a=mkdir('Inplane'); % Holds data in 'slice' format
a=mkdir('Gray'); % Holds data in 3D restricted to the cortical gray matter
a=mkdir('Volume'); % Barely used. Holds data in 3D 
a=mkdir('Raw'); % Original FID files, IRRARE files etc.
a=mkdir('Raw/Anatomy'); 
a=mkdir('Raw/Anatomy/Inplane'); 
a=mkdir('Inplane/ROIs'); % Regions of interest 
a=mkdir('Inplane/Original');
a=mkdir('Inplane/Original/TSeries');
a=mkdir('Gray/ROIs');

tSerDir=['Inplane/Original/TSeries/'];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert the inplanes and generate the anat.mat file.

inpIndex=sprintf('%02d',anatomyInplaneDir);

rotateInplanes=1; % Number of 90degree ccw rotations to apply to everything to make it look nice.
                    % # rotations = rotateInplanes * 90

% anatFile=fullfile(sourceFileBaseDir,int2str(anatomyInplaneDir),[M.subject,'_',inpIndex])
% anat=analyze2mrLoadRetInplanes(fullfile(sourceFileBaseDir,int2str(anatomyInplaneDir),[M.subject,'_',inpIndex]),'./');
% anatFile=fullfile(sourceFileBaseDir,int2str(anatomyInplaneDir))
% anat=analyze2mrLoadRetInplanes(anatFile,'./');
anat=analyze2mrLoadRetInplanes(fullfile(sourceFileBaseDir,int2str(anatomyInplaneDir),'2dseq_001'),'./Raw/Anatomy/Inplane/');

[x,y,nSlices]=size(anat);

% Run through the anat matrix and do rotations
for t=1:nSlices
    anat(:,:,t)=rot90(anat(:,:,t),rotateInplanes);
end

save('Inplane/anat.mat','anat');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create dataTYPES structure

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now we're ready to import and convert the functional data

disp ('Saved mrSESSION: Now converting tSeries data...');

for thisScan=1:nFunctionals
    
    % make the directory and name of the tSeries files to be created here
    thisTSerDir=fullfile(tSerDir,['Scan',int2str(thisScan+MLR_ScanOffset)])
    a=mkdir(thisTSerDir);
    
    % input path and name of input analyze files (2dseq_)
    thisFunc=int2str(sourceSubDirArray(thisScan));
    thisFunc02Padded=sprintf('%02d',sourceSubDirArray(thisScan));
    % sourceRoot=fullfile(sourceFileBaseDir,thisFunc,[M.subject,'_',thisFunc02Padded,'_EPI_']);
    sourceRoot=fullfile(sourceFileBaseDir,thisFunc,'2dseq_');
   
    % imStack=analyze2mrLoadRetTSeries(inFileRoot,outFileRoot,nVols,firstVolIndex,doRotate,scaleFact,flipudFlag,fliplrFlag)
    % where doRotate can be any integer. The images are rotated anticlockwise by doRotate*90degrees.
    % scaleFact is a 2*1 scale factor for scaling the x and y dimensions independently.
    % if flipudFlag or fliprlFlag is set, the images are flipped up/down or left/right after rotation
    imStack=analyze2mrLoadRet3TSeries(sourceRoot,thisTSerDir,F.nFrames,F.junkFirstFrames+1,1,1,0,0);
    
    fprintf('\nDone scan %d (directory %d)\n',thisScan,sourceSubDirArray(thisScan));
    
end

    


