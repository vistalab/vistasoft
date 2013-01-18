function rx = rxLoadBestrotvol(rx,loadPath);
%
% rxLoadBestrotvol([rx],[loadPath]);
%
% Load a mrAlign3 bestrotvol.mat file.
%
% ras 03/05
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ieNotDefined('loadPath')
    loadPath = fullfile(pwd,'bestrotvol.mat');
end

if ~exist(loadPath,'file')
    myErrorDlg('No bestrotvol file found.');
end

load(loadPath);

% construct a 4 x 4 homogenous transform matrix
% from the rot, trans, and scaleFac matrices:
% (This is taken from inplane2VolXform):
A = diag(scaleFac(2,:))*rot*diag(1./scaleFac(1,:));
b = (scaleFac(2,:).*trans)';

newXform = zeros(4,4);
newXform(1:3,1:3)=A;
newXform(1:3,4)=b;
newXform(4,4)=1;

rx = rxSetXform(rx,newXform,0);

rxStore(rx,'bestrotvol');

return
