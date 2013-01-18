function rmModelPositionCorrection(poscorr,dataset,newdataset)
% rmModelPositionCorrection - apply correction factor to position
% estimates of a retinotopy model. E.g. due to eccentric fixation
% or incomplete modeling of the hemodynamic response latency.
%
% model = rmModelPositionCorrection(correction,dataset,newdataset);
%
% Input:
%  correction : [x y polar-angle eccentricity]
%               Will correct in that order! So be careful if you
%               want to correct in several dimensions. Note: put 0 if no
%               correction is required for a particular dimension.
%               All corrections should be provided in degrees of
%               visual angle.
%  dataset    : retModel file (will ask if not provided)
%  newdataset : defaults to 'dataset'-posCorr.mat
%
% 11/2006 SOD: wrote it.

% input checks
if ~exist('poscorr','var') || isempty(poscorr),
    disp(sprintf('[%s]:Error need correction parameters.',mfilename));
    help(mfilename);
    return;
end;
if ~exist('dataset','var') || isempty(dataset);
    [f,p]  = uigetfile({'*.mat'},'Get retModel file.',...
        [pwd filesep 'Gray' filesep]);
    dataset = fullfile(p,f);
    drawnow;
end;
if ~exist('newdataset','var') || isempty(newdataset);
    if ischar(dataset)
        [p n]=fileparts(dataset);
        newdataset = fullfile(p,[n '-posCorr.mat']);
    end
end;

% load data
load(dataset);


% zeropadd - no corrections
if numel(poscorr)<4,
    poscorr = [poscorr(:); zeros(4-numel(poscorr),1)];
end;

% convert pol and ecc to rad
poscorr(3:4) = poscorr(3:4)./360.*(2.*pi);

% change
for n=1:numel(model),
	if poscorr(1)~=0,  % x
		model{n} = rmSet(model{n},'x0',rmGet(model{n},'x0') + poscorr(1));
	end;
	if poscorr(2)~=0,  % y
		model{n} = rmSet(model{n},'y0',rmGet(model{n},'y0') + poscorr(2));
	end;
	if poscorr(3)~=0,  % polar-angle
		p = rmGet(model{n},'pol') + poscorr(3);
		model{n} = rmSet(model{n}, 'pol', p);
	end;
	if poscorr(4)~=0, % eccentricity
		e = rmGet(model{n},'ecc') + poscorr(4);
		model{n} = rmSet(model{n}, 'ecc', e);
	end;
end;

% save new dataset 
params.positionCorrection = poscorr;
save(newdataset,'model','params');

% done
return;
