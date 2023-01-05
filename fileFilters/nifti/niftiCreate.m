function ni = niftiCreate(varargin)
%Initialize a nifti data structure used in Vistasoft
%
% This function should replace dtiWriteNiftiWrapper and niftiGetStruct
% Those are special cases.  This function should create default nii, and
% allow setting the parameters using a (param,val) set of arguments in
% varargin.
%
%   ni = niftiCreate(varargin)
%
% This should be of the form
%
%   nii = niftiCreate('data',val1,'qto_xyz',val2);
%
% We need a document to describe which fields we support and the meaning of
% those fields.  Maybe Rainer will write it.  (Who is Rainer?)
%
% INPUTS
%
% RETURNS
%
% Web Resources
%   mrvBrowseSVN('niftiCreate.m')
%   http://www.mathworks.com/matlabcentral/fileexchange/8797
%
% Example:
%
% See also:  niftiVista2ni, niftiNi2Vista
%
% Copyright Stanford team, mrVista, 2011

%% These fields are the ones used in the m-file niftiRead

% Initialize the VISTASOFT nifti structure with default parameters. 
ni = niftiStructure;

% If there is
if ~isempty(varargin)
    for ii = 1:2:(length(varargin)-1)
        param = mrvParamFormat(varargin{ii});
        if isfield(ni,param) || strcmpi('tr',param)
            val = varargin{ii+1};
            switch param
                case {'data'}
                    ni.(param) = val;
                    ni.dim     = size(val);
                    ni.ndim    = length(ni.dim);
                    ni.pixdim  = ones(1,ni.ndim);
                    ni.cal_min = min(min(min(min(val))));
                    ni.cal_max = max(max(max(max(val))));
                    ni.data_type = niftiClass2DataType(class(val));
                    
                case {'qto_xyz','sto_xyz'}
                    ni.qto_xyz = val;
                    ni.qto_ijk = inv(val);
                    ni.sto_xyz = val;
                    ni.sto_ijk = inv(val);
                    
                    quat_params  = matToQuat(ni.qto_xyz);
                    ni.quatern_b = quat_params.quatern_b;
                    ni.quatern_c = quat_params.quatern_c;
                    ni.quatern_d = quat_params.quatern_d;
                    ni.qoffset_x = quat_params.quatern_x;
                    ni.qoffset_y = quat_params.quatern_y;
                    ni.qoffset_z = quat_params.quatern_z;
                    ni.qfac      = quat_params.qfac;
                    
                    ni.pixdim(1:3) = [quat_params.dx quat_params.dy quat_params.dz];
                    
                case {'qto_ijk','sto_ijk'}
                    ni.qto_xyz = inv(val);
                    ni.qto_ijk = val;
                    ni.sto_xyz = inv(val);
                    ni.sto_ijk = val;
                    
                    quat_params  = matToQuat(ni.qto_xyz);
                    ni.quatern_b = quat_params.quatern_b;
                    ni.quatern_c = quat_params.quatern_c;
                    ni.quatern_d = quat_params.quatern_d;
                    ni.qoffset_x = quat_params.quatern_x;
                    ni.qoffset_y = quat_params.quatern_y;
                    ni.qoffset_z = quat_params.quatern_z;
                    ni.qfac      = quat_params.qfac;
                    
                    ni.pixdim(1:3) = [quat_params.dx quat_params.dy quat_params.dz];
                    
                case {'freq_dim'}
                    ni.freq_dim	 = val(1);
                    ni.phase_dim = val(2);
                    ni.slice_dim = val(3);
                    
                case {'slice_code'} 
                    ni.slice_code     = val(1);
                    ni.slice_start    = val(2);
                    ni.slice_end      = val(3);
                    ni.slice_duration = val(4);
                    
                case {'tr'}
                    if(ni.ndim>=4)
                        if(~isempty(val))
                            ni.pixdim(4) = val;
                        elseif(ni.dim(4)>1)
                            % Don't bother issuing a warning if the 4th dim has only one
                            % volume. This would be the case, e.g., for DTI data, where the
                            % matrix elements are in the 5th dim and 4th dim is size 1.
                            disp('Data appear to be a timeseries, but the TR was not specified. Setting it to 1.');
                        end
                    end
                    
                case {'data_type'}
                    % val is a string and it is converted to a number
                    ni.(param) = niftiClass2DataType(val);
                    % If there are no data, everything is OK.
                    % If there are data, make sure that the data class matches what
                    % we just set.
                    if ~strcmpi(class(ni.data),val) && ~isempty(ni.data)
                        error('[%s] Attempting to set the nifti data type to different type than the data type.',mfilename)
                    end
                    
                otherwise
                    ni.(param) = val;
            end
        else
            error('[%s] No field name %s\n',mfilename, param);
        end
    end
