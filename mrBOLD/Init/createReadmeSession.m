function createReadmeSession(info)
% function createReadmeSession
%
% Dialog box to get basic descriptors of session.
% Writes these to Readme file.
% Called by mrCreateReadme.m
%
% djh, 9.4.01
% ras, 01/12/04: added 'RessCoil' and 'fMRICoil' to list of available
% coils.
% ras, 04/18/04: also added 'Posthead-ReceiveOnly' to coil list.
% ras, 03/30/05: uses info from existing readme if supplied.
% ras, 08/11/06: tries to get protocl from headers. 
global mrSESSION dataTYPES

if notDefined('info')
    % set blank default vals, or vals from mrSESSION
    defaults = {...
            mrSESSION.sessionCode, mrSESSION.description,...
            mrSESSION.subject,'','','','',...
            num2str(mrSESSION.examNum),'',''...
        };
    
    % try to get protocol from header
    try
        w = dir('Raw/Anatomy/Inplane/I*');
        firstIfile = fullfile('Raw', 'Anatomy', 'Inplane', w(1).name);
        [img hdr] = mrReadIfile(firstIfile);
        defaults{10} = hdr.series.prtcl;
    end
        
else
    % get defaults from existing Readme.txt file
    defaults = {...
            info.session, info.description,...
            info.subject, info.operator, ...
            info.operator, info.magnet, info.coil...
            info.examNum, info.sliceOrientation,...
            info.protocol...
    };
end


c=0;

title = 'SESSION IDENTIFIERS';

c=c+1;
dlg(c).string = 'Session code:';
dlg(c).fieldName = 'sessionCode';
dlg(c).style = 'edit';
dlg(c).value = defaults{1};

c=c+1;
dlg(c).string = 'Description:';
dlg(c).fieldName = 'description';
dlg(c).style = 'edit';
dlg(c).value = defaults{2};
c=c+1;
dlg(c).string = 'Subject:';
dlg(c).fieldName = 'subject';
dlg(c).style = 'edit'; 
dlg(c).value = defaults{3};

c=c+1;
dlg(c).string = 'Operator:';
dlg(c).fieldName = 'operator';
dlg(c).style = 'edit';  
dlg(c).value = defaults{4};

c=c+1;
dlg(c).string = 'Recon/Readme by:';
dlg(c).fieldName = 'scribe';
dlg(c).style = 'edit';  
dlg(c).value = defaults{5};

c=c+1;
dlg(c).string = 'Magnet:';
dlg(c).fieldName = 'magnet';
dlg(c).style = 'popupmenu';
dlg(c).list = {'1.5 T', '3 T'};
dlg(c).choice = 2;
dlg(c).value = defaults{6};

c=c+1;
dlg(c).string = 'Coil:';
dlg(c).fieldName = 'coil';
dlg(c).style = 'popupmenu';
dlg(c).list = {'Posthead',  'RessCoil', 'fMRICoil', 'Posthead-ReceiveOnly','Helmet-head','Small-head', 'GE-head', 'Flex-quad'};
dlg(c).choice = 1;
dlg(c).value = defaults{7};

c=c+1;
dlg(c).fieldName = 'examNumber';
dlg(c).string = 'Exam number:';
dlg(c).style = 'edit';
dlg(c).value = defaults{8};

c=c+1;
dlg(c).string = 'Slice orientation:';
dlg(c).fieldName = 'sliceOrientation';
dlg(c).style = 'popupmenu';
dlg(c).list = {'Oblique', 'Coronal', 'Axial', 'Saggital'};
dlg(c).choice = 1;
dlg(c).value = defaults{9};

c=c+1;
dlg(c).string = 'Protocol name:';
dlg(c).fieldName = 'protocol';
dlg(c).style = 'edit';  
dlg(c).value = defaults{10};

% Prepare to make dialog box, make it
height = 1;
vSkip = 0.12;
pos = [35,10,80,length(dlg)*(height+vSkip)+3];
x = 1;
y = length(dlg)*(height+vSkip)+1;
editWidth = 40;
stringWidth = 30;
for uiNum = 1:length(dlg)
    dlg(uiNum).stringPos = [x,y,stringWidth,height];
    dlg(uiNum).editPos = [x+stringWidth-1,y,editWidth,height];
    y = y-(height+vSkip);
end
resp = generaldlg(dlg, pos, title);

% Write to Readme.txt
[fid, message] = fopen('Readme.txt', 'w');    
if (~exist('message','var'))
    message='default message';
end
    
if fid == -1
    warndlg(message);
    return
end

for i = 1:length(dlg)
    fprintf(fid, '%s %s\n', dlg(i).string, resp.(dlg(i).fieldName));
end

status = fclose(fid);
if status == -1
    warndlg(messsage);
    return
end

return
