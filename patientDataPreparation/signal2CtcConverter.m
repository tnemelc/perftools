classdef signal2CtcConverter < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        s0Aif;
        s0Slc;
        %average Baseline signal
        aifAvgBaseLineSg;
        slcAvgBaseLineSg;
        
        % dicomInfo
        aifDcmInfo;
        slcDicomInfo;
        
        %conversion Method (JeroshHerold or Sekihara)
        convMethod;  
        
        %conversion tables
        aifSgCtcLut;
        SlcSgCtcLut;
        
        %concentration time curves
        aifCtc;
        signalCtcSet;
        
        
    end
    
    methods (Access = public)
        function obj = signal2CtcConverter(obj)
        end
        
        %prepare
        function obj = prepare(obj, aifDcmInfo, slcDicomInfo, opt)
            obj.aifDcmInfo = aifDcmInfo; obj.slcDicomInfo = slcDicomInfo;
            obj.aifAvgBaseLineSg = opt.aifAvgBaseLineSg;
            obj.s0Aif = opt.s0Aif;
            obj.slcAvgBaseLineSg = opt.slcAvgBaseLineSg;
            obj.s0Slc = opt.s0Slc;
            obj.convMethod = opt.convMethod;
            obj = obj.generateLookUpTables();
            
        end%prepare
        
        function obj = generateLookUpTables(obj)
            [~, obj.aifSgCtcLut] = signal2concentration(zeros(1,10), ...
                obj.aifDcmInfo, obj.s0Aif, 1,...
                false, obj.aifAvgBaseLineSg);
            obj.aifSgCtcLut = obj.padLut(obj.aifSgCtcLut);
            
            [~, obj.SlcSgCtcLut] = signal2concentration(zeros(1,10), ...
                obj.slcDicomInfo, obj.s0Slc, 1,...
                false, obj.slcAvgBaseLineSg);
            obj.SlcSgCtcLut = obj.padLut(obj.SlcSgCtcLut);
        end
        
        function aifCtc = convertAif(obj, aifSg)
            aifCtc = aifSg;
            for k = 1 : length(aifSg);
                aifCtc(k) = sortedLutSearch(obj.aifSgCtcLut, aifSg(k));
            end
        end%convertAif
        
        function ctc = convertCtc(obj, signal)
            ctc = signal;
            for k = 1 : length(signal);
                ctc(k) = sortedLutSearch(obj.SlcSgCtcLut, signal(k));
                if isnan(ctc(k))
                    debugPath = getGlobalDebugPath();
                    savemat([debugPath 'ctc'], ctc);
                    savemat([debugPath 'signal'], signal);
                    savemat([debugPath 'LUT'], obj.SlcSgCtcLut);
                    throw(MException('signal2CtcConverter:convertCtc', ['assigned value is not a number. signal, lut & ctc is saved in ' debugPath]));
                end
            end
        end%convertCtc
        
        function paddedLut = padLut(~, unpaddedLut)
            p = find(unpaddedLut(1,:) >= (2 * unpaddedLut(1, 1)), 1, 'first');
            tmp = fliplr(unpaddedLut(:,1:p));
            tmp(1, 1 : p) = unpaddedLut(1,1) - (tmp(1, 1 : p) - unpaddedLut(1,1));
            %         tmp = fliplr(tmp);
            tmp(2,:) = tmp(2,:)  * (-1);
            paddedLut = [tmp unpaddedLut];
        end
        
        
        
    end
    
end

