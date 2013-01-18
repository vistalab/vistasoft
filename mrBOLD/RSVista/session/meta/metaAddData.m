function meta = metaAddData(fieldName, value, viewType);
%
%  meta = metaAddData(fieldName, value, [viewType='Inplane']);
%
% Add metadata to a session.
%
% ras, 11/02/06: wrote it.
if nargin<2, error('Not enough Input args.'); end
if notDefined('viewType'), viewType = 'Inplane'; end

switch lower(viewType)
    case 'inplane'
        
        
    case 'volume'
   
    case 'gray'
        
    case 'mr'
        
end