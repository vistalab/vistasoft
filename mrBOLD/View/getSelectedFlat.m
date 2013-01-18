function flat = getSelectedFlat
%
% Return the currently-selected FLAT view, if it exists.
%
%
% Don't know who wrote this? Commented by ras, 05/05.
% Also added the manual search for a view if selectedFLAT is
% empty.
% ras 01/07, for some reason the commented out code was not working;
% I'm trying something simpler (this may be related to the fact that
% MATLAB makes a FLAT variable when copying figure info):
try
    FLAT = evalin('base', 'FLAT')
    s = evalin('base', 'selectedFLAT');
    if isempty(s) | s==0
        s = cellfind(FLAT);
        if isempty(s)   
            warning('No FLAT views defined -- making a hidden view');
            flat = initHiddenFlat;
            return
        end
    end
    flat = FLAT{s};            
    
catch
   flat = initHiddenFlat;
   
end
   
return
% OLD CODE:
% mrGlobals
% if notDefined('FLAT')
%     warning('No selected Flat: FLAT variable is not defined.');
%     flat = [];
%     return
% end
% 
% if ~isempty(selectedFLAT)
%     flat = FLAT{selectedFLAT};
% else
%     flatList=cellfind(FLAT);
%     if (length(flatList)>=1)
%         selectedFLAT=flatList(1);
%         flat=FLAT{selectedFLAT};
%     else
%         flat = [];
%     end
% end
