function dwParams = dtiInitParams(varargin)
% Initialize preprocessing parameters for dtiInit.m and return them in a
% structure [dwParams].
% 
%  dwParams = dtiInitParams([varargin])
% 
% These parameters represent the current default values to used with
% dtiinit.m. A call to this funciton will initialize the dwParams
% structure, which the user can then manipulate to suit their needs.
%   
%  dwParams
%       .bvalue = [];
%                If you already have appropriate bvals/bvecs files in with
%                your diffusion data, then you can leave bvalue and
%                gradDirsCode parameters empty - just as they are by
%                default.
%       .gradDirsCode = [];
%                Enter the GE grads file code here (if applicable).
%       .clobber = 0; 
%                If clobber == 1 or true, then existing output files
%                will be silently overwritten. If clobber == 0 (the
%                default), then you'll be asked if you want to recompute
%                the file or use the existing one. If clobber == -1, then
%                any existing files will be used and only those that are
%                missing will be recomputed.
%       .dt6BaseName = '';
%                Name of the resulting directory which will contain the
%                processed data. By default if empty = 'dti<nDirs>trilin'
%       .flipLrApFlag = false; 
%                If applicable, this flag will signal dtiRawBuildBvecs to
%                reorient the gradient directions specified in the
%                dwepi.grads file to logical space rather than keeping the
%                directions in scanner space. Thus, the bvecs do not need
%                to be reoriented for oblique prescriptions as with some
%                other DTI sequences. However, this sequence assumes that
%                the 2nd column in dwepi.grads is the phase-encode dim. If
%                your phase-encode is the usual '2', then this is fine.
%                But, if you run ASSET and change the phase encode to L-R
%                (dim 1), you need to swap the first and second columns of
%                dwepi.grads. Also, there appears to be a flip in the
%                phase-encode dim, so you also need to flip the sign on the
%                phase-encode column.
%       .numBootStrapSamples = 500;
%                Number of boostrap interations.
%       .fitMethod = 'ls'; 
%                Fit-method for tesnsor fitting Options are: 
%                'ls': least-squares (default)
%                'rt': RESTORE robust tensor fitting and outlier rejection:
%                Chang, Jones & Pierpaoli (2005). RESTORE: Robust
%                Estimation of Tensors by Outlier Rejection. Magnetic
%                Resonance in Medicine, v53.
%                'lsrt': does least-squares and robust tensor fitting in
%                one go giving you 'dti<nDir>trilinrt'
%       .nStep = 50;
%                The number of steps for the restore algorithm in the
%                robust tensor fitting case. (dtiRawFitTensorRobust)
%       .eddyCorrect = true;
%                If eddyCorrect is 1 (the default), motion and eddy-current
%                correction are done. If it's 0, then only motion
%                correction is done, and if it is -1 then nothing is done
%       .excludeVols = [];
%                excludeVols is an optional list of volume indices to
%                ignore in the tensor fitting. Useful if you know that some
%                of your data are bad. Note that the volume indices start
%                at 1, unlike some viewers (e.g., fslview), that start at
%                0. So, if you are using a zero-indexed viewer to find bad
%                volumes, be sure to add 1 to the resulting indices.
%       .bsplineInterpFlag = false; 
%                This is the method used for interpolation during
%                resampling (dtiRawResample). 
%                true = bspline
%                false = trilinear (default)               
%       .phaseEncodeDir = [];
%                Taken from the rawDti nifti field, you can specify it here
%                if it does not exist. If you collected your DTI data using
%                GE's ASSET, you may be prompted to provide phase-encode
%                direction (1= L/R 'row', 2 = A/P 'col'). Information about
%                this, as well as the b-value and gradient code, can be
%                found in the dicom file header.
%       .dwOutMm = [2 2 2];
%                Resolution of the output in mm.
%       .rotateBvecsWithRx = false;
%                Rotate the bvectors according to the perscription. 
%                (see dtiInit section VII)
%       .rotateBvecsWithCanXform = false;
%                Rotate the bvectors according to the canonical xForm. 
%                (see dtiInit section VII)
%       .bvecsFile  = ''; Path to bvecs file (optional) Path to this file
%                set in dtiInitDir.
%       .bvalsFile  = ''; Path to bvals file (optional) Path to this file
%                set in dtiInitDir.
%       .noiseCalcMethod = 'b0'
%                IF you are using robust tensor fitting you must decide how
%                to calculate the image noise. The default is to use the
%                corner of the image but if the corner of the image is
%                padded with zeros then you should use the 'b0' method
%                which calculates the noise baseed on the std of the b=0
%                image.
%       .outDir = '';
%                The directory to which dtiInit should write all output
%                files. 
% 
% Web Resources:
%       http://white.stanford.edu/newlm/index.php/DTI_Preprocessing
%       mrvBrowseSVN('dtiInitParams');
%
% Example:
%       dwParams = dtiInitParams;
%       dtiInit('rawDti.nii.gz','t1.nii.gz', dwParams);
%  OR:  dwParams = dtiInitParams('clobber',1,'phaseEncodeDir',2);
%       dtiInit('rawDti.nii.gz','t1.nii.gz', dwParams);
% 
% See Also:
%       dtiInit.m
%
% (C) Stanford VISTA, 8/2011 [lmp]
% 

%% Set up default dwParams structure
  
dwParams                         = struct;
dwParams.bvalue                  = [];
dwParams.gradDirsCode            = [];
dwParams.clobber                 = 0;    
dwParams.dt6BaseName             = '';
dwParams.flipLrApFlag            = false; 
dwParams.numBootStrapSamples     = 500;
dwParams.fitMethod               = 'ls';
dwParams.nStep                   = 50;
dwParams.eddyCorrect             = 1; 
dwParams.excludeVols             = []; 
dwParams.bsplineInterpFlag       = false; 
dwParams.phaseEncodeDir          = [];
dwParams.dwOutMm                 = [2 2 2];
dwParams.rotateBvecsWithRx       = false; 
dwParams.rotateBvecsWithCanXform = false;
dwParams.bvecsFile               = '';
dwParams.bvalsFile               = '';
dwParams.noiseCalcMethod         = 'b0';
dwParams.outDir                  = '';

%% Varargin

dwParams = mrVarargin(dwParams, varargin);

return

