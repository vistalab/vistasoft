function B = transform_image_V1_3(I, corners, interporation)

% B = transform_image3(I, corners, interporation)
% calculate the transformation matrix for each area

B = nan(256,256);

if notDefined('interporation'), interporation = [];  end;

% V3v
input_points = corners{4};
% base_points =  [40 20;40 35; 80 35; 80 20];
base_points =  [30 80; 15 80; 15 40; 30 40];
udata = [1 201];  vdata = [1 201];  % input coordinate system
tform = maketform('projective',input_points, base_points);
[tmp,xdata,ydata] = imtransform(I,tform,interporation,'udata',udata,...
                                                'vdata',vdata,...
                                                'xdata',udata,...
                                                'ydata',vdata,...
                                                'size',size(I),...
                                                'fill',256);
B(round(20/200*256):round(100/200*256), round(10/200*256):round(30/200*256))=tmp(round(20/200*256):round(100/200*256),round(10/200*256):round(30/200*256));

% V2v
input_points = corners{2};
% base_points =  [40 50;40 35; 80 35; 80 50];
base_points =  [30 80; 45 80; 45 40; 30 40];
udata = [1 201];  vdata = [1 201];  % input coordinate system
tform = maketform('projective',input_points, base_points);
[tmp,xdata,ydata] = imtransform(I,tform,interporation,'udata',udata,...
                                                'vdata',vdata,...
                                                'xdata',udata,...
                                                'ydata',vdata,...
                                                'size',size(I),...
                                                'fill',256);
B(round(20/200*256):round(100/200*256), round(30/200*256):round(45/200*256))=tmp(round(20/200*256):round(100/200*256),round(30/200*256):round(45/200*256));

% V1
input_points = corners{1};
% base_points =  [40 50;40 65; 80 65; 80 50];
base_points =  [75 80; 45 80; 45 40; 75 40];
udata = [1 201];  vdata = [1 201];  % input coordinate system
tform = maketform('projective',input_points, base_points);
[tmp,xdata,ydata] = imtransform(I,tform,interporation,'udata',udata,...
                                                'vdata',vdata,...
                                                'xdata',udata,...
                                                'ydata',vdata,...
                                                'size',size(I),...
                                                'fill',256);
B(round(20/200*256):round(100/200*256), round(45/200*256):round(75/200*256))=tmp(round(20/200*256):round(100/200*256),round(45/200*256):round(75/200*256));

% V2d
input_points = corners{3};
% base_points =  [40 80;40 65; 80 65; 80 80];
base_points =  [75 80; 90 80; 90 40; 75 40];
% input_points = [corners{2};mean(corners{2}(2:3,:)); mean(corners{2})];
% % base_points =  [40 80;40 65; 80 65; 80 80];
% base_points =  [90 80; 75 80; 75 40; 90 40; 75 60; 82.5 60];
udata = [1 201];  vdata = [1 201];  % input coordinate system
tform = maketform('projective',input_points, base_points);
[tmp,xdata,ydata] = imtransform(I,tform,interporation,'udata',udata,...
                                                'vdata',vdata,...
                                                'xdata',udata,...
                                                'ydata',vdata,...
                                                'size',size(I),...
                                                'fill',256);
B(round(20/200*256):round(100/200*256), round(75/200*256):round(90/200*256))=tmp(round(20/200*256):round(100/200*256),round(75/200*256):round(90/200*256));
                                            
% V3d
input_points = corners{5};
% base_points =  [40 80;40 65; 80 65; 80 80];
base_points =  [105 80; 90 80; 90 40; 105 40];
% input_points = [corners{2};mean(corners{2}(2:3,:)); mean(corners{2})];
% % base_points =  [40 80;40 65; 80 65; 80 80];
% base_points =  [90 80; 75 80; 75 40; 90 40; 75 60; 82.5 60];
udata = [1 201];  vdata = [1 201];  % input coordinate system
tform = maketform('projective',input_points, base_points);
[tmp,xdata,ydata] = imtransform(I,tform,interporation,'udata',udata,...
                                                'vdata',vdata,...
                                                'xdata',udata,...
                                                'ydata',vdata,...
                                                'size',size(I),...
                                                'fill',256);
B(round(20/200*256):round(100/200*256), round(90/200*256):round(110/200*256))=tmp(round(20/200*256):round(100/200*256),round(90/200*256):round(110/200*256));

