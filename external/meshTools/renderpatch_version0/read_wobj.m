function FV=read_wobj(filename)
% Read the objects from an W. OBJ file
%
% FV=read_wobj(filename);
%
% FV struct containing:
%
% FV.vertices : This is the N x 3 vertice data normaly used by matlab function patch
% FV.faces    : This is the M x 3 face data normaly used by matlab function patch
%
% FV.vertices_texture: Texture coordinates 
% FV.vertices_normal : Normal vectors
% FV.vertices_point  : Vertice data used for points and lines   
%
% FV.objects  : Cell object with all objects in the OBJ file, 
%           example of a mesh object:
%       FV.objects{i}.type='f'               
%       FV.objects{i}.data.vertices: [n x 3 double]
%       FV.objects{i}.data.texture:  [n x 3 double]
%       FV.objects{i}.data.normal:   [n x 3 double]
%     
%
% Function is written by D.Kroon University of Twente (May 2009)

if(exist('filename','var')==0)
    [filename, pathname] = uigetfile('*.obj', 'Read obj-file');
    filename = [pathname filename];
end

% Open a DI3D OBJ textfile
fid=fopen(filename,'r');

% Vertex data
vertices=[]; nv=0;
vertices_texture=[]; nvt=0;
vertices_point=[]; nvp=0;
vertices_normal=[]; nvn=0;

% Surface data
objects={}; no=0;

% Lines read is zero
linesp=0; 

