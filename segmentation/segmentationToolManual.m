classdef segmentationToolManual < segmentationTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = public)
        
        function run(obj)            
            for k = 1 : length(obj.slcKS)
                slcSerie = obj.slcSerieMap(char(obj.slcKS(k)));
                labelImg.img  = manualSegmentation(slcSerie, char(obj.slcKS(k)));
                % add it to the map
                if ~isa(obj.labelImgMap,'containers.Map')% create map if does not exists
                    obj.labelImgMap = containers.Map(char(obj.slcKS(k)), labelImg) ;
                else % else insert into map
                    obj.labelImgMap(char(obj.slcKS(k))) = labelImg;
                end
            end
        end%run(obj)
        
    end%(Access = public)
    
end

