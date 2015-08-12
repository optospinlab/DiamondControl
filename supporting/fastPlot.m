figure(101)
im = rand(100,100);
tic
for j=1:100
   plot(im(:,j)) 
   drawnow
end
 toc
 
 % fast
 
  h=plot(im(:,1)) 


 tic

for j=1:100
   set(h,'ydata',im(:,j))
end
 toc
 
 
 