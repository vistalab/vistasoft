function slectInitParamchange(lastedit)
global HandlesOfGUI;
zeilen=length(HandlesOfGUI.h_Volumes);
zeile=getNumberFromString(lastedit,1,'_');
if lastedit(1:3)=='Vol'
    handletolock=HandlesOfGUI.h_Volumes(zeile);
    newValue=get(handletolock,'String');
    for replace=zeile+1:zeilen
        set(HandlesOfGUI.h_Volumes(replace),'String',newValue);
    end
end
if lastedit(1:3)=='Sli'
    handletolock=HandlesOfGUI.h_Slices(zeile);
    newValue=get(handletolock,'String');
    for replace=zeile+1:zeilen
        set(HandlesOfGUI.h_Slices(replace),'String',newValue);
    end
end
if lastedit(1:3)=='Ski'
    handletolock=HandlesOfGUI.h_SkipVols(zeile);
    newValue=get(handletolock,'String');
    for replace=zeile+1:zeilen
        set(HandlesOfGUI.h_SkipVols(replace),'String',newValue);
    end
end
if lastedit(1:3)=='Cyc'
    handletolock=HandlesOfGUI.h_Cycles(zeile);
    newValue=get(handletolock,'String');
    for replace=zeile+1:zeilen
        set(HandlesOfGUI.h_Cycles(replace),'String',newValue);
    end
end
return

