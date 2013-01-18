function rx = rxSaveBestrotvol(rx,savePath);
%
% rxSaveBestrotvol([rx],[savePath]);
%
% Save a mrAlign3 bestrotvol.mat file.
%
% ras 03/05
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ieNotDefined('savePath')
    savePath = fullfile(pwd,'bestrotvol.mat');
end

newXform = rx.xform;

A = newXform(1:3,1:3);
b = newXform(1:3,4)';

% account for scale factors
scaleFac(1,:) = 1./rx.rxVoxelSize;
scaleFac(2,:) = 1./rx.volVoxelSize;
rot = diag(1./scaleFac(2,:))*A*diag(scaleFac(1,:));
trans = b ./ scaleFac(2,:);

save(savePath,'rot','trans','scaleFac');
fprintf('Saved %s.\n',savePath);

return
