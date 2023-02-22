function test_mrInit
%Validate that mrInit is doing the right thing
%
%  test_mrInit()
%
% Tests: mrInitDefaultParams, mrInit
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_mrInit()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2011



%% Set up the data: 
mrvCleanWorkspace;

nifti_path = mrtInstallSampleData('functional','mrBOLD_01');

%Sample CNI dataset using the new Inplane processing pipeline which stores
%only the path to the nifti inplane rather than writing out anat.mat file
epi_file{1}     = fullfile(nifti_path,'Raw','fMRI_run01.nii.gz');
epi_file{2}     = fullfile(nifti_path,'Raw','fMRI_run01.nii.gz');
inplane_file = fullfile(nifti_path,'Raw','T1_Inplane.nii.gz'); 
anat_file    = fullfile(nifti_path, '3DAnatomy', 't1.nii.gz');

% Make the sessiondir in the system-defined tempdir:  
sess_path = fullfile(tempdir,'mrSession');
%sess_path = nifti_path;


% Generate the expected generic params structure
params = mrInitDefaultParams;

% And insert the required parameters: 
params.inplane = inplane_file; 
params.functionals = epi_file; 
params.sessionDir = sess_path; 

% Specify some optional parameters
params.vAnatomy = anat_file;
params.keepFrames = [3 -1; 3 96]; %Dropped first 3 frames, kept remaining
params.subject = 'Test Subject 01';
params.annotations = {'Scan 1', 'Scan 2'};
params.coParams{1} = coParamsDefault;
params.coParams{1}.nCycles = 8;
params.coParams{2} = params.coParams{1};


% Run it: 
ok = mrInit(params); 

%% Test the results: 
%Read in the raw files
epi_nii{1} = niftiRead(epi_file{1}); 
epi_nii{2} = niftiRead(epi_file{2}); 
%inplane_nii = niftiRead(inplane_file); 

%Read in the initialized data structures
mrs = load(fullfile(sess_path,'mrSESSION.mat'));
func(1) = sessionGet(mrs.mrSESSION,'Functionals', 1);
func(2) = sessionGet(mrs.mrSESSION,'Functionals', 2);
ip = sessionGet(mrs.mrSESSION,'Inplane Path'); 
dt = mrs.dataTYPES; 

%% Compare the raw to the initialized

% First, just make sure it ran through: 
assertEqual(ok, 1);
%TODO: Put it into a loop

for scanNumber = 1:length(params.functionals)
    % Did you get the right voxel size?
    val = niftiGet(epi_nii{scanNumber},'Pix Dim');
    assertEqual(func(scanNumber).voxelSize, val(1:3));
    
    % And TR? Since this is a functional data set, assume that 'val' has 4
    % dimensions
    assertEqual(func(scanNumber).framePeriod, val(end));
    % Which is also saved in dataTypes:
    assertEqual(dt.scanParams(scanNumber).framePeriod, val(end));
    
    val = niftiGet(epi_nii{scanNumber},'Dim');
    % Number of TRs:
    assertEqual(func(scanNumber).nFrames, val(end) - params.keepFrames(scanNumber, 1));
    % also  in dataTYPES:
    assertEqual(dt.scanParams(scanNumber).nFrames, val(end) - params.keepFrames(scanNumber, 1));
    
    % Inplane dimensions:
    assertEqual(func(scanNumber).fullSize, niftiGet(epi_nii{scanNumber},'Slice Dims'));
    % also in dt (there's no crop per default):
    assertEqual(dt.scanParams(scanNumber).cropSize, niftiGet(epi_nii{scanNumber},'Slice Dims'));
    
    % Number of slices:
    assertEqual(length(func(scanNumber).slices), niftiGet(epi_nii{scanNumber},'Num Slices'));
end

%TODO: Think about implementing something that checks that the data was
%written out correctly

%% From the inplane anatomical data: 
% The init no longer loads the data file into the mrSESSION variable, nor
% does it load its header information there, so we will need to change the
% below

%For now, check to see that the mrSession variable was stored correctly
assertEqual(ip,inplane_file);


%% Check that session can be opened

currDir = pwd;
cd(sess_path);

vw = initHiddenInplane;

cd(currDir);

assertEqual(viewGet(vw,'View Type'),'Inplane');
assertEqual(viewGet(vw,'Name'),'hidden');

mrvCleanWorkspace;
