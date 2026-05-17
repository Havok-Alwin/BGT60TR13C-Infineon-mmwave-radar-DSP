
N = 2;
c = 3e8;
f = 1e9;              
lambda = c / f;
d = lambda/2;                 % the problem 
pos = (0:N-1) * d;   
theta = [-24 -32]; 
a = steervec(pos/lambda, theta);