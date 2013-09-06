function ctrPDFFile(p,altp)
%Create the Contrack PDF file
%
%    ctrPDFFile(params, alteredParams)
%
% The file is stored in the dt6Dir/bin directory with the name
% pdf.nii.gz.  The file contains information about distribution of
% principal diffusion directions (uncertainty).
%
% History
% AJS wrote it at some point
% 02/2009: DY modified it to handle creation of altered (e.g., degraded tensor) PDFs
% 02/24/2009: DY fixed bug created by failing to read in PDDdisp nifti

% Handle various combinations of input arguments
if (~notDefined('p') && notDefined('altp'))
    readNiftiFiles = 1; % Default, for use with CTRINIT
elseif (~notDefined('p') && ~notDefined('altp'))
    readNiftiFiles = 0; %  NOT CTRINIT, createNoDataPDF.m
else
    error('Please check your params input arguments');
end

switch readNiftiFiles

    % Default ctrInit GUI action, read nifti files from subject's bin
    case 1
        niTensors  = niftiRead(fullfile(p.dt6Dir,'bin','tensors.nii.gz'));
        imgTensors = double(squeeze(niTensors.data(:,:,:,1,[1 3 6 2 4 5])));
        % Convert dispersion to Watson concentration parameter. We test to check
        % whether the PDD is in degrees or radian format
        % This is the tensor fit uncertainty from the tensor fitting bootstrap
        if ~exist(fullfile(p.dt6Dir,'bin','pddDispersion.nii.gz'),'file')
            warning('File bin/pddDispersion.nii.gz does not exist!!')
            fprintf('To generate this file you must bootstrap the tensor fitting\n')
        end
        niPDDD = niftiRead(fullfile(p.dt6Dir,'bin','pddDispersion.nii.gz'));
        if(max(niPDDD.data(:))>2*pi)
            imgPDDC = - 1 ./ sin(double(niPDDD.data).*pi./180).^2; % Degrees
        else
            imgPDDC = - 1 ./ sin(double(niPDDD.data)).^2;          % Radians
        end
        imgPDDC(isinf(imgPDDC)) = min(imgPDDC(~isinf(imgPDDC)));
        pdfFile= fullfile(p.dt6Dir,'bin','pdf.nii.gz');
        qto_xyz=niTensors.qto_xyz;

        %  NOT ctrInit: Use info from altp input struct, as in createNoDataPDF.m
    case 0
        niPDF = niftiRead(fullfile(p.dt6Dir,'bin','pdf.nii.gz'));
        imgTensors=altp.dt6;
        imgPDDC=altp.eig1Concentration;
        pdfFile= fullfile(p.dt6Dir,'bin',altp.pdfName);
        qto_xyz=niPDF.qto_xyz;

end


% A brain mask from the tensor fitting
niBM   = niftiRead(fullfile(p.dt6Dir,'bin','brainMask.nii.gz'));

% Compute eigenvalues of the tensors
[eigVec, eigVal] = dtiEig(imgTensors);

% Compute the fiber direction uncertainty based on linearity index
imgCl    = dtiComputeWestinShapes(eigVal);
imgEVec1 = squeeze(eigVec(:,:,:,[1 2 3],1));
imgEVec2 = squeeze(eigVec(:,:,:,[1 2 3],2));
imgEVec3 = squeeze(eigVec(:,:,:,[1 2 3],3));

% The imgPDF represents the eigenvectors, the bootstrap of the PDD
% direction uncertainty from bootstrapping (imgPDDC), the linearity value,
% and 2nd and 3rd eigenvalues.
% We set the pdf 0 where it is outside of brain mask, this is necessary for
% ConTrack program
imgPDF = zeros([size(imgTensors,1),size(imgTensors,2),size(imgTensors,3), 3*3+5]);
imgPDF(:,:,:,1:3) = imgEVec3;
imgPDF(:,:,:,4:6) = imgEVec2;
imgPDF(:,:,:,7:9) = imgEVec1;
% We think this should be changed - the data are duplicated for no real
% reason.  We can't change it here without changing it other places.  AJS
% will do this after dissertation.
imgPDF(:,:,:,10:11) = repmat(double(imgPDDC),[1,1,1,2]);
imgPDF(:,:,:,12) = imgCl;
imgPDF(:,:,:,13:14) = eigVal(:,:,:,2:3);
imgPDF( repmat(double(niBM.data), [1 1 1 size(imgPDF,4)]) == 0 ) = 0;

% Write the file (save)
dtiWriteNiftiWrapper(imgPDF,qto_xyz,pdfFile);

return;
