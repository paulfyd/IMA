function y = gauss2d(x,d0)
%GAUSS2D Bi-dimensional low-pass Gaussian filtering
%   Y=GAUSS2D(X,D0) filters image X with a Gaussian filter whose standard
%   deviation i D0
%   X can be a gray level image or a RGB image
%   
[N M Z] = size(x);
y=zeros(N,M,Z);

[k l] = meshgrid(-M/2+1:M/2,-N/2+1:N/2);
D = exp(-(k.^2+l.^2)/2/(d0^2));

if Z==1,
    y = real(ifft2( fftshift(D).* fft2(x)));
else
    for z=1:Z,
        y(:,:,z) = real(ifft2( fftshift(D).* fft2(x(:,:,z))));
    end
end
