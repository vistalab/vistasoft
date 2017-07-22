function anat = nifti2mrVistaAnat(ni)
% Take a nifti and re-orient to mrVista anatomy convention
%   
%   anat = nifti2mrVistaAnat(ni)
%
%   ni: can be a matrix, a nifti struct, or a path to a nifti file.
%
% Our preferred NIFTI format is [sagittal(L:R), coronal(P:A), axial(I:S)] format. 
% mrLoadRet coords are in [axial(S:I), coronal(A:P), sagittal(L:R)] format.
% This function permutes our preferred NIFTI format into our mrLoadRet format.
%
% April, 2009: JW

% Check format of input argument (Ideally, we shoudl require NIFTI and not
% allow a data array with no header. But we don't want to break things.)
if isnumeric(ni) || islogical(ni), data = ni; end
if ischar(ni), ni = niftiRead(ni); end

% Reorient to RAS
if isstruct(ni), 
    ni = niftiApplyCannonicalXform(ni);
    data = niftiGet(ni, 'data'); 
end

% Permute 
anat = permute(data, [3 2 1]);

% then flip dims 1 and 2
anat = flip(flip(anat, 1),2);

return

