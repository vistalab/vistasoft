function [montage, hdl] = niftiView(ni,varargin)
% Read a NIfTI file or a nifti struct and display a volume
%
%    hdl = niftiView(ni,'volume',number,'figure',handle,'gam',gamma);
%
% RL/BW Vistasoft Team, 2016

p = inputParser;
p.KeepUnmatched = true;

vFunc = @(x) (isstruct(x) || exist(x,'file') );
p.addRequired('ni',vFunc);
p.addParameter('volume',1,@isnumeric);
p.addParameter('hdl',[],@isgraphics);
p.addParameter('gam',0.3,@isnumeric);

p.parse(ni,varargin{:});
volume = p.Results.volume;
hdl = p.Results.hdl;     %#ok<NASGU>
gam = p.Results.gam;

if ischar(ni)
    ni = niftiRead(ni);
end

% Show it as montage 
[montage, hdl] = niftiMontage((double(ni.data(:,:,:,volume)).^gam),varargin{:});

% Label the image
[~,fname,~] = fileparts(ni.fname);
fname = strrep(fname,'_','-');
sz = size(ni.data);
title(sprintf('File %s (%d,%d,%d) (Vol=%d)',fname,sz(1),sz(2),sz(3),volume));

end
