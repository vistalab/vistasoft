function res = viewMapParameterField(paramIn, specialFunctionFlag, paramInSpecial)
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

global DictViewTranslate;

if isempty(DictViewTranslate)
    
    DictViewTranslate = containers.Map;
    
    DictViewTranslate('homedir') = 'homedir';
    DictViewTranslate('homedirectory') = 'homedir';
    DictViewTranslate('sessiondirectory') = 'homedir';
    DictViewTranslate('name') = 'name';
    DictViewTranslate('viewname') = 'name';
    DictViewTranslate('sessionname') = 'sessionname';
    DictViewTranslate('sessioncode') = 'sessionname';
    DictViewTranslate('viewtype') = 'viewtype';
    DictViewTranslate('type') = 'viewtype';
    DictViewTranslate('subject') = 'subject';
    DictViewTranslate('scansubject') = 'subject';
    DictViewTranslate('subdir') = 'subdir';
    DictViewTranslate('subdirectory') = 'subdir';
    DictViewTranslate('annotation') = 'annotation';
    DictViewTranslate('scandescription') = 'annotation';
    DictViewTranslate('annotations') = 'annotations';
    DictViewTranslate('allscandescriptions') = 'annotations';
    DictViewTranslate('curslice') = 'curslice';
    DictViewTranslate('currentslice') = 'curslice';
    DictViewTranslate('currentslicenumber') = 'curslice';
    DictViewTranslate('curscan') = 'curscan';
    DictViewTranslate('currentscan') = 'curscan';
    DictViewTranslate('currentscannumber') = 'curscan';
    DictViewTranslate('datavalindex') = 'datavalindex';
    DictViewTranslate('analysisdomain') = 'analysisdomain';
    DictViewTranslate('nscans') = 'nscans';
    DictViewTranslate('numscans') = 'nscans';
    DictViewTranslate('nscan') = 'nscans';
    DictViewTranslate('numberofscans') = 'nscans';
    DictViewTranslate('numberscans') = 'nscans';
    DictViewTranslate('nslices') = 'nslices';
    DictViewTranslate('numslices') = 'nslices';
    DictViewTranslate('numberofslices') = 'nslices';
    DictViewTranslate('numberslices') = 'nslices';
    DictViewTranslate('montageslices') = 'montageslices';
    DictViewTranslate('curdt') = 'curdt';
    DictViewTranslate('currentdatatype') = 'curdt';
    DictViewTranslate('curdatatype') = 'curdt';
    DictViewTranslate('datatypenumber') = 'curdt';
    DictViewTranslate('currentdt') = 'curdt';
    DictViewTranslate('dtnum') = 'curdt';
    DictViewTranslate('dtnumber') = 'curdt';
    DictViewTranslate('datatypenum') = 'curdt';
    DictViewTranslate('selecteddatatype') = 'curdt';
    DictViewTranslate('dtname') = 'dtname';
    DictViewTranslate('datatypename') = 'dtname';
    DictViewTranslate('datatype') = 'dtname';
    DictViewTranslate('dtstruct') = 'dtstruct';
    DictViewTranslate('currentdatatypestructure') = 'dtstruct';
    DictViewTranslate('curdtstruct') = 'dtstruct';
    DictViewTranslate('refreshfn') = 'refreshfn';
    DictViewTranslate('refreshfunction') = 'refreshfn';
    DictViewTranslate('reffn') = 'refreshfn';
    DictViewTranslate('reffunction') = 'refreshfn';
    DictViewTranslate('coherence') = 'coherence';
    DictViewTranslate('co') = 'coherence';
    DictViewTranslate('allcoherence') = 'coherence';
    DictViewTranslate('scanco') = 'scanco';
    DictViewTranslate('scancoherence') = 'scanco';
    DictViewTranslate('coherencen') = 'scanco';
    DictViewTranslate('coscan') = 'scanco';
    DictViewTranslate('phase') = 'phase';
    DictViewTranslate('ph') = 'phase';
    DictViewTranslate('allphase') = 'phase';
    DictViewTranslate('scanph') = 'scanph';
    DictViewTranslate('scanphase') = 'scanph';
    DictViewTranslate('phasen') = 'scanph';
    DictViewTranslate('amplitude') = 'amplitude';
    DictViewTranslate('amp') = 'amplitude';
    DictViewTranslate('allamp') = 'amplitude';
    DictViewTranslate('scanamp') = 'scanamp';
    DictViewTranslate('scanamplitude') = 'scanamp';
    DictViewTranslate('ampn') = 'scanamp';
    DictViewTranslate('ampscan') = 'scanamp';
    DictViewTranslate('phwin') = 'phwin';
    DictViewTranslate('phasewin') = 'phwin';
    DictViewTranslate('phwindow') = 'phwin';
    DictViewTranslate('phasewindow') = 'phwin';
    DictViewTranslate('cothresh') = 'cothresh';
    DictViewTranslate('mincoherence') = 'cothresh';
    DictViewTranslate('coherencethreshold') = 'cothresh';
    DictViewTranslate('refph') = 'refph';
    DictViewTranslate('refphase') = 'refph';
    DictViewTranslate('referenceph') = 'refph';
    DictViewTranslate('referencephase') = 'refph';
    DictViewTranslate('ampclip') = 'ampclip';
    DictViewTranslate('ampclipmode') = 'ampclip';
    DictViewTranslate('ampclim') = 'ampclip';
    DictViewTranslate('twparams') = 'twparams';
    DictViewTranslate('travelingwaveparams') = 'twparams';
    DictViewTranslate('cbarparams') = 'twparams';
    DictViewTranslate('travellingwaveparameters') = 'twparams';
    DictViewTranslate('map') = 'map';
    DictViewTranslate('statisticalmap') = 'map';
    DictViewTranslate('smap') = 'map';
    DictViewTranslate('allmap') = 'map';
    DictViewTranslate('parmap') = 'map';
    DictViewTranslate('parametermap') = 'map';
    DictViewTranslate('mapname') = 'mapname';
    DictViewTranslate('mapunits') = 'mapunits';
    DictViewTranslate('mapclip') = 'mapclip';
    DictViewTranslate('mapclipmode') = 'mapclip';
    DictViewTranslate('mapclim') = 'mapclip';
    DictViewTranslate('mapwin') = 'mapwin';
    DictViewTranslate('mapwindow') = 'mapwin';
    DictViewTranslate('statmapwindow') = 'mapwin';
    DictViewTranslate('scanmap') = 'scanmap';
    DictViewTranslate('scanstatisticalamplitude') = 'scanmap';
    DictViewTranslate('mapn') = 'scanmap';
    DictViewTranslate('smapn') = 'scanmap';
    DictViewTranslate('scanstatisticalmap') = 'scanmap';
    DictViewTranslate('mapscan') = 'scanmap';
    DictViewTranslate('brightness') = 'brightness';
    DictViewTranslate('bright') = 'brightness';
    DictViewTranslate('anatomy') = 'anatomy';
    DictViewTranslate('anat') = 'anatomy';
    DictViewTranslate('anatomydata') = 'anatomy';
    DictViewTranslate('anatdata') = 'anatomy';
    DictViewTranslate('contrast') = 'contrast';
    DictViewTranslate('anatclip') = 'anatclip';
    DictViewTranslate('anatwin') = 'anatclip';
    DictViewTranslate('anatomyclip') = 'anatclip';
    DictViewTranslate('anatsize') = 'anatsize';
    DictViewTranslate('anatomysize') = 'anatsize';
    DictViewTranslate('sizeanatomy') = 'anatsize';
    DictViewTranslate('anatomynifti') = 'anatomynifti';
    DictViewTranslate('anatnifti') = 'anatomynifti';
    DictViewTranslate('niftianat') = 'anatomynifti';
    DictViewTranslate('niftianatomy') = 'anatomynifti';
    DictViewTranslate('inplaneorientation') = 'inplaneorientation';    
    DictViewTranslate('anatsizexyz') = 'anatsizexyz';
    DictViewTranslate('anatomysizeforclass') = 'anatsizexyz';
    DictViewTranslate('ngraylayers') = 'ngraylayers';
    DictViewTranslate('numgraylayers') = 'ngraylayers';
    DictViewTranslate('numbergraylayers') = 'ngraylayers';
    DictViewTranslate('b0dir') = 'b0dir';
    DictViewTranslate('b0direction') = 'b0dir';
    DictViewTranslate('zdirection') = 'b0dir';
    DictViewTranslate('zdir') = 'b0dir';
    DictViewTranslate('b0axis') = 'b0dir';
    DictViewTranslate('b0') = 'b0dir';
    DictViewTranslate('b0angle') = 'b0angle';
    DictViewTranslate('b0degrees') = 'b0angle';
    DictViewTranslate('roi') = 'roi';
    DictViewTranslate('rois') = 'rois';
    DictViewTranslate('allrois') = 'rois';
    DictViewTranslate('regionsofinterest') = 'rois';
    DictViewTranslate('selectedroi') = 'selectedroi';
    DictViewTranslate('currentroi') = 'selectedroi';
    DictViewTranslate('curroi') = 'selectedroi';
    DictViewTranslate('roistruct') = 'roistruct';
    DictViewTranslate('roioptions') = 'roioptions';
    DictViewTranslate('roiprefs') = 'roioptions';
    DictViewTranslate('roiopts') = 'roioptions';
    DictViewTranslate('nrois') = 'nrois';
    DictViewTranslate('numrois') = 'nrois';
    DictViewTranslate('numberrois') = 'nrois';
    DictViewTranslate('numberofrois') = 'nrois';
    DictViewTranslate('filledperimeter') = 'filledperimeter';
    DictViewTranslate('filledperimeterstate') = 'filledperimeter';
    DictViewTranslate('maskrois') = 'maskrois';
    DictViewTranslate('maskroi') = 'maskrois';
    DictViewTranslate('roimask') = 'maskrois';
    DictViewTranslate('roimasks') = 'maskrois';
    DictViewTranslate('showroisonmesh') = 'maskrois';
    DictViewTranslate('roivertinds') = 'roivertinds';
    DictViewTranslate('roivertexinds') = 'roivertinds';
    DictViewTranslate('roivertexindices') = 'roivertinds';
    DictViewTranslate('roivertindices') = 'roivertinds';
    DictViewTranslate('showrois') = 'showrois';
	DictViewTranslate('hidevolumerois') = 'hidevolumerois';
    DictViewTranslate('hidegrayrois') = 'hidevolumerois';
    DictViewTranslate('roidrawmethod') = 'roidrawmethod';
    DictViewTranslate('roimethod') = 'roidrawmethod';
    DictViewTranslate('roidraw') = 'roidrawmethod';
    DictViewTranslate('roiname') = 'roiname';
    DictViewTranslate('allroinames') = 'allroinames';
    DictViewTranslate('roinames') = 'allroinames';
    DictViewTranslate('roicoords') = 'roicoords';
    DictViewTranslate('roicoordinates') = 'roicoords';
    DictViewTranslate('roigrayindices') = 'roiindices';
    DictViewTranslate('roiindices') = 'roiindices';
    DictViewTranslate('roiinds') = 'roiindices';
    DictViewTranslate('selroicolor') = 'selroicolor';
    DictViewTranslate('roicolor') = 'selroicolor';
    DictViewTranslate('selectedroicolor') = 'selroicolor';
    DictViewTranslate('roimodified') = 'roimodified';
    DictViewTranslate('roidatemodified') = 'roimodified';
    DictViewTranslate('roimodificationdate') = 'roimodified';
    DictViewTranslate('roicomments') = 'roicomments';    
    DictViewTranslate('prevcoords') = 'prevcoords';
    DictViewTranslate('previouscoordinates') = 'prevcoords';
    DictViewTranslate('previouscoords') = 'prevcoords';
    DictViewTranslate('roistodisplay') = 'roistodisplay';
    DictViewTranslate('roilist') = 'roistodisplay';
    DictViewTranslate('tseries') = 'tseries';
    DictViewTranslate('timeseries') = 'tseries';
    DictViewTranslate('tseriesslice') = 'tseriesslice';
    DictViewTranslate('slicetseries') = 'tseriesslice';
    DictViewTranslate('timeseriesslice') = 'tseriesslice';
    DictViewTranslate('slicetimeseries') = 'tseriesslice';
    DictViewTranslate('tseriesscan') = 'tseriesscan';
    DictViewTranslate('tseriescan') = 'tseriesscan';
    DictViewTranslate('scantseries') = 'tseriesscan';
    DictViewTranslate('timeseriesscan') = 'tseriesscan';
    DictViewTranslate('scantimeseries') = 'tseriesscan';
    DictViewTranslate('datasize') = 'datasize';
    DictViewTranslate('mapsize') = 'datasize';
    DictViewTranslate('functionalsize') = 'datasize';
    DictViewTranslate('funcsize') = 'datasize';
    DictViewTranslate('dim') = 'dim';
    DictViewTranslate('dims') = 'dim';
    DictViewTranslate('functionalslicedim') = 'functionalslicedim';
    DictViewTranslate('functionalslicedims') = 'functionalslicedim';
    DictViewTranslate('slicedim') = 'functionalslicedim';
    DictViewTranslate('slicedims') = 'functionalslicedim';
    DictViewTranslate('slicedimension') = 'functionalslicedim';
    DictViewTranslate('slicedimensions') = 'functionalslicedim';
    DictViewTranslate('tr') = 'tr';
    DictViewTranslate('frameperiod') = 'tr';
    DictViewTranslate('framerate') = 'tr';
    DictViewTranslate('repeattime') = 'tr';
    DictViewTranslate('timetorepeat') = 'tr';
    DictViewTranslate('nframes') = 'nframes';
    DictViewTranslate('numframes') = 'nframes';
    DictViewTranslate('numberoftimeframes') = 'nframes';
    DictViewTranslate('ncycles') = 'ncycles';
    DictViewTranslate('numcycles') = 'ncycles';
    DictViewTranslate('numberofcycles') = 'ncycles';
    DictViewTranslate('framestouse') = 'framestouse';
    DictViewTranslate('framesblockdesign') = 'framestouse';
    DictViewTranslate('framescoranal') = 'framestouse';
    DictViewTranslate('rmfile') = 'rmfile';
    DictViewTranslate('retinotopymodelfile') = 'rmfile';
    DictViewTranslate('rmmodel') = 'rmmodel';
    DictViewTranslate('retinotopymodel') = 'rmmodel';
    DictViewTranslate('rmparams') = 'rmparams';
    DictViewTranslate('retinotopyparameters') = 'rmparams';
    DictViewTranslate('retinotopymodelparams') = 'rmparams';
    DictViewTranslate('rmstimparams') = 'rmstimparams';
    DictViewTranslate('retinotopystimulusparameters') = 'rmstimparams';
    DictViewTranslate('rmstimulusparameters') = 'rmstimparams';
    DictViewTranslate('rmmodelnum') = 'rmmodelnum';
    DictViewTranslate('rmmodelid') = 'rmmodelnum';
    DictViewTranslate('selectedretinotopymodel') = 'rmmodelnum';
    DictViewTranslate('retinotopymodelnumber') = 'rmmodelnum';
    DictViewTranslate('rmcurrent') = 'rmcurrent';
    DictViewTranslate('rmcurmodel') = 'rmcurrent';
    DictViewTranslate('rmselectedmodel') = 'rmcurrent';
    DictViewTranslate('rmcurrentmodel') = 'rmcurrent';
    DictViewTranslate('rmmodelnames') = 'rmmodelnames';
    DictViewTranslate('retinotopymodelnames') = 'rmmodelnames';
    DictViewTranslate('rmhrf') = 'rmhrf';
    DictViewTranslate('rmhemodynamicresponsefunction') = 'rmhrf';
    DictViewTranslate('retinotopymodelhrf') = 'rmhrf';
    DictViewTranslate('retinotopymodelhemodynamicresponsefunction') = 'rmhrf';
    DictViewTranslate('classfilename') = 'classfilename';
    DictViewTranslate('classfile') = 'classfilename';
    DictViewTranslate('classpath') = 'classfilename';
    DictViewTranslate('classdata') = 'classdata';
    DictViewTranslate('leftclassfile') = 'leftclassfile';
    DictViewTranslate('leftclassfilename') = 'leftclassfile';
    DictViewTranslate('rightclassfile') = 'rightclassfile';
    DictViewTranslate('rightclassfilename') = 'rightclassfile';
	DictViewTranslate('classdata') = 'classdata';
	DictViewTranslate('leftgrayfile') = 'leftgrayfile';
    DictViewTranslate('leftgrayfilename') = 'leftgrayfile';
    DictViewTranslate('leftpath') = 'leftgrayfile';
    DictViewTranslate('flatleftpath') = 'leftgrayfile';
    DictViewTranslate('rightgrayfile') = 'rightgrayfile';
    DictViewTranslate('rightgrayfilename') = 'rightgrayfile';
    DictViewTranslate('rightpath') = 'rightgrayfile';
    DictViewTranslate('flatrightpath') = 'rightgrayfile';
    DictViewTranslate('mesh') = 'mesh';
    DictViewTranslate('replacemesh') = 'mesh';
    DictViewTranslate('currentmesh') = 'currentmesh';
    DictViewTranslate('curmesh') = 'currentmesh';
    DictViewTranslate('selectedmesh') = 'currentmesh';
    DictViewTranslate('allmeshes') = 'allmeshes';
    DictViewTranslate('meshlist') = 'allmeshes';
    DictViewTranslate('allmesh') = 'allmeshes';
    DictViewTranslate('allmeshids') = 'allmeshids';
    DictViewTranslate('allwindowids') = 'allmeshids';
    DictViewTranslate('allmeshid') = 'allmeshids';
    DictViewTranslate('allwindowid') = 'allmeshids';
    DictViewTranslate('addmesh') = 'addmesh';
    DictViewTranslate('addandselectmesh') = 'addmesh';
    DictViewTranslate('meshdata') = 'meshdata';
    DictViewTranslate('currentmeshdata') = 'meshdata';
    DictViewTranslate('selectedmeshdata') = 'meshdata';
    DictViewTranslate('meshn') = 'meshn';
    DictViewTranslate('meshnum') = 'meshn';
    DictViewTranslate('meshnumber') = 'meshn';    
    DictViewTranslate('currentmeshn') = 'meshn';
    DictViewTranslate('currentmeshnum') = 'meshn';    
    DictViewTranslate('currentmeshnumber') = 'meshn';        
    DictViewTranslate('setcurrentmeshn') = 'meshn';
    DictViewTranslate('curmeshnum') = 'meshn';
    DictViewTranslate('curmeshn') = 'meshn';
    DictViewTranslate('currentmeshnumber') = 'meshn';
    DictViewTranslate('selectedmeshn') = 'meshn';
    DictViewTranslate('selmeshn') = 'meshn';
    DictViewTranslate('nmesh') = 'nmesh';
    DictViewTranslate('numberofmeshes') = 'nmesh';
    DictViewTranslate('nummeshes') = 'nmesh';
    DictViewTranslate('numbermeshes') = 'nmesh';
    DictViewTranslate('nmeshes') = 'nmesh';
    DictViewTranslate('deletemesh') = 'deletemesh';
    DictViewTranslate('removemesh') = 'deletemesh';
    DictViewTranslate('meshnames') = 'meshnames';
    DictViewTranslate('namesofmeshes') = 'meshnames';
    DictViewTranslate('nameofmeshes') = 'meshnames';
    DictViewTranslate('meshdir') = 'meshdir';
    DictViewTranslate('meshdirectory') = 'meshdir';
    DictViewTranslate('nodes') = 'nodes';
    DictViewTranslate('nodegraylevel') = 'nodegraylevel';
    DictViewTranslate('nodesgraylevel') = 'nodegraylevel';
    DictViewTranslate('graylevel') = 'nodegraylevel';
    DictViewTranslate('nnodes') = 'nnodes';
    DictViewTranslate('numberofnodes') = 'nnodes';
    DictViewTranslate('edges') = 'edges';
    DictViewTranslate('nedges') = 'nedges';
    DictViewTranslate('numberofedges') = 'nedges';
    DictViewTranslate('allcoords') = 'allcoords';
    DictViewTranslate('allleftnodes') = 'allleftnodes';
    DictViewTranslate('allleftedges') = 'allleftedges';
    DictViewTranslate('allrightnodes') = 'allrightnodes';
    DictViewTranslate('allrightedges') = 'allrightedges';
    DictViewTranslate('coords') = 'coords';
    DictViewTranslate('coordsfilename') = 'coordsfilename';
    DictViewTranslate('coordsfile') = 'coordsfilename';
    DictViewTranslate('graycoordsfile') = 'coordsfilename';
    DictViewTranslate('graycoordsfilename') = 'coordsfilename';
    DictViewTranslate('ncoords') = 'ncoords';
    DictViewTranslate('numberofcoordinates') = 'ncoords';
    DictViewTranslate('numbergraycoords') = 'ncoords';
    DictViewTranslate('numberofcoords') = 'ncoords';
    DictViewTranslate('scannerxform') = 'scannerxform';
    DictViewTranslate('scannertransform') = 'scannerxform';
    DictViewTranslate('mmpervox') = 'mmpervox';
    DictViewTranslate('mmpervoxel') = 'mmpervox';
    DictViewTranslate('voxsize') = 'mmpervox';
    DictViewTranslate('voxelsize') = 'mmpervox';
    DictViewTranslate('mmperpix') = 'mmpervox';
    DictViewTranslate('pixsize') = 'mmpervox';
    DictViewTranslate('mmpervolvox') = 'mmpervolvox';
    DictViewTranslate('mmpergrayvox') = 'mmpervolvox';
    DictViewTranslate('mmpervoxvolume') = 'mmpervolvox';
    DictViewTranslate('mmpervoxgray') = 'mmpervolvox';
    DictViewTranslate('grayvoxelsize') = 'mmpervolvox';
    DictViewTranslate('volumevoxelsize') = 'mmpervolvox';
    DictViewTranslate('volvoxelsize') = 'mmpervolvox';
    DictViewTranslate('volvoxsize') = 'mmpervolvox';
    DictViewTranslate('grayvoxsize') = 'mmpervolvox';
    DictViewTranslate('flip') = 'fliplr';
    DictViewTranslate('fliplr') = 'fliplr';
    DictViewTranslate('imagerotation') = 'imagerotation';
    DictViewTranslate('rotateimagedegrees') = 'imagerotation';
    DictViewTranslate('hemifromcoords') = 'hemifromcoords';
    DictViewTranslate('hemi') = 'hemifromcoords';
    DictViewTranslate('hemifield') = 'hemifromcoords';
    DictViewTranslate('roihemi') = 'roihemi';
    DictViewTranslate('hemiroi') = 'roihemi';
    DictViewTranslate('roihemifield') = 'roihemi';
    DictViewTranslate('initdisplaymodes') = 'initdisplaymodes';
    DictViewTranslate('resetdisplaymodes') = 'initdisplaymodes';
    DictViewTranslate('ui') = 'ui';
    DictViewTranslate('cmapcurrent') = 'cmapcurrent';    
    DictViewTranslate('userinterface') = 'ui';
    DictViewTranslate('fignum') = 'fignum';
    DictViewTranslate('figurenumber') = 'fignum';
    DictViewTranslate('windowhandle') = 'windowhandle';
    DictViewTranslate('mainaxishandle') = 'mainaxishandle';
    DictViewTranslate('colorbarhandle') = 'colorbarhandle';
    DictViewTranslate('colorbarrange') = 'cbarrange';
    DictViewTranslate('cbarrange') = 'cbarrange';
    DictViewTranslate('anatomymode') = 'anatomymode';
    DictViewTranslate('anatmode') = 'anatomymode';
    DictViewTranslate('uiimage') = 'uiimage';
    DictViewTranslate('imageui') = 'uiimage';
    DictViewTranslate('coherencemode') = 'coherencemode';
    DictViewTranslate('comode') = 'coherencemode';
    DictViewTranslate('correlationmode') = 'correlationmode';
    DictViewTranslate('cormode') = 'correlationmode';
    DictViewTranslate('phasemode') = 'phasemode';
    DictViewTranslate('phmode') = 'phasemode';
    DictViewTranslate('amplitudemode') = 'amplitudemode';
    DictViewTranslate('ampmode') = 'amplitudemode';
    DictViewTranslate('projectedamplitudemode') = 'projectedamplitudemode';
    DictViewTranslate('projampmode') = 'projectedamplitudemode';
    DictViewTranslate('mapmode') = 'mapmode';
    DictViewTranslate('parametermapmode') = 'mapmode';
    DictViewTranslate('displaymode') = 'displaymode';
    DictViewTranslate('dispmode') = 'displaymode';
    DictViewTranslate('phasecma') = 'phasecma';
    DictViewTranslate('cmapphase') = 'phasecma';
    DictViewTranslate('phasemap') = 'phasecma';
    DictViewTranslate('phasecolormap') = 'phasecma';
    DictViewTranslate('phcolormap') = 'phasecma';
    DictViewTranslate('cmap') = 'cmap';
    DictViewTranslate('colormap') = 'cmap';
    DictViewTranslate('curmodecmap') = 'cmap';
    DictViewTranslate('curcmap') = 'cmap';
    DictViewTranslate('currentcmap') = 'cmap';
    DictViewTranslate('overlaycmap') = 'cmap';
    DictViewTranslate('cmapmode') = 'cmapmode';
    DictViewTranslate('colormapmode') = 'cmapmode';
    DictViewTranslate('anatomymap') = 'anatomymap';
    DictViewTranslate('anatomycolormap') = 'anatomymap';
    DictViewTranslate('anatmap') = 'anatomymap';
    DictViewTranslate('loc') = 'locs';
    DictViewTranslate('cursor') = 'locs';
    DictViewTranslate('cursorloc') = 'locs';
    DictViewTranslate('cursorposition') = 'locs';
    DictViewTranslate('locs') = 'locs';
    DictViewTranslate('zoom') = 'zoom';
    DictViewTranslate('xhairs') = 'crosshairs';
    DictViewTranslate('showcursor') = 'crosshairs';
    DictViewTranslate('cursoron') = 'crosshairs';
    DictViewTranslate('crosshairs') = 'crosshairs';
    DictViewTranslate('ampmap') = 'ampmap';
    DictViewTranslate('ampcolormap') = 'ampmap';
    DictViewTranslate('amplitudecolormap') = 'ampmap';
    DictViewTranslate('coherencemap') = 'coherencemap';
    DictViewTranslate('coherencecolormap') = 'coherencemap';
    DictViewTranslate('correlationmap') = 'correlationmap';
    DictViewTranslate('correlationcolormap') = 'correlationmap';
    DictViewTranslate('cmapcolor') = 'cmapcolor';
    DictViewTranslate('overlaycolormap') = 'cmapcolor';
    DictViewTranslate('colormapcolor') = 'cmapcolor';
    DictViewTranslate('cmapgrayscale') = 'cmapgrayscale';
    DictViewTranslate('underlaycolormap') = 'cmapgrayscale';
    DictViewTranslate('underlaycmap') = 'cmapgrayscale';
    DictViewTranslate('colormapgray') = 'cmapgrayscale';
    DictViewTranslate('cmapcurmodeclip') = 'cmapcurmodeclip';
    DictViewTranslate('curmodecmapclip') = 'cmapcurmodeclip';
    DictViewTranslate('cmapcurnumgrays') = 'cmapcurnumgrays';
    DictViewTranslate('curnumgrays') = 'cmapcurnumgrays';
    DictViewTranslate('currentnumberofgrays') = 'cmapcurnumgrays';
    DictViewTranslate('ngrays') = 'cmapcurnumgrays';
    DictViewTranslate('cmapcurnumcolors') = 'cmapcurnumcolors';
    DictViewTranslate('curnumcolors') = 'cmapcurnumcolors';
    DictViewTranslate('currentnumberofcolors') = 'cmapcurnumcolors';
    DictViewTranslate('ncolors') = 'cmapcurnumcolors';
    DictViewTranslate('flipud') = 'flipud';
    DictViewTranslate('flipupdown') = 'flipud';
    DictViewTranslate('flipup/down') = 'flipud';
    DictViewTranslate('flipvertical') = 'flipud';
    DictViewTranslate('verticalflip') = 'flipud';
    DictViewTranslate('ishidden') = 'ishidden';
    DictViewTranslate('hidden') = 'ishidden';
    DictViewTranslate('anatinitialize') = 'anatinitialize';
    DictViewTranslate('anatomyinitialize') = 'anatinitialize';
    DictViewTranslate('anatinit') = 'anatinitialize';
    DictViewTranslate('anatomyinit') = 'anatinitialize';
    DictViewTranslate('spatialgrad') = 'spatialgrad';
    DictViewTranslate('spatialgradient') = 'spatialgrad';
    DictViewTranslate('anatomycurrentslice') = 'anatomycurrentslice';
    DictViewTranslate('anatomyslicedimensions') = 'anatslicedim';
    DictViewTranslate('anatomyslicedims') = 'anatslicedims';
    DictViewTranslate('anatslicedims') = 'anatslicedims';
    DictViewTranslate('anatslicedim') = 'anatslicedim';
    DictViewTranslate('anatomyslicedim') = 'anatslicedim';
    DictViewTranslate('anatomyslicedimension') = 'anatslicedim';
    DictViewTranslate('tseriesdir') = 'tseriesdir';
    DictViewTranslate('tseriesdirectory') = 'tseriesdir';
    DictViewTranslate('graycoords') = 'graycoords';
    DictViewTranslate('size')           = 'size';
    