end

end % End main function

% -------------------------------------- %
function ni = niftiStructure
%
% Populates a VISTASOFT nifti structure with default parameters
%
% Franco (c) Stanford Vista Team 2012

% These are the defaults settings.
imArray = [];
matrixTransform = eye(4);
sclSlope = 1.0;
description = 'VISTASOFT';
freqPhaseSliceDim = [0 0 0];
sliceCodeStartEndDuration = [0 0 0 0];
TR = [];
intentName = '';

% call matToQuat to get quaternion parameters:
quat_params = matToQuat(matrixTransform);

% Fill structure with important info
ni.data  = imArray;
ni.fname = '';

ni.dim    = size(imArray);
ni.ndim   = length(ni.dim);
ni.pixdim = ones(1,ni.ndim);
ni.pixdim(1:3) = [quat_params.dx quat_params.dy quat_params.dz];
if(ni.ndim>=4)
  if(~isempty(TR))
    ni.pixdim(4) = TR;
  elseif(ni.dim(4)>1)
    % Don't bother issuing a warning if the 4th dim has only one
    % volume. This would be the case, e.g., for DTI data, where the
    % matrix elements are in the 5th dim and 4th dim is size 1.
    disp('Data appear to be a timeseries, but the TR was not specified. Setting it to 1.');
  end
end
ni.cal_min = min(min(min(min(imArray))));
ni.cal_max = max(max(max(max(imArray))));

ni.sform_code = 2;
ni.qform_code = 2;
ni.xyz_units  = 'mm';
ni.time_units = 'sec';
ni.nifti_type = 1;
% When there is a niftiGet, this field should go away.
% x = int16(1); niftiClass2DataType(class(x))
ni.data_type  = 4;   % int16.  
ni.descrip    = description;

ni.qto_xyz = matrixTransform;
ni.qto_ijk = inv(matrixTransform);
ni.sto_xyz = matrixTransform;
ni.sto_ijk = inv(matrixTransform);

ni.scl_slope      = sclSlope;
ni.scl_inter      = 0;
ni.freq_dim       = freqPhaseSliceDim(1);
ni.phase_dim      = freqPhaseSliceDim(2);
ni.slice_dim      = freqPhaseSliceDim(3);
ni.slice_code     = sliceCodeStartEndDuration(1);
ni.slice_start    = sliceCodeStartEndDuration(2);
ni.slice_end      = sliceCodeStartEndDuration(3);
ni.slice_duration = sliceCodeStartEndDuration(4);

ni.quatern_b = quat_params.quatern_b;
ni.quatern_c = quat_params.quatern_c;
ni.quatern_d = quat_params.quatern_d;
ni.qoffset_x = quat_params.quatern_x;
ni.qoffset_y = quat_params.quatern_y;
ni.qoffset_z = quat_params.quatern_z;
ni.qfac      = quat_params.qfac;

ni.toffset      = 0;
ni.intent_code  = 0;
ni.intent_p1    = 0;
ni.intent_p2    = 0;
ni.intent_p3    = 0;
ni.intent_name  = intentName;
ni.aux_file     = '';
ni.num_ext      = 0;

end
