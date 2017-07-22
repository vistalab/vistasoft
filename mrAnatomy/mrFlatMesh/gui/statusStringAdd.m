function newStatusString=statusStringAdd(handle,message)
%
%  newStatusString = statusStringAdd(handle,message)
%
%Author: Wade
%Purpose:
%  Adds the current message to the staus box defined by the handle
%  Used in unfoldMeshFromGUI.  It should probably be internal to that
%  program. (BW).
%

if (~isempty(handle))
    oldStatusString = get(handle,'UserData');
    newStatusString = char(oldStatusString,message);
    [depthString,horizString]=size(newStatusString);
    if (depthString<=5)
        st=1;
    else
        st=(depthString-5);
    end

    set(handle,'String',newStatusString(st:end,:));
    set(handle,'UserData',newStatusString);
    dummy=1;
else
    fprintf(['\n',message]);
    dummy=0;
end
drawnow

return;
