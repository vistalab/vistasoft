function [RFcov, figHandle, all_models, weight, data] = rmPlotCoverage(vw, varargin)
% [RFcov, figHandle, all_models, weight, data] = rmPlotCoverage(vw, varargin)
% rmPlotCoverage - calulate the visual field coverage within an ROI
% 
%
% Before you run this script, you have to load 'variance explained', 'eccentricity',
% 'polar-angle' and 'prf size' into 'co', 'map', 'ph' and 'amp' fields, respectively
% 
% OUTPUT
%  RFcov
% INPUT
%  prf_size:        0 = plot pRF center; 1 = use pRF size
%  fieldRange:      maximum eccentricity to plot (deg)
%  method:          'sum','max', 'clipped average', 'signed profile'
%  newfig:          make a new figure (1) or not (0). (-1 indicates don't plot
%                       anything, just return the coverage map.)
%  nboot:           the number of bootstrapping (0 means no bootstrapping)
%  normalizeRange:  if true, scale z axis to [0 1]
%  smoothSigma:     median smoothing default: 2 nearest values
%  cothresh:        threshold by variance explained in model
%  eccthresh:       2-vector ecc limits (default = [0 1.5*fieldRange])
%  nsamples:        num samples in square grid (default = 128)
%  weight:          any of {'fixed', 'parameter map', 'variance explained'} (default = fixed) 
%  weightBeta:      use beta values from rmModel to weight pRFs (default = false)
%  threshByCoh:     if true, threshold by values in coherence map, not variance explained in model 
%                       (note: these are often the same, but don't have to be)  %   addcenters
%  addcenters:      1 = superimpose dots for pRF centers; 0 = do not show centers
%  dualVEthresh:    use both pRF model VE and GLM fit VE as threshold
%

% 08/02 KA wrote
% 08/04 KA added bootstrapping
% 08/04 SD various mods
% 09/02 SD large rearrangments
% 09/08 JW allow superposition of pRF centers; various minor debugs
% 02/10 MB added method 'betasum'
% 09/16 RL edited code to allow for the edge case of ROIs that are 1 or 2 voxels large
if notDefined('vw'),       error('View must be defined.'); end
if notDefined('varargin'), varargin{1} = 'dialog'; end

%% default parameters
vfc.prf_size = true; 
vfc.fieldRange = min(30, vw.rm.retinotopyParams.analysis.maxRF);
vfc.method = 'max';         
vfc.newfig = true;                      
vfc.nboot = 50;                          
vfc.normalizeRange = true;              
vfc.smoothSigma = true;                
vfc.cothresh = viewGet(vw, 'co thresh');         
vfc.eccthresh = [0 1.5*vfc.fieldRange]; 
vfc.nSamples = 128;            
vfc.meanThresh = 0;
vfc.weight = 'fixed';  
vfc.weightBeta = 0;
vfc.cmap = 'jet';						
vfc.clipn = 'fixed';                    
vfc.threshByCoh = false;                
vfc.addCenters = true;                 
vfc.verbose = prefsVerboseCheck;
vfc.dualVEthresh = 0;

compVolume = false;

%% parse options
if strcmpi(varargin{1},'dialog')
    % get parameters from a dialog
    vfc = rmPlotCoverageDialog(vfc);
else
    for ii = 1:2:length(varargin)
        switch lower(varargin{ii})
            case 'prf_size',        vfc.prf_size        = varargin{ii+1}; % deg
            case 'fieldrange',      vfc.fieldRange      = varargin{ii+1}; % deg
            case 'method',          vfc.method          = varargin{ii+1}; % string
            case 'newfig',          vfc.newfig          = varargin{ii+1}; % boolean
            case 'nboot',           vfc.nboot           = varargin{ii+1}; % integer
            case 'normalizerange',  vfc.normalizeRange  = varargin{ii+1}; % boolean
            case 'smoothsigma',     vfc.smoothSigma     = varargin{ii+1}; % boolean   
            case 'cothresh',        vfc.cothresh        = varargin{ii+1};
            case 'eccthresh',       vfc.eccthresh       = varargin{ii+1};
            case 'nsamples',        vfc.nSamples        = varargin{ii+1};
			case 'minmeanmap',      vfc.meanThresh		= varargin{ii+1};
            case 'weight',          vfc.weight          = varargin{ii+1};
            case 'weightbeta',      vfc.weightBeta      = varargin{ii+1};
			case 'cmap',			vfc.cmap			= varargin{ii+1};
            case 'threshbycoh',     vfc.threshByCoh     = varargin{ii+1}; 
            case 'addcenters',      vfc.addCenters      = varargin{ii+1}; % boolean   
            case 'vfc.verbose',     vfc.verbose         = varargin{ii+1}; % boolean   
            case 'dualvethresh',    vfc.dualVEthresh    = varargin{ii+1}; % boolean
        end
    end
end


%% load different pRF parameters
try
    rmModel   = viewGet(vw,'rmSelectedModel');
catch %#ok<CTCH>
    error('Need retModel information. Try using rmSelect. ');
end

% Get coordinates for current ROI
roi.coords   = viewGet(vw, 'roiCoords');
roi.indices  = viewGet(vw, 'roiIndices');
roi.name     = viewGet(vw, 'roiName');
curScan      = viewGet(vw, 'curScan');

% Get co and ph (vectors) for the current scan, within the
% current ROI.
vt      = vw.viewType;
co      = rmCoordsGet(vt, rmModel,'varexp',     roi.indices);
sigma1  = rmCoordsGet(vt, rmModel,'sigmamajor', roi.indices);
sigma2  = rmCoordsGet(vt, rmModel,'sigmaminor', roi.indices);
theta   = rmCoordsGet(vt, rmModel,'sigmatheta', roi.indices);
beta    = rmCoordsGet(vt, rmModel,'beta',       roi.indices);
x0      = rmCoordsGet(vt, rmModel,'x0',         roi.indices);
y0      = rmCoordsGet(vt, rmModel,'y0',         roi.indices);
clear rmModel

%%%%%%%%%%%%%%
% y flip note (r.a.s., 10/2009): 
% ------------------------------
% I believe the stimulus generation code has had problems (from around
% 2006-2009) where all stimuli were up/down flipped with respect to the pRF
% sampling grid [X, Y]. As a consequence, all models solved in this time
% seem to have a Y flip. The values saved on disk are off; you can 
% manually test this with an ROI like V2d which covers a quarterfield. 
%
% I'm now trying to fix this issue. All accessor functions seem to have 
% implicitly corrected the flip, but in hard to trace ways. (This involves 
% a lot of post-hoc calls to functions like 'flipud' which made things 
% confusing.) I'm trying to (1) fix the core problems in the stim code; and
% (2) remove the post-hoc corrections to the accessor code.
%
% But for now, there are a lot of models saved on disk, and it will take a
% long time to fix them. So, I'm keeping the y-flip correction, but making
% it explicit here. When the code is fixed and most models saved on disk
% are correct, we can remove this. 
% y0 = -y0;

% ok. I think it is time to remove. I suggest putting in a flag to flip the
% y-dimension if requested, but otherwise not to.
if getpref('VISTA', 'verbose')
    warning('Negative y values plotted as lower visual field. This may be incorrect for old pRF models, as old code used to treat neagitve y as upper field.'); %#ok<*WNTAG>
end
%%%%%%%%%%%%%%

% grabbing both (x0, y0) and (pol, ecc) are redundant, and allow for the
% two specifications to get separated (because of the y-flip issue). So,
% re-express ecc and pol using x0 and y0.
[ph ecc] = cart2pol(x0, y0);

% If 'threshByCoh' is set (i.e., true), thresholding will be set based on the
% view struct's coherence field, instead of from the variance explained in
% the model. 
if vfc.threshByCoh, co = vw.co{curScan}(roi.indices); end
if ~any(co), co = []; end

% If 'dualVEthresh' is set, thresholding will be based on both the VE of
% the model AND the VE of the GLM fit
if vfc.dualVEthresh == 1
    fprintf('[%s] Using dual VE thresholding \n',mfilename);
    if isempty(vw.dualVE)
        error('Need VE from GLM fit');
    else
        co = (co + vw.dualVE(roi.indices)) ./ 2;
    end
end

% Remove NaNs from subCo and subAmp that may be there if ROI
% includes volume voxels where there is no data.
NaNs = sum(isnan(co));
if NaNs
    fprintf('[%s]:WARNING:ROI includes voxels that have no data. These voxels are being ignored.',mfilename);
    notNaNs = ~isnan(co);
    co      = co(notNaNs);
    ph      = ph(notNaNs);
    ecc     = ecc(notNaNs);
end

% Find voxels which satisfy cothresh and eccthresh.
coIndices = co>vfc.cothresh & ...
    ecc>=vfc.eccthresh(1) & ecc<=vfc.eccthresh(2);
if ~any(coIndices)
   fprintf(1,'[%s]:No values above threshold.\n',mfilename); 
   RFcov = zeros(vfc.nSamples);
   figHandle    = [];
   all_models   = [];
   weight       = [];
   data         = [];
   return
end

% also select by the mean map, if that's selected
if vfc.meanThresh > 0
	meanMapFile = fullfile(dataDir(vw), 'meanMap.mat');
	if ~exist(meanMapFile, 'file')
		warning(['A mean map threshold is specified, but no mean map ' ...
				 'exists. This threshold will be ignored for now.'])
	elseif isempty(map{vw.curScan})
		warning(['A mean map threshold is specified, but no mean map ' ...
				 'is computed for the current scan. ' ...
				 'This threshold will be ignored for now.'])
	else
		load(meanMapFile, 'map');
		meanVals = map{vw.curScan};
		if NaNs
			meanVals = meanVals(notNaNs);
		end
		coIndices = coIndices & (meanVals > vfc.meanThresh);
	end
end

% check
if vfc.verbose
    fprintf(1,'[%s]:co-thresh:%.2f.\n',mfilename,vfc.cothresh); 
    fprintf(1,'[%s]:ecc-thresh:[%.2f %.2f].\n',mfilename,vfc.eccthresh(1),vfc.eccthresh(2)); 
    fprintf(1,'[%s]:Number of voxels above thresh in ROI: %d (total=%d).\n',...
        mfilename,sum(coIndices),numel(coIndices));
end

% Pull out co and ph for desired pixels
subCo    = co(coIndices);
subPh    = ph(coIndices);
subEcc   = ecc(coIndices);
subSize1 = single(sigma1(coIndices));
subSize2 = single(sigma2(coIndices));
subTheta = single(theta(coIndices));
subx0    = x0(coIndices);
suby0    = y0(coIndices);

% smooth sigma
if vfc.smoothSigma
    
    % Cannot do sigma smoothing if the ROI has less than 3 voxels. 
    if size(subx0,2) < 3
        error('Cannot perform sigma smoothing when the ROI has less than 3 voxels. ')
    end
    
    
    if vfc.smoothSigma == 1
        vfc.smoothSigma = 3; %default
    end
    n = vfc.smoothSigma;
	
    %check sigma1==sigma2
    if subSize1 == subSize2
        for ii = 1:length(subSize1)
            %compute nearest coords
            dev = sqrt(abs(subx0(ii) - subx0).^2 + abs(suby0(ii) - suby0).^2);
            [dev, ix] = sort(dev); %#ok<*ASGLU>
            subSize1(ii) = median(subSize1(ix(1:n)));           
        end
        subSize2 = subSize1;
    else
        for ii = 1:length(subSize1)
            %compute nearest coords
            dev = sqrt(abs(subx0(ii) - subx0).^2 + abs(suby0(ii) - suby0).^2);
            [dev, ix] = sort(dev);
            subSize1(ii) = median(subSize1(ix(1:n)));
            subSize2(ii) = median(subSize2(ix(1:n)));
        end
    end
end
             
% polar plot
subX = single(subEcc .* cos(subPh));
subY = single(subEcc .* sin(subPh));


% visual field
x = single( linspace(-vfc.fieldRange, vfc.fieldRange, vfc.nSamples) );
[X,Y] = meshgrid(x,x);

% gather this data to make accessible in the plot
if vfc.newfig  > -1   % -1 is a flag that we shouldn't plot the results
	data.figHandle = gcf;
	data.co        = co;
	data.ph        = ph;
	data.subCo     = subCo;
	data.subPh     = subPh;
	data.subEcc    = subEcc;
	data.subx0     = subx0;
	data.suby0     = suby0;
    data.subSize1  = subSize1;
    data.subSize2  = subSize2;
    data.X         = X;
	data.Y         = Y;

end

% For the pRF center plot, use a small constant pRF size
if vfc.prf_size==0
   subSize1 = ones(size(subSize1)) * 0.1;
   subSize2 = ones(size(subSize2)) * 0.1;   
   subTheta = zeros(size(subTheta));   
end

switch lower(vfc.weight)
    case 'fixed'
        weight = ones(size(subCo));
        
    case 'parameter map'
        weight = getCurDataROI(vw,'map',curScan,roi.coords);
        weight = weight(coIndices);
        
    case {'variance explained', 'varexp', 've'}
        weight = subCo;
        
    otherwise 
        error('Unknown weight parameter: %s',vfc.weight);
end

if vfc.weightBeta==1
    weight = weight .* beta(coIndices);
end
weight = single(weight);

%% special case: for the 'density' coverage option, we don't need to
%% do a lot of memory-hungry steps like making all pRFs. So, I've set those
%% computations aside in their own subroutine. (ras)
if isequal( lower(vfc.method), 'density' )
	RFcov = prfCoverageDensityMap(vw, subx0, suby0, subSize1, X, Y);
	
	all_models = []; % not created for this option	
	if vfc.newfig==-1
		figHandle = [];
	else
		[figHandle, data]  = createCoveragePlot(vw, RFcov, vfc, roi, data);
	end

	return
end


%% make all pRFs:
% make in small steps so we don't go into swap space for large ROIs
n = numel(subX);
s = [(1:ceil(n./1000):n-2) n+1]; 

% For the line above (which assumes that we have at least 3 voxels,
% probably for median smoothing),  s is an empty vector when n < 3 
% -- and an empty rfcov is  returned when we try to plot the 
% coverage. So modify s accordingly for these edge cases: 
% The definition of s is not very intuitive
if n < 3
    s = [1:n+1]; 
end

all_models = zeros( numel(X), n, 'single' );
fprintf(1,'[%s]:Making %d pRFs:...', mfilename, n);
drawnow;
for n=1:numel(s)-1,
    % make rfs
    rf   = rfGaussian2d(X(:), Y(:),...
						subSize1(s(n):s(n+1)-1), ...
						subSize2(s(n):s(n+1)-1), ...
						subTheta(s(n):s(n+1)-1), ...
						subX(s(n):s(n+1)-1), ...
						subY(s(n):s(n+1)-1));
    all_models(:,s(n):s(n+1)-1) = rf;
end;
clear n s rf pred;
fprintf(1, 'Done.\n');
drawnow;

% Correct volume
if compVolume
    tmp = ones(size(all_models, 1), 1, 'single');
    
    vol = sigma1(coIndices).^2;
    vol = vol * (2 * pi);
    
    all_models = all_models ./ (tmp * vol);
end

% For the pRF center plot, put a constant value (1) within each Gaussian
if vfc.prf_size==0
    all_models(all_models>0.1)=1;
end

% weight all models
if isequal( lower(vfc.weight), 'fixed' )
	% if the weights are even, we avoid the redundant, memory-hungry
	% multiplication step that would otherwise be done. 
	all_models_weighted = all_models;
else
	tmp = ones(size(all_models, 1), 1, 'single');
	all_models_weighted = all_models .* (tmp * weight);
	clear tmp
end

%% Different ways of combining them: 
% 1) bootstrap (yes, no) 2) which statistic (sum, max, etc), 
% bootstrap

