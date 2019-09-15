% displayFearturesSpace.m
% brief: diplay vectors in features space
%
%
% references:
%
%
% input:
% dimVectorTab : vector of dimensions to display in the feature space
% dimensionNames: names of dimensions
% output:
% handle: handle of features space figure 
%
%
% keywords:
% author: C.Daviller
% date: 28-Oct-2017  


 function handle =  displayFeaturesSpace(dimVectorTab, dimensionsNameKS, opt)
 if ~nargin
	displayFeaturesSpaceUI();
 return;
 elseif nargin < 2
     cprintf('red', 'error: displayFeaturesSpace requires at least dimVectorTab and dimensionsNameKS arguments')
 elseif nargin == 2
     opt.style = '-';
     opt.color = 'b';
     opt.figName = 'featuresSpace';
 else
     if ~isfield(opt, 'color')
        opt.color = 'b';
     end
     if ~isfield(opt, 'figName')
        opt.figName = 'featuresSpace';
     end
     if ~isfield(opt, 'style')
        opt.style = '-';
     end
 end
 
     
 if isfield(opt, 'axisHdle')
    handle = opt.axisHdle;
    axes(handle);
 else
     handle = figureMgr.getInstance().newFig(opt.figName);
 end
 plot3(dimVectorTab(1, :), dimVectorTab(2, :), dimVectorTab(3, :), 'color', opt.color, 'linestyle', opt.style);
 xlabel(char(dimensionsNameKS(1)));
 ylabel(char(dimensionsNameKS(2)));
 zlabel(char(dimensionsNameKS(3)));
 
%  x = xlim;y=ylim; z=zlim;
%  quiver3(0,0,0,x(2),0,0);
%  quiver3(0,0,0,0,y(2),0);
%  quiver3(0,0,0,0,0,z(2));
 grid on;
 hold all;
 
end