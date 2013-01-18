function view = setMeanFuncAsAnat(view,scan,doSave)
% view = setMeanFuncAsAnat(view,scan,doSave);
%
% Sets the 'anat' field of an inplane to be the mean
% functional values from the selected scan (clipped 
% appropriately in the same manner as used in 
% makeTSeriesMovie). This may be useful for hi-res
% data (where the functionals are very good) or 
% scans with significant motion.
%
% Entering zero as the scan num will cause the anat
% field to be re-set to the inplane anatomical series.
%
% 04/25/04 ras.
global mrSESSION HOMEDIR;

if nargin < 2
    help setMeanFuncAsAnat;
    return;
end
if ~exist('doSave','var') || isempty(doSave)
    doSave=false;
end


if scan < 1
    % re-load the inplane anatomicals
    view = loadAnat(view);
else
    % load the tSeries for the
    % selected scan and all slices
    fprintf('Calculating Mean tSeries ... slice');    
    tSeriesAll = cell(numSlices(view),1);
    for slice = 1:numSlices(view)
        % Load tSeries
        tSeriesAll{slice} = loadtSeries(view,scan,slice);
        
        %To use only first time frame of Tseries. Good for alignment with
        %subsequence motion correction, normally commented out
        %tSeriesAll{slice}=tSeriesAll{slice};
        
        
        fprintf(' %i',slice);        
    end
    
    % get values for rescaling it 
%     histThresh = length(reshape([tSeriesAll{:}],1,[]))/10000;
%     [tsCnt, tsVal] = hist(reshape([tSeriesAll{:}],1,[]),100);
%     minval = tsVal(min(find(tsCnt>histThresh)));
%     maxval = tsVal(max(find(tsCnt>histThresh)));  

    % low-memory, alternate way of getting vals (for big functionals)
    %minval = 1.25 * min(min(tSeriesAll{slice}));
    %maxval = 0.8 * max(max(tSeriesAll{slice}));
    
    % rescale, resize it to the view's sliceDims
    anatSize = mrSESSION.inplanes.cropSize;
    funcSize = dataSize(view,scan);
    % nFrames = numFrames(view,scan);
    anat = zeros(size(view.anat));
    for slice = 1:numSlices(view)
        im = reshape(mean(tSeriesAll{slice},1),funcSize(1:2));
        anat(:,:,slice) = imresize(im,anatSize(1:2));
    end
    fprintf(' done.\n');
    
    % set as the underlying anat image
    view.anat = anat;
end

setAnatClip(view,[0 1]);

view = refreshView(view);

% save (overwrite current anat)
if doSave
    newanat = anat;
    anatFile = fullfile(HOMEDIR, 'Inplane', 'anat.mat');
    anatOldFile = fullfile(HOMEDIR, 'Inplane', 'anat_old.mat');
    load(anatFile);    
    save(anatOldFile, 'anat', 'inplanes');
    anat = newanat; %#ok<NASGU>
    save(anatFile, 'anat', 'inplanes');
end


return
