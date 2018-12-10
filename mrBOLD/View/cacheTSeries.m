function view = cacheTSeries(view,scans);
% view = cacheTSeries(view,[scans]):
%
% load tSeries for one or more scans into a 
% 'tSeriesCache' field in the view, for quicker
% retrieval down the line.
%
% I've noticed the implementation of the tSeries
% field in views is pretty antiquated, at least
% for inplane views, and maybe if other people
% aren't using it it'd be better to just use
% the tSeries field.
%
% 08/04 ras.
if ieNotDefined('scans')
    scans = er_selectScans(view);
end

if ~isfield(view,'tSeriesCache')
    view.tSeriesCache = cell(1,numScans(view));
end

tic

h = mrvWaitbar(0,'Caching tSeries for this view...');

tSeries = cell(numScans(view),numSlices(view));

for s = scans

    % load each tSeries into cache, as a double
    for slice = 1:numSlices(view)
        subt = loadtSeries(view,s,slice);
        tSeries{s,slice} = subt;
    end

    
    % find the range for each tSeries, rescale into uint16
    for slice = 1:numSlices(view)
        rng{s,slice} = [min(tSeries{s,slice}(:)) max(tSeries{s,slice}(:))];
%         rng = [mean(tSeries(:))-3*std(tSeries(:)) mean(tSeries(:))+3*std(tSeries(:))];
        rng{s,slice} = double(rng{s,slice});

        tSeries{s,slice} = rescale2(double(tSeries{s,slice}),rng{s,slice},[0 65535]);
        tSeries{s,slice} = uint16(tSeries{s,slice});
    end
    
    mrvWaitbar(find(scans==s)/length(scans),h);
end

view.tSeriesCache = tSeries;
view.tSeriesRange = rng;

close(h);

toc

return
