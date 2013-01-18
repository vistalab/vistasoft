function nfgTestPathCoords(phantomDir,nBundleID)
%Test pathway coordinate space
%
%   nfgTestPathCoords(phantomDir,nBundleID)
%
% Need to make sure that the pathway coordinates resolve to the right image
% values in Matlab as well as the C code (ConTrack and BlueMatter).
%
% AUTHORS:
%   2009.08.05 : AJS wrote it
%
% NOTES: 

% Directories
strandDir = nfgGetName('strandDir',phantomDir);
% Input Files
dtFile = nfgGetName('dtFile',phantomDir);
goldPDBFile = nfgGetName('goldPDBFile',phantomDir);
sttPDBFile = nfgGetName('sttPDBFile',phantomDir);
goldInfoFile = nfgGetName('goldInfoFile',phantomDir);
% Output Files


% Create new directory from bundle of gold pathways
if 0
    % Directories
    testcoordsDir = nfgGetName('testcoordsDir',phantomDir);
    teststrandsDir = nfgGetName('teststrandsDir',phantomDir);
    strandDir = nfgGetName('strandDir',phantomDir);
    % Input Files
    % Output Files
    % XXX Not doing right now because the mri_sim stage takes too long
    % Create new directories
    disp(['Creating directory for testing pathway coordinates ' phantomDir ' ...']);
    [s,mess,messid] = mkdir(testcoordsDir);
    % Only continue if this is a fresh start
    if strcmp(messid,'MATLAB:MKDIR:DirectoryExists')
        error('Error: Will not overwrite previous directory!!');
    end
    mkdir(teststrandsDir);
    
    % Make strands directory with only strands from provided ID
    str = sprintf('strand_*-%02g-r*.txt',nBundleID);
    files = dir(fullfile(strandDir,str));
    for ff=1:length(files)
        nNewID = 0;
        strN = sprintf('strand_%03g-%02g-r0.030000.txt',ff-1,nNewID);
        fSource = fullfile(strandDir,files(ff).name);
        fDest = fullfile(teststrandsDir,strN);
        copyfile(fSource,fDest);
    end
    
    % mri_sim
    
    % nfgCreateBM
    
    % nfgCreatePDBs
end

% Try to find bundle in image coordinates with FA values
dt = dtiLoadDt6(dtFile);
fa = dtiComputeFA(dt.dt6);
wmI = zeros(size(fa));
wmI(fa>0.1) = 1;

% Compare img data with matlab fiber coords
fgG = mtrImportFibers(goldPDBFile);
%[strand_info, fgG] = mtrStrand2PDB(strandDir);
wmG = GetFiberMap(fgG,dt);

% Compare img data with stt matlab coords
fgS = mtrImportFibers(sttPDBFile);
%[strand_info, fgG] = mtrStrand2PDB(strandDir);
wmS = GetFiberMap(fgS,dt);

showMontage(wmI);
showMontage(wmG);
showMontage(wmS);


% gi = load(goldInfoFile);
% g_bundleID = zeros(1,length(gi.strand_info));
% g_radius = zeros(1,length(gi.strand_info));
% for ii=1:length(gi.strand_info)
%     g_bundleID(ii) = gi.strand_info(ii).bundleID+1;
%     g_radius(ii) = gi.strand_info(ii).radius;
% end

disp('Done.');
return;

function wm = GetFiberMap(fg,dt)
fgX = dtiXformFiberCoords(fg,inv(dt.xformToAcpc));
fgX.fibers = fgX.fibers(:)';
fc = horzcat(fgX.fibers{:});
vox_fc = unique(floor(fc)','rows')';
wm = zeros(size(dt.b0));
wm(sub2ind(size(dt.b0),vox_fc(1,:),vox_fc(2,:),vox_fc(3,:))) = 1;
return;