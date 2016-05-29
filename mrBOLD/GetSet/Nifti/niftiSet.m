function ni = niftiSet(ni,param,val,varargin)
% Set data for various nifti data structures
%   
%     ni = niftiSet(ni,param,val,varargin)
%
% Parameter values
%
%  'pixdim'    - Voxel dimensions in millimeters (though settable)
%  'dim'       - Number of pixels in each dimension (row,col, depth, time/orientation)
%  'data'      - The data
%  'voxelsize' - What is this?  Why isn't it pixdim?
%
%  'checkqto'
%
% Example:
%  
%   ni = niftiCreate;
%   ni = niftiSet(ni,'voxel size',[0.375, 0.375, 2]);
%
%
% EKA/BW Vistasoft Team, 2015

%% Check the parameters
if notDefined('ni'), error('Nifti data structure variable required'); end
if notDefined('param'), error('Parameter field required.'); end
if ~exist('val','var'), error('Val required'); end

%% Squeeze spaces out, force lower case
param = mrvParamFormat(param);

%TODO: Add a nifti paramaterMapField
switch param
    case 'checkqto'
        
        sz = size(niftiGet(ni,'data'));
        dim = niftiGet(ni,'dim');
        
        if(any(dim(1:3)~=sz(1:3)))
            warning('[%s] NIFTI volume dim wrong- setting it to the actual data size.\n',mfilename);
            dim(1:3) = sz(1:3);
            ni = niftiSet(ni,'dim',dim);
        end
        
        if(ni.qform_code==0 && ni.sform_code~=0)
            warning('[%s] ni.qform_code is zero and sform_code ~=0. Setting ni.qto_* from ni.sto_*...\n',mfilename);
            %ni = niftiSetQto(ni, ni.sto_xyz);
            ni = niftiSet(ni,'qto',niftiGet(ni,'sto_xyz'));
        end
        
        dim = niftiGet(ni,'dim');
        qto_ijk = niftiGet(ni,'qto_ijk');
        origin = [qto_ijk(1:3,:)*[0 0 0 1]']';
        if(any(origin<2)||any(origin>dim(1:3)-2))
            [~,r,s,k] = affineDecompose(niftiGet(ni, 'qto_ijk'));
            t = ni.dim/2;
            warning_string = [sprintf('[%s] Qto matrix defines an origin very far away from the isocenter.\n',mfilename),...
                              sprintf('This implies that the Qto matrix may be bad - please check qto_ijk. An automatic fix will be attempted.\n'),...
                              sprintf('Origin to the image center is at [%2.3f,%2.3f,%2.3f] pix.\n',t(1),t(2),t(3))];
            warning(warning_string);
            %ni = niftiSetQto(ni, inv(affineBuild(t,r,s,k)));
            ni = niftiSet(ni,'qto',inv(affineBuild(t,r,s,k)));
            
        end
        
    case 'data'
        ni.data = val;
        
    case 'dim'
        ni.dim = val;
        
    case 'filepath'
        ni.fname = val;
        
    case 'freqdim'
        ni.freq_dim = val;
        
    case 'nifti'
        ni = val; %This means that we are passing in an entire Nifti!
        
    case 'phasedim'
        ni.phase_dim = val;
        
    case 'pixdim'
        ni.pixdim = val;
        
    case 'qfac'
        ni.qfac= val;
        
    case 'qform_code'
        ni.qform_code = val;
        
    case 'qoffset_x'
        ni.qoffset_x = val;
        
    case 'qoffset_y'
        ni.qoffset_y = val;
        
    case 'qoffset_z'
        ni.qoffset_z = val;
        
    case 'qto'
        xformXyz = val;
        q = matToQuat(xformXyz);
        ni = niftiSet(ni,'qform_code',2);
        ni = niftiSet(ni,'qto_xyz',xformXyz);
        ni = niftiSet(ni,'qto_ijk',inv(xformXyz));
        ni = niftiSet(ni,'quatern_b',q.quatern_b);
        ni = niftiSet(ni,'quatern_c ',q.quatern_c);
        ni = niftiSet(ni,'quatern_d',q.quatern_d);
        ni = niftiSet(ni,'qoffset_x',q.quatern_x);
        ni = niftiSet(ni,'qoffset_y',q.quatern_y);
        ni = niftiSet(ni,'qoffset_z',q.quatern_z);
        ni = niftiSet(ni,'qfac',q.qfac);
        
        if length(varargin) < 1
            setStoToo = '';
        else
            setStoToo = varargin{1};
        end
        
        if(~isempty(setStoToo)&&setStoToo)
            ni = niftiSet(ni,'sto_xyz',niftiGet(ni,'qto_xyz'));
            ni = niftiSet(ni,'sto_ijk',niftiGet(ni,'qto_ijk'));
        end
        
    case 'qto_ijk'
        ni.qto_ijk = val;
        
    case 'qto_xyz'
        ni.qto_xyz = val;
        
    case 'quatern_b'
        ni.quatern_b = val;
        
    case 'quatern_c'
        ni.quatern_c = val;
        
    case 'quatern_d'
        ni.quatern_d = val;
        
    case 'slicedim'
        ni.slice_dim = val;
        
    case 'sto_ijk'
        ni.sto_ijk = val;
        
    case 'sto_xyz'
        ni.sto_xyz = val;
        
    case 'voxelsize'
        ni.voxelSize = val;
        
    otherwise
        error('Unknown parameter %s\n',param);
        
end %switch

return
