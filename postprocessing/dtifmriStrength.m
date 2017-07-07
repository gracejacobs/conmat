function output = dtifmriStrength(dtiList, fmriList, minimum, maximum)
    
    fmriSubjIDList = {};
    for i = 1:length(fmriList)
        fmriSplit = strsplit(char(fmriList(i)), '_');
        fmriSubjIDList(i) = cellstr(strjoin(fmriSplit(1:4), '_'));
    end
    
    slopeIndex = 1;
    for dtiIndex = 1:length(dtiList)
        try
            dtiSplit = strsplit(char(dtiList(dtiIndex)), '_');
            dtiSubjID = strjoin(dtiSplit(1:4), '_');
            
            if any(ismember(fmriSubjIDList, dtiSubjID))
                
                fmriIndex = find(ismember(fmriSubjIDList, dtiSubjID));

                dti = csvread(char(dtiList(dtiIndex)), 1, 0);

%                 dti(dti > 0) = 1;
                dti = reshape(dti, 268*268, 1);

                fmri = csvread(char(fmriList(fmriIndex)));
                fmri = reshape(fmri, 268*268, 1);

                minFmri = min(fmri(:));
                maxFmri = max(fmri(:));
                minDti = min(dti(:));
                maxDti = max(dti(:));

                numBins = 500;
                step = (maxFmri-minFmri)/numBins;
                
                index = 1;
                avgDti = [];
                avgFmri = [];
                for i = minFmri:step:maxFmri-step
                    avgDti(index) = mean(dti(fmri >= i & fmri < (i+step)));
%                     avgFmri(index) = (i+step)/2;
                    avgFmri(index) = abs((i + (i+step))/2);                    
                    index = index + 1;
                end
                
                index = 1;
                for i = 1:length(avgFmri)
                    if avgFmri(i) >= minimum & avgFmri(i) <= maximum
%                         fmriStrength(index) = avgFmri(i);
                        fmriStrength(index) = abs(avgFmri(i));                        
                        dtiStrength(index) = avgDti(i);
                        index = index + 1;
                    end
                end
                X = ones(length(fmriStrength), 2);
                X(:, 2) = fmriStrength';
                Y = dtiStrength';
                
                figure;
                scatter(fmriStrength, dtiStrength);
                M = lsline;
                slopeIntercept = polyfit(get(M, 'xdata'), get(M, 'ydata'), 1);
                slopes(slopeIndex) = slopeIntercept(1, 1);
                slopeIndex = slopeIndex + 1;
            end
        catch 
            continue
        end
    end
    mean(slopes)
    figure
    histogram(dtiStrength, 50)
end