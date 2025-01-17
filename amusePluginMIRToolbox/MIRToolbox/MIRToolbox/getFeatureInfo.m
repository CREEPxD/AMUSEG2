function features=getFeatureInfo(f,nBins,smoothingFactor, tracks)

%features=struct('names',{}, ...
%    'fields',{}, ...
%    'trackNames',{}, ...
%    'data',{}, ...
%    'valueRange',[], ...
%    'distribution',[], ...
%    'trackDistributions',[], ...
%    'frameLength',[], ...
%    'framediff',[], ...
%    'frameStart',[], ...
%    'hasPeaks',[], ...
%    'isTrackLevel',[]);
features={};

fieldBranch={};
fieldInd=0;
nFeatures=0;
maxFieldNameLength=7;
binEdges=0:1/(nBins-1):1; %when visualizing the feature distributions, map feature values in the range of 0 and 1
trackNames={};



if isstruct(f)
    tmp=sort(lower(fieldnames(f))); tmp=tmp(:)';
    if isequal(tmp,{'data','framepos','name','title'})
        fieldName='';
        fieldInd=1;
        getData(f,{fieldName},0,false)
    else
        
        recursiveCheck(fieldBranch,f);
    end
elseif isa(f,'mirdata')
    fieldInd=1;
    fieldName='';%get(f,'Title');
    getData(f,{fieldName},0,true);
elseif iscell(f)
    for cellind=1:length(f)
        if isa(f{cellind},'mirdata')
            fieldInd=1;
            fieldName=get(f{cellind},'Title');
            getData(f{1},{fieldName},cellind,true);
        end
    end
else
    error('Feature set must be struct or mirscalar variable.');
end

    function recursiveCheck(fieldBranch,f)
        
        if isstruct(f)
            fieldInd=fieldInd+1;
            
            newFieldNames = fieldnames(f);
            numberOfFields = length(newFieldNames);
        end
        
        for current = 1:numberOfFields
            % Field information
            fieldName = newFieldNames{current};
            newField = f.(fieldName);
            
            if iscell(newField)
                for cellind=1:length(newField)
                    if isa(newField{cellind},'mirdata') %reached the end of branch and found a mirscalar feature
                        fieldBranch{fieldInd}=fieldName;
                        getData(newField{cellind},fieldBranch,cellind,true);
                        
                    end
                end
            elseif isa(newField,'mirdata') %reached the end of branch and found a mirscalar feature
                fieldBranch{fieldInd}=fieldName;
                getData(newField,fieldBranch,0,true);
                
                
            elseif isstruct(newField)
                tmp=sort(lower(fieldnames(newField))); tmp=tmp(:)';
                if isequal(tmp,{'data','framepos','name','title'})
                    %fieldName='';
                    %fieldInd=1;
                    getData(newField,fieldBranch,0,false)
                else
                    
                    fieldBranch{fieldInd}=fieldName;
                    recursiveCheck(fieldBranch,newField);
                end
            else
                continue
            end
            
            
        end
        fieldInd=fieldInd-1;
    end
if isempty(features)
    error('No mirscalar type of feature vectors in the set.');
else
    features.trackNames=trackNames{1};
