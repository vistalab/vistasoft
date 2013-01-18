function [averdist, stdevdist]= InterfiberAveragePoint2CurveDistance(curve1, curve2)
%Average distance between two fibers which are  defined as set of 3d coordinates. Calculated on a point by point basis. Need to be compiled or vectorised. 
%No interpolation used. Averaged across shortest POINT_TO_CURVE distances from all points
%on a shortest fiber to another fiber.
%ER 11/2007

if size(curve1, 2)<size(curve2, 2)
    scurve=curve1; 
lcurve=curve2;
else
    scurve=curve2; 
lcurve=curve1;
end

mindistVector=zeros([size(scurve,2) 1]);
for pnt=1:size(scurve,2)
  
distVector = sqrt((lcurve(1, :)-scurve(1, pnt)).^2 + (lcurve(2, :)-scurve(2, pnt)).^2+(lcurve(3, :)-scurve(3, pnt)).^2);
mindistVector(pnt)=min(distVector);

end

averdist=mean(mindistVector); 
stdevdist=std(mindistVector); 