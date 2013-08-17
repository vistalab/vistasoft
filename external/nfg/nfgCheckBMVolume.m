function nfgCheckBMVolume(phantomDir)
%Verify that the BlueMatter volume calculation is correct
%
%   nfgCheckBMVolume(phantomDir)
%
%
% AUTHORS:
%   2009.08.05 : AJS wrote it
%
% NOTES: 

% Directories
volcheckDir = nfgGetName('volcheckDir',phantomDir);
% Input Files
goldPDBFile = nfgGetName('goldPDBFile',phantomDir);
goldInfoFile = nfgGetName('goldInfoFile',phantomDir);
b0File = nfgGetName('b0File',phantomDir);
ctrparamsFile = nfgGetName('ctrparamsFile',phantomDir);
noisyImg = nfgGetName('noisyImg',phantomDir);
bvalsFile = nfgGetName('bvalsFile',phantomDir);
bvecsFile = nfgGetName('bvecsFile',phantomDir);
wmROIFile = nfgGetName('wmROIFile',phantomDir);

mkdir(volcheckDir);
 
% Get bundle ID and radius of each gold pathway from info file
gi = load(goldInfoFile);
g_bundleID = zeros(1,length(gi.strand_info));
g_radius = zeros(1,length(gi.strand_info));
for ii=1:length(gi.strand_info)
    g_bundleID(ii) = gi.strand_info(ii).bundleID+1;
    g_radius(ii) = gi.strand_info(ii).radius;
end
% Get gold fibers
fgG = mtrImportFibers(goldPDBFile);

% Radii to search through
vR = 0.01:0.01:0.04;
volG = zeros(1,length(vR));
volBM = zeros(1,length(vR));
% Save a .pdb file for each bundle
for bb=1:20
    disp(['Examining bundle ' num2str(bb) ' ...']);
    vcPDB = fullfile(volcheckDir,['b' num2str(bb) '.pdb']);
    vcSBfloat = fullfile(volcheckDir,['b' num2str(bb) '_0.SBfloat']);
    fFile = fullfile(volcheckDir,['f_b' num2str(bb) '.nii.gz']);
    eFile = fullfile(volcheckDir,['e_b' num2str(bb) '.nii.gz']);
    % Write the pdb
    fg = dtiNewFiberGroup();
    fg.fibers = fgG.fibers(g_bundleID==bb);
    if ~isempty(fg.fibers)
        mtrExportFibers(fg,vcPDB);
        % Convert it to the SBfloat format
        pParamFile = [' -i ' ctrparamsFile];
        pOutFile = [' -p ' vcSBfloat];
        pInFile = [' ' vcPDB];
        pThresh = [' --thresh ' num2str(length(fg.fibers))];
        cmd = ['contrack_score' pParamFile pOutFile pThresh ' --seq' pInFile];
        disp(cmd);
        [s,r] = system(cmd);
        for rr=1:length(vR)
            % Run error calculation for each radii
            disp(' '); disp(['Calculating for raidus ' num2str(vR(rr)) ' ...']);
            b0 = niftiRead(b0File);
            fLambda = 0;
            fDiameter = vR(rr)*2;
            argSubSize = [' -s 0,' num2str(b0.dim(1)-1) ',0,' num2str(b0.dim(2)-1) ',0,' num2str(b0.dim(3)-1)];
            argDatabase = [' -d ' vcSBfloat];
            argRaw = [' -r ' noisyImg];
            argBvals = [' --val ' bvalsFile];
            argBvecs = [' --vec ' bvecsFile];
            argB0 = [' -0 ' b0File];
            argMatter = [' -m ' wmROIFile];
            argLambda = [' -w ' num2str(fLambda)];
            argDiameter = [' --diameter ' num2str(fDiameter)];
            argEFile = [' -e ' eFile];
            argFFile = [' --fraction ' fFile];
            argError = [argDatabase argRaw argBvals argBvecs argB0 argMatter argSubSize argLambda argDiameter argEFile argFFile];
            cmdError = ['trueError ' argError];
            disp(cmdError);
            [s,r] = system(cmdError);
            % Get BlueMatter volume calculation
            f = niftiRead(fFile);
            volBM(rr) = volBM(rr)+sum(f.data(:));
            % Get gold volume calculation
            volG(rr) = volG(rr)+volBundle(fg.fibers,vR(rr));
        end
    end
end

% Plot the volume functions
figure; plot(vR,volBM,'b'); hold on; plot(vR,volG,'g');

return;

function [arcL] = arclength(fc)
arcL = sum(sqrt(sum((fc(:,2:end) - fc(:,1:end-1)).^2,1)));
return;

function vol = volBundle(fibers,radius)
lenFibers=0;
for ff=1:length(fibers)
    lenFibers = lenFibers + arclength(fibers{ff});
end
vol = lenFibers*pi*radius^2;
return;
