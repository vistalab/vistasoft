function  dtiFindFGOI

%This functions takes [fgA, A, embbasis] (this is atlas), a set of nvecs in that
%atlas space that define an fgOI, and a new fibergroup fgS. The new fibergroup
%get embedded into the space, and those fibers that fall within the
%boundaries of the fgOI, are highlighted. 



nvec=size(fgOI, 2); 


%Compute embedding vectors for S; 
E=dtiNewDataOntoEmbeddingVectors(A, S, embbasis, nvec);


