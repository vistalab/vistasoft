function vData = scaleVolAnat(vData, ni)
% Scale intensities to 0-255 range
%
%vData = scaleVolAnat(vData, ni);
%
% Input
%  vData: 3D image array 
%  ni:    nifti structure containing volume anatomy
%
% Output
%   vData: 3D image array scaled to [0 - 255] 
%
% Example
%  cd(mrtInstallSampleData('functional', 'erniePRF', [], false))
%  vw = mrVista('3');
%  [vData,~,~,~, ni]= readVolAnat(vANATOMYPATH);
%  vData = scaleVolAnat(vData, ni);
%
% Notes: This function was clipped out of readVolAnat, so that re-orienting
% is decoupled from re-scaling.
%
% NYU Vista team, 2016


switch class(vData)
    case 'uint8'
        vData = double(vData);
    case 'int8'
        vData = double(vData)+127;
    otherwise
        % if possible, apply nifti-specified scale/slope and windowing
        if      checkfields(ni, 'scl_slope') && ...
                checkfields(ni, 'scl_inter') && ...
                checkfields(ni, 'cal_max') && ...
                checkfields(ni, 'cal_min')
            
            if ni.scl_slope~=0
                vData = ni.scl_slope * double(vData) + ni.scl_inter;
            else
                vData = double(vData) + ni.scl_inter;
            end
            if ~(ni.cal_max >0), ni.cal_max = max(vData(:)); end
            
            vData(vData<ni.cal_min) = ni.cal_min;
            vData(vData>ni.cal_max) = ni.cal_max;
            
        else
            vData =double(vData);
        end
        
        % put data in range [0 255]
        vData = vData-min(vData(:));
        vData = vData./max(vData(:)).*255;
end
