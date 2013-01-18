function [statslice,cesslice] = er_stxgslice(hAvgFile,contrast,varargin);
% [statslice,cesslice] = er_stxgslice(hAvgFile,contrast,[options]);
%
% er_stxgslice: fs-fast stx slice grinder script, ported for use with
% mrLoadRet
%
% Computes one (inplane) slice of a contrast map, across one or more input
% scans. Returns the specified statistic as statslice. 
%  
% hAvgFile: path to the tSeries for this slice (e.g.
% Inplane/Original/Tseries/Scan1/tSeries1.mat)
%
% contrast: a structure with the same format as that produced by the
% FS-FAST function mkcontrast-sess. It has at least the following fields:
%       ContrastMtx_0: specifies the condition contrast. For block-design 
%       (non-deconvolved) experiments, it should have the following format:
%       1 row, nConds columns, where nConds does not include the fixation/
%       baseline condition (usually specified as condition 0). Active
%       conditions should have positive sign, control conditions should
%       have negative sign, conditions which are not to be considered
%       should be 0. The sum of the active conditions should be 1, control
%       conditions should be -1. E.g. for 5 conditions, comparing 1 and 2
%       vs. 4 and 5 and ignoring condition 3:
%
%               contrast.ContrastMtx_0 = [0.5 0.5 0 -0.5 -0.5]; 
%
% Right now this doesn't save anything, just hands off two matrices,
% statslice and cesslice. statslice contains the results of a statistic, by
% default the -log10 p value from a t test between the active Versus
% control conditions. cesslice is a measure (still not sure the
% mathematical basis) of the size of the contrast effect. In mrLoadRet
% terms, these might have analogous functions to the coherence (statslice)
% and amplitude (cesslice) of the corAnal.
%
% Options: hand in options in pairs, e.g. 'ihDelta',1.25. Can be strings or
% numeric values (if the parameter is numeric). You can set any of the
% parameters set at the top of the code (sorry this is so hands on; in exchange
% I hope to make the code much more legible as I go over several iterations).


% $Id: er_stxgslice.m,v 1.12 2005/08/09 22:58:27 sayres Exp $
% er_stxgslice: ported from fmri_stxgslice by ras, 10/1/03
% 03/05/04 ras: changed from a script to a function. Doesn't save any
% output files, but instead returns a matrix containing the requested stat
% matrix for the given slice.
%
% See also: computeContrastMap,er_stxgrinder,er_mkcontrast.
% ras 04/03/04: fixed the scaling issue (wasn't taking estimated 
% variance.^2)
statslice = []; cesslice = [];

% fprintf(1,' ---------- StXGSlice.m : Starting ------------\n');

%%%%% PARAMS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
QuitOnError = 1;
OutputFormat = 1; % 0 = log(p) (natural log)
                  %  1 = log10(p)
                  %  2 = p
                  %  3 = test value
