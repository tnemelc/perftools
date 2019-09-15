classdef SegmentationToolRectangle < segmentationTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        vdRectMap;
        vgRectMap;
        myoRectMap;
    end
    
    methods (Access = public)
        
        function run(obj)            
            for k = 1 : length(obj.slcKS)
                slcSerie = obj.slcSerieMap(char(obj.slcKS(k)));
                slcName = char(obj.slcKS(k));
                [rectMyo, rectVD, rectVG] = rectangleSegmentation(slcSerie, char(obj.slcKS(k)));
                obj.myoRectMap = mapInsert(obj.myoRectMap, slcName, rectMyo);
                obj.vdRectMap  = mapInsert(obj.vdRectMap,  slcName, rectVD);
                obj.vgRectMap  = mapInsert(obj.vgRectMap,  slcName, rectVG);
            end
        end%run(obj)
        
        function rect = getVDRect(obj, slcName)
            rect = obj.vdRectMap(slcName);
        end%getVDRect
        function rect = getVGRect(obj, slcName)
            rect = obj.vgRectMap(slcName);
        end%getVDRect
        function rect = getMyoRect(obj, slcName)
            rect = obj.myoRectMap(slcName);
        end%getVDRect
    end%(Access = public)
    
end

