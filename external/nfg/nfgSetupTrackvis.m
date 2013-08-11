function nfgSetupTrackvis(phantomDir,bSanityCheck)
%Setup Trackvis files for BlueMatter NFG tests.
%
%   nfgSetupTrackvis(phantomDir)
%
% 
% AUTHORS:
%   2009.08.05 : AJS wrote it
%
% NOTES: 

if ieNotDefined('bSanityCheck'); bSanityCheck=0; end

% Directories
trkDir = nfgGetName('trkDir',phantomDir);
binDir = nfgGetName('binDir',phantomDir);
% Input Files
nfgGradFile = nfgGetName('nfgGradFile',phantomDir);
noisyImg = nfgGetName('noisyImg',phantomDir);
wmROIFile = nfgGetName('wmROIFile',phantomDir);
ctrparamsFile = nfgGetName('ctrparamsFile',phantomDir);
% Output Files
trkGradFile = nfgGetName('trkGradFile',phantomDir);
trkImg = nfgGetName('trkImg',phantomDir);
trkHardiMatFile = nfgGetName('trkHardiMatFile',phantomDir);
trkOdfReconRoot = nfgGetName('trkOdfReconRoot',phantomDir);
trkTRKFile = nfgGetName('trkTRKFile',phantomDir);
trkPDBFile = nfgGetName('trkPDBFile',phantomDir);
gold_trkPDBFile = nfgGetName('gold_trkPDBFile',phantomDir);
goldPDBFile = nfgGetName('goldPDBFile',phantomDir);

mkdir(trkDir);

% Convert bvals and bvecs into trackvis grad table and get b=0 measurements
% in front of data.
% Convert NFG grad file to ours
bValFactor = 1000;
disp(' '); disp('Converting NFG gradient file to TrackVis format ...');
grad = load(nfgGradFile,'-ascii');
bvals = grad(:,4)/bValFactor;
bvecs = grad(:,1:3)';
% Get the data
data = niftiRead(noisyImg);

% Get b0 to the front of the data
bvals = bvals(:)';
bvecs = cat(2, bvecs(:,bvals==0), bvecs(:,bvals~=0));
data.data = cat(4, data.data(:,:,:,bvals==0), data.data(:,:,:,bvals~=0));
bvals = [bvals(bvals==0) bvals(bvals~=0)];

% Write out trackvis grad table file and data
numb0 = sum(bvals==0);
numdirs = length(bvals) - numb0;
dlmwrite(trkGradFile,bvecs(:,numb0+1:end)', ',');
data.fname = trkImg;
writeFileNifti(data);

% Now call the hardi reconstruction program
cmd = ['hardi_mat ' trkGradFile ' ' trkHardiMatFile];
disp(' '); disp(cmd);
system(cmd,'-echo');
% Now call the odf reconstruction program
cmd = ['odf_recon ' trkImg ' ' num2str(numdirs) ' 181 ' trkOdfReconRoot ' -mat ' trkHardiMatFile ' -b0 ' num2str(numb0)];
disp(' '); disp(cmd);
system(cmd,'-echo');
% Now call the odf tracking program
numSeeds = 10;
cmd = ['odf_tracker '  trkOdfReconRoot ' ' trkTRKFile ' -m ' wmROIFile ' -ix' ' -rseed ' num2str(numSeeds)];
disp(' '); disp(cmd);
system(cmd,'-echo');
% Now convert it to PDB file
mtrTrackVis2PDB(wmROIFile, trkTRKFile, trkPDBFile);

% Now limit the fibers to those that connect the gray matter
% Call contrack_score to limit fibers to those intersecting the GM ROI
disp('Removing fibers that do not have both endpoints in GM ROI ...');
pParamFile = [' -i ' ctrparamsFile];
pOutFile = [' -p ' trkPDBFile];
pInFile = [' ' trkPDBFile];
pThresh = [' --thresh ' num2str(100000)];
cmd = ['contrack_score' pParamFile pOutFile pThresh ' --find_ends' pInFile];
disp(cmd);
system(cmd,'-echo');

if bSanityCheck
    disp(' ');disp('Combining gold and trackvis fibers into one file for sanity check ...');
    % Create a pathway file with both gold standard and stt pathways, label the
    % pathways from stt or gold group with a statistic for easy visualization
    fgG = mtrImportFibers(goldPDBFile);
    fg = mtrImportFibers(trkPDBFile);
    fgBoth = fgG;
    fgBoth.fibers(end+1:end+length(fg.fibers)) = fg.fibers;
    fgBoth = dtiClearQuenchStats(fgBoth);
    fgBoth = dtiCreateQuenchStats(fgBoth,'Length','Length', 1);
    fgBoth = dtiCreateQuenchStats(fgBoth,'Group',[zeros(1,length(fgG.fibers)) ones(1,length(fg.fibers))]);
    mtrExportFibers(fgBoth,gold_trkPDBFile);
    disp(' '); disp(['Run: Quench ' binDir ' ' gold_trkPDBFile ' -- to verify Trackvis']); disp(' ');
end

return;
