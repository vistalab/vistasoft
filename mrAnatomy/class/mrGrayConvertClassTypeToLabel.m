function [newTypeVal,label] = mrGrayConvertClassTypeToLabel(oldTypeVal, hemisphere, labels)
% 
% [newTypeVal,label] = mrGrayConvertClassTypeToLabel(oldTypeVal, hemisphere, [labels=mrGrayGetLabels])
%
% Returns the new mrGray label and value for a given old mrGray class type
% value. If there is no corresponding label, then the label will be
% 'unknown' and the newTypeVal = oldTypeVal-64 if it is >64, newTypeVal =
% oldTypeVal otherwise.
%
% If outFileName is not empty, then the labels are also saved 
% in a text file (in ITKSnap/ITKGray format).
% 
% HISTORY:
% 2009.07.20 RFD wrote it.

if(~exist('labels','var')||isempty(labels))
    labels = mrGrayGetLabels;
end
labelNames = fieldnames(labels);

n = numel(oldTypeVal);

isLeft = strcmpi(hemisphere(1), 'l');

% Old mrGray types:
% class.type.unknown = (0*16);
% class.type.white   = (1*16);
% class.type.gray    = (2*16);
% class.type.csf     = (3*16);
% class.type.other   = (4*16);

label = cell(1,n);
newTypeVal = zeros(1,n);

for(ii=1:n)
    if(oldTypeVal(ii)==16)
        if(isLeft)
            label{ii} = 'leftWhite';
        else
            label{ii} = 'rightWhite';
        end
    elseif(oldTypeVal(ii)==32)
        if(isLeft)
            label{ii} = 'leftGray';
        else
            label{ii} = 'rightGray';
        end
    elseif(oldTypeVal(ii)==48)
        label{ii} = 'CSF';
    else
        label{ii} = 'unknown';
    end
    if(~isempty(strmatch(label{ii},labelNames)))
        newTypeVal(ii) = labels.(label{ii});
    else
        if(oldTypeVal>64)
            newTypeVal(ii) = oldTypeVal(ii)-64;
        else
            newTypeVal(ii) = oldTypeVal(ii);
        end
    end
end
    
return;
