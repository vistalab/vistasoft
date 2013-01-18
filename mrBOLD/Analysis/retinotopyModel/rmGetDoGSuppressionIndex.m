function [suppressionIndex, pos_Vol, neg_Vol, pos_Vol_pRF, neg_Vol_pRF] = rmGetDoGSuppressionIndex(model,varargin)
%[suppressionIndex, pos_Vol, neg_Vol, pos_Vol_pRF, neg_Vol_pRF] = rmGetDoGSuppressionIndex(model,ROIcoords)
%
% rmGetDoGSuppressionIndex - calculates the suppression Index from the DoG model
% Calculates both the volume of the positive gaussian and the negative gaussian that make the
% pRF, it only takes into account the part of the gaussians that fall inside the stimulus window.
% The suppression index is the ratio of the negative and the positive
% volumes. Higher values indicate more suppression. (JOV Zuiderbaan et al.
% 2012)
%
% !! Needs at least the size of the stimulus (sts) as an input in varargin !!
% either by its direct value or by the params of the model:
% [suppressionIndex, pos_Vol, neg_Vol, pos_Vol_pRF, neg_Vol_pRF] = rmGetDoGSuppressionIndex(model,'sts',6.25)
% [suppressionIndex, pos_Vol, neg_Vol, pos_Vol_pRF, neg_Vol_pRF] = rmGetDoGSuppressionIndex(model,'rm',vw.rm)
%
% suppressionIndex          : ratio of the volumes of the negative and the positive gaussian that fall inside the stimuluswindow
% pos_Vol                   : volume of the positive gaussian that falls inside the stimuluswindow
% neg_Vol                   : volume of the negative gaussian that falls inside the stimuluswindow
% pos_Vol_pRF               : volume of the positive part of the pRF that falls inside the stimuluswindow
% neg_Vol_pRF               : volume of the negative part of the pRF that falls inside the stimuluswindow
%
% WZ  02/12: Wrote it


% set default parameters
params.sampleRate = 0.125;      % samplerate of the grid to make the gaussians
params.SI_Centered = false;     % by default the pRF has its original position on the grid, you can make it centered on (0,0) 
                                % by giving this parameter the value true, using varargin

if nargin > 1,
    addArg = varargin;
    if numel(addArg) == 1,
        addArg=addArg{1};
    end;
else
    addArg = [];
end;

% parse command line inputs:
params = rmProcessVarargin(params,addArg);

% the stimulus size needs to be given 
if ~isfield(params,'stimSize') || isempty(params.stimSize),
    disp('ERROR: Need size of the stimulus');
    error('Need size of the stimulus');
end

% make the stimuluswindow
mygridx = (-params.stimSize:params.sampleRate:params.stimSize);
[X2, Y2] = meshgrid(mygridx,mygridx);
Y2 = flipud(Y2);
X2 = X2(:);
Y2 = Y2(:);

ecc = sqrt(X2.^2 + Y2.^2);
keep = ecc > -params.stimSize & ecc < params.stimSize;
X = X2(keep);
Y = Y2(keep);

gridsize = params.sampleRate.^2;

sigma = model.sigma.major;
sigma2 = model.sigma2.major;
beta1 = model.beta(1,:,1);
beta2 = model.beta(1,:,2); 
x = model.x0;
y = model.y0;

% if ROI indices are given, take only the data for that ROI
if isfield(params,'ROIindex') && ~isempty(params.ROIindex)
    sigma = sigma(params.ROIindex);
    sigma2 = sigma2(params.ROIindex);
    beta1 = beta1(params.ROIindex);
    beta2 = beta2(params.ROIindex);
    x = x(params.ROIindex);
    y = y(params.ROIindex);
end

suppressionIndex = zeros(1,numel(sigma2));
pos_Vol = zeros(1,numel(sigma2));
neg_Vol = zeros(1,numel(sigma2));
pos_Vol_pRF = zeros(1,numel(sigma2));
neg_Vol_pRF = zeros(1,numel(sigma2));

for k =1:numel(sigma2)
    if ~params.SI_Centered
        rfpositive = rfGaussian2d(X,Y,sigma(k),sigma(k),0,x(k),y(k));   % original position of the pRF in the stimulus window
        rfnegative = rfGaussian2d(X,Y,sigma2(k),sigma2(k),0,x(k),y(k));    
    else
        rfpositive = rfGaussian2d(X,Y,sigma(k),sigma(k),0,0,0);         % center the pRF at (0,0)
        rfnegative = rfGaussian2d(X,Y,sigma2(k),sigma2(k),0,0,0);
    end
    rfposGaus = beta1(k).*rfpositive;                                   
    rfnegGaus = beta2(k).*rfnegative;
    rftotal = rfposGaus + rfnegGaus;

    % calculate the volume of both gaussians that make the pRF
    pos_Vol(k) = (sum(rfposGaus)).*gridsize;            
    neg_Vol(k) = -(sum(rfnegGaus)).*gridsize;
    ipos = rftotal > 0;
    ineg = rftotal < 0;
    % calculate the volume of the positive and negative part of the pRF
    pos_Vol_pRF(k) = (sum(rftotal(ipos))).*gridsize;
    neg_Vol_pRF(k) = -(sum(rftotal(ineg))).*gridsize;

    if beta2(k)>= 0;
        suppressionIndex(k) = 0;                % if beta2 is bigger or equal to zero, there is no suppression and the suppression index will be 0
    else
        suppressionIndex(k) = neg_Vol(k)./pos_Vol(k);
    end

end


function params = rmProcessVarargin(params,vararg)
if ~exist('vararg','var') || isempty(vararg), return; end
for n=1:2:numel(vararg),
    data = vararg{n+1};
    fprintf(1,' %s,',vararg{n});
    switch lower(vararg{n}),
        case {'ri','roi','roiindex', 'roi_index','roi index'}
            params.ROIindex = data;

        case {'sts','stimsize','size of the stimulus'}
            params.stimSize = data;

        case {'rm','rm params','params struct of the retinotopic model'}    %vw.rm
            params.stimSize = data.retinotopyParams.stim.stimSize;
                    
        case {'sr','samplerate','samplerate of the grid'}
            params.sampleRate = data;
            
        case {'sic','si_centered','si centered','suppression index centered'}
            params.SI_Centered = logical(data);

        otherwise,
            fprintf(1,'[%s]:IGNORING unknown parameter: %s\n',...
                mfilename,vararg{n});
    end;
end;
