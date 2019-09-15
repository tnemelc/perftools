classdef patientDataPreparatorUI < baseUI
    % User interface for Patient Data Preparation
    % this plugin :
    %       * load patient Aif, Apex, Mid, and Base images
    %       * enables user to define mask  and AHA Segments
    %       * creates, labels and stores curves
    
    properties(Access = protected)
        dataPreparator;
        chkBxCoilsCorrection; % Coils inhomogeneity correction
        
    end
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = patientDataPreparatorUI;
            end
            obj = localObj;
        end
    end
    
    %% methods (Access = public)
    methods (Access = public)
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@baseUI(hParent, pluginInfo, opt);
            obj = obj.initPatientPathUI([obj.basePath 'patientData\patients\Boncompain\']);
            obj = obj.initCoilCorrChBx();
            obj.updateSavePath('dataPrep');
        end%initialize
        
    end% methods (Access = public)
    
    %% methods (Access = protected)
    methods (Access = protected)
        
        %init
        function obj = initCoilCorrChBx(obj)
            obj.chkBxCoilsCorrection = ...
                uicontrol('Style', 'checkbox',...
                'Units',  'normalized', 'Position', [obj.col(1) + 0.03, obj.lin(10), 0.1, obj.HdleHeight], ...
                'String',   'Coils Inhomogeneity correction', 'Value', 1);
        end%initCoilCorrChBx
        
        function bRetVal = doCoilInhomogeneityCorr(obj)
           bRetVal = get(obj.chkBxCoilsCorrection, 'value');
        end%doCoilInhomogeneityCorr
        
        % callbacks
        function obj = goCb(obj, ~, ~)
            try
            obj.setFooterStr('running...')
            figureMgr.getInstance().closeAllBut('deconvTool');
            delete(get(obj.rPanel,'Children'));
            opt.path = obj.getPatientPath();
            opt.savePath = obj.getSavePath();
            if ~obj.doCoilInhomogeneityCorr()
                obj.dataPreparator = dataPreparator();
            else 
                obj.dataPreparator = dataPreparatorSCIC;
            end 
            obj.dataPreparator.prepare(opt);
            obj.dataPreparator.run();
            
            obj.dispResults();
            obj.setFooterStr('processing completed.');
            catch e
                obj.setFooterStr('x_x something bad happened (see console)');
                rethrow(e);
            end
        end%goCb
        
        function obj = saveCb(obj, ~, ~)
            
            slcList = obj.dataPreparator.getSlcKeySet();
            savePath = obj.getSavePath();
            if ~obj.checkSavePath()
                obj.setFooterStr('Wrong save path!!! save canceled.')
                return;
            end
            
            if isdir(savePath)
                switch questdlg('patient folder already exist. Squeeze?')
                    case 'Yes'
                        try 
                            rmdir(savePath, 's');
                        catch e
                            obj.setFooterStr('could not remove directory. save canceled.')
                            rethrow(e);
                        end
                    otherwise
                        obj.setFooterStr('save canceled');
                        return;
                end
            end
            curDir = fullfile(savePath, '/Aif/');
            mkdir(curDir);
            savemat(fullfile(curDir, 'aif'), obj.dataPreparator.getAifCurve());
            savemat(fullfile(curDir,'aifCtc'), obj.dataPreparator.getAifCtc());
            savemat(fullfile(curDir,'aifCtcFit'), obj.dataPreparator.getAifCtcFit());
            savemat(fullfile(curDir,'aifMask'), obj.dataPreparator.getAifMask());
            savemat(fullfile(curDir,'aifData'), obj.dataPreparator.getPatientAifData());
            savemat(fullfile(curDir,'aifFitParams'), obj.dataPreparator.getAifFitParams());
            
            root.CreationDate = date;
            root.aif.fitParams = obj.dataPreparator.getAifFitParams();
            root.aif.Params.baselineLength = obj.dataPreparator.getAifBaselineLength();
            root.aif.Params.TimeToPeak = obj.dataPreparator.getAifTimeToPeak();
            
            %struct2xml(root, fullfile(curDir,'\aifFitParams.xml'));
            tAcq = obj.dataPreparator.getAifTimeAcq();
            savemat(fullfile(curDir, 'tAcq'), tAcq);
            
            %root = [];
            for k = 1 : length(slcList)
                curDir = fullfile(savePath, char(slcList(k)));
                mkdir(curDir);
                tAcq = obj.dataPreparator.getSlcTimeAcq(char(slcList(k)));
                mask = obj.dataPreparator.getSlcMask(char(slcList(k)));
                curveSet = obj.dataPreparator.getSlicesCurvesSet(char(slcList(k)));
                ctcSet = obj.dataPreparator.getSlicesCtcSet(char(slcList(k)));
                slcSerie = obj.dataPreparator.getSliceSerie(char(slcList(k)));
                
                blLengthMap = obj.dataPreparator.getSlcBaselineLengthMap(char(slcList(k)));
                blAvgMap = obj.dataPreparator.getSlcBaselineAvgMap(char(slcList(k)));
                blSigmaMap = obj.dataPreparator.getSlcBaselineSigmaMap(char(slcList(k)));
                
                [H, W] = size(mask); [nbCur, T] = size(curveSet);
                
                %formated curve set
                if ~obj.doCoilInhomogeneityCorr()
                    fCurveSet = zeros(H, W, T);
                    fCtcSet = zeros(H, W, T);
                    curvesPos = find(mask);
                    [xCoor, yCoor] = ind2sub([H, W], curvesPos);
                    for l = 1 : nbCur
                        fCurveSet(xCoor(l), yCoor(l), :) =  curveSet(l, :);
                        fCtcSet(xCoor(l), yCoor(l), :) = ctcSet(l, :);
                    end
                else
                    fCurveSet = curveSet;
                    fCtcSet = ctcSet;
                end
                
                savemat(fullfile(curDir,'curveSet'), fCurveSet);
                savemat(fullfile(curDir,'ctcSet'), fCtcSet);
                savemat(fullfile(curDir,'slcSerie'), slcSerie);
                
                savemat(fullfile(curDir,'baselineLengthMap'), blLengthMap);
                savemat(fullfile(curDir,'baselineAvgMap'), blAvgMap);
                savemat(fullfile(curDir,'baselineSigmaMap'), blSigmaMap);
                
                savemat(fullfile(curDir,'mask'), mask);
                savemat(fullfile(curDir,'peakImage'), obj.dataPreparator.getSlcPeakImage(char(slcList(k))));
                savemat(fullfile(curDir,'tAcq'), tAcq);
                
                if obj.doCoilInhomogeneityCorr()
                    savemat( fullfile(curDir,'t1Map'),  obj.dataPreparator.getT1Map( char(slcList( k )) ) );
                end
                
                %xml
                root.(char(slcList(k))).('baselineAverageValue') = obj.dataPreparator.getSlcBaselineAvgValue(char(slcList( k )));                
                root.(char(slcList(k))).('baselineAverageStDeviationValue') = obj.dataPreparator.getSlcBasleinAvgStDeviationValue(char(slcList( k )));
                baselineStdTab = obj.dataPreparator.getSlcSgtBaselineStdTab(char(slcList( k )));
                baselineAvgTab = obj.dataPreparator.getSlcSgtBaselineAvgTab(char(slcList( k )));
                for l = 1 : length(baselineStdTab)
                    root.(char(slcList(k))).('segmentStd').(sprintf('segment%d', l)) = baselineStdTab(l);
                    root.(char(slcList(k))).('segmentAvg').(sprintf('segment%d', l)) = baselineAvgTab(l);
                end
            end%for
            root.(char(slcList(k))).('myocardiumStd') = obj.dataPreparator.getSlcMyoBaselineStdTab(char(slcList( k )));
            root.(char(slcList(k))).('myocardiumAvg') = obj.dataPreparator.getSlcMyoBaselineAvgTab(char(slcList( k )));
            fileStrct.root = root;
            struct2xml(fileStrct, fullfile(savePath,'DataSummary.xml'));
            
            obj.setFooterStr('save finished succesfully');
        end%saveCb
        
        %%results
        function dispResults(obj)
            
%             axes('parent', );
            % aif image and mask overlay
            ha = tight_subplot(2,3,[.1 .03],[.01 .1],[.01 .01], obj.rPanel);
            imoverlay(obj.dataPreparator.getAifPeakImage,...
                obj.dataPreparator.getAifMask(), [], [], [], 0.2, ha(1));
            title('AIF');
            %aif curve
            axes(ha(2));
            tAcqAif = obj.dataPreparator.getAifTimeAcq();
            aifFit = obj.dataPreparator.getAifCtcFit();
            
            if ~obj.doCoilInhomogeneityCorr()
                plot(tAcqAif(4:end) - tAcqAif(4),...
                    aifFit);
            else
                plot(tAcqAif, aifFit);
            end
            hold on;
            title(sprintf('aif curve\n\t baseline len: %0.2fs\n\t ttp: %0.2fs', obj.dataPreparator.getAifBaselineLength(), obj.dataPreparator.getAifTimeToPeak()));
            
            slcKS = obj.dataPreparator.getSlcKeySet();
            for k = 1 : length(slcKS)
                %imagesc(obj.dataPreparator.getSlcPeakImage(char(slcKS(k))));
                sliceName = char(slcKS(k));
                hdle = imoverlay(obj.dataPreparator.getSlcPeakImage(sliceName), ...
                    obj.dataPreparator.getSlcMask(sliceName), [], [], [], 0.2, ha(3 + k));
                 set(hdle, 'ButtonDownFcn', {@obj.onBnClickCb, sliceName});
%                 imagesc(overlay(); 
                title(sliceName); axis off;
            end
        end%dispResults
        
        function onBnClickCb(obj, arg1, ~, slcName)
            axesHandle  = get(arg1, 'Parent');
            coordinates = get(axesHandle, 'CurrentPoint');
            coordinates = floor(coordinates(1, 1:2));
            if ~coordinates(1); coordinates(1) = 1; end
            if ~coordinates(2); coordinates(2) = 1; end
            
            ctcSet = obj.dataPreparator.getSlicesCtcSet(slcName);
            tAcq = obj.dataPreparator.getSlcTimeAcq(slcName);
            figureMgr.getInstance().newFig('ctc Curves');
            plot(tAcq,  squeeze(ctcSet(coordinates(2), coordinates(1), :)));
        end
        
         function obj = browsePatientPathCb(obj, ~, ~)
             path = uigetdir(fullfile(obj.basePath, 'patientData'));
            set(obj.dataPathEditBoxUI, 'String', path);
            set(obj.savePathUI, 'String', fullfile(path, 'dataPrep'));
        end%browseSavePathCb
        
    end%methods (Access = protected)
    
end

