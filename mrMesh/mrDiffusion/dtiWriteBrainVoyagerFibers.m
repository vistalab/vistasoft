function filename = dtiWriteBrainVoyagerFibers(fiberGroups, filename, coordsType)
% Anyone use this for BV?  Or should we rename for Tal only?
%
% filename = dtiWriteBrainVoyagerFibers(fiberGroups, [filename], [coordsType])
% 
% fiberGroups(grpNum).name = 'some text string'
% fiberGroups(grpNum).visible = 0 or 1 (boolean)
% fiberGroups(grpNum).thickness = fiber thickness (diameter? in mm?)
% fiberGroups(grpNum).colorRgb = [R G B] (0-255)
% fiberGroups(grpNum).fibers is a cell array of Nx3 lists of points (in
% XYZ Talairach space if coordsType=TAL)
%
% Writes the fibers (assumed to be in Talairach coords) to the specified
% file. Prompts the user for the file if none is given.
% 
% coordsType should be 'TAL', 'SYS' or 'BVI'. Default is TAL.
% 
% HISTORY:
%   2003.07.02 RFD (bob@white.stanford.edu) wrote it.
%
% Bob (c) Stanford VISTASOFT team.  Probably should be removed.

if(~exist('filename','var') | isempty(filename))
    [f, p] = uiputfile('fibers.fib', 'Save BrainVoyager fibers file...');
    if(isnumeric(f))
        disp('User cancelled.');
        filename = '';
        return;
    end
    filename = fullfile(p, f);
end
if(~exist('coordsType','var') | isempty(coordsType))
    coordsType = 'TAL';
end
numGroups = length(fiberGroups);
fid = fopen(filename, 'wt');
fprintf(fid, 'FileVersion: 1.0\n');
fprintf(fid, 'CoordsType:  %s\n', coordsType);
fprintf(fid, 'NrOfGroups:  %d\n\n', numGroups);
for(gNum=1:numGroups)
    fprintf(fid, 'Name:        %s\n', fiberGroups(gNum).name);
    fprintf(fid, 'Visible:     %d\n', fiberGroups(gNum).visible);
    fprintf(fid, 'Animate:     0\n');
    fprintf(fid, 'Thickness:   %6.2f\n', fiberGroups(gNum).thickness);
    fprintf(fid, 'Color:       %03d %03d %03d\n',  fiberGroups(gNum).colorRgb);
    numFibers = length(fiberGroups(gNum).fibers);
    fprintf(fid, 'NrOfFibers:  %d\n', numFibers);
    for(fNum=1:numFibers)
        numPoints = size(fiberGroups(gNum).fibers{fNum},1);
        fprintf(fid, 'NrOfPoints:  %d\n', numPoints);
        for(p=1:numPoints)
            fprintf(fid, '%7.3f %7.3f %7.3f\n', fiberGroups(gNum).fibers{fNum}(1,p), ...
                                                fiberGroups(gNum).fibers{fNum}(2,p), ...
                                                fiberGroups(gNum).fibers{fNum}(3,p));
        end
        fprintf(fid, '\n');
    end
    fprintf(fid, '\n\n');
end
fclose(fid);
return;

% Code from BrainVoyager:
%
% 	float pos_x, pos_y, pos_z, thickness;
% 	int n_groups, n_fibers, n_points, cr, cg, cb, FileVersion;
% 	bool SystemCoords;
% 	QString strTemp, strTemp2, CoordsType;
% 	// file header
% 	ar << "FileVersion: " << FibersFileVersion << "\n";
% 	if(FibersSystemCoords == 2)
% 		ar << "CoordsType:  BVI\n";
% 	else if(FibersSystemCoords == 1)
% 		ar << "CoordsType:  SYS\n";
% 	else
% 		ar << "CoordsType:  TAL\n";
% 	ar << "NrOfGroups:  " << NrOfFiberGroups << "\n\n";
% 	int g, i, p;
% 	for(g=0; g<NrOfFiberGroups; g++){
% 		ar << "Name:        " << QString(FiberGroups[g].Label) << "\n";
% 		ar << "Visible:     " << (int)FiberGroups[g].visible << "\n";
% 		ar << "Animate:     " << (int)FiberGroups[g].animate << "\n";
% 		ar << "Thickness:   " << FiberGroups[g].thickness << "\n";    // %6.2f
% 		ar << "Color:       " << FiberGroups[g].r << " " << FiberGroups[g].g << " " << FiberGroups[g].b << "\n"; // %3i  %3i  %3i
% 		
% 		n_fibers = FiberGroups[g].n_fibers;
% 
% 		ar << "NrOfFibers:  " << n_fibers << "\n";
% 		
% 		for(i=0; i<n_fibers; i++)
% 		{
% 			n_points = FiberGroups[g].fibers[i].n_points;
% 
% 			ar << "NrOfPoints:  " << n_points << "\n";
% 
% 			for(p=0; p<n_points; p++)
% 			{
% 				ar << FiberGroups[g].fibers[i].pos_x[p] << " " << FiberGroups[g].fibers[i].pos_y[p] << " " << FiberGroups[g].fibers[i].pos_z[p] << "\n";
% 				// fprintf(fp_fbr, "%7.3f %7.3f %7.3f\n", Fibers[i].pos_x[p], Fibers[i].pos_y[p], Fibers[i].pos_z[p]);
% 			}
% 			ar << "\n";
% 		}
% 		ar << "\n\n";
% 	}
% 
% 	f.close();