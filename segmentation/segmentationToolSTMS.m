classdef segmentationToolSTMS < segmentationTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        cmd;
%         ctcSet;
        tmpDir;
        commonRootName;
        outputPath;
        stmsOpt;
        filteredCtcSetMap;
    end
    
    
    %% methods (Access = public)
    methods (Access = public)
        function obj = segmentationToolSTMS(obj)
            obj.cmd = 'D:\Programmes\Git\git-bash.exe D:\02_Matlab\Data\deconvTool\segmentation\tmp\STMS.sh > D:\02_Matlab\Data\deconvTool\segmentation\tmp\out.txt';
            obj.tmpDir = 'D:\02_Matlab\Data\deconvTool\segmentation\tmp\';
            obj.commonRootName = 'Img_';
            obj.outputPath = 'D:\02_Matlab\Data\deconvTool\segmentation\out\';
        end
        
        function obj = prepare(obj, patientPath, opt)
            obj.prepare@segmentationTool(patientPath, opt);
            %             obj.ctcSet = loadmat(ctcSetPath);
            %             obj.mask = loadmat(maskPath);
            obj.stmsOpt.xScale = opt.xScale;
            obj.stmsOpt.yScale = opt.yScale;
            obj.stmsOpt.rScale = opt.rScale;
            obj.stmsOpt.merge = opt.merge;
            obj.stmsOpt.lwTCrop = opt.lwTCrop;
            obj.stmsOpt.upTCrop = opt.upTCrop;
            obj.stmsOpt.nbImg = size(obj.slcSerieMap(char(obj.slcKS(1))), 3);
        end%prepare
        
        function obj = run(obj)
            for k = 1 : obj.slcPathMap.length
                obj.emptyDir();
                %save image in tmp director
                %ctcSet = obj.ctcSetMap(char(obj.slcKS(k)));
                ctcSet = obj.slcSerieMap(char(obj.slcKS(k)));
                for l = 1 : obj.stmsOpt.nbImg
                    if (l >= obj.stmsOpt.lwTCrop) && (l <= obj.stmsOpt.upTCrop)
                        nii = make_nii(ctcSet(:, :, l));
                    else
                        nii = make_nii(zeros(size(ctcSet(:, :, l), 1), ...
                            size(ctcSet(:, :, l), 2)));
                    end
                    save_nii(nii, sprintf('%s\\Img_%03i.nii', [obj.tmpDir 'img\'], l));
                end
                
                % save mask
                nii = make_nii(uint8(obj.maskMap(char(obj.slcKS(k)))));
                save_nii(nii, [obj.tmpDir 'img\mask.nii']);
                obj.initConfig();
                obj.initScript();
                retVal = system(obj.cmd);
                if 0 ~= retVal
                    throw(MException('segmentationTool:run', 'STMS did not end correctly.'));
                end
                % load result classes image
                labelImgPath = [obj.outputPath '\' ls([obj.outputPath '\STMS_Class_*.nii'])];
                labelImg = load_nii(labelImgPath);
                labelImg.img = flipdim(double(labelImg.img), 2);
                labelImg.img = flipdim(labelImg.img, 1);
                labelImg.img = labelImg.img .* obj.maskMap(char(obj.slcKS(k)));
                
                 % add it to the map
                if ~isa(obj.labelImgMap,'containers.Map')% create map if does not exists
                    obj.labelImgMap = containers.Map(char(obj.slcKS(k)), labelImg) ;
                else % else insert into map
                    obj.labelImgMap(char(obj.slcKS(k))) = labelImg;
                end
                
                %load results filtered curves 
                filteredCtcFileList = ls([obj.outputPath '\STMS_X*.nii']);
                for l = 1 : size(filteredCtcFileList, 1)
                     tmp = load_nii([obj.outputPath '\' filteredCtcFileList(l, :)]);
                     tmp = flipdim(double(tmp.img), 2);
                     tmp = flipdim(tmp, 1);
                     filteredCtcSet(:, :, l) = tmp;
                     
                end%for
                
                % add it to the map
                if ~isa(obj.filteredCtcSetMap,'containers.Map')% create map if does not exists
                    obj.filteredCtcSetMap = containers.Map(char(obj.slcKS(k)), filteredCtcSet) ;
                else % else insert into map
                    obj.filteredCtcSetMap(char(obj.slcKS(k))) = filteredCtcSet;
                end
               
            end
        end%run(obj)
        
        function emptyDir(obj)
            if isdir(obj.outputPath)
                rmdir(obj.outputPath, 's');
            end
            pause(2);
            mkdir(obj.outputPath);
            
            if isdir(obj.tmpDir)
                rmdir(obj.tmpDir, 's');
            end
            mkdir([obj.tmpDir '\img']);
        end%emptyDir
        
        function filteredCtcSet = getfilteredCtcSet(obj, key)
            filteredCtcSet = obj.filteredCtcSetMap(key);
        end
        
        function avgTimeCurve = processAverageTimeCurve(obj, imSerie, mask)
            [H, W, ~] = size(imSerie);
            pos = find(mask == 1);
            [x, y] = ind2sub([H, W], pos);
            tmp = 0;
            for n = 1 : length(x)
                tmp = tmp + squeeze(imSerie(x(n), y(n), obj.stmsOpt.lwTCrop:obj.stmsOpt.upTCrop));
            end
            avgTimeCurve = tmp ./ length(x);
        end%processAverageTimeCurve
        %%
        function updateRScale(obj, rScale)
            obj.stmsOpt.rScale = rScale;
        end%updateRScale
    end%methods (Access = public)
    
    
    %% methods (Access = protected)
    methods (Access = protected)
        
        function obj = initConfig(obj)
            configFile = [obj.tmpDir '\stmsConf.xml'];
            
            if exist(configFile, 'file') == 2
                delete(configFile);
            end
            
            fdTmp = fopen('D:\02_Matlab\Data\stms\template\stmsConf.xml.tmp', 'r');
            fd = fopen(configFile, 'w');
            %fprintf('fd: %d', fd);
            for kk = 1 : 32
                str = fgets(fdTmp);
                if kk == 22
                    str = strrep(str, '_INPUT_IMAGES_PATH_', [obj.tmpDir(4:end) 'img\']);
                elseif kk == 23
                    str = strrep(str, '_BASE_IN_', obj.commonRootName);
                elseif kk == 24
                    str = strrep(str, 'null', 'mask');
                elseif kk == 28
                    str = strrep(str, '_OUTPUT_IMAGES_PATH_', obj.outputPath(4:end));
                elseif kk == 29
                    str = strrep(str, '_BASE_OUT_', 'STMS');
                end
                fprintf(fd, '%s', str);
            end
            
            fclose(fd);
            fclose(fdTmp);
        end%initConfig
        
        function obj = initScript(obj)
            scriptFilePath = [obj.tmpDir '\STMS.sh'];
            if exist(scriptFilePath, 'file') == 2
                delete(scriptFilePath);
            end
            fdTmp = fopen('D:\02_Matlab\Data\stms\template\STMS.sh.tmp', 'r');
            fd = fopen(scriptFilePath, 'w');
            fprintf('fd: %d', fd);
            for k = 1 : 10
                str = fgets(fdTmp);
                if k == 8
                    str = strrep(str, '_X_', num2str(obj.stmsOpt.xScale));
                    str = strrep(str, '_Y_', num2str(obj.stmsOpt.yScale));
                    str = strrep(str, '_R_', num2str(obj.stmsOpt.rScale));
                    str = strrep(str, '_NB_IMG_', num2str(obj.stmsOpt.nbImg));
                    str = strrep(str, '_MERGE_OPT_', obj.stmsOpt.merge);
                elseif k == 6
                    str = strrep(str, '_CONFIG_PATH_FILE_', [obj.tmpDir '\stmsConf.xml']);
                end
                fprintf(fd, '%s', str);
            end
            
            fclose(fd);
            fclose(fdTmp);
            
        end%initScript
        
        
    end%methods (Access = private)
end

