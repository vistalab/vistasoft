function motionCompPlayMeanMovie(slice,view)
%
%    gb 04/30/05
%
%    motionCompPlayMeanMovie(view,slice)
%
% Plays the movie of the mean maps of the choosen slice, or creates the
% movie if it does not exist.
%
% The argument view is optional but an error in thrown if it is not
% passed in and the movie does not exist
%
if ~ieNotDefined('view')
    cd(dataDir(view))
end

if ieNotDefined('slice')
    slice = 18;
end

if ~exist(['movie_' num2str(slice) '.avi'])
    try
        motionCompMeanMovie(view,slice)
    catch
        error('The movie has not been created. Please insert a view argument');
    end
end

aviobj = aviread(['movie_' num2str(slice)]);
mplay(aviobj);