% Loop through the Wavefront object file
while true
    if(mod(linesp,10000)==0), 
        disp(['Lines processed : ' num2str(linesp)]); 
    end
    
    % Update number of lines
    linesp=linesp+1;

    % Read a textline
    tline = fgetl(fid);
    
    % Break if end of file is reached
    if ~ischar(tline), break, end
    
    % Process if line is not empty
    if(~isempty(tline))
        % Split line in by empty space separate words
        twords=stringsplit(tline,' ');
        
        type=twords{1};
        
        % Switch on data type line
        switch(type)
            case{'g','s','mg','o','usemtl'}
                % Group name, Smoothing group, Mergin Group, Object name
                no=no+1;
                if(mod(no,10000)==1), objects{no+10001}={}; end
                objects{no}.type=type;
                objects{no}.data=twords{2:end};
            case('v') % vertices 
                nv=nv+1;
                if(length(twords)==4)
                    % Reserve block of memory
                    if(mod(nv,10000)==1), vertices(nv+1:nv+10001,1:3)=0; end
                    % Add to vertices list X Y Z
                    vertices(nv,1:3)=[str2double(twords{2}) str2double(twords{3}) str2double(twords{4})];
                else
                    % Reserve block of memory
                    if(mod(nv,10000)==1), vertices(nv+1:nv+10001,1:4)=0; end
                    % Add to vertices list X Y Z W
                    vertices(nv,1:4)=[str2double(twords{2}) str2double(twords{3}) str2double(twords{4}) str2double(twords{5})];
                end
            case('vp')
                % Specifies a point in the parameter space of curve or surface
                nvp=nvp+1;
                if(length(twords)==2)
                    % Reserve block of memory
                    if(mod(nvp,10000)==1), vertices_point(nvp+1:nvp+10001,1)=0; end
                    % Add to vertices point list U
                    vertices_point(nvp,1)=str2double(twords{2});
                elseif(length(twords)==3)
                    % Reserve block of memory
                    if(mod(nvp,10000)==1), vertices_point(nvp+1:nvp+10001,1:2)=0; end
                    % Add to vertices point list U V
                    vertices_point(nvp,1:2)=[str2double(twords{2}) str2double(twords{3})];
                else
                    % Reserve block of memory
                    if(mod(nvp,10000)==1), vertices_point(nvp+1:nvp+10001,1:3)=0; end
                    % Add to vertices point list U V W
                    vertices_point(nvp,1:3)=[str2double(twords{2}) str2double(twords{3}) str2double(twords{4})];
                end
            case('vn')
                % A normal vector
                nvn=nvn+1; if(mod(nvn,10000)==1),  vertices_normal(nvn+1:nvn+10001,1:3)=0; end
                % Add to vertices list I J K
                vertices_normal(nvn,1:3)=[str2double(twords{2}) str2double(twords{3}) str2double(twords{4})];
            case('vt') 
            % Vertices Texture Coordinate in photo
            % U V W
                nvt=nvt+1;
                if(length(twords)==2)
                    % Reserve block of memory
                    if(mod(nvt,10000)==1), vertices_texture(nvt+1:nvt+10001,1)=0; end
                    % Add to vertices texture list U
                    vertices_texture(nvt,1)=str2double(twords{2});
                elseif(length(twords)==3)
                    % Reserve block of memory
                    if(mod(nvt,10000)==1), vertices_texture(nvt+1:nvt+10001,1:2)=0; end
                    % Add to vertices texture list U V
                    vertices_texture(nvt,1:2)=[str2double(twords{2}) str2double(twords{3})];
                else
                    % Reserve block of memory
                    if(mod(nvt,10000)==1), vertices_texture(nvt+1:nvt+10001,1:3)=0; end
                    % Add to vertices texture list U V W
                    vertices_texture(nvt,1:3)=[str2double(twords{2}) str2double(twords{3}) str2double(twords{4})];
                end
            case{'cstype','deg','step','parm','trim','surf','hole','scrv','sp','curv','curv2','p'};
            % Other data Elements and attributes
                no=no+1; if(mod(no,10000)==1), objects{no+10001}={}; end
                objects{no}.type=type;
                objects{no}.data=str2double(twords{2:end});
            case('bmat');
                % Free-form gemometry statetment
                no=no+1;
                if(mod(no,10000)==1), objects{no+10001}={}; end
                % The b-matrix consist of multiple lines
                row=0; bmatrix=zeros(1,1);
                if(twords{2}=='u')
                    objects{no}.type='bmat u';
                else
                    objects{no}.type='bmat v';
                end
                s=3;
                while true
                    row=row+1; col=0;
                    for i=s:length(twords)
                        if(sum(twords{i}=='\')==0)
                            col=col+1;
                            val=str2double(twords{i});
                            bmatrix(row,col)=val;
                        end
                    end
                    % This was the last matrix row
                    if(sum(tline=='\')==0), break; end
                    % Update number of lines
                    linesp=linesp+1;
                    % Read a textline
                    tline = fgetl(fid);
                    % Split line in by empty space separate words
                    twords=stringsplit(tline,' ');
                    s=2;
                end
                objects{no}.data=bmatrix;
            case('l');
                no=no+1; if(mod(no,10000)==1), objects{no+10001}={}; end
                array_vertices=[];
                array_texture=[];
                for i=2:length(twords);
                   ttwords=stringsplit(twords{i},'/');
                   val=str2double(ttwords{1});
                   if(val<0), val=val+1+nv; end
                   array_vertices(i-1)=val;
                   if(length(ttwords)>1),
                       val=str2double(ttwords{2});
                       if(val<0), val=val+1+nvt; end
                       array_texture(i-1)=val;
                   end
                end
                objects{no}.type='l';
                objects{no}.data.vertices=array_vertices;
                objects{no}.data.texture=array_texture;
            case('f');
                no=no+1; if(mod(no,10000)==1), objects{no+10001}={}; end
                array_vertices=[];
                array_texture=[];
                array_normal=[];
                for i=2:length(twords);
                   ttwords=stringsplit(twords{i},'/');
                   val=str2double(ttwords{1});
                   if(val<0), val=val+1+nv; end
                   array_vertices(i-1)=val;
                   if(length(ttwords)>1), 
                       val=str2double(ttwords{2});
                       if(val<0), val=val+1+nvt; end
                       array_texture(i-1)=val;
                   end
                   if(length(ttwords)>2), 
                       val=str2double(ttwords{3}); 
                       if(val<0), val=val+1+nvn; end
                       array_normal(i-1)=val; 
                   end
                end

                % A face of more than 3 indices is always split into
                % multiple faces of only 3 indices.
                objects{no}.type='f';
                findex=[1 2 3];
                objects{no}.data.vertices=array_vertices(findex);
                if(~isempty(array_texture)), objects{no}.data.texture=array_texture(findex); end
                if(~isempty(array_normal)), objects{no}.data.normal=array_normal(findex); end
                for i=1:length(array_vertices)-3;
                    no=no+1; if(mod(no,10000)==1), objects{no+10001}={}; end
                    findex=[1 2+i 3+i];
                    findex(findex>length(array_vertices))=findex(findex>length(array_vertices))-length(array_vertices);
                    objects{no}.type='f';
                    objects{no}.data.vertices=array_vertices(findex);
                    if(~isempty(array_texture)), objects{no}.data.texture=array_texture(findex); end
                    if(~isempty(array_normal)), objects{no}.data.normal=array_normal(findex); end
                end
            case('end')
                no=no+1;
                if(mod(no,10000)==1), objects{no+10001}={}; end
                objects{no}.type='end';
            case{'#','$'}; 
                % Comment
                disp(tline);
        end
    end
                
end
fclose(fid);

% Initialize new object list, which will contain the "collapsed" objects
objects2{no}={};

index=0;

i=0;
while (i<no), i=i+1;
    type=objects{i}.type;
    % First face found
    if((length(type)==1)&&(type(1)=='f'))
        % Get number of faces
        for j=i:no
            type=objects{j}.type;
            if((length(type)~=1)||(type(1)~='f')) 
                j=j-1; break; 
            end
        end
        numfaces=(j-i)+1;
        
        index=index+1;
        objects2{index}.data.type='f';
        % Process last face first to allocate memory 
        objects2{index}.data.vertices(numfaces,:)= objects{i}.data.vertices;
        objects2{index}.data.texture(numfaces,:) = objects{i}.data.texture;
        objects2{index}.data.normal(numfaces,:)  = objects{i}.data.normal;
        % All faces to arrays
        for k=1:numfaces
            objects2{index}.data.vertices(k,:)= objects{i+k-1}.data.vertices;
            objects2{index}.data.texture(k,:) = objects{i+k-1}.data.texture;
            objects2{index}.data.normal(k,:)  = objects{i+k-1}.data.normal;
        end
        FV.faces=objects2{index}.data.vertices;
        i=j;

    else
        index=index+1; objects2{index}=objects{i};
    end
end

% Add all data to output struct
FV.objects{index}={};
for i=1:index, FV.objects{i}=objects2{i}; end
FV.vertices=vertices(1:nv,:);
FV.vertices_point=vertices_point(1:nvp,:);
FV.vertices_normal=vertices_normal(1:nvn,:);
FV.vertices_texture=vertices_texture(1:nvt,:);


function twords=stringsplit(tline,tchar)
% Get start and end position of all "words" separated by a char
i=find(tline(2:end-1)==tchar)+1; i_start=[1 i+1]; i_end=[i-1 length(tline)];
% Create a cell array of the words
twords=cell(1,length(i_start)); for j=1:length(i_start), twords{j}=tline(i_start(j):i_end(j)); end

