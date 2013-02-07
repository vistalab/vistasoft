function [xformMatrix] = niftiCreateXformFromString(vectorString)
%
%Given a vectorString of the orientation, create the transform that will
%reset to RAS

xformMatrix = zeros(4); %Initialize

%First, let's find out where each of the RAS directions are:

tmp = strfind(vectorString,'R');
tmpVector = zeros(1,4);

if (isempty(tmp)) %Means that we probably have an L and not an R
    tmp = strfind(vectorString,'L');
    if isempty(tmp) %We have neither? Badly formatted string!
        warning('vista:niftiError', 'Unable to parse the vector string and create the Xform matrix. Returning empty.');
        return
    end
    tmpVector(tmp(1)) = -1; %Since we are looking at an L
else
    tmpVector(tmp(1)) = 1; %Since we are looking at an R
end

xformMatrix(1,:) = tmpVector; %We can hardcode in the 1 there, since we
% know that we always want RAS format, which means that R should always be
% the first row

tmp = strfind(vectorString,'A');
tmpVector = zeros(1,4);

if (isempty(tmp)) %Means that we probably have a P and not an A
    tmp = strfind(vectorString,'P');
    if isempty(tmp) %We have neither? Badly formatted string!
        warning('vista:niftiError', 'Unable to parse the vector string and create the Xform matrix. Returning empty.');
        xformMatrix = zeros(4);
        return
    end
    tmpVector(tmp(1)) = -1; %Since we are looking at a P
else
    tmpVector(tmp(1)) = 1; %Since we are looking at an A
end

xformMatrix(2,:) = tmpVector;


tmp = strfind(vectorString,'S');
tmpVector = zeros(1,4);

if (isempty(tmp)) %Means that we probably have an I and not an S
    tmp = strfind(vectorString,'I');
    if isempty(tmp) %We have neither? Badly formatted string!
        warning('vista:niftiError', 'Unable to parse the vector string and create the Xform matrix. Returning empty.');
        xformMatrix = zeros(4);
        return
    end
    tmpVector(tmp(1)) = -1; %Since we are looking at a I
else
    tmpVector(tmp(1)) = 1; %Since we are looking at an S
end

xformMatrix(3,:) = tmpVector;


%Finally, let's pad the matrix with zeros and ones:
padBot = zeros(1,4);
padSide = ones(4,1);

xformMatrix(4,:) = padBot;
xformMatrix(:,4) = padSide;


return