function mrAnatOverlayMontageVolume(funcNifti, anatNifti, outname, overlayClipRng)

%Will overlay functional (in color) onto anatomical (greyscale) and save as
%a true color image to be loaded as a background in Quench.
%overlayClipRng: values to show (e.g., [4 8]), values above upper value in
%the clipRng will be displayed as the upper value. 

%Will clip off all the negative values in the functional -- we do not have to keep this feature. 

%ER 11/2009 wrote it

%funcNifti=fullfile('C:\PROJECTS\Connectome\rb090930\fmri\Resting\ica_unnormalized_corrected', 'melodic_IC_acpc_IC6_corticalDMN.nii.gz'); 
%anatNifti=fullfile('C:\PROJECTS\Connectome\rb090930\t1', 't1.nii.gz'); 
%outname='test.nii.gz';
%mrAnatOverlayMontageVolume(funcNifti, anatNifti, outname)

if  ~exist('overlayClipRng', 'var') || isempty(overlayClipRng)
    overlayClipRng=    [4 8];
end
    
a=niftiRead(funcNifti); 
b=niftiRead(anatNifti); 

[imgRgb, overlayImg, overlayMask, anatImage]=mrAnatOverlayMontage(double(a.data), a.qto_xyz, double(b.data), b.qto_xyz, autumn(256), overlayClipRng, [-30:2:50], [], [], [], [], [], [], [], Inf);

overlayImg(overlayImg<0)=0; %GET RID OF BLUE BLOBS
overlayMask(isnan(overlayMask))=0;
cmap = autumn(256);

      inds = round(overlayImg*255+1);
      inds(isnan(inds)) = 1;

        overlay = reshape(cmap(inds,:),[size(overlayImg) 3]);
        overlay(repmat(~overlayMask|isnan(overlayImg), [1 1 1 3])) = 0;

anatImageTC=repmat(anatImage, [1 1 1 3]);
anatImageTC(repmat(overlayMask>0, [1 1 1 3])) = 0;


anatImageTC=anatImageTC./max(anatImageTC(:)); 

%Save in anatomy space!
b.data=anatImageTC+overlay;  
b.data=permute(b.data, [2 1 3 4]);
b.data=flipdim(b.data, 2); 
b.fname=outname;
b.ndim=4; 
b.dim=[b.dim 3];
b.pixdim=[b.pixdim 1];

writeFileNifti(b); 
