classdef SegmentationToolManualMultiRoi < segmentationTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        vdRectMap;
        vgRectMap;
        myoRectMap;
        regionNameListMap;
    end
    
    methods (Access = public)
        
        function run(obj)            
            for k = 1 : length(obj.slcKS)
                slcSerie= obj.slcSerieMap(char(obj.slcKS(k)));
                %slcName = char(obj.slcKS(k));
                [LabeledImgStack, regionNameList] = manualMultiRoiSegmentation(slcSerie, slcSerie(:,:,end), ones(size(slcSerie,1), size(slcSerie, 2)), char(obj.slcKS(k)));
                obj.labelImgMap = mapInsert(obj.labelImgMap, char(obj.slcKS(k)), LabeledImgStack);
                obj.regionNameListMap = mapInsert(obj.regionNameListMap, char(obj.slcKS(k)), regionNameList);
            end
        end%run(obj)
        
        function labeledSlcImg = getLabledSlcImg(obj, slcName)
            labeledSlcImg = sum(obj.labelImgMap(slcName), 3);
        end %getLabledSlcImg
        
        function roiNameList = getRoiNameList(obj, slcName)
            roiNameList = obj.regionNameListMap(slcName);
        end%getRoiNameList
        
    end%(Access = public)
    
end

