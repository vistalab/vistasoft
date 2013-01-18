function summary = dtiFiberSummary(handles,whichFG)
%Print a summary of the fiber properties - also make some figures
%
%   summary = dtiFiberSummary(handles,[whichFG = current])
%
% The summary statistics pool all of the nodes in the fibers.  Thus, if
% there is a node that has many fibers, that voxel will count more towards
% the summary than a voxel that has only one fiber passing through it.
%
% If you would like to count each voxel just once, then see the function
% dtiGetUniqueEigValsFromFibers.
%
% Examples:
%   summary = dtiFiberSummary(handles) % Queries you for which fiber group
%   summary = dtiFiberSummary(handles,1) % Analyze fiber group 1
%
% TODO:  This routine calls the spm functions for interpolation. It should
% use the same interpolation method as in other functions - which needs to
% be implemented.
%
% HISTORY:
%  2004: RFD: wrote it.
%  2006.12.06 RFD: improved efficiency and added radial/axial diuffusivity
%   to the output. Also, the ADC units (for MD, RD and AD) are now
%   um^2/msec (assuming that the raw data units are um^2/sec). Finally, we
%   now use nearest-neighbor intepolation, which is better than trilinear
%   for this purpose. - This seems to differ across methods, and MBS
%   reported it as a problem.
%
% TODO
%   We should be using dtiGetAllEigValsFromFibers(dt, fg); here rather than
%   this local implementation.
%   The user might want the option (not recommended by BW) of getting just
%   the  voxels where the fibers pass, but not weighting them by the number
%   of fibers that pass through the voxe, via the call to
%   dtiGetUniqueEigValsFromFibers.m  
%   
% Bob (c) Stanford VISTASOFT Team, 2004

%% Input parameters.  Use more sets/gets, please.
if notDefined('whichFG')
    whichFG = dtiGet(handles,'currentfibergroupnumber'); 
end

% This should be a dtiGet()
adcUnits = handles.adcUnits;

% For figures, we use LaTex-style symbols
adcUnitsFig = strrep(adcUnits,'micron','\mum');

fg = handles.fiberGroups(whichFG);
summary = sprintf('FG Name: %s\n',fg.name);
summary = [summary,'--------------------------------'];
if(isempty(fg.fibers)||isempty(fg.fibers{1}))
    summary = [summary '\nNo fibers in this group!'];
    return;
end

% Measure the step size of the first fiber. They *should* all be the same!
stepSize = mean(sqrt(sum(diff(fg.fibers{1},1,2).^2)));

fiberLength = cellfun('length',fg.fibers);

% These are all the coordinates of all of the fibers
coords = horzcat(fg.fibers{:})';

% Get the anatomy 
n               = dtiGet(handles,'bg num');
curBgName       = dtiGet(handles,'bg name',n);
curBg           = dtiGet(handles,'bg image',n);
curBgValRange   = dtiGet(handles,'bg range',n);
curBgXform      = dtiGet(handles,'bg img2acpc xform',n);
curBgUnitStr    = dtiGet(handles,'unit string',n);
% curBgMm         = dtiGet(handles,'bg mmpervox',n);
% curBgDispRange  = dtiGet(handles,'display range',n);
% [curBg,curBgMm,curBgXform,curBgName,curBgValRange,curBgDispRange,curBgUnitStr] = dtiGetCurAnat(handles);

% Transform the coordinates between the anatomy and fibers
imValCoords = mrAnatXformCoords(inv(curBgXform), coords);

% Create the dt6 data in real units using SPM method.  This method should
% be called in a separate function used throughout.
interpType = [1 1 1 0 0 0]; % use [0 0 0 0 0 0] for nearest
curImVal = zeros(size(imValCoords,1), size(curBg,4));
for ii=1:size(curImVal,4)
    bsplineCoefs   = spm_bsplinc(curBg(:,:,:,ii), interpType);
    curImVal(:,ii) = spm_bsplins(bsplineCoefs, imValCoords(:,1), imValCoords(:,2), imValCoords(:,3), interpType);
end
clear curBg imValCoords bsplineCoefs;

% Convert 0-1 nomalized to real units
curImVal = curImVal*(diff(curBgValRange)) + curBgValRange(1);

% Get the dt6 values from the coordinates specified in the fibers
% Build these into a dt6 matrix
[val1,val2,val3,val4,val5,val6] = dtiGetValFromTensors(handles.dt6, coords, dtiGet(handles,'invdt6xform'), 'dt6', 'nearest');
dt6 = [val1,val2,val3,val4,val5,val6];

