function splitParam = viewMapParameterSplit(paramIn)
% Get data from various view structures
%
%   val = viewMapParameterSplit(param)
%
% Reads the parameters of a view struct.
% Access to these structures should go through this routine and through

global DictViewSplit;

if isempty(DictViewSplit)
    
    DictViewSplit = containers.Map;
    
    DictViewSplit('anatclip') =  'anatomy';
    DictViewSplit('anatinitialize') =  'anatomy';
    DictViewSplit('anatomy') =  'anatomy';
    DictViewSplit('anatomycurrentslice') = 'anatomy';
    DictViewSplit('anatomymap') =  'anatomy';
    DictViewSplit('anatomynifti') =  'anatomy';
    DictViewSplit('inplaneorientation') =  'anatomy';
    DictViewSplit('anatsize') =  'anatomy';
    DictViewSplit('anatsizexyz') =  'anatomy';
    DictViewSplit('anatslicedim') =  'anatomy';
    DictViewSplit('anatslicedims') =  'anatomy';
    DictViewSplit('b0angle') =  'anatomy';
    DictViewSplit('b0dir') =  'anatomy';
    DictViewSplit('brightness') =  'anatomy';
    DictViewSplit('contrast') =  'anatomy';
    DictViewSplit('inplanepath') =  'anatomy';
    DictViewSplit('mmpervolvox') =  'anatomy';
    DictViewSplit('mmpervox') =  'anatomy';
    DictViewSplit('ngraylayers') =  'anatomy';
    DictViewSplit('scannerxform') =  'anatomy';
    DictViewSplit('cmap') =  'colorbar';
    DictViewSplit('cmapcolor') =  'colorbar';
    DictViewSplit('cmapgrayscale') =  'colorbar';
    DictViewSplit('cmapmode') =  'colorbar';
    DictViewSplit('twparams') =  'colorbar';
    DictViewSplit('analysisdomain') =  'em';
    DictViewSplit('datavalindex') =  'em';
    DictViewSplit('fliplr') =  'flat';
    DictViewSplit('graycoords') =  'flat';
    DictViewSplit('hemifromcoords') =  'flat';
    DictViewSplit('imagerotation') =  'flat';
    DictViewSplit('leftpath') =  'flat';
    DictViewSplit('rightpath') =  'flat';
    DictViewSplit('roihemi') =  'flat';
    DictViewSplit('map') =  'map';
    DictViewSplit('mapclip') =  'map';
    DictViewSplit('mapname') =  'map';
    DictViewSplit('mapunits') =  'map';
    DictViewSplit('mapwin') =  'map';
    DictViewSplit('scanmap') =  'map';
    DictViewSplit('addmesh') =  'mesh';
    DictViewSplit('allmeshes') =  'mesh';
    DictViewSplit('allmeshids') =  'mesh';
    DictViewSplit('currentmesh') =  'mesh';
    DictViewSplit('deletemesh') =  'mesh';
    DictViewSplit('leftclassfile') =  'mesh';
    DictViewSplit('leftgrayfile') =  'mesh';
    DictViewSplit('mesh') =  'mesh';
    DictViewSplit('meshdata') =  'mesh';
    DictViewSplit('meshdir') =  'mesh';
    DictViewSplit('meshn') =  'mesh';
    DictViewSplit('meshnames') =  'mesh';
    DictViewSplit('nmesh') =  'mesh';
    DictViewSplit('recomputev2gmap') =  'mesh';
    DictViewSplit('rightclassfile') =  'mesh';
    DictViewSplit('rightgrayfile') =  'mesh';
    DictViewSplit('rmcurrent') =  'retinotopy';
    DictViewSplit('rmfile') =  'retinotopy';
    DictViewSplit('rmhrf') =  'retinotopy';
    DictViewSplit('rmmodel') =  'retinotopy';
    DictViewSplit('rmmodelnames') =  'retinotopy';
    DictViewSplit('rmmodelnum') =  'retinotopy';
    DictViewSplit('rmparams') =  'retinotopy';
    DictViewSplit('rmstimparams') =  'retinotopy';
    DictViewSplit('allroinames') =  'roi';
    DictViewSplit('filledperimeter') =  'roi';
    DictViewSplit('hidevolumerois') =  'roi';
    DictViewSplit('maskrois') =  'roi';
    DictViewSplit('nrois') =  'roi';
    DictViewSplit('prevcoords') =  'roi';
    DictViewSplit('roi') =  'roi';
    DictViewSplit('roicoords') =  'roi';
    DictViewSplit('roidrawmethod') =  'roi';
    DictViewSplit('roiindices') =  'roi';
    DictViewSplit('roimodified') =  'roi';
    DictViewSplit('roiname') =  'roi';
    DictViewSplit('roicomments') =  'roi';    
    DictViewSplit('roioptions') =  'roi';
    DictViewSplit('rois') =  'roi';
    DictViewSplit('roistodisplay') =  'roi';
    DictViewSplit('roistruct') =  'roi';
    DictViewSplit('roivertinds') =  'roi';
    DictViewSplit('selectedroi') =  'roi';
    DictViewSplit('selroicolor') =  'roi';
    DictViewSplit('showrois') =  'roi';
    DictViewSplit('annotation') =  'session';
    DictViewSplit('annotations') =  'session';
    DictViewSplit('curdt') =  'session';
    DictViewSplit('curscan') =  'session';
    DictViewSplit('curslice') =  'session';
    DictViewSplit('dtname') =  'session';
    DictViewSplit('dtstruct') =  'session';
    DictViewSplit('homedir') =  'session';
    DictViewSplit('montageslices') =  'session';
    DictViewSplit('name') =  'session';
    DictViewSplit('nscans') =  'session';
    DictViewSplit('nslices') =  'session';
    DictViewSplit('refreshfn') = 'session';
    DictViewSplit('sessionname') =  'session';
    DictViewSplit('size')   =  'session';
    DictViewSplit('subdir') =  'session';
    DictViewSplit('subject') =  'session';
    DictViewSplit('viewtype') =  'session';
    DictViewSplit('datasize') =  'timeseries';
    DictViewSplit('dim') =  'timeseries';
    DictViewSplit('functionalslicedim') = 'timeseries';
    DictViewSplit('nframes') =  'timeseries';
    DictViewSplit('tr') =  'timeseries';
    DictViewSplit('tseries') =  'timeseries';
    DictViewSplit('tseriesdir') =  'timeseries';
    DictViewSplit('tseriesscan') =  'timeseries';
    DictViewSplit('tseriesslice') =  'timeseries';
    DictViewSplit('ampclip') =  'travelingwave';
    DictViewSplit('amplitude') =  'travelingwave';
    DictViewSplit('ampmap') =  'travelingwave';
    DictViewSplit('coherence') =  'travelingwave';
    DictViewSplit('coherencemap') =  'travelingwave';
    DictViewSplit('correlationmap') =  'travelingwave';
    DictViewSplit('cothresh') =  'travelingwave';
    DictViewSplit('phase') =  'travelingwave';
    DictViewSplit('phwin') =  'travelingwave';
    DictViewSplit('refph') =  'travelingwave';
    DictViewSplit('scanamp') =  'travelingwave';
    DictViewSplit('scanco') =  'travelingwave';
    DictViewSplit('scanph') =  'travelingwave';
    DictViewSplit('spatialgrad') =  'travelingwave';
    DictViewSplit('framestouse') =  'travelingwave';
    DictViewSplit('ncycles') =  'travelingwave';    
    DictViewSplit('amplitudemode') =  'ui';
    DictViewSplit('anatomymode') =  'ui';
    DictViewSplit('cbarrange') = 'ui';
    DictViewSplit('colorbarhandle') = 'ui';
    DictViewSplit('cmapcurmodeclip') =  'ui';
    DictViewSplit('cmapcurnumcolors') =  'ui';
    DictViewSplit('cmapcurnumgrays') =  'ui';
    DictViewSplit('cmapcurrent') =  'ui';
    DictViewSplit('coherencemode') =  'ui';
    DictViewSplit('correlationmode') =  'ui';
    DictViewSplit('crosshairs') =  'ui';
    DictViewSplit('displaymode') =  'ui';
    DictViewSplit('fignum') =  'ui';
    DictViewSplit('flipud') =  'ui';
    DictViewSplit('initdisplaymodes') =  'ui';
    DictViewSplit('ishidden') =  'ui';
    DictViewSplit('locs') =  'ui';
    DictViewSplit('mapmode') =  'ui';
    DictViewSplit('mainaxishandle') = 'ui';
    DictViewSplit('phasecma') =  'ui';
    DictViewSplit('phasemode') =  'ui';
    DictViewSplit('projectedamplitudemode') =  'ui';
    DictViewSplit('ui') =  'ui';
    DictViewSplit('uiimage') = 'ui';
    DictViewSplit('windowhandle') =  'ui';
    DictViewSplit('zoom') =  'ui';
    DictViewSplit('allcoords') =  'volume';
    DictViewSplit('allleftedges') =  'volume';
    DictViewSplit('allleftnodes') =  'volume';
    DictViewSplit('allrightedges') =  'volume';
    DictViewSplit('allrightnodes') =  'volume';
    DictViewSplit('classdata') =  'volume';
    DictViewSplit('classfilename') =  'volume';
    DictViewSplit('coords') =  'volume';
    DictViewSplit('coordsfilename') =  'volume';
    DictViewSplit('edges') =  'volume';
    DictViewSplit('graymatterfilename') =  'volume';
    DictViewSplit('ncoords') =  'volume';
    DictViewSplit('nedges') =  'volume';
    DictViewSplit('nnodes') =  'volume';
    DictViewSplit('nodegraylevel') =  'volume';
    DictViewSplit('nodes') =  'volume';
    DictViewSplit('xyznodes') =  'volume';
    
end %if

if DictViewSplit.isKey(paramIn)
    splitParam = DictViewSplit(paramIn);
else
    error('Dict:ViewSplitError', 'The input %s does not appear to be in the split dictionary.', paramIn);
end



return