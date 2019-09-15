classdef voxelFeatExtractTool < refFeatExtractTool
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = public)
        myoMaskMap;
    end%properties(Access = public)
    
    methods (Access = protected)
        function obj = loadMyoMask(obj)
            for k = 1 : obj.slcPathMap.length
                mask = loadmat(fullfile(obj.patientPath, 'dataPrep', char(obj.slcKS(k)), 'mask.mat'));
%                 se = strel('disk', 1);
%                 mask = imerode(mask, se);
                if ~isa(obj.myoMaskMap,'containers.Map')% create map if does not exists
                    obj.myoMaskMap = containers.Map(char(obj.slcKS(k)), mask) ;
                else % else insert into map
                    obj.myoMaskMap(char(obj.slcKS(k))) = mask;
                end
            end
        end%loadMyoMask(obj)
        
        function obj = processFeatVect(obj)
            for k = 1 : obj.slcPathMap.length
                imSerie = obj.slcSerieMap(char(obj.slcKS(k)));
                mask = obj.myoMaskMap(char(obj.slcKS(k)));
                [H, W, ~] = size(imSerie);
                pos = find(mask == 1);
                [x, y] = ind2sub([H, W], pos);
                featVect = [];
                for l = 1 : length(x)
                    featVect(:, l) = obj.processTicFeat(squeeze(imSerie(x(l), y(l), obj.lwTCrop:obj.upTCrop)), 1);
                end
                obj.slcFeatureTabMap = mapInsert(obj.slcFeatureTabMap, char(obj.slcKS(k)), featVect);
            end
        end%processFeatpoints
        
        
    end%methods (Access = protected)
    
     methods (Access = public)
         %%
         function obj = run(obj)
            obj = obj.loadSlcSerie();
            obj = obj.loadMyoMask();
            obj = obj.processFeatVect();
         end%run
         %%
         function updateMyoMask(obj, slcName, mask)
             obj.myoMaskMap(slcName) = mask;
         end%updateMyoMask
         %%
         function saveMyoMaskUpdate(obj, slcName)
             if nargin == 1
                 slcKS = obj.slcKS;
             else
                 slcKS = {slcName};
             end
             %check for modification
             for k = 1 : length(slcKS)
                 slcName = char(slcKS(k));
                 maskFolderPath = fullfile(obj.patientPath, 'dataPrep', slcName);
                 oldMask = loadmat(fullfile(maskFolderPath, 'mask.mat'));
                 maskDiff = abs(oldMask - obj.myoMaskMap(slcName));
                 maskDiffFlag(k) = 0 ~= max(maskDiff(:));
             end
             
             if sum(maskDiffFlag) > 0 &&...
                     strcmp(questdlg('save myocardium mask changes (a backup of old mask will be done)?'), 'Yes')
                 for k = 1 : length(slcKS)
                     if ~maskDiffFlag(k)
                         continue;
                     end
                     slcName = char(slcKS(k));
                     maskPath = fullfile(obj.patientPath, 'dataPrep', slcName, 'mask.mat');
                     copyfile(maskPath, fullfile(obj.patientPath, 'dataPrep',...
                                      slcName, sprintf('%s_mask.mat.bak', datestr(now, 'yyyymmddTHHMMSS'))), 'f');
                     savemat(fullfile(obj.patientPath, 'dataPrep', slcName, 'mask.mat'), obj.myoMaskMap(slcName));
                 end
             end
         end%saveMyoMaskUpdate
         %% getters
         %%
         function myoMask = getMyoMask(obj, slcName)
             myoMask = obj.myoMaskMap(slcName);
         end%getMyoMask
     end% methods (Access = public)
end

