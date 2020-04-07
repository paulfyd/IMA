function y = applyAffineMotion(x,b,B,out)
%APPLYAFFINEMOTION warps an image using an affine motion model
%   y = applyAffineMotion(x,b,B)
%   x = image; b = translation vector; B = 2x2 matrix
%
if nargin<4, out = 100; end
if nargin<3,
    B=zeros(2);
end
if nargin<2,
    error('At least two parameters are needed')
end
[N M] = size(x);
[px py] = meshgrid(-(M-1)/2:(M-1)/2, -(N-1)/2:(N-1)/2);

mvfx = b(1) + B(1,1)*px + B(1,2)*py;
mvfy = b(2) + B(2,1)*px + B(2,2)*py;

mvf(:,:,2)=mvfx;
mvf(:,:,1)=mvfy; 

y = fracMc(x,mvf,out);   