end %if

if specialFunctionFlag
    if strcmp(paramIn,'list')
        allVals = unique(values(DictViewTranslate));
        numVals = numel(allVals);
        display('The list of possible keys, in alphabetical order is: ')
        for i = 1:numVals
            display(allVals{i});
        end %for
    elseif strcmp(paramIn,'help')
        if exist('paramInSpecial','var')
            allVals = cellstr(paramInSpecial);
        else
            allVals = unique(values(DictViewTranslate));
        end %if
        numVals = numel(allVals);
        display('The list keys, with help, in alphabetical order is: ')
        for i = 1:numVals
            display(['<strong>' allVals{i} '</strong>: ' viewHelpParameter(allVals{i})]);
        end %for
    elseif strcmp(paramIn,'type')
        if exist('paramInSpecial','var')
            allVals = cellstr(paramInSpecial);
        else
            allVals = unique(values(DictViewTranslate));
        end %if
        numVals = numel(allVals);
        display('The list keys, with their type, in alphabetical order is: ')
        for i = 1:numVals
            display(['<strong>' allVals{i} '</strong>: ' viewParameterType(viewMapParameterSplit(allVals{i}))]);
        end %for
    end %if    
    
elseif DictViewTranslate.isKey(paramIn)
    res = DictViewTranslate(paramIn);
else
    error('Dict:ViewSplitError', 'The input %s does not appear to be in the dictionary', paramIn);
    res = [];
end

return

