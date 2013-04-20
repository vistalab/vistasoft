function vw = viewSetAnatomy(vw,param,val,varargin)
%Organize methods for setting view parameters.
%
% This function is wrapped by viewSet. It should not be called by anything
% else other than viewSet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'),  error('No view defined.'); end
if notDefined('param'), error('No parameter defined'); end
if notDefined('val'),   val = []; end

mrGlobals;

param = mrvParamFormat(param);


% Standardize the name of the parameter field with name-mapping function
param = viewMapParameterField(param);
paramSplit = viewMapParameterSplit(param);


switch paramSplit
    
    case 'anatomy'
        vw.anat.data = val;
    case 'brightness'
        vw = setSlider(vw, vw.ui.brightness, val);
    case 'contrast'
        setSlider(vw, vw.ui.contrast, val);
    case 'inplanepath'
        vw.anat.inplanepath = val;
    case 'anatinitialize'
        %Expects a path as the value
        %Read in the nifti from the path value
        vw = viewSet(vw,'Anatomy Nifti', niftiRead(val));
        %Calculate Voxel Size as that is not read in
        vw = viewSet(vw,'Anatomy Nifti', niftiSet(viewGet(vw,'Anatomy Nifti'),'Voxel Size',prod(niftiGet(vw.anat,'pixdim'))));
        
        %Let us also calculate and and apply our transform
        vw = viewSet(vw,'Anatomy Nifti',niftiApplyAndCreateXform(viewGet(vw,'Anatomy Nifti'),'Inplane'));
    case 'anatomynifti'
        vw.anat = val; %This means that we are passing in an entire Nifti!
        
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return