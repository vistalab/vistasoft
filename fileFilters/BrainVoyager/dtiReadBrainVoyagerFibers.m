function [fiberGroups, filename, coordsType] = dtiReadBrainVoyagerFibers(filename)
%
% [fiberGroups, filename, coordsType] = dtiReadBrainVoyagerFibers([filename])
% 
% fiberGroups(grpNum).name = 'some text string'
% fiberGroups(grpNum).visible = 0 or 1 (boolean)
% fiberGroups(grpNum).thickness = fiber thickness (diameter? in mm?)
% fiberGroups(grpNum).colorRgb = [R G B] (0-255)
% fiberGroups(grpNum).fibers is a cell array of Nx3 lists of points (in
% XYZ Talairach space if coordsType=TAL)
%
% Reads the fibers to the specified file. Prompts the user for the file if none is given.
% 
% coordsType should be 'TAL', 'SYS' or 'BVI'. Default is TAL.
% 
% HISTORY:
%   2003.09.02 RFD (bob@white.stanford.edu) wrote it.
%

if(~exist('filename','var') | isempty(filename))
    [f, p] = uigetfile({'*.fib';'*.*'}, 'Read BrainVoyager fibers file...');
    if(isnumeric(f))
        disp('User cancelled.');
        filename = '';
        return;
    end
    filename = fullfile(p, f);
end

fid = fopen(filename, 'rt');
version = fscanf(fid, 'FileVersion: %f\n');
coordsType = fscanf(fid, 'CoordsType:  %s\n');
numGroups = fscanf(fid, 'NrOfGroups:  %d\n\n');
if(isempty(numGroups) | ~isfinite(numGroups))
    numGroups = 0;
end
for(gNum=1:numGroups)
    fiberGroups(gNum).name = fscanf(fid, 'Name:        %s\n');
    fiberGroups(gNum).visible = fscanf(fid, 'Visible:     %d\n');
    animate = fscanf(fid, 'Animate:     %d\n');
    fiberGroups(gNum).thickness = fscanf(fid, 'Thickness:   %6.2f\n');
    fiberGroups(gNum).colorRgb = fscanf(fid, 'Color:       %03d %03d %03d\n');
    numFibers = fscanf(fid, 'NrOfFibers:  %d\n');
    if(~isempty(numFibers) & isfinite(numFibers))
        for(fNum=1:numFibers)
            numPoints = fscanf(fid, 'NrOfPoints:  %d\n');
            for(p=1:numPoints)
                [fiberGroups(gNum).fibers{fNum}(p,1), fiberGroups(gNum).fibers{fNum}(p,2), fiberGroups(gNum).fibers{fNum}(p,3)] = fscanf(fid, '%7.3f %7.3f %7.3f\n');
            end
            fscanf(fid, '\n');
        end
        fscanf(fid, '\n\n');
    end
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