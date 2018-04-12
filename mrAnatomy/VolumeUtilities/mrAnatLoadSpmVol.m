function V = mrAnatLoadSpmVol(fname,makeUint8)
% Simple wrapper to load various file formats into an SPM-style 'vol'
% V = mrAnatLoadSpmVol(fname,[makeUint8=true])
%
% 2007.08.03 RFD wrote it.

if(~exist('makeUint8','var')||isempty(makeUint8))
    makeUint8 = true;
end

% SPM doesn't know how to read gzipped niftis, so we'll load NIFTIs ourselves
if(ischar(fname)&&~isempty(strfind(fname,'.nii')))
    fname = niftiRead(fname);
end


if(ischar(fname))
    V = spm_vol(fname);
elseif(isstruct(fname)&&isfield(fname,'nifti_type'))
    % Convert our NIFTI struct into an SPM 'vol' struct
    V.fname = fname.fname;
    V.mat = fname.qto_xyz;
    V.dim = size(fname.data);
    if(makeUint8)
        type = spm_type('uint8');
    else
        type = class(fname.data);
        if(strcmp(type,'single')), type = 'float32';
        elseif(strcmp(type,'double')), type = 'float64'; end
        type = spm_type(type);
    end
    V.dt = [type 0];
    V.dat = fname.data;
    if(makeUint8 && ~strcmp(class(V.dat),'uint8'))
        V.dat = double(V.dat);
        V.dat = V.dat-min(V.dat(:));
        V.dat = uint8(V.dat./max(V.dat(:))*255);
    end
    V.pinfo = [fname.scl_slope fname.scl_inter]';
end

return;
