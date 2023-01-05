function l=avgLineROIs(view,dist,flip);
% avgLineROIs - well... just that
%
% l=avgLineROIs(view,dist,flip);
%
% line roi is randomly ordered so some need to be flipped in the right
% direction, flip indicates which ROI numbers, e.g. [2 4] have to be flipped.

if ~exist('dist','var') || isempty(dist),
    dist = 0;
end
if ~exist('flip','var') || isempty(flip),
    flip = 0;
end

% get number of rois
nROIs = numel(view.ROIs);

xint = linspace(0,1,100)';
maxX = 0;
yint = zeros(size(xint));
yall = repmat(yint,1,nROIs);
for n=1:nROIs
    view.selectedROI = n;
    if any(flip==n),
        doflip = true;
    else
        doflip = false;
    end
    r = plotLineROI(view,dist,false,sprintf('roi %d',n));
    
    % remove steps larger than 3
    myEnd = find(diff(r.x)>5);
    if ~isempty(myEnd),
        r.x = r.x(1:myEnd(1));
        r.y = r.y(1:myEnd(1));
    end
    
    % flip
    if doflip,
        r.x = flipud(r.x(:));
        r.x = abs(r.x-max(r.x));
        r.y = flipud(r.y(:));
    end
    
    % interpolate
    yall(:,n) = interp1(r.x(:),r.y(:),xint.*max(r.x),'spline');
    maxX = maxX + max(r.x);
end
yint = mean(yall')';
ystd = std(yall')';
ysterr = ystd./nROIs;
maxX = maxX ./ numel(view.ROIs);
xint = xint.*maxX;

% plot and output 
figure;hold on;
plot(xint,yint,'k-');
plot(xint,yint+ysterr,'k:');
plot(xint,yint-ysterr,'k:');
axis([0 max(xint) -1 1]);

l.x = xint;
l.y = yint;
