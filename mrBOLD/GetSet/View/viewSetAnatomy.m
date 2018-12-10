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

switch param
    
    case 'anatomy'
        switch viewGet(vw, 'viewType')
            case 'Inplane'
                vw.anat.data = val;
            case {'Gray' 'Volume' 'Flat'}
                    vw.anat = val;
        end
    case 'brightness'
        vw = setSlider(vw, vw.ui.brightness, val);
    case 'contrast'
        setSlider(vw, vw.ui.contrast, val);
    case 'inplanepath'
        vw.anat.inplanepath = val;
    case 'inplaneorientation'
        vw.inplaneOrientation = val;
    case 'anatinitialize'
        %Expects a path as the value
        % Read in the nifti from the path value
        ip = niftiRead(val);
        
        % Re-orient
        
        %If functional orientation is defined, make sure we use it
        ipOrientation = viewGet(vw, 'Inplane Orientation');
        if ~isempty(ipOrientation)            
            vectorFrom = niftiCurrentOrientation(ip);
            xform      = niftiCreateXformBetweenStrings(vectorFrom,ipOrientation);
            ip         = niftiApplyXform(ip,xform);
        else
            %Let us also calculate and and apply our transform
            ip = niftiApplyAndCreateXform(ip,'Inplane');
        end
        
        %Calculate Voxel Size as that is not read in (what is this used for??)
        voxelSize = prod(niftiGet(ip,'pixdim'));
        ip = niftiSet(ip,'Voxel Size',voxelSize);        

        % set up
        vw = viewSet(vw,'Anatomy Nifti', ip);


        
    case 'anatomynifti'
        vw.anat = val; %This means that we are passing in an entire Nifti!
    case 'mmpervox'
        vw.mmPerVox = val;
        
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return