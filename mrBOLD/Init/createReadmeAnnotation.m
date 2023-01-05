function createReadmeAnnotation
% function createReadmeAnnotation
%% Dialog box to get annotation strings for each scan.
% Writes these descriptions to Readme file.
% Sets annotation fields in dataTYPES.
%
% Called by mrCreateReadme.m%% DJH, 9/4/01

global mrSESSION dataTYPESnScans = length(mrSESSION.functionals);for iScan = 1:nScans    PfileName = mrSESSION.functionals(iScan).reconParams.PfileName;    uiStruct(iScan).string = ['Scan ',num2str(iScan),' (',PfileName,'):'];    uiStruct(iScan).fieldName = ['scan',num2str(iScan)];    uiStruct(iScan).style = 'edit';    uiStruct(iScan).value = dataTYPES(1).scanParams(iScan).annotation;   endtitle = 'Annotation';vSkip = 0.12;height = 1;editWidth = 45;width = 70;pos = [35,3,width,length(uiStruct)*(height+vSkip)+3];x = 1;y = length(uiStruct)*(height+vSkip)+1;stringWidth = pos(3)-editWidth-2;for uiNum = 1:length(uiStruct)    uiStruct(uiNum).stringPos = [x,y,stringWidth,height];    uiStruct(uiNum).editPos = [x+stringWidth-1,y,editWidth,height];    y = y-(height+vSkip);endoutStruct = generaldlg(uiStruct,pos,title);[fid, message] = fopen('Readme.txt','a');if fid == -1    warndlg(messsage);    returnendfprintf(fid,'\n\n%s\n','Descriptions:');fprintf(fid,'%s\t%s\n','scan','Description');for iScan = 1:nScans    str = getfield(outStruct,uiStruct(iScan).fieldName);    fprintf(fid,'%d\t%s\n',iScan,str);    dataTYPES(1).scanParams(iScan).annotation = str;endstatus = fclose(fid);if status == -1    warndlg(messsage);    returnend% save annotation strings in dataTYPESsaveSession
return