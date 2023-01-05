handles = guidata(gcf);
method = 'transorbital';

pivotPoint = dtiGet(handles,'curpos');

switch(method)
    case 'standard',
        if(pivotPoint(1)<0)
            radius = 60/handles.talairachScale.lac;
            apAngleDeg = 0;
            siAngleDeg = 0;
        else
            radius = 60/handles.talairachScale.rac;
            apAngleDeg = 180;
            siAngleDeg = 180;
        end
        upperAngle = 50;
        lowerAngle = 10;

    case 'transorbital',
    	radius = 50/handles.talairachScale.sac;
        apAngleDeg = -90;
        siAngleDeg = -30;
        upperAngle = 30;
        lowerAngle = 30;
end

roiName = 'arcRoi';
roiColor = 'r';

prompt = {'ROI name:','ROI color:','Pivot point (ac-pc):','Upper arc angle (deg):',...
    'Lower arc angle (deg):','Radius:','SI plane angle (deg):','AP plane angle (deg):'};
defAns = {roiName,roiColor,num2str(pivotPoint),num2str(upperAngle),num2str(lowerAngle),...
            num2str(radius),num2str(siAngleDeg),num2str(apAngleDeg)};
resp = inputdlg(prompt,'Arc ROI Params',1, defAns);
if(isempty(resp)) error('User canceled.'); end
roiName = resp{1};
roiColor = resp{2};
pivotPoint = str2num(resp{3});
upperAngle = str2num(resp{4});
lowerAngle = str2num(resp{5});
radius = str2num(resp{6});
siAngleDeg = str2num(resp{7});
apAngleDeg = str2num(resp{8});

upperAngle = upperAngle/180*pi;
lowerAngle = lowerAngle/180*pi;
% Creat a grid that can contain the entire ROI
maxRad = ceil(radius);
roi2d = zeros(maxRad*2+1,maxRad*2+1);
center = [maxRad,maxRad];
refVector = [0,maxRad];
for(x=1:size(roi2d,2))
    for(y=1:size(roi2d,1))
        testPt = [x,y]-center;
        testRadius = norm(testPt);
        if(testRadius==0)
            % we are at the center.
            roi2d(x,y) = 1;
        elseif(testRadius<radius)
            testAngle = acos(dot(refVector,testPt)/(norm(refVector)*norm(testPt)));
            if(testPt(1)>0)
                % then we are above the center
                if(testAngle<upperAngle)
                    roi2d(x,y) = 1;
                end
            else
                % we are below the center
                if(testAngle<lowerAngle)
                    roi2d(x,y) = 1;
                end
            end 
        end
    end
end

%figure; imagesc(roi2d); axis equal tight xy;
[z,x] = ind2sub(size(roi2d),find(roi2d>0));
z = z-center(2); x = x-center(1);
y = zeros(size(x));
rotation = [siAngleDeg/180*pi,apAngleDeg/180*pi,0];
xform = affineBuild(pivotPoint, rotation, [1 1 1], [0 0 0]);
coords = mrAnatXformCoords(xform,[x,y,z]);
roi = dtiNewRoi(roiName, roiColor, coords);

handles = dtiAddROI(roi, handles);
handles = dtiRefreshFigure(handles);
guidata(gcf,handles);
