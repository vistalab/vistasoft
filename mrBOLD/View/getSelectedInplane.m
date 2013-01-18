function inplane = getSelectedInplane
% Returns the currently selected inplane.
% If no inplane is selected, but a single inplane window is open, 
% returns that.
% ARW 081203 - Added default inplane return.
mrGlobals
if notDefined('INPLANE')
%     warning('No selected Inplane: INPLANE variable is not defined.');
    inplane = [];
    return
end
if ~isempty(selectedINPLANE)
    inplane = INPLANE{selectedINPLANE};
else
    inplaneList=cellfind(INPLANE);
    if (length(inplaneList)==1)
        selectedINPLANE=inplaneList;
        inplane=INPLANE{selectedINPLANE};
        
    else
        inplane = [];
    end
end
return;
