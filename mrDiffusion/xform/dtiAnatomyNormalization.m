% Anatomical normalization
allSubjects = findSubjects;
N = length(allSubjects);
for g = 1:N
    %FIND t1NormParams HERE - UNFINISHED
    
    % dField = inv(
    dField = mrAnatSnToDeformation(t1NormParms.sn,[2 2 2]);
    t1ToTensorXform  = inv(anat.xformToAcPc*xformToAnat);
    
    %Reorient deformation field to tensor space from t1 space - UNFINISHED

    
    %Applying the deformation field to dt6, b0 images
    [dt6,b0] = dtiDeformer(dt6,b0,dField);
    
    %PPD Reorientation of dt6 image
    R = dtiFindXformPPD(dt6,dField);
    dt6 = dtiXformTensorsPPD(dt6,R);
    
end



