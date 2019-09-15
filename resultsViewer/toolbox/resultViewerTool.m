classdef resultViewerTool < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        paramMatrixMap;
        slcKS;
        slcPathMap;
        peakImgMap;
        peakPosMap;
        imHistOpt; %image histogram (not map histogram) options
    end
    
    methods (Access = public)
        function prepare(obj, opt)
            obj.slcKS = {'apex', 'mid', 'base'};
            obj.slcPathMap = containers.Map(obj.slcKS, ...
                {[opt.path '\apex\'],...
                [opt.path '\mid\'],...
                [opt.path '\base\']});
            obj.imHistOpt.contrast = opt.contrast;
            obj.imHistOpt.brightness = opt.brightness;
            for k = 1 : 3 % remove possible inexistant directory
                if ~isdir(obj.slcPathMap(char(obj.slcKS(k))))
                    disp(['no direrctory ' obj.slcPathMap(char(obj.slcKS(k)))]);
                    remove(obj.slcPathMap, char(obj.slcKS(k)));
                    continue;
                end
            end
            %remove key with not existing directory
            rmSlcCount = 0;
            for k = 1 : 3
                if ~obj.slcPathMap.isKey(char(obj.slcKS(k - rmSlcCount)))
                    obj.slcKS(k - rmSlcCount) =  '';
                    rmSlcCount = rmSlcCount + 1;
                end
            end
        end
        
        function loadpeakImg(obj)
            
            for k = 1 : obj.slcPathMap.length
                dcmPath = fileparts(fileparts(fileparts(fileparts(obj.slcPathMap(char(obj.slcKS(k)))))));
                imStack = loadDcm(fullfile(dcmPath, char(obj.slcKS(k))));
                peakPos = selectPeakImage(imStack);
                obj.peakImgMap = mapInsert(obj.peakImgMap, char(obj.slcKS(k)), imStack(:, :, peakPos));
                obj.peakPosMap = mapInsert(obj.peakPosMap, char(obj.slcKS(k)), peakPos);
            end
            
        end
    end%methods (Access = public)
    
    methods  (Access = protected)
        
        function corrIm = correctImage(obj, image)
            maxValue = max(image(:));
            lut(1, :) = (0 : maxValue);
            tmp = obj.imHistOpt.contrast .*  lut(1, :) + obj.imHistOpt.brightness;
            tmp(tmp < 0) = 0; tmp(tmp > maxValue) = maxValue;
            lut(2, :) = tmp;
            corrIm = zeros(size(image));
            for k = 1 : numel(image)
                corrIm(k) = lut(2, lut(1,:) == image(k));
            end
        end%correctImage
        
        function onKeyPressCb(obj, ~, arg)
            switch arg.Key
                case 'uparrow'
                    if obj.imHistOpt.brightness < 100
                        obj.imHistOpt.brightness = obj.imHistOpt.brightness + 1;
                    end
                case 'downarrow'
                    if obj.imHistOpt.brightness > 0
                        obj.imHistOpt.brightness = obj.imHistOpt.brightness - 1;
                    end
                case 'leftarrow'
                    if obj.imHistOpt.contrast > 0.2
                        obj.imHistOpt.contrast = obj.imHistOpt.contrast - 0.2;
                    end
                case 'rightarrow'
                    if obj.imHistOpt.contrast < 5
                        obj.imHistOpt.contrast = obj.imHistOpt.contrast + 0.2;
                    end
            end%switch
            cprintf('green', 'resultViewerTool: \ncontrast: %0.1f, brightness: %d\n', obj.imHistOpt.contrast, obj.imHistOpt.brightness);
        end%onKeyPressCb
        
    end%methods  (Access = protected)
    
    methods (Abstract, Access = public)
        run(obj);
    end
    
end

