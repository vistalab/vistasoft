% regParamInit - This script takes information from current windows and angles
% in mrAlign2 to produce initial rotation and translation matrices.
%
% Oscar Nestares - 5/99
%

% question asking what I need
QUEST = strvcat('To compute the initial parameters I need:',...
                ' ','1) The interpolated inplane being displayed',...
                    '   must be the same than the anatomy inplane.',...
                ' ','2) One corresponding point must be marked.',...
                ' ', '                CONTINUE?',...
                ' ','WARNING: the use of this code is being logged.',...
                    'Every time you use it you''ll owe me a beer.');

RESP = questdlg(QUEST, 'WARNING', 'Yes', 'No', 'Yes');

if strcmp(RESP, 'No')
   error(' Alignment computation cancelled...')
end

% sagittal rotation
sTheta = atan2((obYM(1,2)-obYM(1,1)),(obXM(1,2)-obXM(1,1)));
Xang = -sTheta;
Rx = [1 0 0; 0 cos(Xang) sin(Xang); 0 -sin(Xang) cos(Xang)];

% coronal rotation
Yang = -cTheta;
Ry = [cos(Yang) 0 sin(Yang);0 1 0; -sin(Yang) 0 cos(Yang)];

% axial rotation
Zang = -aTheta;
Rz = [cos(Zang) sin(Zang) 0; -sin(Zang) cos(Zang) 0; 0 0 1];

% reflection in z
% initial direction in z, taken from the line perpendicular to the
% inplanes in the sagittal window
uz = [0 obXM(length(obXM),2)-obXM(length(obXM),1) obYM(length(obXM),2)-obYM(length(obXM),1)];
% THIS ASSUMES AN EVEN NUMBER OF INPLANES and that the current selected
% inplane in the sagittal view is the same than in the anatomy view 
if (viewGet(INPLANE, 'Current Slice')==curInplane)
   uz = uz/norm(uz);
else
   uz = - uz/norm(uz);
end
uy = [0 obXM(1,2)-obXM(1,1) obYM(1,2)-obYM(1,1)];
uy = uy/norm(uy);
ux = [1 0 0];
zRef = dot(cross(ux,uy),uz);

% change of variables from inplane to volume
RR = [0 1 0; 0 0 1; 1 0 0];

% reflections
Ref = [reflections(1) 0 0; 0 reflections(2) 0; 0 0 zRef];

% initial rotation matrix
Rinit = RR*Rz*Ry*Rx*Ref;

NOPOINT = 1;
% initial translation, needs ONE REFERENCE POINT, taken from inpt and volpts
if exist('volpts')&exist('inpts')
   if ~isempty(volpts) & ~isempty(inpts)
      Tinit=(volpts(1,:)./scaleFac(2,:))'-Rinit*(inpts(1,:)./scaleFac(1,:))';
      NOPOINT = 0;
   end
end

if NOPOINT
   error('Need one corresponding point to compute the initial translation')
end


