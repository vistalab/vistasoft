function [montage, hdl] = niftiView(ni,varargin)
% Read a NIfTI file or a nifti struct and display one of its volumes
%
%    hdl = niftiView(ni,'volume',number,'hdl',handle,'gam',gamma);
%
% Input:
%    ni:  Either a nifti file or a nifti struct
%
% Parameter/values
%    volume:  Which volume to display.  
%    slice:   Restrict to a slice
%    hdl:     Graphics handle to the display window
%               (default mrvNewGraphWin);
%    gam:     Gamma value for display (default 0.5)
%
% Returns:
%    montage:  The image in the window
%    hdl:      The returned figure handle 
%
% RL/BW Vistasoft Team, 2016

%% Parse parameters

p = inputParser;
p.KeepUnmatched = true;

% A file or a nifti struct
vFunc = @(x) ((isstruct(x) && isfield(x,'nifti_type')) || (ischar(x) && exist(x,'file')));
p.addRequired('ni',vFunc);
if ischar(ni), ni = niftiRead(ni);  end

% Parameter/values
p.addParameter('volume',1,@isnumeric);
p.addParameter('slice',[],@isnumeric);
p.addParameter('hdl',[],@isgraphics);
p.addParameter('gam',0.5,@isnumeric);

p.parse(ni,varargin{:});
volume = p.Results.volume;
hdl    = p.Results.hdl;     %#ok<NASGU>
gam    = p.Results.gam;
slice  = p.Results.slice;   % Which slice?

%% Either bring up the whole volume or just a slice from one volume

% This is the relevant volume, gamma corrected
v = squeeze(double(ni.data(:,:,:,volume))).^gam;

if isempty(slice)
    % Show multiple slices in a volume as montage.
    
    % Be alert that we are treating 3D data as if it could have a fourth volume
    % dimension, but make sure that volume is always 1.
    if length(ni.dim) == 3 && volume ~= 1
        error('Volume parameter out of range')
    end
    [montage, hdl] = niftiMontage(v,varargin{:});
    
    % Label the image
    [~,fname,~] = fileparts(ni.fname);
    fname = strrep(fname,'_','-');
    sz = size(ni.data);
    lst = min(length(fname),12);
    title(sprintf('%s (%d,%d,%d) (Vol=%d)',fname(1:lst),sz(1),sz(2),sz(3),volume));
else
    % Show one slice from one volume of the nifti file
    
    % We should allow a way to specify different slices, not just the 3rd
    % dimension
    mrvNewGraphWin;
    montage = v(:,:,slice);
    imagesc(montage);
    colormap(gray); axis image;
    
    % Label the image.  Sometimes the label is too long.
    [~,fname,~] = fileparts(ni.fname);
    fname = strrep(fname,'_','-');
    sz = size(ni.data);
    lst = min(length(fname),12);
    title(sprintf('%s (%d,%d,%d) (V=%d, S=%d)',fname(1:lst),sz(1),sz(2),sz(3),volume,slice));
end

end
