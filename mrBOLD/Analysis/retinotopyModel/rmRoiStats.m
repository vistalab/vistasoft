function [s coordsInd] = rmRoiStats(view,cothresh)
% rmRoiStats - report statistical properties of ROI
%
% [s coordsInd] = rmRoiStats(view);
%
% 2006/06 SOD: wrote it.
% 2007/05 SOD: weight by percent variance explained.

if ~exist('view','var') || isempty(view), error('Need view struct'); end;
if ~exist('cothresh','var') || isempty(cothresh),
    % get threshold
    cothresh = viewGet(view,'cothresh');
end

% load model
model = viewGet(view,'rmModel');
if isempty(model),
    rmFile = viewGet(view,'rmFile');
    if isempty(rmFile),
        view = rmSelect(view);
        rmFile = viewGet(view,'rmFile');
    end;
    load(rmFile,'model');
end;

% get ROI coordinate indices
coords = view.ROIs(view.selectedROI).coords;
switch lower(view.viewType),
    case 'inplane'
        coordsInd = sub2ind(size(rmGet(model{1},'x')),...
            coords(1,:),coords(2,:),coords(3,:));

    case 'gray',
        allcoords    = viewGet(view,'coords');
        [d coordsInd] = intersectCols(allcoords,coords);

    otherwise,
        error('[%s]:viewtype not yet incorporated.',mfilename);
end;

% stats we like to get
stats = {'varexp','x','y','ecc','sigma','x2','y2','ecc2','sigma2','sigmaratio'};

% output
s = cell(numel(model),1);
for ii=1:numel(model),
    s{ii}.desc = rmGet(model{ii},'desc');
    varexp = rmGet(model{ii},'varexp');
    ci     = coordsInd(varexp(coordsInd)>=cothresh);
    varexp = varexp(ci);
    for n=1:numel(stats),
        tmp = rmGet(model{ii},stats{n});
        if ~isempty(tmp),
            % limit to roi
            data = tmp(ci);
            try
                tmps = wstat(data,varexp);
                s{ii}.(stats{n}).mean  = tmps.mean;
                s{ii}.(stats{n}).stdev = tmps.stdev;
                s{ii}.(stats{n}).min   = min(data);
                s{ii}.(stats{n}).max   = max(data);
                s{ii}.(stats{n}).data  = data;
            catch
                s{ii}.(stats{n}).mean  = 0;
                s{ii}.(stats{n}).stdev = 0;
                s{ii}.(stats{n}).min   = 0;
                s{ii}.(stats{n}).max   = 0;   
                s{ii}.(stats{n}).data  = [];
            end;
        end
    end;
end;


% print out information for every model if no output is requested
if ~nargout,
    fprintf(1,'\n-----------------------------------------\n');
    for ii=1:numel(model),

        fprintf(1,'[%s]:Weighted summary for model #%d: %s\n',mfilename,...
            ii,rmGet(model{ii},'desc'));
        fprintf(1,'%sThreshold: %.2f\n',blanks(3),cothresh);
        for n=1:numel(stats),
            try
                tmps = s{ii}.(stats{n});
                fprintf(1,'%sParameter: %s = %.2f(%.2f) [%.2f - %.2f].\n',...
                    blanks(3),stats{n},tmps.mean,tmps.stdev,...
                    tmps.min,tmps.max);
            catch
                % do nothing
            end
        end;
    end
    fprintf(1,'-----------------------------------------\n');
end

return;

