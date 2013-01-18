function dtiIntersectFibers(dt6FileName, fgName, roiName, intersectOpt)
% Wrapper to perform ROI-Fiber intersection calculation
%
%   dtiIntersectFibers(dt6FileName, fgName, roiName, intersectOpt={'and','endpoints'})
%
% This is just a wrapper routine that figures out various parameters and
% sends the information to the working routine dtiIntersectFibersWithROI.
%

if(~exist('dt6FileName','var') || isempty(dt6FileName))
    [f,p] = uigetfile('*.mat', 'Load the dt6 file');
    dt6FileName = fullfile(p,f);
end
if(~exist('fgName','var') || isempty(fgName))
    [f,p] = uigetfile('*.mat', 'Load the fibers file');
    fgName = fullfile(p,f);
end
if(~exist('roiName','var') || isempty(roiName))
    [f,p] = uigetfile('*.mat', 'Load the ROI file');
    roiName = fullfile(p,f);
end
if(~exist('intersectOpt','var') || isempty(intersectOpt))
    intersectOpt = {'and','endPoints'};
end

dt = load(dt6FileName, 't1NormParams');

roi = dtiReadRoi(roiName, dt.t1NormParams);
fg = dtiReadFibers(fgName, dt.t1NormParams);

disp('Intersecting fibers- please wait...');
fg = dtiIntersectFibersWithRoi(0, intersectOpt, [], roi, fg);
newFgName = fullfile(fileparts(fgName), [fg.name '.mat']);
if(exist(newFgName,'file'))
    [f,p] = uiputfile('*.mat', 'Select new fiber file name', ...
        newFgName);
    if(isnumeric(f))
        error('user cancelled');
    end
    newFgName = fullfile(p,f);
end
disp(['writing new fiber group to ' newFgName '...']);
dtiWriteFiberGroup(fg, newFgName, 1, 'acpc');
clear fg;
return;
