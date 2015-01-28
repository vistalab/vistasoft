function res = sessionMapParameterField(paramIn, specialFunctionFlag, paramInSpecial)
% Maps paramIn to a standard format, implementing aliases
%
%    res = viewMapParameterField(paramIn);
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

%As always, we assume that the input has already been sanitized

%Now, let's create our hard-coded hash, then look it up
% A hash works like an array, only it maps non-integer keys to values
if ~exist('specialFunctionFlag','var'), specialFunctionFlag = 0; end;

global DictSessionTranslate

if isempty(DictSessionTranslate)
    
    DictSessionTranslate = containers.Map;
    
    DictSessionTranslate('alignment') = 'alignment';
    DictSessionTranslate('description') = 'description';
    DictSessionTranslate('eventdetrend') = 'eventdetrend';
    DictSessionTranslate('examnum') = 'examnum';
    DictSessionTranslate('framedt') = 'interframetiming';
    DictSessionTranslate('frameperiod') = 'tr';
    DictSessionTranslate('functionalinplanepath') = 'functionalinplanepath';
    DictSessionTranslate('functionalparameters') = 'functionals';
    DictSessionTranslate('functionals') = 'functionals';
    DictSessionTranslate('functionalsslicedim') = 'functionalsslicedim';
    DictSessionTranslate('functionalvoxelsize') = 'functionalvoxelsize';
    DictSessionTranslate('functionalorientation') = 'functionalorientation';
    DictSessionTranslate('inplane') = 'inplane';
    DictSessionTranslate('inplanepath') = 'inplanepath';
    DictSessionTranslate('interframedelta') = 'interframetiming';
    DictSessionTranslate('interframetiming') = 'interframetiming';
    DictSessionTranslate('nframes') = 'nsamples';
    DictSessionTranslate('nsamples') = 'nsamples';
    DictSessionTranslate('nshots') = 'nshots';
    DictSessionTranslate('nslices') = 'nslices';
    DictSessionTranslate('numberslices') = 'nslices';
    DictSessionTranslate('pfilelist') = 'pfilelist';
    DictSessionTranslate('pfilenamecellarray') = 'pfilenamecellarray';
    DictSessionTranslate('pfilenames') = 'pfilenames';
    DictSessionTranslate('referenceslice') = 'refslice';
    DictSessionTranslate('refslice') = 'refslice';
    DictSessionTranslate('screensavesize') = 'screensavesize';
    DictSessionTranslate('sessioncode') = 'sessioncode';
    DictSessionTranslate('sliceorder') = 'sliceorder';
    DictSessionTranslate('sliceordering') = 'sliceorder';
    DictSessionTranslate('subject') = 'subject';
    DictSessionTranslate('timebetweenframes') = 'interframetiming';
    DictSessionTranslate('timingreferenceslice') = 'refslice';
    DictSessionTranslate('title') = 'title';
    DictSessionTranslate('tr') = 'tr';
    DictSessionTranslate('version') = 'version';

end %if


if specialFunctionFlag
    if strcmp(paramIn,'list')
        allVals = unique(values(DictSessionTranslate));
        numVals = numel(allVals);
        display('The list of possible keys, in alphabetical order is: ')
        for i = 1:numVals
            display(allVals{i});
        end %for
    elseif strcmp(paramIn,'help')
        if exist('paramInSpecial','var')
            allVals = cellstr(paramInSpecial);
        else
            allVals = unique(values(DictSessionTranslate));
        end %if
        numVals = numel(allVals);
        display('The list keys, with help, in alphabetical order is: ')
        for i = 1:numVals
            display(['<strong>' allVals{i} '</strong>: ' sessionHelpParameter(allVals{i})]);
        end %for
    end %if    
    
elseif DictSessionTranslate.isKey(paramIn)
    res = DictSessionTranslate(paramIn); %This means that it is an alias, look it up
else
    res = paramIn; %Assume it was typed in correct and not an alias
end


return

