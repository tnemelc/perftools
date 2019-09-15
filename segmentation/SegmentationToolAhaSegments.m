classdef SegmentationToolAhaSegments < segmentationTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = public)
        
        function run(obj)
            for k = 1 : length(obj.slcKS)
                slcSerie = obj.slcSerieMap(char(obj.slcKS(k)));
                curPkImg = obj.slcPeakImgMap(char(obj.slcKS(k)));
                [H, W] = size(curPkImg);
                %display the pkeak Image and ask user to click on the LV/RV
                %junction
                h = figureMgr.getInstance().newFig('RVLV'); imagesc(curPkImg); title('Choose the jonction between RV/LV');
                axis off; axis image;
                [pc, pl] = ginput(1);
                pl = round(pl); pc = round(pc);
                close(h);
                mask = obj.maskMap(char(obj.slcKS(k)));
                measurements = regionprops(mask, 'Centroid');
                center = [round(measurements.Centroid(2)), round(measurements.Centroid(1))];
                mask(center(1), center(2)) = 1;
                %matrix and sector
                switch char(obj.slcKS(k))
                    case 'apex'
                        nbSegments = 4;
                    case {'base', 'mid'}
                        nbSegments = 6;
                end
                [~, maskSegmentsStack] = Sector_from_roi_cda(center, [pc pl], mask, curPkImg, nbSegments);
                %
                labeledImg.img = zeros(H, W);

                for l = 1 : nbSegments
                    labeledImg.img = labeledImg.img + maskSegmentsStack(:, :, l) * l;
                end%for l = 1 : 6
                if ~isa(obj.labelImgMap,'containers.Map')% create map if does not exists
                    obj.labelImgMap = containers.Map(char(obj.slcKS(k)), labeledImg) ;
                else % else insert into map
                    obj.labelImgMap(char(obj.slcKS(k))) = labeledImg;
                end
            end%for k = 1 : length(obj.slcKS)
        end%run
        
    end%(Access = public)
    
end

