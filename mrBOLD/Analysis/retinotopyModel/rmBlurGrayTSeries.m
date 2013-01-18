function tSeries = rmBlurGrayTSeries(view,tSeries,iterlambda)
% rmBlurGrayTSeries - smooth raw time series across cortical surface
%
% tSeries = rmBlurGrayTSeries(view,tSeries,iterlambda);
% 
% result^{i+1}[x] = c2[x] s^i[x]               data missing
% 		  = c1[x] (input[x] + lambda s^i[x])     otherwise
% 
% c_1[x] = 1/(1 + numNeighbors)
% c_2[x] = 1/numNeighbors
% s[x] = sumNeighbors

% 2007/02 SOD: adapted from regularizeGray.

if ~exist('view','var') || isempty(view),
    error('Need view struct.');
else
    if ~strcmpi(view.viewType,'gray'),
        error('Need gray viewType.');
    end;
end;
if ~exist('tSeries','var') || isempty(tSeries),
    error('Need tSeries');
end;

% these defaults approximate a FWHM of 5mm at 1mm3 resolution
if ~exist('iterlambda','var') || isempty(iterlambda),
    iter = 5; 
    lambda = 1;
else
  iter = iterlambda(1);
  lambda = iterlambda(2);
end;

% sanity check
if iter==0 || lambda==0,
    return;
end;

% works only on double format (for now):
tSeries = double(tSeries);

warning('off','MATLAB:divideByZero');

% Get numNeighbors and compute c1 and c2
edges        = double(view.edges);
numNeighbors = double(view.nodes(4,:));
edgeOffsets  = double(view.nodes(5,:));

% Initialize iterations
fprintf(1,'[%s]:Smoothing data:',mfilename);drawnow;tic;
for ii = 1:iter,
    % Get indices for missing data, we assume that data is missing for
    % entire time for a particular location.
    nanSummary = sum(tSeries,1);
    NaNs       = isnan(nanSummary);
    notNaNs    = ~isnan(nanSummary);    
    withData   = double(notNaNs);

    % compute weights
    denom = sumOfNeighbors(withData,edges,edgeOffsets,numNeighbors)';

    % compute data that can be estimated (more than one valid data point
    % in the neighborhood)
    estdata = denom>0.5;
    
    % now restrict NaNs and notNaNs to estdata
    NaNs    = NaNs(:)    & estdata(:);
    notNaNs = notNaNs(:) & estdata(:);
    
    % new data
    newt    = NaN(1,size(tSeries,2));
    for n=1:size(tSeries,1)
        % input fill nans with zeros
        tmp = tSeries(n,:);
        tmp(NaNs) = 0;
        
        % Compute sumNeighbors
        sumNeighbors = sumOfNeighbors(tmp,edges,edgeOffsets,numNeighbors)';

        % Compute new values
        newt(NaNs)    = sumNeighbors(NaNs) ./ denom(NaNs);
        newt(notNaNs) = (tmp(notNaNs) + lambda.*sumNeighbors(notNaNs))./...
                        (denom(notNaNs)+1);
        
        % store
        tSeries(n,:)=newt;
    end;
    fprintf(1,'.');drawnow;
end;
fprintf(1,'Done[%.1fmin].\n',toc./60);drawnow;

return;
