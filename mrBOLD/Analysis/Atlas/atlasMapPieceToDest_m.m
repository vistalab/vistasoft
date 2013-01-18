function Atlas = atlasMapPieceToDest_m(Atlas,AtlasPiece,X,Y,fillvalue)
%   Atlas = atlasMapPieceToDest_m(Atlas,AtlasPiece,X,Y,fillvalue)
%
% Purpose:
%    The created piece of atlas starts at 0,0 and of limited size this
%    function fills all values of the Atlaspiece into the Atlas, exept at
%    the location with the value "fillvalue"
%
% Examples:
%     AtlasE= atlasMappieceToDest_m(AtlasE,AtlasPieceE,X,Y,-1)
%
% Author: Schira

if ~exist('fillvalue','var') , fillvalue = -1; end
for ii=1:size(AtlasPiece,1)
    for jj=1:size(AtlasPiece,2)
        if AtlasPiece(ii,jj) ~= fillvalue
            Atlas(ii+X(2),jj+X(1)) = AtlasPiece(ii,jj);
        end
    end
end
return;