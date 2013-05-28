function [xform] = niftiCreateXform(nii,xformType)
%First create then apply a specified transform onto the supplied nifti
%struct.
%
% USAGE
%  nii = readNifti(niftiFullPath);
%  xformType = 'Inplane';
%  niftiCreateXform(nii,xformType);
%
% INPUTS
%  Nifti struct
%  String specifying the transform to apply
%
% RETURNS
%  Xform matrix in the form a quaternion
%
%
% Copyright Stanford VistaLab 2013

xformType = mrvParamFormat(xformType);

xform = zeros(4); %Initialization
sliceDim = niftiGet(nii,'slicedim');
if (sliceDim == 0) %Default to a slice dim of 3 if not populated
    sliceDim = 3;
end %if

switch xformType
    case 'inplane'
        [vectorFrom, xform] = niftiCurrentOrientation(nii);
        if ~strcmp(vectorFrom,'PRS')
            %We don't need to change the transform at all
            vectorTo = niftiCreateStringInplane(vectorFrom,sliceDim);
            xform = niftiCreateXformBetweenStrings(vectorFrom,vectorTo);
        end
        
    otherwise
        warning('vista:niftiError','The supplied transform type was unrecognized. Please try again. Returning empty transform.');
        return
end %switch

return
