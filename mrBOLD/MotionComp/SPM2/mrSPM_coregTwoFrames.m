function coregRotMatrix = mrSPM_coregTwoFrames(varargin)
% Between modality coregistration using information theory
% FORMAT coregRotMatrix = spm_coreg(frameA_img, frameB_img, ...
%                     [paramA], [paramB], [flags],[ROI],[coregRotMatrix])
% frameA_img - first (target) image as a 3-D array.
% frameB_img - second (source) image as a 3-D array.
% paramA, paramB - structures of additional parameters for target and source images:
%       mat - a 4x4 affine transformation matrix mapping from
%           voxel coordinates to real world coordinates
%           if paramB.mat is not provided, assume that paramB.mat = paramA.mat
%           NOTE: WE DON'T ASSUME THAT paramA.mat = paramB.mat (although
%           typically they will be), or that they are = eye(4); 
%           COMPUTATIONS WITH paramA.mat = paramB.mat = eye(4) CAN PRODUCE
%           VERY DIFFERENT RESULTS!
%       voxels - vector of (x,y,z) voxel sizes:
%           they can be computed as sqrt(sum(mat(1:3,1:3).^2));
%       scale - a scale factor = V.pinfo(1,1) used for anti-aliasing
% flags - a structure containing the following elements:
%          sep      - optimisation sampling steps (mm)
%                     default: [4 2]
%          params   - starting estimates (6 elements)
%                     default: [0 0 0  0 0 0]
%          cost_fun - cost function string:
%                      'mi'  - Mutual Information
%                      'nmi' - Normalised Mutual Information
%                      'ecc' - Entropy Correlation Coefficient
%                      'ncc' - Normalised Cross Correlation
%                      default: 'nmi'
%          tol      - tolerances for accuracy of each param
%                     default: [0.02 0.02 0.02 0.001 0.001 0.001]
%          fwhm     - smoothing to apply to 256x256 joint histogram
%                     default: [7 7]
%
% ROI - specify a subset to compare. Not sure how to specify, it's unclear
% from the code...(ras, adding comments)
%
% coregRotMatrix - the parameters describing the rigid body rotation.
%   such that a mapping from voxels in frameA_img to voxels in frameB_img
%   is attained by:  matB\spm_matrix(coregRotMatrix(:)')*matA
%
% The registration method used here is based on the work described in:
% A Collignon, F Maes, D Delaere, D Vandermeulen, P Suetens & G Marchal
% (1995) "Automated Multi-modality Image Registration Based On
% Information Theory". In the proceedings of Information Processing in
% Medical Imaging (1995).  Y. Bizais et al. (eds.).  Kluwer Academic
% Publishers.
%
% The original interpolation method described in this paper has been
% changed in order to give a smoother cost function.  The images are
% also smoothed slightly, as is the histogram.  This is all in order to
% make the cost function as smooth as possible, to give faster
% convergence and less chance of local minima.
%
% References
% ==========
% Mutual Information
% ------------------
% Collignon, Maes, Delaere, Vandermeulen, Suetens & Marchal (1995).
% "Automated multi-modality image registration based on information theory".
% In Bizais, Barillot & Di Paola, editors, Proc. Information Processing
% in Medical Imaging, pages 263--274, Dordrecht, The Netherlands, 1995.
% Kluwer Academic Publishers.
%
% Wells III, Viola, Atsumi, Nakajima & Kikinis (1996).
% "Multi-modal volume registration by maximisation of mutual information".
% Medical Image Analysis, 1(1):35-51, 1996. 
%
% Entropy Correlation Coefficient
% -------------------------------
% F Maes, A Collignon, D Vandermeulen, G Marchal & P Suetens (1997).
% "Multimodality image registration by maximisation of mutual
% information". IEEE Transactions on Medical Imaging 16(2):187-198
%
% Normalised Mutual Information
% -----------------------------
% Studholme,  Hill & Hawkes (1998).
% "A normalized entropy measure of 3-D medical image alignment".
% in Proc. Medical Imaging 1998, vol. 3338, San Diego, CA, pp. 132-143.             
%
% Optimisation
% ------------
% Press, Teukolsky, Vetterling & Flannery (1992).
% "Numerical Recipes in C (Second Edition)".
% Published by Cambridge.
%_______________________________________________________________________
% MA, 11/8/2004: based on spm_coreg.m 2.4 by John Ashburner
% needs SPM2 toolbox to run
%
% gb 02/15/05
% The argument ROI is added in order to reduce the domain of computation of
% the mutual information

if nargin>=7 %???
	coregRotMatrix = optfun(varargin{:});

	return;
end;

if nargin < 2,
	myErrorDlg('Calling mrSPM_coregTwoFrames, you must provide at least two arguments!');
    return;
end;
frameA_img = varargin{1};
frameB_img = varargin{2};

if length(varargin)>=6
    ROI = varargin{6};
end

[paramA, paramB] = setParams(varargin{:});
voxelsA = paramA.voxels; voxelsB = paramB.voxels;

def_flags = struct('sep',[4 2],'params',[0 0 0  0 0 0], 'cost_fun','nmi','fwhm',[7 7],...
	'tol',[0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001],'graphics',1);
if nargin < 5,
	flags = def_flags;
else,
	flags = varargin{5};
	fnms  = fieldnames(def_flags);
	for i=1:length(fnms),
		if ~isfield(flags,fnms{i}), flags = setfield(flags,fnms{i},getfield(def_flags,fnms{i})); end;
	end;
end;
%disp(flags)

% Smoothnesses:
fwhma = sqrt(max([1 1 1]*flags.sep(end)^2 - voxelsA.^2, [0 0 0]))./voxelsA;
fwhmb = sqrt(max([1 1 1]*flags.sep(end)^2 - voxelsB.^2, [0 0 0]))./voxelsB;

% Convert image data into arrays of unsigned bytes:
uint8a = getuint8(frameA_img, paramA.scale, fwhma);
uint8b = getuint8(frameB_img, paramB.scale, fwhmb);

sc = flags.tol(:)'; % Required accuracy
sc = sc(1:length(flags.params));
xi = diag(sc*20);
coregRotMatrix  = flags.params(:);
for samp=flags.sep(:)',
    if exist('ROI','var')
        [coregRotMatrix fval] = mrv_spm_powell(coregRotMatrix(:),xi,sc,...
            mfilename,uint8a,uint8b,paramA,paramB, samp,...
            flags.cost_fun,flags.fwhm,ROI);
    else
        [coregRotMatrix fval] = mrv_spm_powell(coregRotMatrix(:),xi,sc,...
            mfilename,uint8a,uint8b,paramA,paramB, samp,...
            flags.cost_fun,flags.fwhm);
    end

    coregRotMatrix        = coregRotMatrix(:)';
end;
%if flags.graphics,
%	display_results(VG,VF,x,flags);
%end;
return;
%_______________________________________________________________________



%_______________________________________________________________________
function [paramA, paramB] = setParams(varargin)
% set optional parameters:
def_params = struct('voxels', [1 1 1], 'scale', 0, 'mat', eye(4));
if nargin < 3
    paramA = def_params;
else
    paramA = varargin{3};
    if ~isfield(paramA, 'mat')
        paramA.mat = def_params.mat;
    end;
    if ~isfield(paramA, 'scale')
        paramA.scale = def_params.scale;
    end;
	paramA.voxels = sqrt(sum(paramA.mat(1:3,1:3).^2));
end;
if nargin < 4
    paramB = def_params;
    paramB.voxels = paramA.voxels;
else
    paramB = varargin{4};
    if ~isfield(paramB, 'mat')
        paramB.mat = paramA.mat;
    end;
    if ~isfield(paramB, 'scale')
        paramB.scale = def_params.scale;
    end;
    if ~isfield(paramB, 'mat')
        paramB.mat = def_params.mat;
    end;
	paramB.voxels = sqrt(sum(paramB.mat(1:3,1:3).^2));
end;
return;
%_______________________________________________________________________




%_______________________________________________________________________
function o = optfun(coregRotMatrix,uint8a,uint8b,pa,pb,s,cf,fwhm,ROI)

q = [0 0 0 0 0 0 1 1 1 0 0 0];
indexes = find(isnan(coregRotMatrix));
coregRotMatrix(indexes) = q(indexes);

% The function that is minimized.
if nargin<9, ROI = ones(size(uint8a));   end;
if nargin<7, fwhm = [7 7];   end;
if nargin<6, cf   = 'mi';    end;
if nargin<5, s    = [1 1 1]; end;

sa = s./pa.voxels;

% Creates the joint histogram
ROI = ROI/max(ROI(:));
ROI = uint8(255*ROI);
H = spm_hist2_weighted(uint8a,uint8b, pb.mat\spm_matrix(coregRotMatrix(:)')*pa.mat, sa, ROI);

% Smooth the histogram
sm = max(fwhm/sqrt(8*log(2)),0.001); % FWHM -> Gaussian param
t  = max(round(3*sm(1)),0); krn1 = exp(-([-t:t].^2)/sm(1)^2) ; krn1 = krn1/sum(krn1) ; H = conv2(H,krn1);
t  = max(round(3*sm(2)),0); krn2 = exp(-([-t:t].^2)/sm(2)^2)'; krn2 = krn2/sum(krn2)'; H = conv2(H,krn2);
%d = 32;
%H = sum(reshape(H,[256/d d 256]),1);
%H = reshape(sum(reshape(H,[d 256/d d]),2),[d d]);

% Compute cost function from histogram
H  = H+eps;
sh = sum(H(:));
H  = H/sh;
s1 = sum(H,1);
s2 = sum(H,2);

switch lower(cf)
	case 'mi',
		% Mutual Information:
		H   = H.*log2(H./(s2*s1));
		mi  = sum(H(:));
		o   = -mi;
	case 'ecc',
		% Entropy Correlation Coefficient of:
		% Maes, Collignon, Vandermeulen, Marchal & Suetens (1997).
		% "Multimodality image registration by maximisation of mutual
		% information". IEEE Transactions on Medical Imaging 16(2):187-198
		H   = H.*log2(H./(s2*s1));
		mi  = sum(H(:));
		ecc = -2*mi/(sum(s1.*log2(s1))+sum(s2.*log2(s2)));
		o   = -ecc;
	case 'nmi',
		% Normalised Mutual Information of:
		% Studholme,  Hill & Hawkes (1998).
		% "A normalized entropy measure of 3-D medical image alignment".
		% in Proc. Medical Imaging 1998, vol. 3338, San Diego, CA, pp. 132-143.
		nmi = (sum(s1.*log2(s1))+sum(s2.*log2(s2)))/sum(sum(H.*log2(H)));
        nmi = nmi/2;
		o   = -nmi;
	case 'ncc',
		% Normalised Cross Correlation
		i     = 1:size(H,1);
		j     = 1:size(H,2);
		m1    = sum(s2.*i');
		m2    = sum(s1.*j);
		sig1  = sqrt(sum(s2.*(i'-m1).^2));
		sig2  = sqrt(sum(s1.*(j -m2).^2));
		[i,j] = ndgrid(i-m1,j-m2);
		ncc   = sum(sum(H.*i.*j))/(sig1*sig2);
		o     = -ncc;
	otherwise,
		error('Invalid cost function specified');
end;

return;
%_______________________________________________________________________




%_______________________________________________________________________
function udat = getuint8(V, acc, fwhm)
% Convert data from 3-D double array V into an array of unsigned bytes.

% Computing max/min of V:
% mx = max(max(max(V))); mn = min(min(min(V)));
mx = max(V(:)) + acc; mn = min(V(:));

% acc = abs(V.pinfo(1,1)) = mx per Bob -???
if acc==0,
	udat = uint8(round((V-mn)*(255/(mx-mn))));
else,
	% Add random numbers before rounding to reduce aliasing artifact
	rand('state',100);
	r = rand(size(V))*acc;
	udat = uint8(round((V+r-mn)*(255/(mx-mn))));
end;
% udat = smooth_volume(udat, fwhm); % Note side effects
return;
%_______________________________________________________________________




%_______________________________________________________________________
function V = smooth_volume(V,fwhm)
% Convolve the volume in memory (fwhm in voxels).
s  = fwhm/sqrt(8*log(2));
x  = round(6*s(1)); x = [-x:x];
y  = round(6*s(2)); y = [-y:y];
z  = round(6*s(3)); z = [-z:z];
x  = exp(-x.^2/(2*s(1).^2+eps));
y  = exp(-y.^2/(2*s(2).^2+eps));
z  = exp(-z.^2/(2*s(3).^2+eps));
x  = x/sum(x);
y  = y/sum(y);
z  = z/sum(z);

i  = (length(x) - 1)/2;
j  = (length(y) - 1)/2;
k  = (length(z) - 1)/2;
spm_conv_vol(V,V, x,y,z, -[i j k]);
return;
%_______________________________________________________________________

