function [montage, hdl] = niftiView(ni,varargin)
% Read a NIfTI file or a nifti struct and display one of its volumes
%
%    hdl = niftiView(ni,'volume',number,'figure',handle,'gam',gamma);
%
% RL/BW Vistasoft Team, 2016

p = inputParser;
p.KeepUnmatched = true;

vFunc = @(x) ((isstruct(x) && isfield(x,'nifti_type')) || (ischar(x) && exist(x,'file')));
p.addRequired('ni',vFunc);
if ischar(ni), ni = niftiRead(ni);  end

p.addParameter('volume',1,@isnumeric);
p.addParameter('hdl',[],@isgraphics);
p.addParameter('gam',0.5,@isnumeric);

p.parse(ni,varargin{:});
volume = p.Results.volume;
hdl    = p.Results.hdl;     %#ok<NASGU>
gam    = p.Results.gam;

% Show it as montage.  Be alert that we are treating 3D data as if it could
% have a fourth volume dimension, but make sure that volume is always 1.
if length(ni.dim) == 3 && volume ~= 1
    error('Volume parameter out of range')
end
[montage, hdl] = niftiMontage((squeeze(double(ni.data(:,:,:,volume))).^gam),varargin{:});

% Label the image
[~,fname,~] = fileparts(ni.fname);
fname = strrep(fname,'_','-');
sz = size(ni.data);
title(sprintf('File %s (%d,%d,%d) (Vol=%d)',fname,sz(1),sz(2),sz(3),volume));

end
