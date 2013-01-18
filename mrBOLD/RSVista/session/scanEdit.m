function scan = scanEdit(session,dt,scan)
% Dialog to edit fields of a scan.
%
% scan = scanEdit(session,[dt],[scan]);
%
% If omitted, will edit the data type and scan selected
% in the session's settings.
%
% ras, 10/2005.
if notDefined('session'), session=get(gcf,'UserData'); end
if notDefined('dt'), dt = sessGet(session,'dataType'); end
if notDefined('scan') 
    scans = sessGet(session,'scans');
    scan = scans(1);
end

dlg(1).fieldName = 'name';
dlg(1).style = 'edit';
dlg(1).string = 'Scan Name:';
dlg(1).value = session.(dt)(scan).name;

resp = generalDialog(dlg,'Edit Scan');

% exit quietly if user aborts
if isempty(resp), return; end

% copy fields over to session
for f = fieldnames(resp)'
    session.(dt)(scan).(f{1}) = resp.(f{1});
end

% save session
sessionSave(session);

return
