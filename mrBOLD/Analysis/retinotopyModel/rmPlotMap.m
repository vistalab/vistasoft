function rmPlotMap (v,  saveFlag, method, fieldname, prf_size, fieldRange)
% rmPlotMap (v, fieldname, saveFlag, prf_size, fieldRange)
%   
%   Purpose: 
%       Visualize the responses within an ROI in stimulus-referred space.
%       The stimulus referred space is created via a retinotopic model,
%       which gives an x, y, and sigma value to each voxel. The responses
%       come from the current scan - it does not need to be the scan used
%       to make the pRF model. The model of each voxel's RF is then scaled
%       to the current scan's  map. The models from all the maps are then
%       added together and plotted as figure in stimulus space. 
% 
%   Note: works only in Gray view
%
%
%  
%   INPUT
%       v:           mrVista view structure
%       fieldname:   'ph', 'co', 'amp', or 'map': the parameter used to
%                           scale the RF plot
%       saveFlag:    boolean (if true, then save the plot as a jpg)
%       prf_size:    boolean (if true, use prf sigma to generate RFs, 
%                           if false assume fixed size for all pRFs)
%       fieldRange:  deg (size of visual field to plot)
%
%  
%
%   6/19/2008: JW wrote it, adpating from KA's rmPlotCoverage 
%   7/3/2008:  Divided the image at each point by the total pRF coverage of 
%              that point in space. This puts the image in  % signal units.
%   
          

% Check the arguments and set defaults
if ieNotDefined('v'), v = getCurView; end
if ieNotDefined('fieldname'), fieldname = v.ui.displayMode; end
if ieNotDefined('saveFlag'), saveFlag = true;  end
if ieNotDefined('prf_size'), prf_size = 'from model';  end
if ieNotDefined('fieldRange'), fieldRange = 15;  end % deg
if ieNotDefined('nSamples'), nSamples = 75;  end 
if ieNotDefined('normResponses'), normResponses = true;  end 
if ieNotDefined('method'), method = 0; end %0 = sum

if isequal(saveFlag, 'dialog')
	% get parameters from a dialog
	[prf_size method normResponses fieldRange nSamples saveFlag ok] = rmPlotMapParams;
    if ~ok, return; end
end

% Get pRF model
try
    rmModel   = viewGet(v,'rmSelectedModel');
    rmfname   = viewGet(v,'rmfile');
    [foo,rmfname,foo,foo] = fileparts(rmfname);
catch
    error('Need to load retModel into curent view');
end


% Get ROI
try
    ROIcoords = getCurROIcoords(v);
    ROIname = v.ROIs(v.selectedROI).name;
catch
    error('Need to select ROI in GUI')
end

% Get scan
curScan = getCurScan(v);

% If cothresh is set in GUI, use it to restrict ROI
try
    co  = getCurDataROI(v,'co',curScan,ROIcoords);
    cothresh = viewGet(v, 'cothresh');
    ROIcoords = ROIcoords(:, co > cothresh);
end

nVoxels = size(ROIcoords,2);

% Get the map
curData  = getCurDataROI(v,fieldname,curScan,ROIcoords);

% Get X, Y, and sigma for each voxel
[tmp1 tmp2 indices] = intersectCols(ROIcoords, v.coords);
clear tmp1 tmp2;
subSize = rmModel.sigma.major(indices);
subX = rmModel.x0(indices);
subY = rmModel.y0(indices);
% if prf_size is false, then make all pRFs the same size, instead of using
%   the fitted sigmas. 
if strcmp(prf_size, 'equal for every voxel')
   subSize=ones(size(subSize))*0.5;
end

% Set up stimulus-referred visual field
x = linspace(-fieldRange,fieldRange,nSamples);
[X,Y] = meshgrid(x,x);
mask = makecircle(size(X,1));


% Build pRF for each voxel:
%all_models = rfGaussian2d(single(X(:)),single(Y(:)),...
%    single(subSize),single(subSize),single(0), single(subX),single(subY));


% Plot the total coverage of the RF. 
RFcov = zeros(nSamples^2,1);
for ii = 1:nVoxels
    thisModel = rfGaussian2d(single(X(:)),single(Y(:)),...
    single(subSize(ii)),single(subSize(ii)),single(0), single(subX(ii)),single(subY(ii)));
    if method == 0, 
        RFcov = RFcov + thisModel;
    else
        RFcov = max(RFcov, thisModel); 
    end
end

RFcov = reshape(RFcov,[1 1].*sqrt(numel(RFcov)));

h = figure;
subplot(2,1,1)
imagesc (X(1,:),Y(:,1),RFcov .* mask);
colorbar
axis equal tight;
title([ROIname, ', Visual field coverage (sum)']);

% Plot the current map in stimulus-referred space 
%   (This is the main point of the function)
RF = zeros(nSamples^2,1);
for ii = 1:nVoxels
    thisModel = rfGaussian2d(single(X(:)),single(Y(:)),...
        single(subSize(ii)),single(subSize(ii)),single(0), single(subX(ii)),single(subY(ii)));
    RF = RF + thisModel * curData(ii);
end
% convert RF model from 1D to 2D
RF = reshape(RF,[1 1].*sqrt(numel(RF)));

% divide the movie by the coverage map to normalize (approximatley) to % signal  
if normResponses == true, RF = RF ./ RFcov; end

%set color range 
imMax = max(max(RF(:)), -min(RF(:)));
imMin = -imMax;

% plotting
figure(h);
headerStr = [ROIname,', ', fieldname, ', scan', num2str(curScan) ];
subplot(2,1,2)
imagesc(X(1,:),Y(:,1),RF .* mask, [imMin imMax])
colorbar
axis equal tight;
title(headerStr);
xlabel(rmfname);


% saving
if saveFlag,
    fname = [headerStr,  '.jpg'];
    saveas(gcf, fname)
end

return

% /------------------------------------------------------------------/ %



% /------------------------------------------------------------------/ %
function [prf_size method normResponses fieldRange nSamples saveFlag ok] = rmPlotMapParams;
%% dialog to get parameters for rmPlotParam.
dlg(1).fieldName = 'prf_size';
dlg(end).style = 'listbox';
dlg(end).list = {'from model', 'equal for every voxel'};
dlg(end).string = 'pRF sigma';
dlg(end).value = 1;

dlg(end+1).fieldName = 'fieldRange';
dlg(end).style = 'number';
dlg(end).string = 'Visual Field Range (deg)?';
dlg(end).value = '20';

dlg(end+1).fieldName = 'nSamples';
dlg(end).style = 'number';
dlg(end).string = 'Num Samples?';
dlg(end).value = '75';

dlg(end+1).fieldName = 'normResponses';
dlg(end).style = 'number';
dlg(end).string = 'Normalize responses to visual field coverage?';
dlg(end).value = '1';

dlg(end+1).fieldName = 'method';
dlg(end).style = 'number';
dlg(end).string = 'Use sum (0) or max (1) for pRF coverage map?';
dlg(end).value = 0;


dlg(end+1).fieldName = 'saveFlag';
dlg(end).style = 'checkbox';
dlg(end).string = 'Save Image?';
dlg(end).value = 0;


[resp ok] = generalDialog(dlg, mfilename);
if ~ok
	disp('User Aborted.')
    prf_size = 0;
    method = 0;
    normResponses = 0;
    fieldRange = 0;
    nSamples = 0;
    saveFlag = 0;
    return;
end

prf_size = resp.prf_size;
method = resp.method;
normResponses = resp.normResponses;
fieldRange = resp.fieldRange;
nSamples = resp.nSamples;
saveFlag = resp.saveFlag;

return

