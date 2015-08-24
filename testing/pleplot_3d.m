
final=randi(5,10,10,5);
X=linspace(1,10,10);
Z=1:5;
[x y z]=meshgrid(X,X,Z);
xslice=[];
yslice=[];
zslice=Z;

figure;
h=slice(x,y,z,final,xslice,yslice,zslice);
set(h,'FaceColor','interp');
%set(h,'FaceAlpha','0.5');
set(h,'EdgeColor','none');
%set(h,'DiffuseStrength',0.8);
colormap('copper');
colorbar('vert');
view([-68 12])