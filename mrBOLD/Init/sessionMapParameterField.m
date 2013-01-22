function res = sessionMapParameterField(fieldName)
% Maps fieldName to a standard format, implementing aliases
%
%    res = viewMapParameterField(fieldName);
%
% Add aliases for viewGet and viewSet.
%
% The standard format is lower case with no spaces.
%
% By using this function, we can refer to parameters in clearer text. For
% example, we can use 'Current Slice Number' to indicate the parameter
% curSlice. 
%
% Examples:
%   sessionMapParameterField('Current Slice')
%   sessionMapParameterField('Current Data Type')s

%Let's strip the field name first
fieldName = mrvParamFormat(fieldName);

%Now, let's create our hard-coded hash, then look it up

sPM = containers.Map;

sPM('functionals') = 'functional';
sPM('functionalparameters') = 'functional';
sPM('pfilenames') = 'pfilenamecellarray';
sPM('sliceordering') = 'sliceorder';
sPM('numberslices') = 'nslices';
sPM('referenceslice') = 'refslice';
sPM('timingreferenceslice') = 'refslice';
sPM('interframedelta') = 'interframetiming';
sPM('timebetweenframes') = 'interframetiming';
sPM('framedt') = 'interframetiming';
sPM('nframes') = 'nsamples';
sPM('frameperiod') = 'tr';


if sPM.iskey(fieldname)
    res = sPM(fieldname); %This means that it is an alias, look it up
else
    res = fieldName; %Assume it was typed in correct and not an alias
end


return

