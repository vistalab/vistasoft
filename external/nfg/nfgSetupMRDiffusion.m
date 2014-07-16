function nfgSetupMRDiffusion(phantomDir)
%Setup mrDiffusion files for BlueMatter NFG tests.
%
%   nfgSetupMRDiffusion(phantomDir)
%
% 
% AUTHORS:
%   2009.08.05 : AJS wrote it
%
% NOTES: 
%   * We are automatically dividing the NFG b-value by 1000, but there
%   should be a more appropriate dynamic way to do this.
%

% Directories
dtDir = nfgGetName('dtDir',phantomDir);
% Input Files
nfgGradFile = nfgGetName('nfgGradFile',phantomDir);
noisyImg = nfgGetName('noisyImg',phantomDir);
brainMaskFile = nfgGetName('brainMaskFile',phantomDir);
% Output Files
bvalsFile = nfgGetName('bvalsFile',phantomDir);
bvecsFile = nfgGetName('bvecsFile',phantomDir);

% XXX b-value factor to adjust into our units
bValFactor = 1000;

% Convert NFG grad file to ours
disp(' '); disp('Converting NFG gradient file to mrDiffusion format ...');
grad = load(nfgGradFile,'-ascii');
bvals = grad(:,4)/bValFactor;
bvecs = grad(:,1:3)';
fid = fopen(bvalsFile,'wt');
fprintf(fid, '%1.3f ', bvals); 
fclose(fid);
fid = fopen(bvecsFile,'wt');
fprintf(fid, '%1.4f ', bvecs(1,:)); fprintf(fid, '\n'); 
fprintf(fid, '%1.4f ', bvecs(2,:)); fprintf(fid, '\n');
fprintf(fid, '%1.4f ', bvecs(3,:)); 
fclose(fid);

% Do tensor fitting
numBootstraps=300;
disp(' '); disp(['Tensor fitting with ' num2str(numBootstraps) ' bootstraps ...']);
dtiRawFitTensorMex(noisyImg, bvecsFile, bvalsFile, dtDir, numBootstraps);

% Fix automatically generated brain mask
disp(' '); disp('Fixing automatically generated brain mask ...');
ni = niftiRead(brainMaskFile);
ni.data(:) = 1;
writeFileNifti(ni);

% Need to produce pdf image now
disp(' '); disp('Creating ConTrack PDF file ...');
mtrCreateConTrackOptionsFromROIs(0,1,dtDir);

return;
