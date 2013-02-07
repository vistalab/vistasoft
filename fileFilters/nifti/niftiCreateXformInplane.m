function [xformMatrix] = niftiCreateXformInplane(vectorFrom, sliceDimension)
%
%Given a vector string and the slice dimension, return the correct matrix
%taking this vector to correct VistaLab Inplane format.
%
%2013 - VistaLab

vectorTo = niftiCreateStringInplane(vectorFrom,sliceDimension);

xformMatrix = zeros(4); %Initialization

if ~isempty(vectorTo)
    xformMatrix = niftiCreateXformBetweenStrings(vectorFrom,vectorTo);
else
    warning('vista:nifti:transformError', 'The vector was returned incorrectly. Please check and try again. Returning empty.');
end %if

return