end




    function getData(scalarFeature,fieldBranch,ci,isMirdata)
        
        if isMirdata
            featureData_tmp=get(scalarFeature,'Data');
        else
            featureData_tmp=scalarFeature.data;
        end
        if ~isempty(tracks)
            featureData_tmp=featureData_tmp(tracks);
        end
        
        
        
        
        %read the branch of fieldnames to get summarized
        fieldBranch{fieldInd}=fieldName;
        featureName='';
        for i=1:fieldInd
            featureName=strcat(featureName,fieldBranch{i}(1:min(end,maxFieldNameLength)),'/');
        end
        %featureName=strcat(featureName,fieldBranch{fieldInd});
        
        if isMirdata
            featureName=strcat(featureName,get(scalarFeature,'Title'));
        else
            featureName=strcat(featureName,scalarFeature.title);
        end
        
        
        
        nFeatures=nFeatures+1; %add feature
        
        if isMirdata && length(featureData_tmp{1})==1 && length(featureData_tmp{1}{1})==1
            features.isTrackLevel(nFeatures)=1;
        elseif ~isMirdata && length(featureData_tmp{1})==1
            features.isTrackLevel(nFeatures)=1;
        else
            features.isTrackLevel(nFeatures)=0;
        end
        
        if isMirdata
            trackNames{nFeatures}=get(scalarFeature,'Name'); %just to check that each feature is extracted from the same track. (what if the first track feature is empty due to the feature characteristics?)
        else
            trackNames{nFeatures}=scalarFeature.name;
        end
        if ~isempty(tracks)
            trackNames{nFeatures}=trackNames{nFeatures}(tracks);
        end
        if nFeatures>1 && ~isequal(trackNames{1},trackNames{nFeatures})
            error('%s: all features must relate to the same set of tracks.',featureName);
        end
        
        
        features.fields{nFeatures}=fieldBranch;
        features.names{nFeatures}=featureName;
        features.cellinds(nFeatures)=ci;
        features.types{nFeatures}=class(scalarFeature);
        features.isMirdata(nFeatures)=isMirdata;
        
        %peaks...
        %peakPos=get(scalarFeature,'PeakPos');
        %peakPos=peakPos{1};
        %peakPos=peakPos{1};
        
        %if feature hasn't got peaks detected
        %if 0 && isempty(peakPos) %not empty
        %    features.hasPeaks(nFeatures)=0;
        %else
        %    features.hasPeaks(nFeatures)=1;
        %end
        
        %get value range of the feature (summarize its overal distribution)
        features.valueRange(nFeatures,1:2)=[Inf,-Inf];
        features.distribution(nFeatures,1:nBins)=zeros(1,nBins);
        features.emptytrack = zeros(1,length(featureData_tmp));
        
        for track=1:length(featureData_tmp)
            tmp = featureData_tmp{track};
            if iscell(tmp)
            tmp = tmp{1};
            end
            if iscell(tmp)
            tmp = tmp{1};
            end
            if iscell(tmp)
                tmp2 = [];
                for i = 1:length(tmp)
                    tmp2 = [tmp2 tmp{i}(:)'];
                end
                featureData_tmp{track}{1} = tmp2;
            end
            
            if ~isempty(tmp) && ~all(isnan(tmp(:)))
                features.mintrack(nFeatures,track) = min(tmp(:));
                minValue = min(tmp(:));
                features.maxtrack(nFeatures,track) = max(tmp(:));
                maxValue = max(tmp(:));
            else
                warning('%s, track %d: No feature extracted. Check if there was some error in feature extraction. Including an empty feature...',featureName, track);
                features.mintrack(nFeatures,track) = NaN;
                features.maxtrack(nFeatures,track) = NaN;
                features.emptytrack(track) = 1;
                continue
            end
            
            features.valueRange(nFeatures,1:2)=[ min(features.mintrack(nFeatures,track),features.valueRange(nFeatures,1)), max(features.maxtrack(nFeatures,track),features.valueRange(nFeatures,2)) ];
            
            
            
            %frames with peaks
            if 0 && features.hasPeaks(nFeatures)
                peakFrames=get(scalarFeature,'PeakPos');
                features.peakPos{nFeatures}{track}=peakFrames{track}{1}{1};
                
                %get peak strength relative to feature value span
                features.peaks{nFeatures}{track}=(featureData_tmp{track}{1}(features.peakPos{nFeatures}{track})-minValue)/(maxValue-minValue);
            end
            
        end
        
        if iscell(tmp)
            features.trackDistributions{nFeatures} = [];
        else
            for track=1:length(featureData_tmp)
                %compute distribution of in one track, related to
                %the featureValueRange
                features.trackDistributions{nFeatures}(track,1:nBins)=medfilt1(histc((tmp(:)-features.valueRange(nFeatures,1))/(features.valueRange(nFeatures,2)-features.valueRange(nFeatures,1)),binEdges),smoothingFactor); %histogram, values related to the featureValueRange
                
                if isequal(features.trackDistributions{nFeatures}(track,1:nBins),zeros(1,nBins)) %if filtering was too harsh due to small number of feature values
                    features.trackDistributions{nFeatures}(track,1:nBins)=histc((tmp-features.valueRange(nFeatures,1))/(features.valueRange(nFeatures,2)-features.valueRange(nFeatures,1)),binEdges);
                end
                
                features.distribution(nFeatures,1:nBins)=features.distribution(nFeatures,1:nBins)+features.trackDistributions{nFeatures}(track,1:nBins);
                
            end
            
            %map feature distributions to [0,1]
            
            features.trackDistributions{nFeatures}=features.trackDistributions{nFeatures}./repmat(max(features.trackDistributions{nFeatures},[],2),1,nBins);
            features.distribution(nFeatures,1:nBins)=features.distribution(nFeatures,1:nBins)./repmat(max(features.distribution(nFeatures,1:nBins),[],2),1,nBins);
        end
        
        %features.data{nFeatures}=featureData_tmp;
        if isMirdata
        framePos=get(scalarFeature,'FramePos');
        else
            framePos=scalarFeature.framepos;
        end
        if ~isempty(tracks)
            framePos = framePos(tracks);
        end
        
        if iscell(framePos{1}) && length(framePos{1})==1 && size(framePos{1}{1},2) == 1 && ~isa(scalarFeature,'miraudio')
            features.isTrackLevel(nFeatures)=1;
        elseif ~iscell(framePos{1}) && size(framePos{1},2) == 1 && ~isa(scalarFeature,'miraudio')
            features.isTrackLevel(nFeatures)=1;
        end
        %features.framePos{nFeatures}=framePos;
    end

end