classdef myoMaskEditorImSerieTool < exampleImgSerieTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = public)
        function obj = run(obj, ~)
            obj = obj.run@cPerfImSerieTool();
            obj = obj.loadMyoMask();
        end
    end
    
    methods (Access = public)
        function updateMyoMask(obj, isName, mask)
            obj.myoMaskMap = mapInsert(obj.myoMaskMap, isName, mask);
        end
        
         %%
        function saveMyoMaskUpdate(obj, isName)
            if nargin == 1
                 slcKS = obj.isKS;
             else
                 slcKS = {isName};
             end
             %check for modification
             for k = 1 : length(slcKS)
                 isName = char(slcKS(k));
                 maskFolderPath = fullfile(obj.dataPath, 'dataPrep', isName);
                 oldMask = loadmat(fullfile(maskFolderPath, 'mask.mat'));
                 maskDiff = abs(oldMask - obj.myoMaskMap(isName));
                 maskDiffFlag(k) = 0 ~= max(maskDiff(:));
             end
             
             if sum(maskDiffFlag) > 0 &&...
                     strcmp(questdlg('save myocardium mask changes (a backup of old mask will be done)?'), 'Yes')
                 for k = 1 : length(slcKS)
                     if ~maskDiffFlag(k)
                         continue;
                     end
                     isName = char(slcKS(k));
                     maskPath = fullfile(obj.dataPath, 'dataPrep', isName, 'mask.mat');
                     copyfile(maskPath, fullfile(obj.dataPath, 'dataPrep',...
                                      isName, sprintf('%s_mask.mat.bak', datestr(now, 'yyyymmddTHHMMSS'))), 'f');
                     savemat(fullfile(obj.dataPath, 'dataPrep', isName, 'mask.mat'), obj.myoMaskMap(isName));
                 end
             end
        end
       
    end
    
end

