function view = rmMain(view,roiFileName,wSearch,varargin)
% rmMain - main retinotopy model program
%
% view = rmMain([view],[roiFileName],[wSearch],[varargin]);
%
%   view        : mrVista view structure or view pointer [required]
%   roiFileName : Restrict analysis to this ROI file [default = [] (none)]
%                 unless ROI file is loaded in the view struct.
%   wSearch     : 1 = grid search only ("coarse"),
%                 2 = minimization search only ("fine"),
%                 3 = grid followed by minimization search [default]
%                 4 = grid followed by two minimization searches, the first
%                     with temporal decimation, the second without.
%                 5 = grid followed by two minimization searches, followed
%                     by HRF search, followed by PRF search
%   varargin    : Other arguments can include redefinitions of
%                  parameter (argument type) [default]
%                 General parameters:
%                   pRF model   ({'model','model2'})  [{'one gaussian'}]
%                   hrf         ({int,string,matrix})     [user defined]
%                   matFileName (string)   ['retModel-currentDateAndTime']
%                 Grid search parameters (first stage):
%                   coarse to fine     (boolean) [1,true]
%                   coarse sample      (boolean) [1,true]
%                   coarse blur params (matrix)  [5 1]
%                   decimate           (int)     [0]
%                   gridpoints         (int)     [50]
%                   number of sigmas   (int)     [24]
%                   space sigmas       (sting)   ['linlog']
%                   relative grid step (float)   [2.3548]
%                   scale with sigmas  (boolean) [0,false]
%                   min pRF size       (float)   [0.2]
%                   max pRF size       (float)   [stimulus radius]
%                   sigmaRatio         (matrix)  [2 4 6 8]
%                   outerlimit         (float)   [2]
%                 Minimization search parameters (second stage):
%                   vethresh           (float)   [0.15]
%                   maxiter            (int)     [25]
%                   expand range       (int)     [5]
%                 See 'rmDefineParameters' for details.
%
% Examples:
% Basic call.  Writes out the relevant file inside of Gray\yourDataType directory.
% Called this way, the results are not attached to the current VOLUME
% global. They results can still be loaded in from the GUI.
%
%   vw = VOLUME{1};
%   roiFileName = 'leftMT';
%   searchType  = 'coarse to fine';
%   rmMain(vw,roiFileName,searchType);
%
% Called this way, the current VOLUME is updated with the results of the
% analysis. The results  are written to file, as above.  Notice that you
% can make the call with multiple model names and both will be created for
% you.  They are both stored in the same output file.
%
%   outFileName = 'myFile'
%   prfModels = {'one gaussian','difference of gaussians'};
%   VOLUME{1} = rmMain(vw,roiFileName,searchType,'matFileName', outFileName,'model',prfModels);
%   
%   
% 2005/2006 SOD: wrote it.

%-----------------------------------
% argument checks
%-----------------------------------
if notDefined('view'),        error('Need view struct');  end;
if notDefined('roiFileName'), roiFileName = [];           end;
if notDefined('wSearch'),     wSearch = 3;                end;
if isnumeric(wSearch),        wSearch = num2str(wSearch); end;
if nargin > 3,
    addArg = varargin;
else
    addArg = [];
end;

% If we do a search fit we need the optimization toolbox. We try to reserve
% it here. If not successfull we continue anyway and let rmSearchFit try
% just before we really need it.
if wSearch>1,
    reserveToolbox('optimization');
end

% view can either be a proper view structure, in which case we skip this
% step and continue, or a set of pointers that point to how to create the
% view struct. If the latter we create the view struct here. This is useful
% for running the analysis in the background.
if ~isstruct(view),
    view = rmInitView(view,roiFileName);
end

%-----------------------------------
% define parameters structure used in the rest of the program
%-----------------------------------
params = rmDefineParameters(view,addArg);

%-----------------------------------
% make stimuli to convolve with pRF
%-----------------------------------
params = rmMakeStimulus(params);

% record the annotation for this stimulus, for reference
% (kept outside rmMakeStimulus, so that function won't need the view)
dt = viewGet(view, 'dt struct');
for n = 1:length(params.stim)
	params.stim(n).annotation = dtGet(dt, 'annotation', n);
end

%-----------------------------------
% Different fitting strategies
%-----------------------------------
switch lower(wSearch)
    case {'1','coarse','grid fit'}
        fprintf(1,'[%s]:Brute force fitting of bank of pRFs (coarse fit).\n',mfilename);
        view = rmGridFit(view,params);

    case {'2','fine','search fit'}
        % search fit takes the params from the existing fit (which should
        % be stored in the view struct). 
        % If this is not wanted see option 7 below.
        fprintf(1,'[%s]:Refining fit above a certain threshold (fine fit).\n',mfilename);
        fprintf(1,'[%s]:Taking fitting parameters from existing pRF model',mfilename);
        view = rmSearchFit(view);

    case {'3','2 stage coarse to fine fit','coarse to fine'}
        fprintf(1,'[%s]:Two stage coarse-to-fine fit.\n',mfilename);
        view = rmGridFit(view,params);
        view = rmSearchFit(view,params);
        
    case {'4','3 stage coarse to fine fit','coarse to fine 2'}
        fprintf(1,'[%s]:Three stage coarse-to-fine fit.\n',mfilename);
        view = rmGridFit(view,params);
        view = rmSearchFit(view,params,params.analysis.coarseDecimate);
        view = rmSearchFit(view,params);

    case {'5','3x2 stage coarse to fine fit','coarse to fine and hrf'}
        fprintf(1,'[%s]:3x2 pRF & HRF stage coarse-to-fine fit.\n',mfilename);
        view = rmGridFit(view,params);
        view = rmSearchFit(view,params,params.analysis.coarseDecimate);
        view = rmSearchFit(view,params);
        view = rmFinalFit(view,params);
        [view,params] = rmHrfSearchFit(view,params);
        view = rmFinalFit(view,params);
        view = rmSearchFit(view,params);


    case {'6','hrf coarse to fine fit','hrf'}
        [view, params] = rmHrfSearchFit(view, params);
        view = rmFinalFit(view,params);
        view = rmSearchFit(view, params);
        
    case {'7','search fit and reset params'}
        % Modify existing fit AND refresh the parameters. This is
        % particularly useful when the initial model is estimated from a
        % different data-set (or stimulus). 
        % If you do not want to reset the fitting params see option 2
        % above.
        fprintf(1,'[%s]:Refining fit above a certain threshold (fine fit).\n',mfilename);
        fprintf(1,'[%s]: *****************************************\n',mfilename);
        fprintf(1,'[%s]: * WARNING:Resetting fitting parameters! *\n',mfilename);
        fprintf(1,'[%s]: *****************************************\n',mfilename);
        view = rmSearchFit(view,params);

        
    otherwise
        error('[%s]:Unknown search option: %s',mfilename,wSearch);
end

%-----------------------------------
% Final fit (only for certain models)
%-----------------------------------
% Note GLU 2021-10-14: if you ask for wSearch=1 or 'grid fit', this saves
% an additionnal result, and some values are changed. For grid fit just
% read the gFit.mat result. 
view = rmFinalFit(view,params);

% done
return;
