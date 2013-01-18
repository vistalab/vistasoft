function [ringWedgeScans ringWedgeFields] = readRingWedgeScans(dlgTitle);
%
%   [ringWedgeScans ringWedgeFields]  = readRingWedgeScans(dlgTitle);
%
% Author: Wandell, Brewer
% Purpose:
%    Utility to read ring and wedge scan numbers
%    ringWedgeScans(1) is the scan num of the ring
%    ringWedgeScans(2) is the scan num of the wege
%
% ras, 04/2009: updated with slots for the data field (co, amp, ph, map)
% for each scan as well. (Important for pRF data.)
if notDefined('dlgTitle'), dlgTitle='Read ring and wedge scan numbers'; end

dlg(1).fieldName = 'ringScan';
dlg(end).style = 'number';
dlg(end).value = 1;
dlg(end).string = 'Eccentricity (ring) data scan?';

dlg(end+1).fieldName = 'ringField';
dlg(end).style = 'popup';
dlg(end).list = {'co' 'amp' 'ph' 'map'};
dlg(end).value = 'map';
dlg(end).string = 'Polar Angle (wedge) data field?';

dlg(end+1).fieldName = 'wedgeScan';
dlg(end).style = 'number';
dlg(end).value = 1;
dlg(end).string = 'Eccentricity (ring) data scan?';

dlg(end+1).fieldName = 'wedgeField';
dlg(end).style = 'popup';
dlg(end).list = {'co' 'amp' 'ph' 'map'};
dlg(end).value = 'ph';
dlg(end).string = 'Polar Angle (wedge) data field?';

[resp ok] = generalDialog(dlg, dlgTitle);

if ~ok, error('User Aborted.');		end

ringWedgeScans = [resp.ringScan resp.wedgeScan];
ringWedgeFields = {resp.ringField resp.wedgeField};

return;