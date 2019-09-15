classdef maskCropTool < toolBase
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        maskName;
        mask;
        cropedMask;
    end
    
    methods
        function obj = prepare(obj, opt)
            obj.inputDataRootPath = opt.inputDataRootPath;
            obj.maskName = opt.maskName;
            obj.mask = loadmat(fullfile(obj.inputDataRootPath, obj.maskName));
        end%prepare
        %%
        function obj = run(obj, opt)
            tmp = zeros(size(obj.mask));
            tmp(obj.mask > 0) = 1;
            blobMeasurements = regionprops(tmp, 'BoundingBox');
            bBox = floor(blobMeasurements.BoundingBox);
            %square bBox;
            if bBox(4) > bBox(3)
                bBox(3) = bBox(4);
            else
                bBox(4) = bBox(3);
            end
            opt.sideLength =   bBox(4) + 1;
            obj.cropedMask = obj.mask(bBox(2):bBox(2) + bBox(4), bBox(1):bBox(1) + bBox(3));
        end%run
        
        %% getters
        %%
        function mask = getMask(obj)
            mask = obj.mask;
        end
        %%
        function croppedMask = getCroppedMask(obj)
            croppedMask = obj.cropedMask;
        end
        %%
        function maskName = getMaskName(obj)
            maskName = obj.maskName ;
        end%getMaskName
    end
    
end

