function res = dtMapParameterField(paramIn, specialFunctionFlag, paramInSpecial)
% Maps paramIn to a standard format, implementing aliases
%
%    res = viewMapParameterField(fieldName,[specialFunctionFlag]);
%
% Add aliases for viewGet and viewSet.
%
% The standard format is lower case with no spaces.
%
% The special function flag enables the use of unique keywords such as
% 'list' and 'help' to perform meta actions.
%
% By using this function, we can refer to parameters in clearer text. For
% example, we can use 'Current Slice Number' to indicate the parameter
% curSlice. 
%
% Examples:
%   viewMapParameterField('Current Slice')
%   viewMapParameterField('Current Data Type')
if ~exist('specialFunctionFlag','var'), specialFunctionFlag = 0; end;

global DictDtTranslate;

if isempty(DictDtTranslate)
    
    DictDtTranslate = containers.Map;
    
    DictDtTranslate('analysistype') = 'atype';
    DictDtTranslate('atype') = 'atype';
    DictDtTranslate('eventorblock') = 'atype';
    DictDtTranslate('annotation') = 'annotation';
    DictDtTranslate('blockedanalysisparams') = 'blockparams';
    DictDtTranslate('blockparams') = 'blockparams';
    DictDtTranslate('bparams') = 'blockparams';
    DictDtTranslate('bparms') = 'blockparams';
    DictDtTranslate('cropsize') = 'cropsize';
    DictDtTranslate('eventanalysisparams') = 'eventparams';
    DictDtTranslate('eventparams') = 'eventparams';
    DictDtTranslate('eparams') = 'eventparams';
    DictDtTranslate('eparms') = 'eventparams';
    DictDtTranslate('frameperiod') = 'frameperiod';
    DictDtTranslate('funcsize') = 'funcsize';
    DictDtTranslate('inplanesize') = 'funcsize';
    DictDtTranslate('inplanepath') = 'inplanepath';
    DictDtTranslate('keepframes') = 'keepframes';
    DictDtTranslate('nframes') = 'nframes';
    DictDtTranslate('nscans') = 'nscans';
    DictDtTranslate('nslices') = 'nslices';
    DictDtTranslate('parfile') = 'parfile';
    DictDtTranslate('pfilename') = 'pfilename';
    DictDtTranslate('rmparams') = 'rmparams';
    DictDtTranslate('retinomodelparams') = 'rmparams';
    DictDtTranslate('retinotopymodelparams') = 'rmparams';
    DictDtTranslate('scanparams') = 'scanparams';
    DictDtTranslate('slices') = 'slices';
    DictDtTranslate('smoothframes') = 'smoothframes';
    
end %if


%Leave this here, but do not implement passing in a specialFunction flag
%until ready to do so.
if specialFunctionFlag
    if strcmp(paramIn,'list')
        allVals = unique(values(DictDtTranslate));
        numVals = numel(allVals);
        display('The list of possible keys, in alphabetical order is: ')
        for i = 1:numVals
            display(allVals{i});
        end %for
    elseif strcmp(paramIn,'help')
        if exist('paramInSpecial','var')
            allVals = cellstr(paramInSpecial);
        else
            allVals = unique(values(DictDtTranslate));
        end %if
        numVals = numel(allVals);
        display('The list keys, with help, in alphabetical order is: ')
        for i = 1:numVals
            display(['<strong>' allVals{i} '</strong>: ' dtHelpParameter(allVals{i})]);
        end %for
    end %if    
    
elseif DictDtTranslate.isKey(paramIn)
    res = DictDtTranslate(paramIn);
else
    error('Dict:DTSplitError', 'The input %s does not appear to be in the dictionary', paramIn);
    res = [];
end

return

