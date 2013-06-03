function res = viewParameterType(paramIn)
% Maps the paramIn to the heading that it existed in, and thus the file
% that the viewGet/Set function splits it into. This can be useful to
% find both the file as well as the to get further information about what
% exactly a variable was originally defined as. This function should never
% be called directly, but is instead wrapped by viewMapParameterField.
%
%    res = viewParameterType(paramIn);
%
% Displays the type functionality for viewGet/Set.
%
% By using this function, we can get information from the program itself
% trying to understand a certain input to viewGet/Set. This embeds 
% knowledge of what each field does into the program, rather than into 
% someone's head.
%
% res returns a string that corresponds to the 'header' strings in the original 
% viewGet file. 
%
% Examples:
%   viewParameterType('name')
%   viewParameterType('curdt')


global DictViewHeadings;

if isempty(DictViewHeadings)
    DictViewHeadings = containers.Map;
    
    DictViewHeadings('session') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('travelingwave') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('map') = 'Map properties';
    DictViewHeadings('anatomy') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('roi') = 'ROI-related properties';
    DictViewHeadings('timeseries') = 'Time-series related properties';
    DictViewHeadings('retinotopy') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('mesh') = 'Mesh-related properties';
    DictViewHeadings('volume') = 'Volume/Gray-related properties';
    DictViewHeadings('flat') = 'Flat-related properties';
    DictViewHeadings('ui') = 'UI properties';
    DictViewHeadings('em') = 'EM / General-Gray-related properties';
    DictViewHeadings('colorbar') = 'Colorbar-Related Params';    
    
end %if

if DictViewHeadings.isKey(paramIn)
    res = DictViewHeadings(paramIn);
else
    error('Dict:ViewHeadingsError', 'The input %s does not appear to be in the dictionary', paramIn);
    res = [];
end %if

return