ActiveCond = contrast.condNums(find(contrast.WCond > 0));
ControlCond = contrast.condNums(find(contrast.WCond < 0));
CorrIdeal = 0;
CmpIdeal = 0;
TestType = 'tm'; % for list of test types, help fmri_mrestriction
ihDelta = 1.25; 
ihTau = 2.5;
dataSize = [];  % [X Y] size of inplanes; enter through varargin if functional is not square (e.g., cropped)
datfile = fullfile(fileparts(hAvgFile),'h.dat'); % this should be produced by selxavg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parse the option flags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:length(varargin)
    if (i < length(varargin)) & (ischar(varargin{i}))
		if (isnumeric(varargin{i+1}))
	        cmd = sprintf('%s = [%s];',varargin{i},num2str(varargin{i+1}));
		elseif ischar(varargin{i+1})
	        cmd = sprintf('%s = ''%s'';',varargin{i},varargin{i+1})
		elseif iscell(varargin{i+1});
			tmp = unNestCell(varargin{i+1});
	        cmd = sprintf('%s = {',varargin{i});			
			for j = 1:length(tmp)-1
				cmd = [cmd '''' tmp{j} ''','];
			end		
			cmd = [cmd '''' tmp{end} '''};']
	    end
        eval(cmd);
	end
end

if (CmpIdeal) | (CorrIdeal) % still trying to figure out what CorrIdeal is -- it's for deconvolved data, at least
    if isempty(ihDelta)
        error('er_stxgslice: need to input ihDelta if correlating w/ Ideal HRF.')
    end

    if isempty(ihTau)
        error('er_stxgslice: need to input ihTau if correlating w/ Ideal HRF.')
    end
end

%%%% ----- Check that variables are the proper values ---- %%%%%
% Check the Test Type %
if ( isempty( strmatch(upper(TestType),{'T ','TM','FM','F0','FD','FC','FCD','FDC'},'exact')))
    fprintf(2,'Error: Unkown TestType %s',TestType);
    if (QuitOnError) quit;
    else            return;
    end
end

if ( OutputFormat < 0 | OutputFormat > 3)
    fprintf(2,'Error: OutputFormat=%d, must be within 0 to 3\n',OutputFormat);
    if (QuitOnError) quit;
    else            return;
    end
end

%% -- check that input files exist -- %%
if ~exist(hAvgFile,'file')
    error(['Can''t find file ' hAvgFile '.']);
end
if ~exist(datfile,'file')
    error(['Can''t find file ' datfile '.']);
end

%% --- Read the h.dat Header File ---- %%%
% fprintf(1,'Reading h.dat Header \n');
hd = fmri_lddat3(datfile);
if isempty(dataSize) % if not entered through varargin
    dataSize = [hd.Nrows hd.Ncols];
end

%% --- Read the hAvg File ---- %%%
% fprintf(1,'Reading hAvg File \n');
load(hAvgFile)
if ~exist('tSeries','var')
    error([hAvgFile ' does not contain a tSeries variable!']);
end

%% --- This should always be 1 until I add deconvolution support ---- %%%
if (hd.GammaFit > 0) 
    HDelTest = 1;
else
   newHDelMin = hd.TER*round(HDelMin/hd.TER)+hd.TER*round(hd.TPreStim/hd.TER);
   newHDelMax = hd.TER*round(HDelMax/hd.TER)+hd.TER*round(hd.TPreStim/hd.TER);
   fprintf(1,'Info: newHDelMin = %g, newHDelMax = %g\n',newHDelMin,newHDelMax);
   HDelTest = round([newHDelMin/hd.TER:newHDelMax/hd.TER]') + 1; %'
   fprintf(1,'Info: HDelTest '); 
   fprintf(1,' %d',HDelTest);
   fprintf(1,'\n');
end


%% --- From the sxa format of the tSeries, grab hAvg and eVar ---- %%%
% These are the average planes for each condition and the estimated
% residual variance. I may be incorrect--I need to verify this--but I
% believe the format selxavg saves as contains the residual variance as the
% estimated variances for the null, 0, condition. This is the first plane.
% So for block design expts (Nh = 1), the format of the rows of the tSeries
% is: zeros for baseline, eVar, hAvg for Cond 1, variance for Cond 1, hAvg
% for Cond 2, variance for cond 2, etc. er_stxgrinder requires hAvg and
% eVar:
eVar = reshape(tSeries(2,:),dataSize);
eVar = eVar .* eVar;
ind = 3:2:size(tSeries,1);
for i = 1:length(ind)
	hAvg(:,:,i) = reshape(tSeries(ind(i),:),dataSize);
end

if ( exist('HDelMin') & hd.GammaFit > 0)
    msg = 'Cannot specify a delay range with gamma-fit average files';
    qoe(msg); error(msg);
end

if (CorrIdeal & hd.GammaFit > 0)
    msg = 'Cannot correlate ideal HDR with gamma-fit average files';
    qoe(msg); error(msg);
end

nVoxels = hd.Nrows*hd.Ncols;

nPreStim = floor(hd.TPreStim/hd.TER);

% set up params for er_stxgrinder, which does the actual GLM contrast
% computation:
%Ch = fmri_ldbfile(hcovFile);
Ch = hd.hCovMtx;              % covariance matrix
RM = contrast.ContrastMtx_0;  % restriction matrix
nRM = size(RM,2);
nh  = size(hAvg,3);
if (nRM ~= nh)
    msg = sprintf('er_stxgslice: hAvg size (%d) is inconsistent with CMtx (%d)',nh,nRM);
    error(msg);
else
    RM = contrast.ContrastMtx_0;
end

q = zeros(size(hAvg,3),1);

% The meat of the calculation -- create the maps
[vSig pSig ces] = er_stxgrinder(TestType,hAvg,eVar,Ch,hd.DOF,RM,q);

if nargout > 1
    % ---- Compute ces as percent of baseline --- %
    inputdir = fileparts(hAvgFile);
    a = findstr('hAvg',hAvgFile)+4;
    b = findstr('.mat',hAvgFile)-1;
    sliceno = str2num(hAvgFile(a:b));
    hoffsetname = fullfile(inputdir,sprintf('mean_%03d.mat',sliceno));
    hoffset = er_ldtfile(hoffsetname);
    if (isempty(hoffset))
        fprintf('ERROR: could not load %s\n',hoffsetname);
        return;
    elseif size(hoffset,2)==1 
        % somehow the mean image (hoffset) gets saved
        % as a column rather than row vector
        hoffset = hoffset';
    end
    indz = find(hoffset==0);
    hoffset(indz) = 10^10;
    nces = size(ces,3);
    cesslice = ces./repmat(reshape(hoffset,size(ces)),[1 1 nces]);
end

if (CmpIdeal)
    pSig = 1 - pSig ;
end

if (strncmp('T',upper(TestType),1))
    SignMask = ((vSig>=0) - (vSig<0));
    pSig = pSig .* SignMask;
else
    SignMask = [];
end

% Dont let pSig = zero (messes up log10)
iz = find(abs(pSig) < 10^-300); 
pSig(iz) = sign(pSig(iz)) * 10^-300;
iz = find(pSig == 0);
pSig(iz) = 10^-300; % Have to do this because sign(0) = 0

if (OutputFormat == 0)     pSig = -log(abs(pSig))  .*sign(pSig);
elseif (OutputFormat == 1) pSig = -log10(abs(pSig)).*sign(pSig);
end

statslice = pSig;

return
