function res = sessionHelpParameter(paramIn)
% Maps the paramIn to the help file, displaying an explanation of what each
% sessionGet/Set parameter should do.
% This function should never
% be called directly, but is instead wrapped by sessionMapParameterField.
%
%    res = sessionHelpParameter(paramIn);
%
% Add help functionality for viewGet/Set.
%
% By using this function, we can get help from the program itself when
% trying to call a certain field. This embeds knowledge of what each field
% does into the program, rather than into people's heads.
%
% res returns a multi-line string that, when printed, will display across
% multiple lines, similar to the multi-line comments previously stored in
% the Matlab code.
%
% Examples:
%   sessionHelpParameter('alignment')
%   sessionHelpParameter('description')

global DictSessionHelp;

if isempty(DictSessionHelp)
    DictSessionHelp = containers.Map;
    
    DictSessionHelp('alignment') = '';
    DictSessionHelp('description') = '';
    DictSessionHelp('eventdetrend') = '';
    DictSessionHelp('examnum') = '';
    DictSessionHelp('functionalinplanepath') = '';
    DictSessionHelp('functionalsslicedim') = '';
    DictSessionHelp('functionalvoxelsize') = '';
    DictSessionHelp('functionals') = ['sessionGet(s,''functionals'',3);' char(10) ...
                   'sessionGet(s,''functionals'');'];
    DictSessionHelp('inplane') = ['Return the structure of the inplanes data' char(10) ...
        'inplane = sessionGet(s, ''inplane'');'];
    DictSessionHelp('inplanepath') = ['Return the path to the nifti for the' char(10) ...
        'inplane anatomy (underlay for the functional data)' char(10) ...
        'pth = sessionGet(s, ''inplane path'');'];
    DictSessionHelp('interframetiming') = ['This is the proportion of a TR that separates each frame' char(10) ...
        'acquisition. This is NOT a real number in seconds.' char(10) ...
        'sessionGet(mrSESSION,''interframedelta'',2)'];
    DictSessionHelp('nsamples') = '';
    DictSessionHelp('nshots') = '';
    DictSessionHelp('nslices') = '';
    DictSessionHelp('pfilelist') = ['Return indices into the functional scans corresponding to the' char(10) ...
        'cell array of pFile names' char(10) ...
        'sessionGet(s,''pFileList'',{''name1'',''pFile2.mag''})'];
    DictSessionHelp('pfilenamecellarray') = '';
    DictSessionHelp('pfilenames') = '';
    DictSessionHelp('refslice') = '';
    DictSessionHelp('screensavesize') = '';
    DictSessionHelp('sessioncode') = '';
    DictSessionHelp('sliceorder') = '';
    DictSessionHelp('subject') = '';
    DictSessionHelp('title') = '';
    DictSessionHelp('tr') = 'Time series processing parameters for block and event analyses';
    DictSessionHelp('version') = '';
    
end %if

if DictSessionHelp.isKey(paramIn)
    res = DictSessionHelp(paramIn);
else
    error('Dict:SessionHelpError', 'The input %s does not appear to be in the dictionary', paramIn);
end %if

return