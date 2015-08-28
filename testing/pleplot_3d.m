
final=randi(5,50,50,5);
X=linspace(1,50,50);
Z=1:5;
[x y z]=meshgrid(X,X,Z);
xslice=[];
yslice=[];
zslice=Z;

figure;
h=slice(x,y,z,final,xslice,yslice,zslice);
set(h,'FaceColor','interp');
set(h,'FaceAlpha','0.5');
set(h,'EdgeColor','none');
%set(h,'DiffuseStrength',0.8);
colormap('copper');
colorbar('vert');
view([-68 12])