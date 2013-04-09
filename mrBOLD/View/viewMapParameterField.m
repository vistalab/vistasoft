function res = viewMapParameterField(fieldName)
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
%   viewMapParameterField('Current Slice')
%   viewMapParameterField('Current Data Type')

fieldName = mrvParamFormat(fieldName);

%TODO: Replace the below with a hash map, as in sessionMapParameterField

switch fieldName
    
    %%%%% Session-related properties; selected scan, slice, data type
    case {'homedir' 'homedirectory' 'sessiondirectory'}
        res = 'homedir';
    case {'name' 'viewname'}
        res = 'name';
    case {'sessionname' 'sessioncode'}
        res = 'sessionname';
    case {'viewtype' 'type'}
        res = 'viewtype';
    case {'subject' 'scansubject'}
        res = 'subject';
    case {'subdir' 'subdirectory'}
        res = 'subdir';
    case {'viewdir' 'viewdirectory'}
        res = 'viewdir';
    case {'annotation' 'scandescription'}
        res = 'annotation';
    case {'annotations' 'allscandescriptions'}
        res = 'annotations';
    case {'curslice' 'currentslice' 'currentslicenumber'}
        res = 'curslice';
    case {'curscan' 'currentscan' 'currentscannumber'}
        res = 'curscan';
    case {'datavalindex'}
        res = 'datavalindex';
    case {'analysisdomain'}
        res = 'analysisdomain';
    case {'nscans' 'numscans' 'nscan' 'numberofscans' 'numberscans'}
        res = 'nscans';
    case {'nslices' 'numslices' 'numberofslices' 'numberslices'}
        res = 'nslices';
    case {'montageslices'}
        res = 'montageslices';
    case {'curdt' 'currentdatatype' 'curdatatype' 'datatypenumber',...
           'currentdt' 'dtnum' 'dtnumber' 'datatypenum' 'selecteddatatype'}
        res = 'curdt';
    case {'dtname' 'datatypename' 'datatype'}
        res = 'dtname';               
    case {'dtstruct' 'currentdatatypestructure' 'curdtstruct'}
        res = 'dtstruct';
    case {'refreshfn' 'refreshfunction' 'reffn' 'reffunction'}
        res = 'refreshfn';
        %%%%% Traveling-Wave / Coherence Analysis properties
 
    case {'coherence' 'co' 'allcoherence'} 
        res = 'coherence';
    case {'scanco' 'scancoherence' 'coherencen' 'coscan'}
        res = 'scanco';
    case {'phase' 'ph' 'allphase'}
        res = 'phase';
    case {'scanph' 'scanphase' 'phasen'}
        res = 'scanph';
    case {'amplitude' 'amp' 'allamp'}
        res = 'amplitude';
    case {'scanamp' 'scanamplitude' 'ampn' 'ampscan'}
        res = 'scanamp';
    case {'phwin' 'phasewin' 'phwindow' 'phasewindow'}
        res = 'phwin';
    case {'cothresh' 'mincoherence' 'coherencethreshold'}
        res = 'cothresh';
    case {'refph' 'refphase' 'referenceph' 'referencephase'}
        res = 'refph';
    case {'ampclip' 'ampclipmode' 'ampclim'}
        res = 'ampclip';
   case {'twparams' 'travelingwaveparams' 'cbarparams' 'travellingwaveparameters'}
        res = 'twparams';        
 
        %%%%% Map properties
    case {'map' 'statisticalmap' 'smap' 'allmap'}
        res = 'map';
    case {'mapname'}
        res = 'mapname';
    case {'mapunits'}
        res = 'mapunits';
    case {'mapclip' 'mapclipmode' 'mapclim'}
        res = 'mapclip';
    case {'mapwin' 'mapwindow' 'statmapwindow'}
        res = 'mapwin';
    case {'scanmap' 'scanstatisticalamplitude' 'mapn' 'smapn' 'scanstatisticalmap' 'mapscan'}
        res = 'scanmap';
    case {'brightness' 'bright'}
        res = 'brightness';        

        %%%%% Anatomy / Underlay-related properties
    case {'anatomy' 'anat' 'anatomydata' 'anatdata'}
        res = 'anatomy';
    case {'contrast'}
        res = 'contrast';
    case {'anatclip' 'anatwin' 'anatomyclip'}
        res = 'anatclip';
    case {'anatsize' 'anatomysize' 'sizeanatomy'}
        res = 'anatsize';
    case {'anatomynifti','anatnifti','niftianat','niftianatomy'}
        res = 'anatomynifti';
    case {'anatsizexyz' 'anatomysizeforclass'}
        res = 'anatsizexyz';
    case {'ngraylayers' 'numgraylayers' 'numbergraylayers'}
        res = 'ngraylayers';
    case {'b0dir' 'b0direction' 'zdirection' 'zdir' 'b0axis' 'b0'}
        res = 'b0dir';
    case {'b0angle' 'b0degrees'}
        res = 'b0angle';

        %%%%% ROI related properties
    case {'roi'}
        res = 'roi';
    case {'rois' 'allrois' 'regionsofinterest'}
        res = 'rois';
    case {'selectedroi' 'currentroi' 'curroi'}
        res = 'selectedroi';
    case {'roistruct'}
        res = 'roistruct';
    case {'roioptions' 'roiprefs' 'roiopts'}
        res = 'roioptions';
    case {'nrois' 'numrois' 'numberrois'  'numberofrois'}
        res = 'nrois';
    case {'filledperimeter' 'filledperimeterstate'}
        res = 'filledperimeter';
    case {'maskrois' 'maskroi' 'roimask' 'roimasks' 'showroisonmesh'}
        res = 'maskrois';
    case {'roivertinds' 'roivertexinds' 'roivertexindices' 'roivertindices'}
        res = 'roivertinds';
    case 'showrois'
        res = 'showrois';
    case {'hidevolumerois' 'hidegrayrois'}
        res = 'hidevolumerois';
    case {'roidrawmethod'  'roimethod' 'roidraw'}
        res = 'roidrawmethod';
    case {'roiname'}
        res = 'roiname';
    case {'allroinames' 'roinames'}
        res = 'allroinames';
    case {'roicoords' 'roicoordinates'}
        res = 'roicoords';
    case {'roigrayindices' 'roiindices' 'roiinds'}
        res = 'roiindices';
    case {'selroicolor' 'roicolor' 'selectedroicolor'}
        res = 'selroicolor';
    case {'roimodified' 'roidatemodified' 'roimodificationdate'}
        res = 'roimodified';
    case {'prevcoords' 'previouscoordinates' 'previouscoords'}
        res = 'prevcoords';
    case {'roistodisplay' 'roilist'}
        res = 'roistodisplay';        
        
        %%%%% Time-series related properties
    case {'tseries' 'timeseries'}
        res = 'tseries';
    case {'tseriesslice' 'slicetseries' 'timeseriesslice' 'slicetimeseries'}
        res = 'tseriesslice';
    case {'tseriesscan' 'tseriescan' 'scantseries' 'timeseriesscan' 'scantimeseries'}
        res = 'tseriesscan';
    case {'datasize' 'mapsize' 'functionalsize' 'funcsize'}
        res = 'datasize';
    case {'dim' 'dims'}
        res = 'dim';
    case {'functionalslicedim' 'functionalslicedims' 'slicedim' ... 
            'slicedims' 'slicedimension' 'slicedimensions'}
        res = 'functionalslicedim';
    case {'tr' 'frameperiod' 'framerate' 'repeattime' 'timetorepeat'}
        res = 'tr';
    case {'nframes' 'numframes' 'numberoftimeframes'}
        res = 'nframes';
    case {'ncycles' 'numcycles' 'numberofcycles'}
        res = 'ncycles';
    case {'framestouse' 'framesblockdesign' 'framescoranal'}
        res = 'framestouse';
        
        %%%%% Retinotopy/pRF Model related properties
    case {'rmfile' 'retinotopymodelfile'}
        res = 'rmfile';
    case {'rmmodel' 'retinotopymodel'}
        res = 'rmmodel';
    case {'rmparams' 'retinotopyparameters' 'retinotopymodelparams'}
        res = 'rmparams';
    case {'rmstimparams' 'retinotopystimulusparameters' 'rmstimulusparameters'}
        res = 'rmstimparams';
    case {'rmmodelnum' 'rmmodelid' 'selectedretinotopymodel' 'retinotopymodelnumber'} 
        res = 'rmmodelnum';
    case {'rmcurrent' 'rmcurmodel' 'rmselectedmodel' 'rmcurrentmodel'}
        res = 'rmcurrent';
    case {'rmmodelnames' 'retinotopymodelnames'}
        res = 'rmmodelnames';
    case {'rmhrf' 'rmhemodynamicresponsefunction' 'retinotopymodelhrf' 'retinotopymodelhemodynamicresponsefunction'}
        res = 'rmhrf';
        %%%%% Mesh-related properties
        % these params relate to the segmentation / coords.mat file
    case {'classfilename' 'classfile' 'classpath'}
        res = 'classfilename';
    case {'leftclassfile' 'leftclassfilename'}
        res = 'leftclassfile';
    case {'rightclassfile' 'rightclassfilename'}
        res = 'rightclassfile';
    case {'leftgrayfile' 'leftgrayfilename' 'leftpath' 'flatleftpath'}
        res = 'leftgrayfile';
    case {'rightgrayfile' 'rightgrayfilename' 'rightpath' 'flatrightpath'}
        res = 'rightgrayfile';
        % these params interface with the mrMesh functions
    case {'mesh' 'replacemesh'}
        res = 'mesh';
    case {'currentmesh' 'curmesh' 'selectedmesh'}
        res = 'currentmesh';
    case {'allmeshes','meshlist','allmesh'}
        res = 'allmeshes';
    case {'allmeshids','allwindowids','allmeshid','allwindowid'}
        res = 'allmeshids';
    case {'addmesh' 'addandselectmesh'}
        res = 'addmesh';
    case {'meshdata' 'currentmeshdata' 'selectedmeshdata'}
        res = 'meshdata';
    case {'meshn' 'currentmeshn' 'setcurrentmeshn' 'curmeshnum' 'curmeshn'  'currentmeshnumber' 'selectedmeshn' 'selmeshn'}
        res = 'meshn';
    case {'nmesh','numberofmeshes', 'nummeshes', 'numbermeshes', 'nmeshes'}
        res = 'nmesh';
    case {'deletemesh' 'removemesh'}
        res = 'deletemesh';
    case {'meshnames' 'namesofmeshes' 'nameofmeshes'}
        res = 'meshnames';
    case {'meshdir', 'meshdirectory'}
        res = 'meshdir';
        
        %%%%% Volume/Gray-related properties
    case {'nodes'}
        res = 'nodes';
    case {'nodegraylevel' 'nodesgraylevel' 'graylevel'}
        res = 'nodegraylevel';
    case {'nnodes','numberofnodes'}
        res = 'nnodes';
    case {'edges'}
        res = 'edges';
    case {'nedges','numberofedges'}
        res = 'nedges';
    case {'allleftnodes'}
        res = 'allleftnodes';
    case {'allleftedges'}
        res = 'allleftedges';
    case {'allrightnodes'}
        res = 'allrightnodes';
    case {'allrightedges'}
        res = 'allrightedges';
    case {'coords'}
        res = 'coords';
    case {'coordsfilename' 'coordsfile' 'graycoordsfile' 'graycoordsfilename'}
        res = 'coordsfilename';
    case {'ncoords' 'numberofcoordinates' 'numbergraycoords' 'numberofcoords'}
        res = 'ncoords';
    case {'scannerxform' 'scannertransform'}
        res = 'scannerxform';
        %%%%% Vol/Gray/Flat check
    case {'mmpervox' 'mmpervoxel' 'voxsize' 'voxelsize' 'mmperpix' 'pixsize'}
        res = 'mmpervox';
    case {'mmpervolvox' 'mmpergrayvox' 'mmpervoxvolume' 'mmpervoxgray' 'grayvoxelsize' 'volumevoxelsize' 'volvoxelsize' 'volvoxsize' 'grayvoxsize'}
        res = 'mmpervolvox';                        
    case {'flip' 'fliplr'}
        res = 'fliplr';
    case {'imagerotation' 'rotateimagedegrees'}
        res = 'imagerotation';
    case {'hemifromcoords' 'hemi' 'hemifield'}
        res = 'hemifromcoords';
    case {'roihemi' 'hemiroi' 'roihemifield'}
        res = 'roihemi';
        %%%%% UI properties
    case {'initdisplaymodes' 'resetdisplaymodes'}
        res = 'initdisplaymodes';
    case {'ui' 'userinterface'}
        res = 'ui';
    case {'fignum','figurenumber'}
        res = 'fignum';
    case {'windowhandle'}
        res = 'windowhandle';
    case {'mainaxishandle'}
        res = 'mainaxishandle';
    case {'colorbarhandle'}
        res = 'colorbarhandle';
    case {'colorbarrange' 'cbarrange'}
        res = 'cbarrange';
    case {'anatomymode' 'anatmode'}
        res = 'anatomymode';
    case {'uiimage' 'imageui'}
        res = 'uiimage';
    case {'coherencemode' 'comode'}
        res = 'coherencemode';
    case {'correlationmode' 'cormode'}
        res = 'correlationmode';
    case {'phasemode' 'phmode'}
        res = 'phasemode';
    case {'amplitudemode' 'ampmode'}
        res = 'amplitudemode';
    case {'projectedamplitudemode' 'projampmode'}
        res = 'projectedamplitudemode';
    case {'mapmode' 'parametermapmode'}
        res = 'mapmode';
    case {'displaymode' 'dispmode' 'fieldname' 'field' 'field name'}
        res = 'displaymode';
    case {'phasecma' 'cmapphase' 'phasemap' 'phasecolormap' 'phcolormap'}
        res = 'phasecma';
    case {'cmap' 'colormap' 'curmodecmap' 'curcmap'  'currentcmap' 'overlaycmap'}
        res = 'cmap';
    case {'anatomymap' 'anatomycolormap' 'anatmap'}
        res = 'anatomymap';
    case {'loc' 'cursor' 'cursorloc' 'cursorposition' 'locs'}
        res = 'locs';
    case {'zoom'}
        res = 'zoom';
    case {'xhairs' 'showcursor' 'cursoron' 'crosshairs'}
        res = 'crosshairs';
    case {'ampmap' 'ampcolormap' 'amplitudecolormap'}
        res = 'ampmap';
    case {'coherencemap' 'coherencecolormap'}
        res = 'coherencemap';
    case {'correlationmap' 'correlationcolormap'}
        res = 'correlationmap';
    case {'cmapcolor' 'overlaycolormap' 'colormapcolor'}
        res = 'cmapcolor';
    case {'cmapgrayscale' 'underlaycolormap' 'underlaycmap' 'colormapgray'}
        res = 'cmapgrayscale';
    case 'cmapcurrent'
        res = 'cmapcurrent';
    case {'cmapcurmodeclip' 'curmodecmapclip'}
        res = 'cmapcurmodeclip';
    case {'cmapcurnumgrays' 'curnumgrays' 'currentnumberofgrays' 'ngrays'}
        res = 'cmapcurnumgrays';
    case {'cmapcurnumcolors' 'curnumcolors' 'currentnumberofcolors' 'ncolors'}
        res = 'cmapcurnumcolors';
    case {'flipud' 'flipupdown' 'flipup/down' 'flipvertical' 'verticalflip'}
        res = 'flipud';
    case {'ishidden' 'hidden'}
        res = 'ishidden';
    otherwise
        res = fieldName;
end

return

