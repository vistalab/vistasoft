function ROIid = getROIdbId(view)
% function ROIid = getROIdbId(view)
% User should select a ROI from a list (a list of all
% ROIs available in the DB).
% Or maybe we must show ROIs for the current session only?..

OKflag = openDbConnection(view);
if(~OKflag)
  ROIid = 0;
  return;
end;

[IdList,NameList,SessionIdList] = ...
  mysql('SELECT rois.id,rois.ROIname,rois.sessionid FROM rois');
[KnownSessionsId,KnownSessionsName] = ...
  mysql('SELECT sessions.id, sessions.sessionCode FROM sessions,rois WHERE sessions.id=rois.sessionid');
mysql('close');

for(Q=1:length(IdList))
  if(SessionIdList(Q)~=0)
    NameList{Q} = ['Session [' KnownSessionsName{max(find(KnownSessionsId==SessionIdList(Q)))} ']: ' NameList{Q}];
  else
    NameList{Q} = ['Unknown session: ' NameList{Q}];
  end
end

[ROIid,OK] = selector(IdList,NameList,'Choose a ROI');

if(OK==0)
  ROIid = 0;
end