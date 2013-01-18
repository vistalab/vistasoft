function newlp = mrRefreshInplanes(lp,obXM,obYM,curInplane,deleteFlag)
% function newlp = mrRefreshInplanes(lp,obXM,obYM,curInplane,deleteFlag)
% ---------------------------------------------------
% Function: refreshes the inplane grid image replacing old handles with
% new ones derived from obXM and obYM
% Author: SPG
% Date: 2.26.97
% Notes: object handling in matlab is seriously screwed up. So be wary of
% altering any delete(lp) calls here or elsewhere, because I don't think
% logic applies to them.

global sagwin

figure(sagwin);

if deleteFlag == 1
  for i=1:length(lp)
    delete(lp(i));
  end
end

if ~isempty(lp)
 for i=1:length(lp)
   if i == curInplane
        newlp(i)=line(obXM(i,:),obYM(i,:),'Color','r');
   else
        newlp(i)=line(obXM(i,:),obYM(i,:),'Color','b');
   end
  end
else
 newlp = [];
end