% If we are only working with 1 voxel, bootstrapping does not do anything. 
% We turn it off because the bootstp function does not handle this case well. 
if size(subX,2) == 1
    vfc.nboot = 0; 
end

if vfc.nboot>0
    if isempty(which('bootstrp'))
        warndlg('Bootstrap requires statistics toolbox');
        RFcov = [];
        return;
    end
    all_models(isnan(all_models))=0;

    switch lower(vfc.method)
        case {'sum','add','avg','average everything', 'average'}
            m = bootstrp(vfc.nboot, @mean, all_models');
        
        case {'max','profile','maximum profile' 'maximum'}
            m = bootstrp(vfc.nboot, @max, all_models');
        
        otherwise
            error('Unknown method %s',vfc.method)
    end
    RFcov=median(m,1)';
    
% no bootstrap
else
    switch lower(vfc.method)
                    
        % coverage = sum(pRF(i)*w(i)) / (sum(pRF(i))
        case {'beta-sum','betasum','weight average'}
            RFcov = sum(all_models_weighted, 2) ./ sum(all_models,2);
            
        % coverage = sum(pRF(i)*w(i)) / (sum(pRF(i)) + clipping
        case {'clipped beta-sum','clippedbeta','clipped weight average'}
            % set all pRF beyond 2 sigmas to zero
            clipval = exp( -.5 *((2./1).^2));
            all_models(all_models<clipval) = 0;
            n = all_models > 0;
            
            % recompute all_models_weighted
			tmp = ones( size(all_models,1), 1, 'single' );
            all_models_weighted = all_models .* (tmp*weight);
            
            % compute weighted clipped sum/average
            sumn = sum(n,2);
            mask = sumn==0;
            sumn(mask) = 1; % prevent dividing by 0
            RFcov = sum(all_models_weighted,2) ./ sum(all_models,2);
            RFcov(mask) = 0;
            
            %clip to zero if n<clipn
            if isnumeric(vfc.clipn)
                RFcov(sumn<=vfc.clipn) = 0;
            end            
           
        % coverage = sum(pRF(i)*w(i)) / (sum(w(i))
        case {'sum','add','avg','average','prf average'}
            RFcov = sum(all_models_weighted, 2) ./ sum(weight);
        
        % coverage = sum(pRF(i)*w(i)) / (sum(w(i)) + clipping
        case {'clipped average','clipped','clipped prf average'}
            % set all pRF beyond 2 sigmas to zero
            clipval = exp( -.5 *((2./1).^2));
            all_models(all_models<clipval) = 0;
            n = all_models > 0;
            
            % recompute all_models_weighted
			tmp = ones( size(all_models,1), 1, 'single' );
            all_models_weighted = all_models .* (tmp*weight);
            
            % compute weighted clipped mean
            sumn = sum(weight.*n);
            mask = sumn==0;
            sumn(mask) = 1; % prevent dividing by 0
            RFcov = sum(all_models_weighted,2) ./ sumn;
            RFcov(mask) = 0;
            
            %clip to zero if n<clipn
            if isnumeric(vfc.clipn)
                RFcov(sumn<=vfc.clipn) = 0;
            end
            
        % coverage = max(pRF(i))
        case {'maximum profile', 'max', 'maximum'}
            RFcov = max(all_models_weighted,[],2);
            
        case {'signed profile'}
            RFcov  = max(all_models_weighted,[],2);
            covmin = min(all_models_weighted,[],2);
            ii = RFcov<abs(covmin);
            RFcov(ii)=covmin(ii);
            
        case {'p','probability','weighted statistic corrected for upsampling'}
            RFcov = zeros(vfc.nSamples);
			
			% I guess this upsample factor assumes your functional data are
			% 2.5 x 2.5 x 3 mm?
            upsamplefactor = 2.5*2.5*3; % sigh.....
            for ii = 1:size(all_models,1)
                s = wstat(all_models(ii,:),weight,upsamplefactor);
                if isfinite(s.tval)
                    RFcov(ii) = 1 - t2p(s.tval,1,s.df);
                end
            end

        otherwise
            error('Unknown method %s',vfc.method)
    end
end

% convert 1D to 2D
RFcov = reshape( RFcov, [1 1] .* sqrt(numel(RFcov)) );

% When no voxels exceed threshold, return nan matrix rather than empty
% matrix
if sum(size(RFcov))==0
    RFcov=nan(nSamples,nSamples);
end

% if the newfig flag is set to -1, just return the image
if vfc.newfig==-1, 
    figHandle = [];
else
	[figHandle, data] = createCoveragePlot(vw, RFcov, vfc, roi, data);
end


return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function [figHandle, data] = createCoveragePlot(vw, RFcov, vfc, roi, data)
% plotting subroutine for rmPlotCoverage. Broken off by ras 10/2009.
if vfc.newfig
    figHandle = figure('Color', 'w');
else
	figHandle = selectGraphWin;
end

headerStr = sprintf('Visual field coverage, ROI %s, scan %i', ...
					roi.name, vw.curScan);
set(gcf, 'Name', headerStr);


% normalize the color plots to 1
if vfc.normalizeRange, 
	rfMax = max(RFcov(:)); 
else
	rfMax = 1; 
end

img = RFcov ./ rfMax;
mask = makecircle(length(img));
img = img .* mask;
imagesc(data.X(1,:), data.Y(:,1), img);
set(gca, 'YDir', 'normal');
grid on

data.img = img;

colormap(vfc.cmap);
colorbar;

% start plotting
hold on;

% t = 0:.01:2*pi;
%
% % rings every 5 deg
% for n=(1:3)/3*vfc.fieldRange
%     polar(t,ones(size(t))*n,'w');
% end
% plot([0 0],[-vfc.fieldRange vfc.fieldRange],'w')
% plot([-sqrt(vfc.fieldRange^2/2) sqrt(vfc.fieldRange^2/2)],[-sqrt(vfc.fieldRange^2/2) sqrt(vfc.fieldRange^2/2)],'w')
% plot([-vfc.fieldRange vfc.fieldRange],[0 0],'w')
% plot([-sqrt(vfc.fieldRange^2/2) sqrt(vfc.fieldRange^2/2)],[sqrt(vfc.fieldRange^2/2) -sqrt(vfc.fieldRange^2/2)],'w')


% add polar grid on top
p.ringTicks = (1:3)/3*vfc.fieldRange;
p.color = 'w';
polarPlot([], p);

% add pRF centers if requested
if vfc.addCenters, 
    inds = data.subEcc < vfc.fieldRange;
    plot(data.subx0(inds), data.suby0(inds), '.', ...
		'Color', [.5 .5 .5], 'MarkerSize', 4); 
end


% scale z-axis
if vfc.normalizeRange
	if isequal( lower(vfc.method), 'maximum profile' )
		caxis([.5 1]);
	else
	    caxis([0 1]);
	end
else
    if min(RFcov(:))>=0
        caxis([0 ceil(max(RFcov(:)))]);
    else
        caxis([-1 1] * ceil(max(abs(RFcov(:)))));
    end
end
axis image;   % axis square;
xlim([-vfc.fieldRange vfc.fieldRange])
ylim([-vfc.fieldRange vfc.fieldRange])

title(roi.name, 'FontSize', 24, 'Interpreter', 'none');

% Save the data in gca('UserData')
set(gca, 'UserData', data);

return;
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function RFcov = prfCoverageDensityMap(vw, x0, y0, sigma, X, Y) %#ok<INUSL>
% for each point (x, y) in visual space, this returns
% the proportion of voxels in the ROI for which (x, y) is
% within one standard deviation of the pRF center.
mask = NaN( size(X, 1), size(X, 2), length(x0) );

for v = 1:length(x0)
	% make a binary mask within one sigma of the center
	R = sqrt( (X - x0(v)) .^ 2 + (Y - y0(v)) .^ 2 );
	mask(:,:,v) = ( R < 2*sigma(v) );
end

% average (sum?) across all masks
RFcov = nansum(mask, 3);

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function vfc = rmPlotCoverageDialog(vfc)
%% dialog to get parameters for rmPlotCoverage.
dlg(1).fieldName = 'method';
dlg(end).style = 'popup';
dlg(end).list = {'maximum profile' 'average' 'clipped average' ...
				 'density' 'signed profile' 'probability'};
dlg(end).string = 'Method for combining pRFs?';
dlg(end).value = vfc.(dlg(end).fieldName);


dlg(end+1).fieldName = 'weight';
dlg(end).style = 'popup';
dlg(end).list = {'fixed' 'variance explained' 'parameter map'};
dlg(end).string = 'Method for weighting pRFs?';
dlg(end).value = vfc.(dlg(end).fieldName);


dlg(end+1).fieldName = 'fieldRange';
dlg(end).style = 'number';
dlg(end).string = 'Visual Field Range (deg)?';
dlg(end).value = vfc.(dlg(end).fieldName);


dlg(end+1).fieldName = 'nboot';
dlg(end).style = 'number';
dlg(end).string = 'Number of bootstrapping steps?';
dlg(end).value = vfc.(dlg(end).fieldName);


dlg(end+1).fieldName = 'cmap';
dlg(end).style = 'popup';
dlg(end).list = mrvColorMaps;
dlg(end).string = 'If plotting, color map for coverage?';
dlg(end).value = vfc.(dlg(end).fieldName);


dlg(end+1).fieldName = 'normalizeRange';
dlg(end).style = 'checkbox';
dlg(end).list = {};
dlg(end).string = 'Normalize data range to [0 1]';
dlg(end).value = vfc.(dlg(end).fieldName);


dlg(end+1).fieldName = 'smoothSigma';
dlg(end).style = 'checkbox';
dlg(end).list = {};
dlg(end).string = 'Smooth sigma (medianfilter)';
dlg(end).value = vfc.(dlg(end).fieldName);


dlg(end+1).fieldName = 'prf_size';
dlg(end).style = 'checkbox';
dlg(end).list = {};
dlg(end).string = 'Use pRF sizes from model';
dlg(end).value = vfc.(dlg(end).fieldName);


dlg(end+1).fieldName = 'newfig';
dlg(end).style = 'checkbox';
dlg(end).string = 'Show results in new figure';
dlg(end).value = vfc.(dlg(end).fieldName);


dlg(end+1).fieldName = 'addCenters';
dlg(end).style = 'checkbox';
dlg(end).string = 'Add dots to show pRF centers';
dlg(end).value = vfc.(dlg(end).fieldName);


[resp ok] = generalDialog(dlg, mfilename);
if ~ok
	error('User Aborted.')
end
drawnow;

vfc = mergeStructures(vfc, resp);

return
