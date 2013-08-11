function [E, wE] = nfgCompareVolumeTrueError(fgGS, fgSS, g_radius,vR,phantomDir)
%Compare volume of two fiber groups using trueError program
%
%   [E, wE] = nfgCompareVolumeTrueError(fgGS, fgSS, g_radius,vR,phantomDir)
%
% Assumes that fgGS is the gold standard group and fgSS is the selected
% fibers that match the gold standard from the test group.  g_radius is the
% radius of the gold standard fibers and vR is a vector of radii that might
% be the thickness of the test fibers.
%
%
% NOTES: 


% Let's see how trueError compares these fibers
tempFiberDir = nfgGetName('tempFiberDir',phantomDir);
ctrparamsFile = nfgGetName('ctrparamsFile',phantomDir);
noisyImg = nfgGetName('noisyImg',phantomDir);
bvalsFile = nfgGetName('bvalsFile',phantomDir);
bvecsFile = nfgGetName('bvecsFile',phantomDir);
b0File = nfgGetName('b0File',phantomDir);
tensorsFile = nfgGetName('tensorsFile',phantomDir);
wmROIFile = nfgGetName('wmROIFile',phantomDir);
gmROIFile = nfgGetName('gmROIFile',phantomDir);

% XXX special check to find fibers less than 5 points in gold standard
fiberLen = cellfun('size',fgGS.fibers,2);
lt5 = fiberLen<5;
if sum(lt5)>0
    disp(['Warning there are ' num2str(sum(lt5)) ' fibers with less than 5 pts.']);
    fgGS.fibers = fgGS.fibers(~lt5);
end

mkdir(tempFiberDir);
mtrExportFibers(fgSS,fullfile(tempFiberDir,'ss.pdb'));
mtrExportFibers(fgGS,fullfile(tempFiberDir,'gs.pdb'));

% Convert to SBfloat
argParams = [' -i ' ctrparamsFile];
argD_SS = [' -p ' fullfile(tempFiberDir,'ss_0.SBfloat')];
argInput = [' ' fullfile(tempFiberDir,'ss.pdb')];
argThresh = [' --thresh ' num2str(length(fgSS.fibers)) ' --seq '];
cmd = ['contrack_score' argParams argD_SS argThresh argInput];
%disp(cmd);
[s,r] = system(cmd);
argD_GS = [' -p ' fullfile(tempFiberDir,'gs_0.SBfloat')];
argInput = [' ' fullfile(tempFiberDir,'gs.pdb')];
argThresh = [' --thresh ' num2str(length(fgGS.fibers)) ' --seq '];
cmd = ['contrack_score' argParams argD_GS argThresh argInput];
%disp(cmd);
[s,r] = system(cmd);
% Run true error on gold
argD_GS = [' -d ' fullfile(tempFiberDir,'gs_0.SBfloat')];
argR = [' -r ' noisyImg];
argVal = [' --val ' bvalsFile];
argVec = [' --vec ' bvecsFile];
arg0 = [' -0 ' b0File];
argG = [' -g ' gmROIFile];
argM = [' -m ' wmROIFile];
argT = [' --ten ' tensorsFile];
argGroupSize = ' -v 2';
b0 = niftiRead(b0File);
argSubSize = [' -s 0,' num2str(b0.dim(1)-1) ',0,' num2str(b0.dim(2)-1) ',0,' num2str(b0.dim(3)-1)];
argW = ' -w 0';
argDiameter = [' --diameter ' num2str(max(g_radius)*2)];
fracGoldFile = fullfile(tempFiberDir,'fgs.nii.gz');
argFractionFile = [' --fraction ' fracGoldFile];
cmd = ['trueError' argR argD_GS argVal argVec arg0 argG argM argT argGroupSize argSubSize argW argDiameter argFractionFile];
%disp(cmd);
[s,r] = system(cmd);
fracG = niftiRead(fracGoldFile);

% Search for the right radius to compare the selection to the gold
argD_SS = [' -d ' fullfile(tempFiberDir,'ss_0.SBfloat')];
fracImgs = zeros(size(repmat(b0.data,[1 1 1 length(vR)])));
E = zeros(size(vR));
for rr=1:length(vR)
    strD = num2str(vR(rr)*2);
    disp(['Comparing trueError volume using test diameter ' strD ' ...']);
    argDiameter = [' --diameter ' strD];
    fracFile = fullfile(tempFiberDir,['fss' strD '.nii.gz']);
    argFractionFile = [' --fraction ' fracFile];
    cmd = ['trueError' argR argD_SS argVal argVec arg0 argG argM argT argGroupSize argSubSize argW argDiameter argFractionFile];
    %disp(cmd);
    [s,r] = system(cmd);
    ni = niftiRead(fracFile);
    fracImgs(:,:,:,rr) = ni.data;
    %E(rr) = sum(abs(ni.data(:)-fracG.data(:)))/sum(fracG.data(:)) * 100;
    E(rr) = abs((sum(ni.data(:))-sum(fracG.data(:)))/sum(fracG.data(:)) * 100);
end
wE = sum(fracG.data(:));
% Cleanup the temp space
rmdir(tempFiberDir,'s');

return;
