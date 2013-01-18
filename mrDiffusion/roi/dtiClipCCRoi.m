function dtiClipCCRoi(cc,saveDir)
%
% dtiClipCC(ccRoi,[saveDir])
% Example: dtiClipCC('CC.mat','ROIs/MT/')
%
% This function takes a CC.mat file (created from dtiFindCallosum) and
% clips it into three planes, each one voxel wide. 
% The planes will be saved in the saveDir with the names: CC_clipMid.mat,
% CC_clipLeft.mat and CC_clipRight.mat.
%
% History:
% 04/02/2009 - LMP wrote the thing
%

if notDefined('saveDir'), saveDir = pwd; end
if notDefined('cc'), error('You must pass in a .mat file.'); end
origCC = cc;
roiDir = saveDir;


    clippedCC = fullfile(roiDir, 'CC_clipMid.mat');
    leftCC = fullfile(roiDir, 'CC_clipLeft.mat');
    rightCC = fullfile(roiDir, 'CC_clipRight.mat');

    origCC = dtiReadRoi(origCC);

    % create and save the central CC plane
    [centerCC roiNot] = dtiRoiClip(origCC, [1 1], [], []);
    [newCC roiNot] = dtiRoiClip(centerCC, [-1 -1], [], []);
    newCC.name = 'CC_clipMid';
    newCC.color = 'g';

    dtiWriteRoi(newCC, clippedCC);

    % create and save the left CC plane
    [ltCC roiNot] = dtiRoiClip(origCC, [0 1], [], []);
    ltCC.name = 'CC_clipLeft';
    ltCC.color = 'b';

    dtiWriteRoi(ltCC, leftCC);

    % create and save the right CC plane
    [rtCC roiNot] = dtiRoiClip(origCC, [-1 0], [], []);
    rtCC.name = 'CC_clipRight';
    rtCC.color = 'r';

    dtiWriteRoi(rtCC, rightCC);
    
    disp(sprintf(['\n\tSaved: ', clippedCC]));
    disp(sprintf(['\n\tSaved: ', leftCC]));
    disp(sprintf(['\n\tSaved: ', rightCC]));
return
    