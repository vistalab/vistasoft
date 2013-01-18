function C = cell2ColorOrder(colors);
% 
% C = cell2ColorOrder(colors);
%
% Convert a cell array containing color signifiers
% into an N x 3 matrix, useable for color orders for 
% axes. (e.g., in setLineColors or mybar).
%
% color signifiers can be 1x3 matrices of [R G B]
% values (from 0-1 for each channel), or else one
% of the following characters:
%
%   'r': red [1 0 0]
%   'g': green [0 1 0]
%   'b': blue [0 0 1]
%   'k': black [0 0 0]
%   'y': yellow [1 1 0]
%   'm': magenta [1 0 1]
%   'c': cyan [0 1 1]
%   'w': white [1 1 1]
%   'e' or 'a': gray [.6 .6 .6]
%
%
% ras, 06/05.
if ~iscell(colors), error('Requires a cell input'); end

colors = unNestCell(colors);
C = zeros(length(colors),3);

for i = 1:length(colors)
    if isnumeric(colors{i}) & length(colors{i})==3
        C(i,:) = colors{i};
    elseif ischar(colors{i})
        ch = colors{i}(1);
        switch ch
            case 'r', C(i,:) = [1 0 0];
            case 'g', C(i,:) = [0 1 0];
            case 'b', C(i,:) = [0 0 1];
            case 'k', C(i,:) = [0 0 0];
            case 'y', C(i,:) = [1 1 0];
            case 'm', C(i,:) = [1 0 1];
            case 'c', C(i,:) = [0 1 1];
            case 'w', C(i,:) = [1 1 1];
            case {'e','a'}, C(i,:) = [.6 .6 .6];
            otherwise, 
                warning(sprintf('Unrecognized character %s',ch));
        end
    else
        error(sprintf('Entry %i is not a color signifier.',i));
    end
end

return

                