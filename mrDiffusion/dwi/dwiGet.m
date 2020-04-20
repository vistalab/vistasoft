function [val, dwi] = dwiGet(dwi, param, varargin)
% Get data from the dwi structure
%
%   [val, dwi] = dwiGet(dwi, param, varargin)
%
% Retrieve data from a dwi structure (see dwiCreate).
% We allow passing a filename for dwi which calls dwiLoad and returns the
% dwi.
%
% There is a parallel set of sets/gets/create for the handles of the
% mrDiffusion window (dtiGet/Set/Create/Load).  These should be better
% coordinated in the code.
%
% Parameters (incomplete, needs updating)
%   General
%    {'name'}
%    {'type'}
%
%   Data values
%    {'diffusion data acpc'}
%    {'diffusion data image'}
%    {'n images'}
%    {'n diffusion images'}
%    {'n nondiffusion images'}
%    {'b0 image nums'}
%    {'b0 vals image'}
%
%   Estimated values
%    {'adc data acpc'}
%    {'adc data image'}
%    {'tensor image'}
%    {'tensor acpc'}
%    {'diffusion distance image'}
%    {'diffusion distance acpc'}
%    {'b0 std image'}
%    {'b0 mean image'}
%    {'b0 acpc' }
%    {'b0 STD image'}
%    {'b0 SNR image'} Return an SNR (mean/std) value for each voxel in
%                     coords. Coords are in the rows (i.e., nCoords x 3)
%    {'b0 SNR roi'}   Return an SNR (mean/sigma) value for each voxel in
%                     coords. Sigma is the standard deviation of the b0 
%                     measurements corrected for small samples.
% 
%   Measurement parameters
%    {'bvals'}
%    {'bvecs'}
%    {'n diffusion bvecs'}
%    {'n diffusion bvals'}
%
% Examples:
%   To get diffusion data from a fiber
%   nifti = niftiRead('raw/DTI__aligned_trilin.nii.gz');
%   bvecs =   dlmread('raw/DTI__aligned_trilin.bvecs');
%   bvals =   dlmread('raw/DTI_aligned_trilin.bvals');
%   dwi   = dwiCreate('nifti',nifti,'bvecs',bvecs,'bvals',bvals);
%   coords = [64 64 30;64 64 31; 64 64 32];
%
%   dws = dwiGet(dwi,'diffusion data acpc',coords);
%
%   ADC = dwiGet(dwi,'adc data image',coords);
%
%   SNR = dwiGet(dwi,'b0 snr',coords);
%
% See also:  dwiCreate, dwiSet, dtiGet, dtiSet, dtiCreate
%
% (c) Stanford Vistasoft 2013

% TODO:
%   Keep adjusting the diffusion data gets
%
if notDefined('dwi'), error('dwi structure or filename required'); end
if notDefined('param'), help('dwiGet'); end

% We allow passing a string for the dwi, which is a filename to use for
% loading the dwi.  In that case, we also return the dwi structure as the
% second return argument
if ischar(dwi)
    % This requires that the bvecs and bvals files be in standard form and
    % located relative to the dwi file.  We don't check.
    if exist(dwi,'file'),    dwi = dwiLoad(dwi);
    else,                    error('File not found %s\n',dwi);
    end
end

val = [];

