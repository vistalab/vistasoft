function hdl = niftiView(ni,varargin)
% Read a NIfTI file or a nifti struct and display a volume
%
%    hdl = niftiView(ni,'volume',number,'figure',handle,'gam',gamma);
%
% RL/BW Vistasoft Team, 2016

p = inputParser;
vFunc = @(x) (isstruct(x) || exist(x,'file') );
p.addRequired('ni',vFunc);
p.addParameter('volume',1,@isnumeric);
p.addParameter('hdl',[],@isgraphics);
p.addParameter('gam',0.3,@isnumeric);

p.parse(ni,varargin{:});
volume = p.Results.volume;
hdl = p.Results.hdl;
if isempty(hdl), hdl = mrvNewGraphWin; end
gam = p.Results.gam;

if ischar(ni)
    ni = niftiRead(ni);
end

% Show it as montage 
showMontage((double(ni.data(:,:,:,volume)).^gam));
title(sprintf('Volume %d',volume))

end
