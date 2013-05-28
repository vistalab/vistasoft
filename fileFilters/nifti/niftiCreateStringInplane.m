function [vectorTo] = niftiCreateStringInplane(vectorFrom, sliceDimension)
%
%Given a vector string and the slice dimension, return the correct string
%orientation in the Vistalab Inplane format, which does not touch the slice
%dimension

%We are looking to return something that will keep the slice dimension the
%same, but make it be the 3rd dimension, then if, L-R are there, make it
%the second dimension, otherwise, leave the other two dimensions as they are

vectorTo = vectorFrom; %We will operate purely on vectorTo

if (sliceDimension ~= 3)
    %We need to move the slice dimension to 3
    tmpChar = vectorTo(sliceDimension);
    vectorTo(sliceDimension) = vectorTo(3);
    vectorTo(3) = tmpChar;
end %if

%We now have a vector that has the 3rd dimension be the slice dimension
%Now, let's move LR dimension to 1st position

LRdim = niftiFindDimOfString(vectorTo,'R'); %This will find either R or L

if (LRdim ~= 3 && LRdim ~= 2) %i.e. it is not the slice dimension nor is it already the second dimension
    tmpChar = vectorTo(2);
    vectorTo(2) = vectorTo(LRdim);
    vectorTo(LRdim) = tmpChar;
end %if

tmpChar = vectorTo(3); %Get the slice dimension and reapply it after, to preserve it
vectorTo = niftiCreateComplementString(vectorTo);
vectorTo(3) = tmpChar;

return