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
    
    DictViewHeadings('homedir') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('sessionname') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('subject') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('name') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('annotation') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('annotations') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('viewtype') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('subdir') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('curscan') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('curslice') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('nscans') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('nslices') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('montageslices') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('dtname') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('curdt') = 'Session-related properties; selected scan, slice, data type';
    DictViewHeadings('dtstruct') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('coherence') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('scanco') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('phase') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('scanph') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('amplitude') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('scanamp') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('refph') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('ampmap') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('coherencemap') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('correlationmap') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('cothresh') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('phwin') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('twparams') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('cmap') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('cmapcolor') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('cmapgrayscale') = 'Map properties';
    DictViewHeadings('map') = 'Map properties';
    DictViewHeadings('mapwin') = 'Map properties';
    DictViewHeadings('mapname') = 'Map properties';
    DictViewHeadings('mapunits') = 'Map properties';
    DictViewHeadings('mapclip') = 'Map properties';
    DictViewHeadings('scanmap') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('anatomy') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('anatomymap') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('anatomynifti') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('anatclip') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('anatslicedim') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('anatslicedims') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('anatsize') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('anatomycurrentslice') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('anatsizexyz') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('brightness') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('contrast') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('mmpervox') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('mmpervolvox') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('ngraylayers') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('scannerxform') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('b0dir') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('b0angle') = 'ROI-related properties';
    DictViewHeadings('rois') = 'ROI-related properties';
    DictViewHeadings('roistruct') = 'ROI-related properties';
    DictViewHeadings('roicoords') = 'ROI-related properties';
    DictViewHeadings('roiindices') = 'ROI-related properties';
    DictViewHeadings('roivertinds') = 'ROI-related properties';
    DictViewHeadings('roiname') = 'ROI-related properties';
    DictViewHeadings('roimodified') = 'ROI-related properties';
    DictViewHeadings('allroinames') = 'ROI-related properties';
    DictViewHeadings('nrois') = 'ROI-related properties';
    DictViewHeadings('selectedroi') = 'ROI-related properties';
    DictViewHeadings('filledperimeter') = 'ROI-related properties';
    DictViewHeadings('selroicolor') = 'ROI-related properties';
    DictViewHeadings('prevcoords') = 'ROI-related properties';
    DictViewHeadings('roistodisplay') = 'ROI-related properties';
    DictViewHeadings('roidrawmethod') = 'ROI-related properties';
    DictViewHeadings('showrois') = 'ROI-related properties';
    DictViewHeadings('hidevolumerois') = 'ROI-related properties';
    DictViewHeadings('maskrois') = 'Time-series related properties';
    DictViewHeadings('tseriesdir') = 'Time-series related properties';
    DictViewHeadings('datasize') = 'Time-series related properties';
    DictViewHeadings('dim') = 'Time-series related properties';
    DictViewHeadings('functionalslicedim') = 'Time-series related properties';
    DictViewHeadings('tseries') = 'Time-series related properties';
    DictViewHeadings('tseriesslice') = 'Time-series related properties';
    DictViewHeadings('tseriesscan') = 'Time-series related properties';
    DictViewHeadings('tr') = 'Time-series related properties';
    DictViewHeadings('nframes') = 'Time-series related properties';
    DictViewHeadings('ncycles') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('framestouse') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('rmfile') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('rmmodel') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('rmcurrent') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('rmmodelnames') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('rmparams') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('rmstimparams') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('rmmodelnum') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('rmhrf') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('one gamma (boynton style)') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('two gammas (spm style)') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('impulse') = 'Retinotopy/pRF Model related properties';
    DictViewHeadings('impulse') = 'Mesh-related properties';
    DictViewHeadings('allmeshes') = 'Mesh-related properties';
    DictViewHeadings('allmeshids') = 'Mesh-related properties';
    DictViewHeadings('mesh') = 'Mesh-related properties';
    DictViewHeadings('currentmesh') = 'Mesh-related properties';
    DictViewHeadings('meshn') = 'Mesh-related properties';
    DictViewHeadings('meshdata') = 'Mesh-related properties';
    DictViewHeadings('nmesh') = 'Mesh-related properties';
    DictViewHeadings('meshnames') = 'Mesh-related properties';
    DictViewHeadings('meshdir') = 'Volume/Gray-related properties';
    DictViewHeadings('nodes') = 'Volume/Gray-related properties';
    DictViewHeadings('xyznodes') = 'Volume/Gray-related properties';
    DictViewHeadings('nodegraylevel') = 'Volume/Gray-related properties';
    DictViewHeadings('nnodes') = 'Volume/Gray-related properties';
    DictViewHeadings('edges') = 'Volume/Gray-related properties';
    DictViewHeadings('nedges') = 'Volume/Gray-related properties';
    DictViewHeadings('allleftnodes') = 'Volume/Gray-related properties';
    DictViewHeadings('allleftedges') = 'Volume/Gray-related properties';
    DictViewHeadings('allrightnodes') = 'Volume/Gray-related properties';
    DictViewHeadings('allrightedges') = 'Volume/Gray-related properties';
    DictViewHeadings('allnodes') = 'Volume/Gray-related properties';
    DictViewHeadings('alledges') = 'Volume/Gray-related properties';
    DictViewHeadings('coords') = 'Volume/Gray-related properties';
    DictViewHeadings('allcoords') = 'Volume/Gray-related properties';
    DictViewHeadings('coordsfilename') = 'Volume/Gray-related properties';
    DictViewHeadings('ncoords') = 'Volume/Gray-related properties';
    DictViewHeadings('classfilename') = 'Volume/Gray-related properties';
    DictViewHeadings('classdata') = 'Volume/Gray-related properties';
    DictViewHeadings('graymatterfilename') = 'Volume/Gray-related properties';
    DictViewHeadings('datavalindex') = 'EM / General-Gray-related properties';
    DictViewHeadings('analysisdomain') = 'Flat-related properties';
    DictViewHeadings('fliplr') = 'Flat-related properties';
    DictViewHeadings('imagerotation') = 'Flat-related properties';
    DictViewHeadings('hemifromcoords') = 'Flat-related properties';
    DictViewHeadings('roihemi') = 'UI properties';
    DictViewHeadings('ishidden') = 'UI properties';
    DictViewHeadings('ui') = 'UI properties';
    DictViewHeadings('fignum') = 'UI properties';
    DictViewHeadings('windowhandle') = 'UI properties';
    DictViewHeadings('displaymode') = 'UI properties';
    DictViewHeadings('anatomymode') = 'UI properties';
    DictViewHeadings('coherencemode') = 'UI properties';
    DictViewHeadings('correlationmode') = 'UI properties';
    DictViewHeadings('phasemode') = 'UI properties';
    DictViewHeadings('amplitudemode') = 'UI properties';
    DictViewHeadings('projectedamplitudemode') = 'UI properties';
    DictViewHeadings('mapmode') = 'UI properties';
    DictViewHeadings('zoom') = 'UI properties';
    DictViewHeadings('crosshairs') = 'UI properties';
    DictViewHeadings('locs') = 'UI properties';
    DictViewHeadings('phasecma') = 'UI properties';
    DictViewHeadings('cmapcurrent') = 'UI properties';
    DictViewHeadings('cmapcurmodeclip') = 'UI properties';
    DictViewHeadings('cmapcurnumgrays') = 'UI properties';
    DictViewHeadings('cmapcurnumcolors') = 'UI properties';
    DictViewHeadings('flipud') = 'UI properties';
    DictViewHeadings('addmesh') = 'Mesh-related properties';
    DictViewHeadings('ampclip') = 'UI properties';
    DictViewHeadings('anatinitialize') = 'Anatomy / Underlay-related properties';
    DictViewHeadings('cbarrange') = 'UI properties';
    DictViewHeadings('colorbarhandle') = 'UI properties';
    DictViewHeadings('deletemesh') = 'Mesh-related properties';
    DictViewHeadings('initdisplaymodes') = 'UI properties';
    DictViewHeadings('leftclassfile') = 'Volume/Gray-related properties';
    DictViewHeadings('leftgrayfile') = 'Volume/Gray-related properties';
    DictViewHeadings('mainaxishandle') = 'UI properties';
    DictViewHeadings('refreshfn') = 'UI properties';
    DictViewHeadings('rightclassfile') = 'Volume/Gray-related properties';
    DictViewHeadings('rightgrayfile') = 'Volume/Gray-related properties';
    DictViewHeadings('roi') = 'ROI-related properties';
    DictViewHeadings('roioptions') = 'ROI-related properties';
    DictViewHeadings('spatialgrad') = 'Traveling-Wave / Coherence Analysis properties';
    DictViewHeadings('uiimage') = 'UI properties';

    
end %if

if DictViewHeadings.isKey(paramIn)
    res = DictViewHeadings(paramIn);
else
    error('Dict:ViewHeadingsError', 'The input %s does not appear to be in the dictionary', paramIn);
    res = [];
end %if

return