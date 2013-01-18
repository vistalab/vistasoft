function result = convZ(input,filter) 
%
% function result = convZ(input,filter) 
%
% input is volume, 3d array
% filter is a vector containing the taps of a 1d filter
%
% result is a 3d volume which is the computed by convolving
% input by filter in the Z direction.  Edges are ignored so that
% result is smaller than input (like using 'valid' for the shape
% parameter in conv2).
%
% Bugs:
% filter must have odd number of taps

edgeSize = floor(length(filter)/2);

% Reverse/flip filter
filter = filter(length(filter):-1:1);

result = zeros(size(input,1),size(input,2),size(input,3)-length(filter)+1);

for outZ=1:size(result,3)
  for tap=1:length(filter)
    inZ=outZ+tap-1;
    result(:,:,outZ)=result(:,:,outZ)+filter(tap)*input(:,:,inZ);
  end
end

return;

% Debug:
input = ones(5,5,3);
input = ones(3,3,5);
filter = [1/4,1/2,1/4];
result = convZ(input,filter);
