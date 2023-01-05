function dataTypeName = getDataTypeName(view);%% dataTypeName = getDataTypeName(view);% % Determine the name of the current dataType.%% djh, 2/2001
global dataTYPES
curDataType = dataTYPES(view.curDataType);dataTypeName = curDataType.name;
return;
