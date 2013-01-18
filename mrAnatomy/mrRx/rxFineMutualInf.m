function rx = rxFineMutualInf(rx, startFromXform, nuCorrect, useIfiles, sep);
%
% rx = rxFineMutualInf(rx, [startFromXform=1], [gradientCorrect=1], ...
%						   [useIfiles=1], [searchScale=[8 4 2]]);
%
% Perform a fine alignment using SPM2's 
% Mutual-Information based tools.
%
% ras 03/05
% ras 07/07: after several attempts at getting this to work and failing,
% I've replaced the old code with code directly lifted from mrAlignMI,
% which works surprisingly well.
if notDefined('rx')
    cfig = findobj('Tag', 'rxControlFig');
    rx = get(cfig, 'UserData');
end

if ishandle(rx),		rx = get(rx, 'UserData');		end
if notDefined('nuCorrect'),		nuCorrect = 1;			end
if notDefined('startFromXform'), startFromXform = 1;	end
if notDefined('useIfiles'),		useIfiles = 1;			end
if notDefined('sep'),			sep = [8 4 2];			end

% check for SPM toolbox
if isempty( which('spm_coreg') ) 
    myErrorDlg(['Requires spm2 tools! Try adding ' ...
				'.../matlab/toolbox/mri/spm2 to your path.']);
end

h = msgbox('Using Mutual Information to Compute Alignment...');


%%%%% (1) Build VF struct: volume->physical alignment structure
% Build a very rough xform to axial, ac-pc space
% this assumes rx.vol is oriented along the lines of mrVista/mrGray
% vAnatomies: I|P|R space, or (rows, cols, slices) go increasingly
% (inferior, posterior, right).
% ***FIX ME: I'm not sure the v.mm is correct here. I've only tested it on
% isotropic data so far, so I can't tell.
hsz = rx.volDims ./ 2;
res = rx.volVoxelSize;
vAnatAcpcXform = [0 0 res(3) -hsz(3); ...
				  0 -res(2) 0 hsz(1); ...
				  -res(1) 0 0 hsz(2); ...
				  0 0 0 1];
VF.uint8 = uint8(rx.vol);
VF.mat = vAnatAcpcXform;

%%%%% (2) Build VG struct: inplane->physical alignment structure
% Correct for intensity gradient if requested
if nuCorrect==1
	if ~isa(rx.ref, 'double')
		rx.ref = double(rx.ref);
	end
	[GradInt GradNoise]  = regEstFilIntGrad(rx.ref);
	inplaneAnat          = regCorrIntGradWiener(rx.ref, GradInt, GradNoise);
else
	inplaneAnat = rx.ref;
end


%% (3) Set initial xform
% check for inplane files
pattern = fullfile(pwd, 'Raw', 'Anatomy', 'Inplane', 'I*');
w = dir(pattern);

%% If Ifiles exist use them for an initial xform otherwise center on 0.
if ~isempty(w)	&  useIfiles==1
	verbose = prefsVerboseCheck;	
	if verbose >= 1
		fprintf('[%s]: Using xform from I-file to scanner space.\n', mfilename);
	end

	% See if we can get a crop from the mrSESSION structure
	mrSessPath = fullfile(pwd, 'mrSESSION.mat');
	if exist(mrSessPath, 'file')
		load(mrSessPath, 'mrSESSION');
		crop = mrSESSION.inplanes.crop;
	else
		crop = [];
	end	
	
	% get xform to scanner coords (some serious voodoo in that last line)
	inplaneFile = fullfile(pwd, 'Raw', 'Anatomy', 'Inplane', w(1).name);
	xformToScanner = computeXformFromIfile(inplaneFile, crop);
	xformToScanner = inv( xformToScanner ); 
	xformToScanner(1:3,4) = xformToScanner([1:3],4) + [10 -20 -20]';
	
	VG.mat = xformToScanner;	

else
	%% default xform (center on 0,0,0)
	trans = -[rx.refDims .* rx.volDims ./ 2]';
	VG.mat = [diag(rx.refVoxelSize) trans; 0 0 0 1];
	
	% GE convention is right-to-left, but we want l-to-r (Talairach
	% convention)
	% Careful! If you rerun you don't want to keep flipping your image
	% all the time
	VG.mat(1,:) =  -VG.mat(1,:);
	
end

% do some best-guess clipping (w/ some voodoo) for the inplane data
ipAnat = mrAnatHistogramClip(rx.ref, 0.2, 0.99);
VG.uint8 = uint8(ipAnat * 255 + 0.5);


%%%%% (3) build flags to use in spm_coreg
% flags.sep specifies the step size to use for each iteration
% of search. 
flags.sep    = sep;

% set initial search parameters
if startFromXform==1
	xform = rx.xform;
	
	% flip to (x,y,z) instead of (y,x,z):
	xform(:,[1 2]) = xform(:,[2 1]);
	xform([1 2],:) = xform([2 1],:);

	revAlignment = spm_imatrix(VF.mat * xform / VG.mat);
	flags.params = revAlignment(1:6)
	
	%% key step
	rotTrans     = spm_coreg(VG, VF, flags);			
end


%%%%% (4) key step: align using spm_coreg
rotTrans     = spm_coreg(VG, VF, flags);


%%%%% (5) convert back into mrRx format
%% build 4 x 4 xform matrix from SPM rotTrans params
alignment = VF.mat \ spm_matrix(rotTrans) * VG.mat

% alignment is in [y,x,z] format -- flip back to [x,y,z]
alignment(:,[1 2]) = alignment(:,[2 1]);
alignment([1 2],:) = alignment([2 1],:);

%% set in rx struct and mark the settings
rx = rxSetXform(rx, alignment);

rxStore(rx, 'Mutual Inf Align');

close(h)

return




% % old:
% swapXY = [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
% 
% %% get the source image (the volume)
% % for now, clipVals will be the min and max of rx.vol
% clipVals = [];
% VG.uint8 = uint8(rescale2(vol, clipVals, [0 255]));
% VG.mat = eye(4);
% 
% %% get the target image (reference)
% clipVals = []; % may use histogram criterion later...
% VF.uint8 = uint8(rescale2(rx.ref, clipVals, [0 255]));
% VF.mat = eye(4);
% 
% %% initialize estimated params 
% spm_defaults; global defaults;
% estParams = defaults.coreg.estimate;
% %estParams.sep = [2];  % small step size -- we should be close
% %estParams.cost_fun = 'ncc'; % normalized cross-correlation cost function
% 
% xformParams = spm_coreg(VG, VF, estParams);
% adjustment = VF.mat \ spm_matrix(xformParams) * VG.mat;
% 
% % % some x/y order flipping here:
% % adjustment([1 2],:) = adjustment([2 1],:);
% % adjustment(:,[1 2]) = adjustment(:,[2 1]);
% 
% %% the xform solved by spm_coreg is an adjustment to our existing xform:
% newXform = adjustment * rx.xform;
