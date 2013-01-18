function rx = rxFinePoints(rx);
%
% rx = rxFinePoints(rx);
%
% Using the set of selected corresponding
% points between prescribed and reference
% volumes, compute a fine alignment.
%
% This uses the mrAlign3 code.
%
%
% ras 03/05.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

% check that there are points to use
if ~isfield(rx,'points') | isempty(rx.points{1})
    msg = 'No points selected! ';
    msg = [msg 'Select Edit | Points | Add Points.'];
    myWarnDlg(msg);
    return
end

% setup params
volpts = rx.points{1};
refpts = rx.points{2};
nPoints = size(volpts,2);

h = msgbox('Computing Alignment From Selected Points...');

%%%%%%%%%%%%%%
% main calc. %
%%%%%%%%%%%%%%
% (Overall strategy: -- a bit diff't from mrAlign --
% first move the points into the same space, in
% the volume, then estimate rotation and translation
% params as a correction to the existing xform.
% I did it this way mainly b/c the one-step didn't seem
% to work.)

% move reference pts into volume space
refpts = rx2vol(rx,refpts);

% express points relative to center:
centeredRefpts = refpts - repmat(mean(refpts,2),[1 nPoints]);
centeredVolpts = volpts - repmat(mean(volpts,2),[1 nPoints]);

% solve for rotation (+ scales & skews, if points are bad):
H = zeros(3,3);
for i = 1:nPoints
    H = H + (centeredRefpts(:,i) * centeredVolpts(:,i)');
end
[U S V] = svd(H);
rot = V*(U');

% solve for translation
xrefpts = rot * refpts;
trans = mean(volpts,2) - mean(xrefpts,2);

% report on goodness-of fit of each point:
fiterr = mean(abs(volpts-xrefpts).^2);
fprintf('\nMean error of fit for each point: \n');
for i = 1:length(fiterr)
    fprintf(' Point %i: %3.2f \n',i,fiterr(i));
end

% build 4x4 affine xform matrix
correction = [rot trans; 0 0 0 1];

% this is an additional correction to the
% existing xform:
newXform = correction * rx.xform;

% minor preference:
% sometimes the math will produce tiny values
% (e.g. 1e-16) instead of zero, when 0 clearly
% is the correct setting. Occasionally
% this may make a difference. Squelch these:
newXform(abs(newXform) < 0.001) = 0;

% this fit may well include some skews
% and scales, esp. if it's overdetermined.
% check if these are large, to detect 
% potential outlier pairs of points
% (points which don't agree well):
[trans rot scale skew] = affineDecompose(newXform);

% normalize scale to take into account 
% expected differences in resolution:
scale = scale .* rx.volVoxelSize ./ rx.rxVoxelSize;

if sum(skew) > 0.2
    disp('Potential outliers -- large skew')
end

if any(abs(scale)<0.9) | any(abs(scale)>1.1)
    disp('Potential outliers -- >10% scaling')
end

% force scale and skew to adhere to rigid body
% constraints:
skew = [0 0 0];
scale(scale>0) = 1;
scale(scale<=0) = -1;
scale = scale .* rx.rxVoxelSize ./ rx.volVoxelSize;

% re-build the correction matrix:
newXform = affineBuild(trans,rot,scale,skew);

% set in rx struct
rx = rxSetXform(rx,newXform);

% store setting
rxStore(rx,'Point Alignment');

close(h);

return
