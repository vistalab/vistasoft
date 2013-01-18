function roiXformView(vw)

% roiXformView(vw)
%
% If we are in INPLANE view, do nothing. If we are in FLAT,  GRAY, or
% VOLUME, xform the ROI to INPLANE. Open a hidden INPLANE if needed.
% Currently this code is duplicated inside many functions (plotMeanTSeries,
% plotSingleCycle, etc.). Now this will happen in one place (here).
%
% JW 2/2009

mrGlobals;

% ----------------------------------
% xform ROI if not in INPLANE view 
% ----------------------------------
scanNum = viewGet(vw, 'curscan');

%Specifics for Flat, Gray, or Inplane views - xform ROI to INPLANE view
switch vw.viewType
    case {'Volume' 'Gray'}   %%%For ROIs in Gray view - xform to inplane
        % If the data do not exist in the inplane try getting the data from the
        % gray view directly.

        %selectedVOLUME = viewSelected('volume');

        %initiate and / or select INPLANE window
        if isempty(INPLANE),
            INPLANE{1} = initHiddenInplane;
            INPLANE{1} = viewSet(INPLANE{1},'name','hidden');
            selectedINPLANE = 1;
        else
            selectedINPLANE = viewSelected('inplane');
            if isempty(INPLANE{selectedINPLANE}), 
                for s = 1:length(INPLANE)
                    if ~isempty(INPLANE{s}), selectedINPLANE = s; end
                end
            end
        end

        % Set the Inplane scan number and datatype to match the Volume view.
        try
            curDataType = viewGet(vw,'datatypenumber');
            INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'datatypenumber',curDataType);
            INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'currentscan',scanNum);

            %Transfer current VOLUME ROI to INPLANE
            INPLANE{selectedINPLANE} = vol2ipCurROI(vw,INPLANE{selectedINPLANE});
        catch
            %rethrow(lasterror);
        end;

    case {'Flat'} % For ROIs in Flat view - xform to inplane

        selectedFLAT = viewSelected('flat');

        %initiate and / or select VOLUME and INPLANE windows
        if isempty(VOLUME),
            VOLUME{1} = initHiddenGray;
            VOLUME{1} = viewSet(VOLUME{1},'name','hidden');
            selectedVOlUME = 1;
        else
            selectedVOLUME = viewSelected('volume');
        end

        if isempty(INPLANE),
            INPLANE{1} = initHiddenInplane;
            INPLANE{1} = viewSet(INPLANE{1},'name','hidden');
            selectedINPLANE = 1;
        else
            selectedINPLANE = viewSelected('inplane');
        end

        % Set the Inplane scan number and datatype to match the Flat view.
        %         curScan =     viewGet(FLAT{selectedFLAT},'currentscan');
        curDataType = viewGet(FLAT{selectedFLAT},'datatypenumber');
        INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'datatypenumber',curDataType);
        INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'currentscan',scanNum);

        %Transfer current FLAT ROI to INPLANE
        INPLANE{selectedINPLANE} = flat2ipCurROI(vw,INPLANE{selectedINPLANE},VOLUME{selectedVOLUME});

    case {'Inplane'}   %%%For ROIs in INPLANE view - select inplane
        selectedINPLANE = viewSelected('inplane');
end

return