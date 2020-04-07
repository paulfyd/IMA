function y = medianFilter(x,N)
z = padarray(x,[N N],'replicate');
[R C ] =size(x);
y = zeros(R,C);
for r = 1:R,
    for c=1:C,
        tmp = z(r:r+2*N,c:c+2*N);
        y(r,c) = median(tmp(:));
    end
end

        
