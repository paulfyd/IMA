function h=displayMVF(I,mvf,subsamp,block)
%DISPLAYMVF shows motion vectors
%    This function shows the motion vector field mvf against an image
%    displayMVF(I,MVF,SUBSAMPLE)  
%    I    is the image to be shown; if it is a single component image the
%         colormap is gray(256)
%    MVF  is the motion vector field. It should be in the dense format, 
%         with 2 components, the first for the vertical (row-wise) the
%         second for the horizontal (column-wise) component. 
%    SUBSAMPLE is the subsampling factor used to show the dense mvf. It can
%         be a scalar if the same subsampling must be used along rows and
%         columns; otherwise it should be in the form [rowSub colSub]
%
%    displayMVF(I,MVF,SUBSAMPLE,BLOCK)  
%    A fourth optional parameter can be given in order to trace the block
%    contours. If BLOCK is equal to zero, the blocks have the size
%    specified by the SUBSAMPLE parameter. Otherwise, ant other blocksize
%    can be assigned. BLOCK can be a scalar for square blocks; it must be a
%    vector in order to assign different row and col sizes
%
%    See also: me, mc, fracMc
%    (C) 2003-2008 Marco Cagnazzo - TELECOM-ParisTech
%    

if numel(subsamp) == 1, subsamp(2) = subsamp; end


[row  col z] = size(I);
% Subsample dense MVF 
vectRow=mvf(1:subsamp(1):row,1:subsamp(2):col,1);
vectCol=mvf(1:subsamp(1):row,1:subsamp(2):col,2);

% Determine vector origins
[X,Y]=meshgrid(1:subsamp(2):col,1:subsamp(1):row);
X = X + floor(subsamp(1)/2);
Y = Y + floor(subsamp(2)/2);

% Show image
figure; h=imagesc(I);  hold on; 
vh = quiver(X,Y,vectCol,vectRow, 3,'r');
set(vh, 'Linewidth', 2, 'color','green');
axis equal
hold off;
if size(I,3) == 1, colormap(gray(256)); end;

% Build grid
if nargin == 4
    if isequal(block,0),
        block=subsamp;
    else
        if numel(block) == 1, block(2) = block; end
    end

    horPos = 0.5:block(2):col;
    Xhor  = kron(ones(row,1),horPos);
    vertPos = 1:row;
    Yhor = transpose( kron(vertPos,ones(numel(horPos),1)));
    line(Xhor,Yhor,'color','yellow','linewidth',2);
    verPos = 0.5:block(1):row;
    Yhor  = kron(ones(col,1),verPos);
    horPos = 1:col;
    Xhor = transpose( kron(horPos,ones(numel(verPos),1)));
    line(Xhor,Yhor,'color','yellow','linewidth',2);
end