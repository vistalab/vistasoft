function [im,slope,offset] = mrScale(im,b1,b2)
%
%  im = mrScale(im)                             scale from 0 to 1
%  im = mrScale(im,lowerBound,upperBound)
%  im = mrScale(im,maxValue)                    scale  largest value to maxValue
%  [im,range,b1] = mrScale(im,.1,1);
%     newIm = inputIm*range + b1;
%
%Author: Wandell
%Purpose:
%   Scale the values in im into the specified range.
%

% Find data range
mx = max(im(:));
mn = min(im(:));

% If only one bounds argument, just set peak value
if nargin == 2
    im = im*(b1/mx);
    return;
end


% If 0 or 2 bounds arguments, we first scale data to 0,1
im = (im - mn)/(mx - mn);

if nargin == 1
    % No bounds arguments, assume 0,1
    b1 = 0;
    b2 = 1;
elseif nargin == 3
    if b1 >= b2
        error('ieScale: bad bounds values.');
    end
end

% Put the (0,1) data into the range
range = b2 - b1;
im = range*im + b1;

slope = range/(mx-mn);
offset = b1 - ((range*mn)/(mx-mn));

return;

% Debug
im = -10:50;
tmp = ieScale(im,20,90);
min(tmp(:))
max(tmp(:))

im = randn([6,3,9])* 10;