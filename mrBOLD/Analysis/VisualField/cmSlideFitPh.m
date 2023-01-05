function [distanceShift] = cmSlideFitPh(cortMag)% % AUTHOR: Brewer, Wandell% DATE:   10.30.00% PURPOSE:% %   Find the shift (in mm)  along the distance axis to bring the data on% a meridian into agreement with the first meridian.% % The shifting is with respect to the complex phases, so phase-wrapping% is not a problem when sliding. % % SEE ALSO:% 
nMeridia = length(cortMag.corticalDist);
% These are the values that we will return% distanceShift = zeros(1,nMeridia);
% These are the shifts we will test.  We look at the total range of the% ROI length of the template and we test shifts +/- one half that distance.% if(~isfield(cortMag,'templateRoiNum'))    cortMag.templateRoiNum = 0;    for(ii=1:nMeridia)        if(~isempty(cortMag.corticalDist{ii}))            cortMag.templateRoiNum = ii;            break;        end    endend
if(cortMag.templateRoiNum==0 | isempty(cortMag.corticalDist{cortMag.templateRoiNum}))    myErrorDlg(['Roi # ',num2str(cortMag.templateRoiNum),' is not a suitable template.']);end
uDistTemplate = cortMag.corticalDist{cortMag.templateRoiNum};mnPhTemplate = cortMag.meanPh{cortMag.templateRoiNum};

%mnPhTemplate = unwrapPhases(complexPh2PositiveRad(mnPhTemplate));for ii=1:nMeridia    if(isempty(cortMag.corticalDist{ii}))        distanceShift(ii) = 0;    else
        % Set the shift range to be half of the distance range of the data.        r = round(max(cortMag.corticalDist{ii}) - min(cortMag.corticalDist{ii}));        dShift = [-r:r];
        uDist = cortMag.corticalDist{ii};        mnPh = cortMag.meanPh{ii};
        %mnPh = unwrapPhases(complexPh2PositiveRad(mnPh));
        % selectGraphWin; plot(uDist,angle(mnPh),'ro')
        
        % Test exhaustively across the shift range
        % 
        err = zeros(size(dShift));
        for jj = 1:length(dShift)
            err(jj) = CMFfitOneMeridianFun(dShift(jj), uDistTemplate, mnPhTemplate, uDist, mnPh);
        end
        
        % selectGraphWin; plot(dShift,err)
        [val idx] = min(err);
        if(min(err)>100)
            % really bad estimate- possibly no overlapping values. Default to no shift.
            distanceShift(ii) = 0;
            disp(['ROI ',num2str(ii),': Distance shift failed- maybe delete this ROI?']);
        else
            distanceShift(ii) = dShift(idx);
            fprintf('ROI %.0f: Distance shift was %.0f mm (range %.0f mm).\n',ii,dShift(idx),r);
        end
    end
end

return;
