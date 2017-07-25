function varExplained = rmVarExplained(view, roi, modelNum);
% Compute the proportion variance explained by a retinotopy model fit.
%
% varExplained = rmVarExplained([view], [coords or roi], [modelNum]);
%
%
% ras, 12/2006
if notDefined('view'),      view = getCurView;                          end
if notDefined('modelNum'),  modelNum = viewGet(view, 'rmModelNum');     end
if notDefined('coords'),    roi = rmGetCoords(view, modelNum);       end

roi = tc_roiStruct(view, roi);

verbose = prefsVerboseCheck;
if verbose, hwait = mrvWaitbar(0, 'Loading % Variance Explained...'); end

params = viewGet(view, 'rmParams');
[tSeries coords params] = rmLoadTSeries(view, params, roi);
if verbose, mrvWaitbar(.5, hwait); end

fit = rmPredictedTSeries(view, coords, modelNum);    
if verbose,  mrvWaitbar(.7, hwait); end

residual = tSeries - fit;            
if verbose,  mrvWaitbar(1, hwait); end

nVoxels = size(tSeries, 2);
for v = 1:nVoxels
    varExplained(v) = 1 - (sum(residual(:,v).^2) ./ sum(tSeries(:,v).^2));  
end

return
