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
% A hash works like an array, only it maps non-integer keys to values

global sessionParameterMap

sessionParameterMap = containers.Map;

sessionParameterMap('functionalparameters') = 'functionals';
sessionParameterMap('pfilenames') = 'pfilenamecellarray';
sessionParameterMap('sliceordering') = 'sliceorder';
sessionParameterMap('numberslices') = 'nslices';
sessionParameterMap('referenceslice') = 'refslice';
sessionParameterMap('timingreferenceslice') = 'refslice';
sessionParameterMap('interframedelta') = 'interframetiming';
sessionParameterMap('timebetweenframes') = 'interframetiming';
sessionParameterMap('framedt') = 'interframetiming';
sessionParameterMap('nframes') = 'nsamples';
sessionParameterMap('frameperiod') = 'tr';


if sessionParameterMap.isKey(fieldName)
    res = sessionParameterMap(fieldName); %This means that it is an alias, look it up
else
    res = fieldName; %Assume it was typed in correct and not an alias
end


return

