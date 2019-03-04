clear
clc
n=[10 20 40 80]; %number of elements
testnum=length(n);
xleft=0;
xright=2*pi;
tleft=0;
tright=1;
k=3; %highest degree of polynomials
A=zeros(k+1);
C=zeros(k+1);
B=zeros(k+1);
DD=zeros(k+1);
E=zeros(k+1,k+1);

for i=1:testnum
    dx=(xright-xleft)/n(i);
    dt=dx^3/1000;
    D=zeros((k+1)*n(i));
    X0=zeros(n(i)*(k+1),1);
    U=zeros(n(i),k+1); %solution matrix
    for j=1:n(i)
        xjmh=xleft+(j-1)*dx; %namely, x_{j-half}
        xjph=xleft+j*dx; %namely, x_{j+half}
        xj=(j-0.5)*dx+xleft;
        for m=0:k
            basismj=@(x) basis(m,x,xj,dx);
            basisgradmj=@(x) basisgrad(m,x,xj,dx);
            basisgradmj2=@(x) basisgrad2(m,x,xj,dx);
            basisgradmj3=@(x) basisgrad3(m,x,xj,dx);
            for l=0:k
                basislj=@(x) basis(l,x,xj,dx);
                basisgradlj=@(x) basisgrad(l,x,xj,dx);
                basisgradlj2=@(x) basisgrad2(l,x,xj,dx);
                basisljm=@(x) basisgrad(l,x,xj-dx,dx);
                basisljp=@(x) basisgrad(l,x,xj+dx,dx);
                basisljm2=@(x) basis(l,x,xj-dx,dx);
                basisljp2=@(x) basis(l,x,xj+dx,dx);
                first=@(x) basislj(x).*basisgradmj3(x); 
                second=@(x) basislj(x).*basismj(x);
                A(m+1,l+1)=-integral(first,xjmh,xjph)-basisgradlj2(xjmh).*basismj(xjmh)+basislj(xjph).*basisgradmj2(xjph)-basisgradlj(xjph)*basisgradmj(xjph);
                B(m+1,l+1)=integral(second,xjmh,xjph);
                C(m+1,l+1)=-basisljm2(xjmh)*basisgradmj2(xjmh)+basisljm(xjmh).*basisgradmj(xjmh);
                DD(m+1,l+1)=basisgradlj2(xjmh)*basismj(xjph);
            end
        end
        A2=B\A;
        C2=B\C;
        DD2=B\DD;
        D((j-1)*(k+1)+1:j*(k+1),(j-1)*(k+1)+1:j*(k+1))=A2;
        if (j>1&&j<n(i))
            D((j-1)*(k+1)+1:j*(k+1),(j-2)*(k+1)+1:(j-1)*(k+1))=C2;
            D((j-1)*(k+1)+1:j*(k+1),j*(k+1)+1:(j+1)*(k+1))=DD2;
        elseif (j==1)
            D((j-1)*(k+1)+1:j*(k+1),(n(i)-1)*(k+1)+1:n(i)*(k+1))=C2;
            D((j-1)*(k+1)+1:j*(k+1),j*(k+1)+1:(j+1)*(k+1))=DD2;
        elseif (j==n(i))
            D((j-1)*(k+1)+1:j*(k+1),(j-2)*(k+1)+1:(j-1)*(k+1))=C2;
            D((j-1)*(k+1)+1:j*(k+1),1:(k+1))=DD2;
        end
        intpoint=linspace(xjmh,xjph,k+1)';
        S=sin(intpoint);
        X0((j-1)*(k+1)+1:j*(k+1))=S;
    end
    
    [sol,t]=RK3( D,X0,dt,tleft,tright,n(i)*(k+1)); 
    evals=200000;
    x=linspace(0,2*pi,evals);
    uh=zeros(evals,1);
    u=zeros(evals,1);

    t2=length(t);
    for p=1:evals
        u(p)=sin(x(p)-t(t2));
        j=floor(x(p)*n(i)/2/pi)+1;
        if (j==n(i)+1) 
            j=j-1;
        end
        xj=(j-0.5)*dx+xleft;
        for l=0:k
            uh(p)=basis(l,x(p),xj,dx)*sol((j-1)*(k+1)+l+1,t2)+uh(p);   
        end
    end
    
    error(i)=abs((cos(x)*(u-uh)))/evals; %moment error
    error2(i)=sum(abs(u-uh))/evals; %l1 error
    error3(i)=sqrt(sum((u-uh).^2)/evals); %l2 error
    error4(i)=max(u-uh); %linf error
end

for i=2:testnum
    rate(i-1)=log(error(i-1)/error(i))/log(2); %rate for moment
    rate2(i-1)=log(error2(i-1)/error2(i))/log(2); %rate for l1
    rate3(i-1)=log(error3(i-1)/error3(i))/log(2); %rate for l2
    rate4(i-1)=log(error4(i-1)/error4(i))/log(2); %rate for linf
end

for i=3:testnum
    rrate2(i-1)=-log((error2(i-1)-error2(i))/(error2(i-2)-error2(i-1)))/log(2); %rate for l1
    rrate3(i-1)=-log((error3(i-1)-error3(i))/(error3(i-2)-error3(i-1)))/log(2); %rate for l2
    rrate4(i-1)=-log((error4(i-1)-error4(i))/(error4(i-2)-error4(i-1)))/log(2); %rate for linf
end
plot(x',uh,'o')
hold on
plot(x',u)
legend('uh','u')
title('P3 Solution for N=40 at t=1')
hold off