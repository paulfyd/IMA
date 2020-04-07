function y = angle2D(x)

%%
a = angle(x);

b1 = unwrap(a);
b2 = unwrap(b1,[],2);
b3 = fliplr(unwrap(a));
b4 = fliplr(unwrap(b3,[],2));

y = (b2+b4)/2/(-2*pi); 


%ANGLE1 = transpose(unwrap(transpose(unwrap(angle(IM1./IM2)))))/(-2*pi);