switch(mrvParamFormat(param))
    
    % General parameters
    case {'name'}
        val = dwi.name;
    case {'type'}
        val = dwi.type;
        % bval and bvec properties
    case {'size','dim','volumesize','datasize'}
        val = dwi.nifti.dim;
    case {'nimages','nbvecs'}
        % Number of diffusion and b=0 images
        % dwiGet(dwi,'n images')
        val = dwi.nifti.dim(4);
    case {'xform2img'}
        % Affine trasformation to image space.
        % dwiGet(dwi,'xfomr 2 img')
        val = dwi.nifti.qto_ijk;
    case {'ndiffusionimages','numdiffusionimages'}
        % Number of images with diffusion gradient on (b > 0)
        % dwiGet(dwi,'n diffusion images')
        n = dwiGet(dwi,'nimages');
        m = dwiGet(dwi,'n nondiffusion images');
        val = n - m;
    case {'nb0','nnondiffusionimages','numnondiffusionimages'}
        % Number of non-diffusion images (b=0)
        val = sum(dwiGet(dwi,'findb0index'));
    case {'bvecs'}
        if isfield(dwi,'bvecs'), val = dwi.bvecs; end
    case {'bvals'}
        if isfield(dwi,'bvals'), val = dwi.bvals(:); end
    case {'b0imagenums'}
        val = find(dwiGet(dwi,'findb0index'));
    case {'diffusionimagenums','dimagenums'}
        val = find(~dwiGet(dwi,'findb0index'));
    case {'diffusionbvecs'}
        % bvecs = dwiGet(dwi,'diffusion bvecs');
        % bvecs in the diffusion gradient on case (the others don't matter)
        indexBvals = ~dwiGet(dwi,'findb0index');
        val        = dwi.bvecs(indexBvals,:);
        
    case {'diffusionbvals'}
        % bvals = dwiGet(dwi,'diffusion bvals');
        % bvals when the diffusion gradient is on
        indexBvals = ~dwiGet(dwi,'findb0index');
        
        % There are apparently some unit issues.  We should force this to
        % be explicit rather than guess like this. - BW
        if any(dwi.bvals > 10)
            val = dwi.bvals(indexBvals,:) ./ 1000;
        else
            val = dwi.bvals(indexBvals,:);
        end
        
    case {'findb0index'}
        % Guess the number of shells in the data. Some data (Siemens and
        % Human Connectome for example) come in with BVALS that are around
        % a value sau 1000={995,999,1002} or 0={0,5,10}, here instead of
        % enforcing the round-off of the values we try to guess the number 
        % of shels and indices of the b0
          bvals         = dwiGet(dwi,'bvals');
          rounded_bvals = round((bvals./100))*100;
          
          % report which shells were found.
          %unique_shells = unique(rounded_bvals);
          %unique_shells_string = sprintf('%d ', unique_shells);
          %fprintf('[%s] Found DWI shells %s.',mfilename,unique_shells_string)
          
          % find the indices of the B0 images
          val  = (rounded_bvals == 0);

    case {'ndiffusionbvals'}
        val = size(dwiGet(dwi,'diffusion bvals'),1);
    case {'ndiffusionbvecs'}
        val = size(dwiGet(dwi,'diffusion bvecs'),1);
        
        % Diffusion data
        % the last bit (image or acpc) indicates the coordinate frame of
        % coords argument.
    case{'diffusionsignalimage','dimage','dwimage','diffusiondataimage','dsigimage'}
        % dSig = dwiGet(dsi,'diffusion data image',coord)
        %
        % The raw diffusion measurements at coords in image space.
        %
        % Diffusion-weighted data from image coords
        % The coordinates need to be rounded to integers
        % dSig = dwiGet(dwi,'diffusion data image',coords)
        if ~isempty(varargin), coords = varargin{1};
        else, error('coords required');
        end
        
        % Checks the dimensionality
        coords = coordCheck(coords);
        
        % We use floor to keep the coordintes within the current voxel.
        % Every decimal up to the next integer should be kept as part of
        % the current voxel.
        coords = floor(coords);
        
        % val will be a 2D matrix with dimensions (N coords,N vols) where
        % N coords is the number of coordinates passed in and N vols is the
        % number of volumes in the nifti image
        indx = sub2ind(dwi.nifti.dim(1:3),coords(:,1),coords(:,2),coords(:,3));
        dimg = dwiGet(dwi,'dimagenums');
        val  = zeros(length(indx),length(dimg));
        for ii = 1:length(dimg)
            tmp = squeeze(dwi.nifti.data(:,:,:,dimg(ii)));
            val(:,ii) = tmp(indx);
        end
        
    case{'diffusionsignalacpc','dacpc','dwacpc','diffusiondataacpc'}
        % dSig = dwiGet(dwi,'diffusion signal acpc',coords);
        %
        % get dwi data from a set of coordinates in ac-pc space
        % Returns the diffusion data, excluding b=0, at a set of
        % coordinates
        
        % transform ac-pc coordinates which have units of millimeters from
        % the anterior commisure to image indices.  By image indices we
        % mean integer locations within the dwi volume that correspond to
        % the ac-pc coordinates. At some point we may want to interpolate
        % these as oppose to rounding them to integers but for the time
        % being it seems to make more sense to grab data from a full voxel
        if ~isempty(varargin), coords = varargin{1};
        else, error('coords required');
        end
        coords = coordCheck(coords);
        
        % Convert coordinates to image space. We use floor here because we
        % want keep the coordintes to be within the current voxel. Every
        % decimal up to the next integer should be kept as part of the
        % current voxel.
        coords = floor(mrAnatXformCoords(dwi.nifti.qto_ijk,coords));
        val    = dwiGet(dwi,'diffusion data image',coords);
        
    case {'adcdataimage'}
        % dwiGet(dwi,'adc data image',coord)
        % Compute the ADC values from data in image coordinates
        %
        % The returned values are the ADC in each column of a matrix
        % The row dimension is the number of bvec directions, 
        % The column dimension is the number of coordinates
        %
        % See also: The function dtiADC predicts the ADC given a tensor
        %
        % We could have cases 'adctensorimage' and 'adctensoracpc'.  Or, we
        % could just make up functions for doing this, such as dtiADC,
        % dwiQ, and the mess that is out there.  To think and discuss.
        %
        
        if ~isempty(varargin), coords = varargin{1};
        else,                  error('image coords required');
        end
        
        % Get the data
        coords = coordCheck(coords);
        bvals  = dwiGet(dwi,'diffusion bvals');
        S0     = dwiGet(dwi,'b0 image',coords);
        % When there are multiple b=0 images, S0 is ncoords x nImages
        % For this code to make sense, we use the mean of the b=0 images.
        % It would be possible to select one by an input argument (BW).
        
        dSig = dwiGet(dwi,'diffusion data image', coords);
        
        % Compute the ADC in each direction.  This is the inverse of the
        % Stejskal Tanner Equation that predicts the diffusion signal from
        % the ADC.
        %
        % Suppose the dSig in each direction, and b is the bvalue in the
        % direction.
        %
        %   dSig = S0 * exp(-b*ADC)
        %
        % If there are multiple b=0 images, we need to reduce S0.  Here we
        % choose the mean S0 value.  It would be possible to select one of
        % them by adding an argument.
        S0  = mean(S0,2);
        val = -log(diag(1./S0)*dSig)*diag((bvals).^-1);
        val = val';    % ADC for each voxel is in the columns
        
        % Only worked for 1 coord
        % val = - diag( (bvals).^-1 )*log(dSig(:)/S0);  % um2/ms
        
    case {'adcdataacpc'}
        % dwiGet(dwi,'adc data acpc',coord)
        % Get the ADC values from a particular acpc coordinate location
        if ~isempty(varargin), coords = varargin{1};
        else, error('acpc coords required');
        end
        coords = coordCheck(coords);
        
        % Convert coordinates to image space. We use floor here because we
        % want keep the coordintes to be within the current voxel. Every
        % decimal up to the next integer should be kept as part of the
        % current voxel.
        coords = floor(mrAnatXformCoords(dwi.nifti.qto_ijk,coords));
        val    = dwiGet(dwi,'adc data image',coords);
        
    case {'diffusiondistanceimage'}
        % dwiGet(dwi,'diffusion distance image',coord)
        % Estimate the diffusion distance values from an image
        % coordinate location in all the bvec directions.  This uses the
        % ADC value, it does not rely on the tensor model.
        
        % These notes are from dtiRenderAdcEllipsoids.m - Needs more
        % referencing and clarification, but it is about right.
        %
        % The eigenvalues of Q are related to the ADC values by
        % sqrt(2*lambda_i).  When u is in the principal direction, the ADC
        % is sqrt(2*val).
        %
        % Diffusion distance ellipsoid axis lengths = sqrt(2*lambda_i*T);
        % here T=1. Scale the eigenvectors in the columns of vec by
        % sqrt(2*lambda_i). Project the set of unit vectors (u) onto these
        % scaled vectors. e = u*sqrt(2*val)*vec';
        
        if ~isempty(varargin), coords = varargin{1};
        else, error('image coords required');
        end
        
        % Get the adc data.  By the DTI model, these satisfy adc = u' Q u;
        % where u are unit length vectors (bvecs).
        adc = dwiGet(dwi,'adc data image',coords);
        
        % The diffusion distance are the lengths of the vectors that
        % satisfy 1 = v'Qv.  The vectors v are u/sqrt(adc), because
        % (u'/sqrt(adc)) Q (u/sqrt(adc)) = u' Q u / adc = adc / adc = 1
        %
        % We don't understand how to make the units real distance yet.
        % T should be set to the diffusion time for a real distance.
        % This way it is distance per second, maybe.
        % T = 1; val = 1./sqrt(2*T*adc);
        val = 1./sqrt(adc);
        
    case {'tensorimage'}
        % dwiGet(dwi,'tensor image', coords)
        %
        % Returns the quadratic form that predicts the ADCs at this
        % coordinate in image space.
        if ~isempty(varargin), coords = varargin{1};
        else, error('image coords required');
        end
        coords = coordCheck(coords);
        val = dwiQ(dwi,coords);
        
    case {'tensoracpc'}
        % dwiGet(dwi,'tensor acpc', coords)
        % coords are nCoords x 3
        if ~isempty(varargin), coords = varargin{1};
        else, error('image coords required');
        end
        coords = coordCheck(coords);
        
        % Convert to image space
        coords = floor(mrAnatXformCoords(dwi.nifti.qto_ijk,coords));
        val = dwiQ(dwi,coords);
        
    case{'b0acpc','s0acpc'}
        % get B0 data from a set of coordinates in ac-pc space
        % Please fix to be consistent with the next b0 code that BW added.
        if ~isempty(varargin), coords = varargin{1};
        else, error('coords required');
        end
        coords = coordCheck(coords);
        
        % transform ac-pc coordinates which have units of millimeters from
        % the anterior commisure to image indices.  By iimage indices we
        % mean integer locations within the dwi volume that correspond to
        % the ac-pc coordinates. At some point we may want to interpolate
        % these as oppose to rounding them to integers but for the time
        % being it seems to make more sense to grab data from a full voxel.
        %
        % We use floor here because we want keep the coordintes to be
        % within the current voxel. Every decimal up to the next integer
        % should be kept as part of the current voxel.
        coords = floor(mrAnatXformCoords(dwi.nifti.qto_ijk,coords));
        
        
        % val will be a 1xN vector where N is the number of coordinates
        % passed in.  The measurements across b0 volumes are averaged
        indx=sub2ind(dwi.nifti.dim(1:3),coords(:,1),coords(:,2),coords(:,3));
        b0 = find(dwiGet(dwi,'findb0index'));
        
        for ii = 1:length(b0)
            tmp = squeeze(dwi.nifti.data(:,:,:,b0(ii)));
            val(:,ii) = tmp(indx);
        end
        val = nanmean(val,1);
        
    case{'meanb0'}
        % S0 = dwiGet(dwi,'b0 mean image');
        %
        % Return the mean of the b=0 (non diffusion) images
        % Was a duplicate of below, which made no sense.
        % So LMP/BW changed this to do the right thing and return the mean
        % of the b=0 images in dwi.nifti data
        
        lst = dwiGet(dwi,'n nondiffusion images');
        val = dwi.nifti.data(:,:,:,lst);
        % Apparently, this runs even if there is only one element in lst
        val = mean(val,4);
        
    case {'b0image','b0valsimage','s0valsimage','s0image'}
        % S0 = dwiGet(dwi,'b0 image',coords); Return an S0 value for each
        % voxel in coords. The specified coords are in the rows (i.e.,
        % nCoords x 3).
        %
        % When there are multiple b=0 images in the dwi data, the S0 value
        % for each b=0 image is placed in the columns of the return.  So,
        % if you ask for 100 coords and there are 4 b=0 images, the return
        % is 100 x 4.
        if ~isempty(varargin), coords = varargin{1};
        else,                  error('coords required');
        end
        coords = coordCheck(coords);
        
        % Indices of the coords in the 3D volume.
        indx = sub2ind(dwi.nifti.dim(1:3),coords(:,1),coords(:,2),coords(:,3));
        b0 = dwiGet(dwi,'b0 image nums');
        val = zeros(size(coords,1),length(b0));
        for ii = 1:length(b0)
            tmp = squeeze(dwi.nifti.data(:,:,:,b0(ii)));
            val(:,ii) = tmp(indx);
        end
        
    case {'b0stdimage','s0stdimage','s0standarddeviationimage'}
        % std = dwiGet(dwi,'b0 STD image',coords);
        %
        % Return an standard deviation of the b0 image across repeated
        % measures for each voxel in coords.
        % Coords are in the rows (i.e., nCoords x 3)
        if ~isempty(varargin), coords = varargin{1};
        else, error('coords required');
        end
        val = dwiGet(dwi,'b0 vals image',coords);
        
        % find the direction equal to the nbvals
        nbvals = length(dwiGet(dwi,'b0imagenums'));
        dim    = find(size(val)==nbvals);
        val    = std(val,[],dim);
        
    case {'b0snrimage','s0snrimage','s0signal2noiseratioimage'}
        % SNR = dwiGet(dwi,'b0 SNR image',coords);
        % Return an SNR (mean/std) value for each voxel in coords
        % Coords are in the rows (i.e., nCoords x 3)
        if ~isempty(varargin), coords = varargin{1};
        else, error('coords required');
        end
        
        m  = dwiGet(dwi,'b0 image',coords);
        sd = dwiGet(dwi,'b0 std image',coords);
        val = m./sd;
        
    case {'b0sigmaimageroi'}
        % sigma = dwiGet(fe,'b0 sigma image')
        % sigma is the std of the b0-image with a correction for small
        % samples.
        if ~isempty(varargin), coords = varargin{1};end
        b0vals = dwiGet(dwi,'b0 vals image',coords);
        nb0    = dwiGet(dwi,'nb0');
        
        % Calculate the median of the standard deviation. We do not think that
        % this needs to be rescaled. Henkelman et al. (1985) suggest that this
        % aproaches the true noise as the signal increases.
        sigma = median(std(b0vals,0,1));
        
        % std of a sample underestimates sigma (see http://nbviewer.ipython.org/4287207/)
        % This can be very big for small n (e.g., 20% for n=2)
        % We can compute the underestimation bias:
        bias = sigma * (1 - sqrt(2 / (nb0-1)) * (gamma(nb0 / 2) / gamma((nb0-1) / 2)));
        
        % and correct for it:
        val = sigma + bias;
        
    case {'b0snrroi','s0snrroi','s0signal2noiseratioimageroi'}
        % SNR = dwiGet(dwi,'b0 SNR roi',coords);
        % Return an SNR (mean/sigma) value for each voxel in coords
        % sigma is the standard deviation of the b0 measurements corrected
        % fro small samples.
        % Coords are in the rows (i.e., nCoords x 3)
        if ~isempty(varargin), coords = varargin{1};
        else, error('coords required'); end
        
        m     = mean(dwiGet(dwi,'b0 image',coords));
        sigma = dwiGet(dwi,'b0 sigma image roi',coords);
        val   = m / sigma;
        
    otherwise
        error('Unknown parameter: "%s"\n',param);
end

end


%% Check that coords have 3D
function coords = coordCheck(coords)
% Make sure the coordinates are in columns rather than rows
%
if size(coords,2) ~= 3
    if size(coords,1) == 3
        disp('Transposing coordinates to rows.')
        coords = coords';
    else
        error('Bad size of coords matrix');
    end
end
end



