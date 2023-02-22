function [dataView, dataTypeNum] = getDataView(atlasView)
%
% [dataView, dataTypeNum] = getDataView(atlasView)
%
% 
%

mrGlobals;
dataViewList = {};

if(isfield(dataTYPES(atlasView.curDataType).atlasParams(1), 'sourceDataTypeName'))
    dataTypeName = dataTYPES(atlasView.curDataType).atlasParams(scanNum).sourceDataTypeName;
    dataTypeNum = existDataType(dataTypeName);
    for(ii=1:length(FLAT))
        if(~isempty(FLAT{ii}) & strcmp(dataTypeName,getDataTypeName(FLAT{ii})))
            dataViewList{end+1} = ii;
        end
    end
else
    for(ii=1:length(FLAT))
        if(~isempty(FLAT{ii}) & ~strcmp('Atlases',getDataTypeName(FLAT{ii})))
            dataViewList{end+1} = ii;
        end
    end
end
if(isempty(dataViewList))
    dataView = [];
    dataTypeNum = [];
elseif(length(dataViewList)==1)
    dataView = FLAT{dataViewList{1}};
    dataTypeNum = dataView.curDataType;
else
    reply = radiobuttondlg(dataViewList, 'Select Data Figure Num');
    dataView = FLAT{dataViewList{reply}};
    dataTypeNum = dataView.curDataType;
end


return;