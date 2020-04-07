%% Estimation of global translation
clear all; close all; clc; 
%% Read image
im1 = double(imread('ball.bmp'));  
%im1= double(imread('lena.bmp'));
% Add noise to avoid a perfectly uniform background
sigma = 2; im1 = im1+ sigma*randn(size(im1));
figure; imagesc(uint8(im1)); colormap(gray(256)); axis image;
[N M] = size(im1);
%% Apply translation
horiz_displacement = 10.3;
vert_displacement  = 1.2;
b = [ horiz_displacement, vert_displacement]; 
% Affine motion matrix
B= zeros(2); % 
%B = [0 0.00001; -0.00001 0]; %
im2 = applyAffineMotion(im1,b,B, 'circular');
figure; imagesc(uint8(im2)); colormap(gray(256)); axis image;


%%  Estimation by Fourier Transform
IM1 = fft2(im1); % F[ i(x,y)]         = I(fx,fy)
IM2 = fft2(im2); % F[ i(x+dx,y+dy) ]  = I(fx,fy) exp(-2 pi j (dx*fx+dy*fy))
% IM1/IM2 = exp[ -2 pi j (dx*x+dy*y)] 
phi = angle2D(IM1./IM2);

%%
% Show phi = (dx*fx+dy*fy): it should be a planar surface
[fx fy] = meshgrid((-(M-1)/2:(M-1)/2)/M, (-(N-1)/2:(N-1)/2)/N);
figure;
surf(fx,fy,phi); shading interp;
title('\phi(f_x, f_y)');
xlabel('f_x'); ylabel('f_y');

%% Translation estimation: looking for the slope of the plane
% Method 1: Median of the gradient
[gx gy] = gradient(phi,1/M,1/N);
figure; imagesc([gx,gy]); axis image; colorbar
GX1= median(gx(:));
GY1= median(gy(:));

%%
% Method 2: Least Square planar approximation of phi
phi=phi-phi(N/2+1, M/2+1);
t = medianFilter(phi,1);

tmp1= fx(:);
tmp2 =fy(:);
tmp3 = t(:);
A= [tmp1, tmp2];  x0=tmp3;
bEst = A\x0;

%% Show estimated and original surfaces
% Z = bEst(1)*fx/N+bEst(2)*fy/M;
% figure;
% hold on;
% surf(fx/N,fy/M,Z);
% surf(fx/N,fy/M,phi);
% shading interp

%% Print results
fprintf('Method     bx      by\n\nGrad+Med%9.3f%9.3f\nLS plane%9.3f%9.3f\n', ...
    GX1,GY1,bEst(1),bEst(2));



%% Estimation by block matching
lambda = 0;  % If lambda==0, no regularization is performed
mvf = me_ssd(im2,im1,32,32,10,lambda);
% Show MVF computed by block matching
displayMVF(im2,mvf,32); 
% Compute global motion as median motion vector
mvf_x = mvf(:,:,2);
mvf_y = mvf(:,:,1);
bx = median(mvf_x(:));
by = median(mvf_y(:));
% Print results
fprintf('--------------------------\nBM SSD  %9.3f%9.3f\n',bx,by);

%% Estimation by H.S. optic flow
alpha = 100; ite = 100;
uInitial = mvf(:,:,2); vInitial=mvf(:,:,1);
[u, v] = HS(im2, im1, alpha, ite, uInitial, vInitial,0);
mvf_hs(:,:,1) = v; mvf_hs(:,:,2) = u;
% Show MVF computed by block matching
displayMVF(im1,mvf_hs,4); 

% Compute global motion as median motion vector
bx = median(u(:));
by = median(v(:));
% Print results
fprintf('--------------------------\nHS SSD  %9.3f%9.3f\n',bx,by);
%%
fprintf('--------------------------\nActual  %9.3f%9.3f\n',b(1),b(2));