% Clean the data in two ways.
% Some fibers extend a little beyond the brain mask. Remove those points by
% exploiting the fact that the tensor values out there are exactly zero.
dt6 = dt6(~all(dt6==0,2),:);

% There shouldn't be any nans, but let's make sure:
dt6Nans = any(isnan(dt6),2);
if(any(dt6Nans))
    dt6Nans = find(dt6Nans);
    for ii=1:6
        dt6(dt6Nans,ii) = 0;
    end
    fprintf('NOTE: %d fiber points had NaNs. These will be ignored...',length(dt6Nans));
    disp('Nan points (ac-pc coords):');
    for(ii=1:length(dt6Nans))
        fprintf('%0.1f, %0.1f, %0.1f\n',coords(dt6Nans(ii),:));
    end
end

% We now have the dt6 data from all of the fibers.  We extract the
% directions into vec and the eigenvalues into val.  The units of val are
% um^2/sec or um^2/msec ... somebody answer this here, please.

[vec,val] = dtiEig(dt6);

% Tragically, some of the ellipsoid fits are wrong and we get negative eigenvalues.
% These are annoying. If they are just a little less than 0, then clipping
% to 0 is not an entirely unreasonable thing. Maybe we should check for the
% magnitude of the error?
nonPD = find(any(val<0,2));
if(~isempty(nonPD))
    fprintf('NOTE: %d fiber points had negative eigenvalues. These will be clipped to 0...',length(nonPD));
    val(val<0) = 0;
end

threeZeroVals=find(sum(val, 2)==0);
if ~isempty (threeZeroVals)
     fprintf('\n NOTE: %d of these fiber points had all three negative eigenvalues. These will be excluded from analyses', length(threeZeroVals));
end
val(threeZeroVals, :)=[];

% Now we have the eigenvalues just from the relevant fiber positions - but
% all of them.  So we compute for every single node on the fibers, not just
% the unique nodes.
[fa,md,rd,ad] = dtiComputeFA(val);


%% Display and print
h = mrvNewGraphWin; 
set(h,'Name',[fg.name ': ' curBgName]);
hist(curImVal(~isnan(curImVal)),100); ylabel('count'); xlabel([curBgName '(' curBgUnitStr ')']);

h = mrvNewGraphWin; 
set(h,'Name',[fg.name ': tensor']);
subplot(2,2,1);hist(fa,100); ylabel('count'); xlabel('FA');
subplot(2,2,2); hist(md,101); ylabel('count'); xlabel(['MD ' adcUnitsFig]);
subplot(2,2,3); hist(ad,101); ylabel('count'); xlabel(['Axial ADC ' adcUnitsFig]);
subplot(2,2,4); hist(rd,101); ylabel('count'); xlabel(['Radial ADC ' adcUnitsFig]);

% Print stuff
[cl, cp, cs] = dtiComputeWestinShapes(val);
summary = [summary,sprintf('\nMean length: %.03f mm (Range = [%.04f, %.04f])\n',mean(fiberLength)*stepSize,min(fiberLength)*stepSize,max(fiberLength)*stepSize)];
summary = [summary,sprintf('Number of fibers: %.0f\n',length(fg.fibers))];
summary = [summary,sprintf('Mean %s: %.04f %s (Range = [%.04f, %.04f])\n',curBgName,nanmean(curImVal),curBgUnitStr,min(curImVal),max(curImVal))];
summary = [summary,sprintf('Mean FA: %.04f (Range = [%.04f, %.04f])\n',mean(fa),min(fa), max(fa))];
summary = [summary,sprintf('Mean MD: %.04f %s (Range = [%.04f, %.04f])\n',mean(md),adcUnits,min(md), max(md))];
summary = [summary,sprintf('Mean Axial ADC: %.04f %s (Range = [%.04f, %.04f])\n',mean(ad),adcUnits,min(ad), max(ad))];
summary = [summary,sprintf('Mean Radial ADC: %.04f %s (Range = [%.04f, %.04f])\n',mean(rd),adcUnits,min(rd), max(rd))];
summary = [summary,sprintf('Linearity: %.04f (Range = [%.04f, %.04f])\n',mean(cl),min(cl), max(cl))];
summary = [summary,sprintf('Planarity: %.04f (Range = [%.04f, %.04f])\n',mean(cp),min(cp), max(cp))];

return;
