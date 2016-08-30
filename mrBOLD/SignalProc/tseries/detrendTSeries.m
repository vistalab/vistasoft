function [tSeries, trends] = detrendTSeries(tSeries,detrendOption,smoothFrames)
%
% [detrendedTSeries,  trends] = detrendTSeries(tSeries,detrendOption,[smoothFrames])
%
% detrendOption is one of the following:  
%   0 no trend removal
%   1 highpass trend removal
%   2 quadratic removal
%   -1 linear trend removal
% default determined by calling 'detrendFlag' that uses blockedAnalysisParams.detrend
%
% smoothFrames only needed for detrendOption==1
%
% djh, 2/2001
% jw, 7/2012: For linear and quadratic detrending, set model to have a
%             maximum value of 1 to avoid rank deficient matrices when
%             calculating 
%                   wgts = model\tSeries;

%disp('Detrending tSeries...');

% reshape into matrix if tSeries is 3D array
dims = size(tSeries);
nFrames = dims(1);
tSeries = reshape(tSeries, nFrames, []);


switch detrendOption
case 2
    % remove a quadratic function

    model = [(1:nFrames).*(1:nFrames);(1:nFrames);ones(1,nFrames)]';    
    
    % Limit range of model to [0 1] to avoid the possibility of rank
    % deficiency in calculating model \ tSeries
    model = bsxfun(@rdivide, model, max(model));      
    wgts = model\tSeries;
    
    trends = model*wgts;
    tSeries = tSeries - trends;
    
case -1  
    % remove a linear function
    model = [(1:nFrames);ones(1,nFrames)]';
    model = bsxfun(@rdivide, model, max(model));    

    wgts = model\tSeries;
    
    trends = model*wgts;
    tSeries = tSeries - trends;
    
case 1
    % Do high-pass baseline removal
    calcstep = 1e4;
    if size(tSeries,2) <= calcstep;
        [tSeries, trends] = removeBaseline2(tSeries, smoothFrames);        
    else % solve the out of memory problem
        trends = NaN(size(tSeries));
        for ii = 1:calcstep:size(tSeries,2);
            curRange = ii:min(ii+calcstep-1,size(tSeries,2));
            [tSeries(:,curRange), trends(:,curRange)] = ...
                removeBaseline2(tSeries(:,curRange), smoothFrames);
        end
    end
otherwise
    % Do nothing
    trends = zeros(size(tSeries));
    
end

% reshape tSeries in case we changed it from 3D array to matrix
tSeries = reshape(tSeries, dims);
trends    = reshape(trends, dims);

return













%% DEBUG

% seed random stream
s = RandStream('mt19937ar','Seed',1);
RandStream.setGlobalStream(s);

% generate a time series
ts = single(smooth(randn(300,1), 5));

% detrend three ways
[~, fit1] = detrendTSeries(ts,-1); % linear
[~, fit2] = detrendTSeries(ts, 2); % quadratic
[~, fit3] = detrendTSeries(ts, 1, 20); % high pass

% plot
figure(101)
clf

plot(1:length(ts), ts, 'k-');
hold on
plot(1:length(ts), fit1, 'r-', 'LineWidth', 2);
plot(1:length(ts), fit2, 'g-', 'LineWidth', 2);
plot(1:length(ts), fit3, 'b-', 'LineWidth', 2);

legend({'linear', 'quadratic', 'highpass'}, 'Location', 'Best')

% Compare quadratic detrend using old vs new method

% old:
n = length(ts);
model = [(1:n).*(1:n);(1:n);ones(1,n)]';    
wgts = model\ts;
trends = model*wgts;

% new (divide each column of model by its max)
n = length(ts);
model = [(1:n).*(1:n);(1:n);ones(1,n)]'; 
model = bsxfun(@rdivide, model, max(model));
wgts = model\ts;
fit2 = model*wgts;

figure(102); 
plot(1:n, trends, 'r', 1:n, fit2, 'k')
