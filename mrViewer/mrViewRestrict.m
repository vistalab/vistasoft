function [coords, mask] = mrViewRestrict(ui, coords, overlayNum, method);
% Restrict a set of coordinates to be within all thresholded 
% overlays in a mrViewer UI.
%
%  [coords, mask] = mrViewRestrict(ui, coords, [overlayNum], [method]);
%
% The input coords are assumed to be specified in terms of the
% UI's base MR data. This coordinate space is used by ROIs and
% the underlay data.
%
% Optional Input Arguments:
% overlayNum: index (or indices) into the overlays, if you 
% only want to restrict by a subset of overlays.
%
% method: 'nearest', 'linear', 'cubic', or 'spline'; the method
% by which to interpolate maps if the overlay map and the base
% volume aren't coregistered. Defaults to nearest for speed. 
%
% The second output argument is a binary mask set to 1 if a given
% column passes threshold, and 0 otherwise.
%
% ras, 09/06/2005.
if notDefined('ui'), ui = mrViewGet;                                end
if ishandle(ui), ui = get(ui,'UserData');                           end
if notDefined('overlayNum'), overlayNum = [1:length(ui.overlays)];  end
if notDefined('method'), method = 'nearest';                        end
if isempty(ui.overlays), return; end % don't restrict w/ no overlays

% figure(ui.fig);
% hmsg = msgbox('Restricting ROI to overlays...');

%%%%%initialize a binary mask of size 1 x nVoxels:
mask = logical(zeros(1, size(coords, 2)));

%%%%%run through each overlay, finding values that pass threshold:
%%%%%this is an OR function for the mask, in that a pixel only has
%%%%%to pass threshold for one overlay to be included in the mask
for o = overlayNum
    m = ui.overlays(o).mapNum;

    %%%%%interpolate the values from this map at the specified coords    
    % (1) get map volume for the appropriate timepoint 
    vol = ui.maps(m).data;
    if ndims(vol)>3, vol = vol(:,:,:,1); end    

    % xform coords into map data coordinates
    xform1 = inv(ui.maps(m).baseXform);
    if isequal(xform1,eye(4))
        C = coords;
    else
        C = xform1 * [coords; ones(1,size(coords,2))];
        C = C(1:3,:);
    end

    % get the values for the overlay map
    vals = interp3(vol, C(2,:), C(1,:), C(3,:), method);

    %%%%%build a mask of which pixels exceed threshold
    ok = logical(ones(size(vals)));
    for j = find([ui.overlays(o).thresholds.on]==1)
        th = ui.overlays(o).thresholds(j).mapNum;            

        % see if we can use the existing xformed coords,
        % or if the thresh map has to use diff't xformed coords
        if m==th  % thresholding by the overlay map
            tst = vals;
        else
            testVol = ui.maps(th).data;
            tsz = ui.maps(th).dims;
            if ndims(testVol)>3, testVol = testVol(:,:,:,1); end

            if (ui.maps(m).baseXform==ui.maps(th).baseXform)
                % thresholding by diff't map w/ same coordinate system
                if(method(1)=='n')  % nearest
                    tst = myCinterp3(testVol, [tsz(1) tsz(2)], tsz(3), ...
                                       round(C([2 1 3],:)'), 0.0);
                elseif(method(1)=='l')  % linear
                    tst = myCinterp3(testVol, [tsz(1) tsz(2)], tsz(3), ...
                            C([2 1 3],:)', 0.0);
                else
                    tst = interp3(testVol, C(2,:), C(1,:), C(3,:), method);
                end


            else
                % thresholding by diff't map, w/ diff't coordinates
                % (let's always use nearest-neighbor for the thresholding)
                xform2 = inv(ui.maps(th).baseXform);
                C2 = xform1 * [coords; ones(1,size(coords,2))];
%                 tst = interp3(testVol, C2(2,:), C2(1,:), C2(3,:));
                
                % using myCinterp3 and round is actually faster than
                % rounding the coords C2 and accessing ... :P
                tst = myCinterp3(testVol, [tsz(1) tsz(2)], tsz(3), ...
                                 round(C2([2 1 3],:)'), 0.0);
                
            end
            
        end

        % restrict ok voxels to min/max
        ok = ok & (tst>=ui.overlays(o).thresholds(j).min);
        ok = ok & (tst<=ui.overlays(o).thresholds(j).max);
        
    end

    %%%%%perform OR function: accept values passing any threshold
    mask = mask | ok;
end

%%%%%restrict coords
coords = coords(:,mask);

% close(hmsg);

return
