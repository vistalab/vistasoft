function [xformMatrix] = niftiCreateXformBetweenStrings(vectorFrom, vectorTo)
%
%Given two vector strings, return the transform that will take one to the
%other. This will be returned as a transform unit matrix


xformMatrix = zeros(4); %Initialize

%Let's get the temporary matrices for each of these
% These matrices should transform each string to RAS format

xformFrom   = niftiCreateXformFromString(vectorFrom);
xformTo     = niftiCreateXformFromString(vectorTo);

if ~isempty(xformFrom) && ~isempty(xformTo)
    xformMatrix = xformTo \ xformFrom;
else
    warning('vista:nifti:transformError', 'A matrix was malformed. Please check and try again. Returning empty');
    return
end

padSide = ones(4,1);

xformMatrix(:,4) = padSide;


return