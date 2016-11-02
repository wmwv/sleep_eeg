function specdat=readspectralpsg3(id,study,datadir,channel,existingspecdat,dataformatspec)
%%COMMENTS
if nargin<1, id=216592; end
if nargin<2, study=2; end
if nargin<3, datadir='J:\PAN2\spectral_vertsd'; end
if nargin<4, channel='cz'; end
if nargin<5, existingspecdat=[]; else specdat=existingspecdat; end
if nargin<6, leadorder={'fz';'fcz';'cz';'pz'};
            specbandorder={'point5to4Hz';'4_8Hz';'8_12Hz';'12_16Hz';'16_20Hz'};
end


%workaround for multiple channels
% leadorder=channel;

%% GET RAW DATA
fprintf('Getting raw data for %d %d.\n',id,study)
%get all data file names for a specific study
cd(datadir);

if size(dbstack,1)==1 || size(dbstack,1)==2
    filelist=getallfiles(datadir,'tsdold');
else
    global filelist;
end

if study<10
    expr=['.*?\\' channel '.*?\\v' num2str(id) '00' num2str(study) '(?:~1)?\.txt'];
else
    expr=['.*?\\' channel '.*?\\v' num2str(id) '0' num2str(study) '(?:~1)?\.txt'];
end

matches=regexp(filelist,expr,'match');
ind=find(~cellfun(@isempty,matches));
fnames=cell(size(ind));
fnames=deal(filelist(ind));

alldata.id=id;
alldata.study=study;

specdat.usecd=1;
specdat.id=id;
specdat.study=study;

fileindex=find(cellfun(@isempty,strfind(fnames,'Sleep_staging')));
currlead=strcmpi(leadorder,channel);
%read raw
index=1;
for i=1:length(fileindex)
    %NEED TO START READING IN WITH DELTA TO GET HAC
    
    %get the data label from path name
    expr2='\\spectral_vertsd\\(.*?)\\v.*?';
    tok=regexp(fnames(fileindex(i)),expr2,'tokens');
    thislabel=strrep(tok{1}{1}{:},'-','_');
    alldata.labels{i}=thislabel;
    
    %open file for reading, start with header
    fid=fopen(fnames{fileindex(i)});
    thisheader=fgetl(fid);
    alldata.header{i}=strsplit(strtrim(thisheader));
%     alldata.header(i,:)=strsplit(strtrim(thisheader));
    
%     findhac=strfind(alldata.(thislabel).header,'HAC');
    findhac=strfind(alldata.header{i},'HAC');
    if ~isempty([findhac{:}]) %if the file has a separate column for HAC
%         alldata.(thislabel).data=textscan(fid,'%d %d %s %s %d %f %f %f %f %f %f %f %f %f %f %f');
        alldata.data{i}=textscan(fid,'%d %d %s %s %d %d %d %d %d %f %f %f %f %f %f %f');
        %alldata.data{i}=textscan(fid,'%d %d %s %s %d %d %d %d %d %f %f %f %f %f %f','Delimiter',{'\t',' '},'MultipleDelimsAsOne',0);
    else 
%         alldata.(thislabel).data=textscan(fid,'%d %d %s %s %d %f %f %f %f %f %f %f %f');
        alldata.data{i}=textscan(fid,'%d %d %s %s %d %f %f %f %f %f %f %f %f');
    end
    fclose(fid);
%     fieldnames{i}=thislabel;
%     totalsamps(i)=length(alldata.(thislabel).data{1});
    totalsamps(i)=length(alldata.data{i}{1});
end

% expr='v(\d+).txt';
% tok=regexp(filelist,expr,'tokens');
% ids=str2double(cell2mat([tok{:}]))';

%% FORMAT DATA
fprintf('Formatting data.\n')
if length(unique(totalsamps))>2
   fprintf('Warning: the total number of samples per file differs for more than 2 files.\n')
end

for i=1:length(alldata.data)
    for index=2:length(alldata.data{i})
        lengthcheck=length(alldata.data{i}{1})-length(alldata.data{i}{index});
        if lengthcheck>0
            if lengthcheck==1
                alldata.data{i}{index}(end+1)=-999;
            else
                alldata.data{i}{index}(end+1:end+(lengthcheck-1))=-999;
            end
        end
    end
end
%return first index at which max and min samps occur. Assumes that files
%all share a LCD, and there are only two different total samples across
%all files.
[maxsamps,maxind]=max(totalsamps);
[minsamps,minind]=min(totalsamps);
% timeintersect=ismember(alldata.(fieldnames{maxind}).data{4},alldata.(fieldnames{minind}).data{4}); %Assumes time is stored in column 4
%alldata.(fieldnames{totalsamps==maxsamps}).data(:)(timeintersect)=[]; %to
%finish! 4.2.16. basically, take all the files where data was duplicated,
%and resize to only include times that intersected with the smaller
%dataset. need to figure out how to not use a loop to iterate through
%fieldnames as well as all of the indicies of alldata.fieldnames.data.

timeintersect=ismember(alldata.data{maxind}{4},alldata.data{minind}{4});
alldata.dataresize=alldata.data;

indstoresize=find(maxsamps==totalsamps);
for j=1:length(indstoresize)
    for index=1:length(alldata.data{indstoresize(j)})
        alldata.dataresize{indstoresize(j)}{index}(~timeintersect)=[];
    end
end

for i=1:length(alldata.dataresize)
    totalsamps_check(i)=length(alldata.dataresize{i}{1});
end

clear indstoresize; 
if any(unique(totalsamps_check))
    [maxsamps,maxind]=max(totalsamps_check);
    [minsamps,minind]=min(totalsamps_check);
    timeintersect=ismember(alldata.dataresize{maxind}{4},alldata.dataresize{minind}{4});
    indstoresize=find(maxsamps==totalsamps);
    for j=1:length(indstoresize)
        for index=1:length(alldata.data{indstoresize(j)})
            alldata.dataresize{indstoresize(j)}{index}(~timeintersect)=[];
        end
    end
end

specdat.rawdata_labels(currlead,:)=alldata.labels;
specdat.leadorder=leadorder;
specdat.bandorder=specbandorder;

% expr='C(\d+)';
% expr2='(\w{1,3})_(\w+)';
expr='\D+(\d+)';
temp.bandkey=[];
for i=1:length(alldata.dataresize)
    for j=1:length(alldata.dataresize{i})
%         if (any(strfind(alldata.header{i}{j},'C')) && ~(any(strfind(alldata.header{i}{j},'HAC'))))
%             tok=regexp(alldata.header{i}{j},expr,'tokens');
%             freqind=str2num(tok{:}{:});
%             tok=regexp(alldata.labels{i},expr2,'tokens');
%             thislead=tok{1}{1};
%             thisband=tok{1}{2};
%             specdat.rawdata(strmatch(thislead,leadorder),freqind+1,:)=alldata.dataresize{i}{j};
%             specdat.bandkey(strmatch(thisband,specbandorder),end+1)=freqind;
%         elseif any(strncmpi(alldata.header{i}{j},leadorder,2)) && ~(any(strfind(alldata.header{i}{j},'C30')))
%             tok=regexp(alldata.labels{i},expr2,'tokens');
%             thislead=tok{1}{1};
%             thisband=tok{1}{2};
%             expr3=[upper(thislead) '(\d+)'];
%             tok=regexp(alldata.header{i}{j},expr3,'tokens');
%             freqind=str2num(tok{:}{:});
%             specdat.rawdata(strmatch(thislead,leadorder),freqind+1,:)=alldata.dataresize{i}{j};
%             specdat.bandkey(strmatch(thisband,specbandorder),end+1)=freqind;    
        if ~isempty(regexp(alldata.header{i}{j},expr,'match')) %if that column contains spectral data
            tok=regexp(alldata.header{i}{j},expr,'tokens');
            freqind=str2num(tok{1}{1});
            tok=regexp(alldata.labels{i},'(\w{1,3})_(\w+)','tokens');
            thislead=tok{1}{1};
            thisband=tok{1}{2};
%             specdat.rawdata(strmatch(thislead,leadorder),freqind+1,:)=alldata.dataresize{i}{j};
             temp.rawdata(1,freqind+1,:)=alldata.dataresize{i}{j};
            temp.bandkey{freqind+1}=thisband;
%         elseif ~isfield(specdat,alldata.header{i}{j}) %if it does not already exist, i.e. adding a channel to existing specdat.
%             specdat.(alldata.header{i}{j})(i,:)=alldata.dataresize{i}{j}; %if that column contains non-spectral data
        else
            temp.(alldata.header{i}{j})(i,:)=alldata.dataresize{i}{j};
            %if exists, skip. (i.e. ID does not need to be read in for
            %every file for the same study
        end
    end
end

if length(unique(temp.TIME(:,:)))>length(temp.ID)
    sprintf('WARNING: Improper time cross registration between files.')
    error('formatRaw:timeCorrect','Improper time cross registration between files.');
end

%find where HAC becomes sleep. resize all to only include data after SO.
%And clean up redundant data
temp.SOindex=find(temp.HAC(find(sum(temp.HAC'),1,'first'),:)==17,1,'first'); %pull HAC from the first row that actually contains data.
finalwake=find((temp.HAC(find(sum(temp.HAC'),1,'first'),:)>4) &~ (temp.HAC(find(sum(temp.HAC'),1,'first'),:)>64),1,'last');
if finalwake==length(temp.HAC) | (finalwake==length(temp.HAC)-1 & temp.HAC(find(sum(temp.HAC'),1,'first'),end)>64) %if they don't wake up before GMT, use last instance of sleep, or if there is bad data at end of file.
    temp.WAKEindex=finalwake;
else
    temp.WAKEindex=finalwake+1; %use the epoch after the last instance of sleep, i.e. first epoch of wake following the final instance of sleep
end

indstouse=zeros(1,length(temp.HAC));
indstouse(temp.SOindex:temp.WAKEindex)=1;

temp.ID(2:end,:)=[];
temp.STDY(2:end,:)=[];
temp.DATE(2:end,:)=[];
temp.TIME(2:end,:)=[];
temp.PT(2:end,:)=[];

hacind=sum(temp.HAC,2);
temp.HAC(~ismember([1:length(hacind)],find(hacind,1,'first')),:)=[];
temp.EPI(~ismember([1:length(hacind)],find(hacind,1,'first')),:)=[];
temp.STG(~ismember([1:length(hacind)],find(hacind,1,'first')),:)=[];
temp.PRD(~ismember([1:length(hacind)],find(hacind,1,'first')),:)=[];

temp.ID(:,~indstouse)=[];
temp.STDY(:,~indstouse)=[];
temp.DATE(:,~indstouse)=[];
temp.TIME(:,~indstouse)=[];
temp.PT(:,~indstouse)=[];

temp.HAC(:,~indstouse)=[];
temp.EPI(:,~indstouse)=[];
temp.STG(:,~indstouse)=[];
temp.PRD(:,~indstouse)=[];

vars={'ID','STDY','DATE','TIME','PT','HAC','EPI','STG','PRD'};

for i=1:length(vars)
    specdat.(vars{i})=temp.(vars{i});
end

temp.rawdata(:,:,~indstouse)=[];
% specdat.rawdata(:,:,~indstouse)=[];
specdat.rawdata(currlead,:,:)=temp.rawdata;

%% DIAGNOSTICS
fprintf('Calculating diagnostics.\n')
specdat.pct_invalid=(sum(squeeze(isnan(specdat.rawdata(:,1,:))),2)./length(specdat.rawdata)).*100;
specdat.TRP=length(specdat.rawdata)/15;
specdat.TRPsamp=length(specdat.rawdata);
specdat.TST=sum(specdat.HAC>4)/15;
specdat.WASO=sum(specdat.HAC==4)/15;
specdat.minNRMP=sum(specdat.EPI==1)/15;
specdat.minREMP=sum(specdat.EPI==2)/15; 
%
specdat.numNRMP=sum(mod(unique(specdat.PRD),2));
specdat.numREMP=sum(~mod(unique(specdat.PRD),2));
specdat.midpoint=specdat.TIME{round(length(specdat.TIME)/2)};

%% AVERAGE ACROSS 20S EPOCHS
fprintf('Averaging across 20s epochs.\n')
for i=1:size(specdat.rawdata,1)
    ep=1:5:size(specdat.rawdata,3);
    for j=1:length(ep)-1
%generate logical index where 1=bad (i.e. not continuous 2/3 or rem, such as crossover averaged epochs)
        specdat.bad_20s(i,j)=~(all(specdat.HAC(ep(j):ep(j+1)-1)==17 | specdat.HAC(ep(j):ep(j+1)-1)==22) | all(specdat.HAC(ep(j):ep(j+1)-1)==64));
        specdat.data_20s(i,:,j)=nanmean(squeeze(specdat.rawdata(i,:,ep(j):ep(j+1)-1)),2);
        specdat.HAC_20s(1,j)=mode(specdat.HAC(1,ep(j):ep(j+1)-1));
        specdat.PRD_20s(1,j)=mode(specdat.PRD(1,ep(j):ep(j+1)-1));
%         specdat.nremonly_20s(i,j)=all(specdat.HAC(ep(j):ep(j+1)-1)==17 | specdat.HAC(ep(j):ep(j+1)-1)==22); %only get epochs with ALL NREM
    end
end

%% RESCALE OUTLIERS
% fprintf('Rescaling outliers.\n')
% for i=1:size(specdat.rawdata,1)
%     specdat.rescaledata(i,:,:)=rescaleoutlierstimeseries(squeeze(specdat.rawdata(i,:,:))')';
% end

%% INTERPOLATE AND SMOOTH
% fprintf('Interpolating through bad data.\n')
% %http://www.mathworks.com/matlabcentral/newsreader/view_thread/305784
% for i=1:size(specdat.rawdata,1)
%     for j=1:size(specdat.rawdata,2)
%         x=squeeze(specdat.rawdata(i,j,:));
%         y=x;
%         bd=isnan(x);
%         gd=find(~bd);
%         bd([1:(min(gd)-1) (max(gd)+1):end])=0;
%         y(bd)=interp1(gd,x(gd),find(bd));
%         y(isnan(y))=0; %can't interpolate NaN @ beg/end of data. rep that data w/0;
%         specdat.data(i,j,:)=y;
%     end
% end

% % THIS IS THE ONE! For using same, you must switch the order
% for i=1:size(specdat.data,1)
%     for ct=1:size(specdat.data,2)
%         specdat.smoothdata28(i,ct,:)=conv(squeeze(specdat.data(i,ct,:)),ones([1,28])./28,'same'); 
%     end
% end
% 
% for i=1:size(specdat.data,1)
%     for ct=1:size(specdat.data,2)
%         specdat.smoothdata15(i,ct,:)=conv(squeeze(specdat.data(i,ct,:)),ones([1,15])./15,'same'); 
%     end
% end
% 
% for i=1:size(specdat.data,1)
%     for ct=1:size(specdat.data,2)
%         specdat.smoothdata100(i,ct,:)=conv(squeeze(specdat.data(i,ct,:)),ones([1,100])./100,'same'); 
%     end
% end

for i=1:size(specdat.data_20s,1)
    for ct=1:size(specdat.data_20s,2)
        specdat.smoothdatalowess(i,ct,:)=smooth(1:size(specdat.data_20s,3),specdat.data_20s(i,ct,:),0.1,'lowess');
    end
end

% for i=1:size(specdat.data_20s,1)
%     for ct=1:size(specdat.data_20s,2)
%         specdat.smoothdataspline(i,ct,:)=spline(1:size(specdat.data_20s,3),specdat.data_20s(i,ct,:));
%     end
% end

%% FIND PEAKS AND TROUGHS
fprintf('Identfying peaks.\n')
%preallocate
% template=repmat(-999,[size(specdat.data_20s,1),size(specdat.data_20s,2),specdat.numNRMP]);
% fields={'peaks' 'peak_locs' 'endpeak' 'endpeak_locs' 'startpeak60' 'startpeak60_locs'};
% for i=1:length(fields)
%     specdat.(fields{i})=template;
% end

%Peak 'waveform' identification algorithm: 
% 1) find peaks in each timeseries under the constraint that only 1 peak
% can occur within a 90 minute window (1 complete NREM-REM cycle)
% 2) Invert the signal, and locate the peaks (i.e. the inverted troughs).
% Again, under the constrain that only 1 peak can occur within a 90 minute
% window.
% 3) Constrain valid troughs to only be the ones that occur immediately
% following each peak. If no trough follows a peak (i.e. they were woken up
% before completing the cycle), use the end of the file as the trough.
% Defined as 'endpeak'.
% 4) Define the start of the peak 'waveform' as being 60 minutes preceeding
% the endpeak. This accounts for the fact that the ascending slope is much
% slower than descending (left skew of the waveform) while allowing to
% compare equivalent timeperiods across within and across studies.

%preallocate
% specdat.nrmp_start=repmat(-999,[size(specdat.data_20s,1), size(specdat.data_20s,2),20]);
% specdat.nrmp_end=repmat(-999,[size(specdat.data_20s,1), size(specdat.data_20s,2),20]);

% for i=1:size(specdat.data_20s,1) %logical error here. This script only runs 1 channel at a time, no loop needed. 
for i=strmatch(channel,specdat.leadorder)
    [prdval,prdloc]=unique(specdat.PRD_20s);
    if any(diff(prdval)>1)
        prdloc(find(diff(prdval)>1)+1)=[];
        prdval(find(diff(prdval)>1)+1)=[];
    end
    if length(prdval)==1
       prdloc(end+1)=size(specdat.data_20s,3);
       prdval(end+1)=specdat.PRD_20s(prdloc(end));
       specdat.REMonset=-999;
       specdat.nrmp_start(i,:)=prdloc(1);
       specdat.nrmp_end(i,:)=prdloc(end);
    else
        specdat.REMonset=prdloc(logical(~mod(prdval,2)));
        specdat.nrmp_start(i,1:length(prdloc(logical(mod(prdval,2)))))=prdloc(logical(mod(prdval,2)));
        specdat.nrmp_end(i,1:length(prdloc(logical(~mod(prdval,2)))-1))=prdloc(logical(~mod(prdval,2)))-1;
    end
    if size(specdat.nrmp_end(i,:),2)<size(specdat.nrmp_start(i,:),2) %Assumes that if there are less ends than starts, it was b/c the recording ended on a NRMP
        orig_size=size(specdat.nrmp_start(i,:),1);
        specdat.nrmp_end(i,end+1)=length(specdat.PRD_20s);
    end
    specdat.nrmp_start=sort(specdat.nrmp_start);
    specdat.nrmp_end=sort(specdat.nrmp_end);
    specdat.HAC_NRMP_mins=(specdat.nrmp_end(i,:)-specdat.nrmp_start(i,:))./3;
    missedrem=specdat.nrmp_end(i,:)-specdat.nrmp_start(i,:)>(90*3);
    grandmean=nanmean(nanmean((squeeze(specdat.data_20s(1,1:4,:)))))/2; %take mean of all data points in first 4 freq bands and divide by 2
     if any(missedrem)
%         smoothedpeaks=smooth(1:specdat.nrmp_end(i,missedrem_ind)-specdat.nrmp_start(i,missedrem_ind)+1,squeeze(specdat.data_20s(i,1,specdat.nrmp_start(i,missedrem_ind):specdat.nrmp_end(i,missedrem_ind))),0.1,'lowess').*-1;
%         [pks locs]=findpeaks(smoothedpeaks,'MinPeakDistance',size(smoothedpeaks,1)-1);
        specdat.missedrem=1;
        specdat.missedrem_num=sum(missedrem);
        for ct=1:sum(missedrem)
            missedrem_ind=find(missedrem);
            if specdat.nrmp_end(i,missedrem_ind(ct))-specdat.nrmp_start(i,missedrem_ind(ct))>(30*3)
                clear meanlocs;
                [pks,locs]=findpeaks(nanmean(squeeze(specdat.data_20s(i,1:4,specdat.nrmp_start(i,missedrem_ind(ct)):specdat.nrmp_end(i,missedrem_ind(ct))))).*-1,'MinPeakDistance',15*3);
                if ~isempty(pks)
                    for j=1:length(locs)
                        meanlocs(j)=mean2(squeeze(specdat.data_20s(i,1:4,specdat.nrmp_start(i,missedrem_ind(ct))+locs(j):specdat.nrmp_start(i,missedrem_ind(ct))+locs(j)+3)));
                    end
                    if any(locs<(30*3) | locs>(specdat.nrmp_end(i,missedrem_ind(ct))-30*3))
                        indstoremove=locs<(30*3) | locs>(specdat.nrmp_end(i,missedrem_ind(ct))-30*3); %remove false identification of troughs at begninning and end of period. 
                        locs(indstoremove)=[];
                        pks(indstoremove)=[];
                        meanlocs(indstoremove)=[];
                    end
                    if any(meanlocs>grandmean)
                        indstoremove=meanlocs>grandmean;
                        locs(indstoremove)=[];
                        pks(indstoremove)=[];                
                    end
                    if length(locs)==1
                        specdat.nrmp_start(i,1:end+1)=sort([[specdat.nrmp_start(i,:)] [locs+1+specdat.nrmp_start(i,missedrem_ind(ct))]']');
                        specdat.nrmp_end(i,1:end+1)=sort([[specdat.nrmp_end(i,:)] [locs+specdat.nrmp_start(i,missedrem_ind(ct))]']');
                    else
                        specdat.nrmp_start(i,1:end+length(locs))=sort([[specdat.nrmp_start(i,:)] [locs+1+specdat.nrmp_start(i,missedrem_ind(ct))]]);
                        specdat.nrmp_end(i,1:end+length(locs))=sort([[specdat.nrmp_end(i,:)] [locs+specdat.nrmp_start(i,missedrem_ind(ct))]]);
                    end
                end
            end
        end
     else
         specdat.missedrem=0;
         specdat.missedrem_num=0;
    end
end


for i=1:size(specdat.data_20s,1)
    specdat.data_delta_sum(i,1:size(specdat.data_20s,3))=sum(squeeze(specdat.data_20s(i,1:7,:)));
    specdat.data_delta_avg(i,1:size(specdat.data_20s,3))=specdat.data_delta_sum(i,:)./7;
end

% vars={'data_20s','data_delta_sum','data_delta_avg'};

specdat.NRMP_mins=(specdat.nrmp_end(i,:)-specdat.nrmp_start(i,:))./3;
allnanind=isnan(specdat.data_20s);
hacind=((specdat.HAC_20s==17 | specdat.HAC_20s==22) & ~specdat.bad_20s(currlead,:)); %stages 2 and 3
for i=1:size(specdat.data_20s,1)
    for ct=1:size(specdat.data_20s,2)
        nanind=squeeze(allnanind(i,ct,:));
        specdat.sumpower_wholenight(i,ct)=sum(squeeze(specdat.data_20s(i,ct,~nanind & hacind')));
        
        diviso=length(squeeze(specdat.data_20s(i,ct,~nanind & hacind')));
%         specdat.avgpower_wholenight(i,ct)=sum(squeeze(specdat.data_20s(i,ct,~nanind & hacind')))./size(specdat.data_20s(i,ct,~nanind & hacind'),3);
        specdat.avgpower_wholenight(i,ct)=sum(squeeze(specdat.data_20s(i,ct,~nanind & hacind')))./diviso;
        if size(specdat.data_20s,3)< (210*3)
            specdat.sumpower_210min(i,ct)=specdat.sumpower_wholenight(i,ct);
            specdat.avgpower_210min(i,ct)=specdat.avgpower_wholenight(i,ct);   
        else
            specdat.sumpower_210min(i,ct)=sum(squeeze(specdat.data_20s(i,ct,~nanind(1:(210*3)) & hacind(1:(210*3))')));
            %what's length of sum? 
            d1=length(squeeze(specdat.data_20s(i,ct,~nanind(1:(210*3)) & hacind(1:(210*3))')));
            specdat.avgpower_210min(i,ct)=sum(squeeze(specdat.data_20s(i,ct,~nanind(1:(210*3)) & hacind(1:(210*3))')))./d1; %./size(specdat.data_20s(i,ct,~nanind & hacind'),3);
        end
        if size(specdat.data_20s,3)<(180*3)
            specdat.sumpower_180min(i,ct)=specdat.sumpower_wholenight(i,ct);
            specdat.avgpower_180min(i,ct)=specdat.avgpower_wholenight(i,ct);  
        else
            specdat.sumpower_180min(i,ct)=sum(squeeze(specdat.data_20s(i,ct,~nanind(1:(180*3)) & hacind(1:(180*3))')));
            d2=length(squeeze(specdat.data_20s(i,ct,~nanind(1:(180*3)) & hacind(1:(180*3))')));
            specdat.avgpower_180min(i,ct)=sum(squeeze(specdat.data_20s(i,ct,~nanind(1:(180*3)) & hacind(1:(180*3))')))./d2;
        end
    end
end

vars={'data_delta_sum','data_delta_avg'};
for i=1:size(specdat.data_delta_sum,1)
    nanind_delta=any(squeeze(allnanind(i,1:7,:)),1)';
    for ct=1:length(vars)
        specdat.(['sumpower_wholenight' vars{ct}])(i,:)=sum(squeeze(specdat.(vars{ct})(i,~nanind_delta & hacind')));
        diviso=size((squeeze(specdat.(vars{ct})(i,~nanind_delta & hacind'))),2);
        specdat.(['avgpower_wholenight' vars{ct}])(i,:)=sum(squeeze(specdat.(vars{ct})(i,~nanind_delta & hacind')))./diviso;  %size(specdat.(vars{ct}),2);
        if specdat.TST<(210)
            specdat.(['sumpower_210min' vars{ct}])(i,:)=specdat.(['sumpower_wholenight' vars{ct}])(i,:);
            specdat.(['avgpower_210min' vars{ct}])(i,:)=specdat.(['avgpower_wholenight' vars{ct}])(i,:);   
        else
             diviso=size(squeeze(specdat.(vars{ct})(i,~nanind_delta(1:(210*3)) & hacind(1:(210*3))')),2);
            specdat.(['sumpower_210min' vars{ct}])(i,:)=sum(squeeze(specdat.(vars{ct})(i,~nanind_delta(1:(210*3)) & hacind(1:(210*3))')));
            specdat.(['avgpower_210min' vars{ct}])(i,:)=sum(squeeze(specdat.(vars{ct})(i,~nanind_delta(1:(210*3)) & hacind(1:(210*3))')))./diviso;
        end
        if specdat.TST<(180)
            specdat.(['sumpower_180min' vars{ct}])(i,:)=specdat.(['sumpower_wholenight' vars{ct}])(i,:);
            specdat.(['avgpower_180min' vars{ct}])(i,:)=specdat.(['avgpower_wholenight' vars{ct}])(i,:);  
        else
            diviso=size(squeeze(specdat.(vars{ct})(i,~nanind_delta(1:(180*3)) & hacind(1:(180*3))')),2);
            specdat.(['sumpower_180min' vars{ct}])(i,:)=sum(squeeze(specdat.(vars{ct})(i,~nanind_delta(1:(180*3)) & hacind(1:(180*3))')));
            specdat.(['avgpower_180min' vars{ct}])(i,:)=sum(squeeze(specdat.(vars{ct})(i,~nanind_delta(1:(180*3)) & hacind(1:(180*3))')))./diviso;
        end
    end
end

specdat.auc_cum=double(size(specdat.data_20s));

%calculate cumulative AUC 
for j=1:size(specdat.data_20s,1)
    for i=1:size(specdat.data_20s,2)
        thisnan=squeeze(allnanind(j,i,:));
        thisdata=squeeze(specdat.data_20s(j,i,:));
        alldelta=specdat.HAC_20s==17 | specdat.HAC_20s==22;
        x=1:length(thisdata)';
        thisauc=cumtrapz(x(~thisnan & alldelta'),thisdata(~thisnan & alldelta'));
        specdat.auc_cum(j,i,1:length(thisauc))=thisauc;
    end
end



% allnanind=isnan(specdat.rawdata);
% for j=1:size(specdat.rawdata,1)
%     for i=1:size(specdat.rawdata,2)
%         thisnan=squeeze(allnanind(1,i,:));
%         thisdata=squeeze(specdat.rawdata(1,i,:));
%         x=1:length(thisdata)';
%         auc_cum3(i,:)=cumtrapz(x(~thisnan),thisdata(~thisnan));
%     end
% end
% 
% 
% for i=1:10
%     thisnan=squeeze(allnanind(1,i,:));
%     thisdata=squeeze(specdat.rawdata(1,i,:));
%     x=1:length(thisdata)';
%     sum_cum(i,:)=cumsum(thisdata(~thisnan));
% end
% 
% for i=1:10
%     thisnan=squeeze(allnanind(1,i,:));
%     thisdata=squeeze(specdat.rawdata(1,i,:));
%     x=1:length(thisdata)';
%     auc_cum3(i,:)=cumtrapz(x,thisdata);
% end
% 




% for i=1:size(specdat.data_20s,1)
%     for ct=1:size(specdat.data_20s,2)
%         [pks,locs]=findpeaks(squeeze(specdat.data_20s(i,ct,:)),'MinPeakDistance',90*15);
%         numpks=1:length(pks);
%         specdat.peaks(i,ct,numpks)=pks;
%         specdat.peak_locs(i,ct,numpks)=locs;
%         [ipks,ilocs]=findpeaks(squeeze(specdat.data_20s(i,ct,:)*-1),'MinPeakDistance',90*15);
%         clear ilocs_tokeep;
%         for j=1:length(pks) %find troughs that immediately follow peaks
%            if j==length(pks) & isempty(find(ilocs>locs(j),1,'first')) %period was cut off, no trough following last NREMP
%                ilocs(end+1)=size(specdat.data_20s,3);
%                ipks(end+1)=specdat.data_20s(i,ct,end);
%            end
%            ilocs_tokeep(j)=find(ilocs>locs(j),1,'first');
%         end
%         ipks=ipks(ilocs_tokeep); ilocs=ilocs(ilocs_tokeep);
%         numipks=1:length(ipks);
%         specdat.endpeak(i,ct,numipks)=specdat.data_20s(i,ct,ilocs);
%         specdat.endpeak_locs(i,ct,numipks)=ilocs;
% %        specdat.startpeak60(i,ct,numipks)=specdat.data_20s(i,ct,ilocs-60);
% %        specdat.startpeak60_locs(i,ct,numipks)=ilocs-60;
%     end
% end

%FROM STUBLINKS
% numpts=length(data.RescaleData);
% avgdata=conv([1 1 1]./3,data.RescaleData);
% avgdata=avgdata(2:numpts+1);
% avgdata=conv([1 1 1]./3,data.RescaleData);
% avgdata=avgdata(2:numpts+1);
% avgdata(1:10)=data.RescaleData(1:10);
% avgdata((end-10):end)=data.RescaleData(end-10:end);
% avgdata(end:length(data.RescaleData))=avgdata(end);

% for ct=1:length(blinkstarts)
%   firstindex=max(1,blinkstarts(ct)-4);
%   lastindex=min(numpts,blinkends(ct)+9);
%   %endind=blinkends(min(length(blinkends),ct));
%   %interpdata=linspace(avgdata(firstindex,avgdata(min(length(avgdata),endind+4)),max(1,endind-blinkstarts(ct)+1));
%   %data.NoBlinks(blinkstarts(ct):endind)=interpdata;
%   %data.NoBlinksUnsmoothed(blinkstarts(ct):endind)=interpdata;
%   interpdata=linspace(avgdata(firstindex),avgdata(lastindex),max(1,lastindex-firstindex+1));
%   data.NoBlinks(firstindex:lastindex)=interpdata;
%   data.NoBlinksUnsmoothed(firstindex:lastindex)=interpdata;
% end


% %% GRAPH
% fprintf('Plotting data. WILL OVERWRITE EXISTING GRAPHS!!\n')
% for i=1:size(specdat.data_20s,1)
%     figure;
%     plot(1:size(specdat.data_20s(i,:,:),3),squeeze(specdat.data_20s(i,:,:)))
% %     hold on; plot(1:size(specdat.data_20s(i,:,:),3),specdat.HAC, 'r')
%     title(sprintf('%d-%d %s Spectral Data',specdat.ID(1),specdat.STDY(1),specdat.leadorder{i}))
% %     hold off;
% 
%     figure;
%     plot(1:size(specdat.data_20s(i,:,:),3),squeeze(specdat.smoothdata15(i,:,:)))
% %     hold on; plot(1:size(specdat.data_20s(i,:,:),3),specdat.HAC, 'r')
%     title(sprintf('%d-%d %s Spectral Data Smoothed x15',specdat.ID(1),specdat.STDY(1),specdat.leadorder{i}))
% %     hold off;
% 
%     figure;
%     plot(1:size(specdat.data_20s(i,:,:),3),squeeze(specdat.smoothdata28(i,:,:)))
% %     hold on; plot(1:size(specdat.data_20s(i,:,:),3),specdat.HAC, 'r')
%     title(sprintf('%d-%d %s Spectral Data Smoothed x28',specdat.ID(1),specdat.STDY(1),specdat.leadorder{i}))
% %     hold off;
% 
%     figure;
%     plot(1:size(specdat.data_20s(i,:,:),3),squeeze(specdat.smoothdata100(i,:,:)))
% %     hold on; plot(1:size(specdat.data_20s(i,:,:),3),specdat.HAC, 'r')
%     title(sprintf('%d-%d %s Spectral Data Smoothed x100',specdat.ID(1),specdat.STDY(1),specdat.leadorder{i}))
% %     hold off;
% 
%     figure;
%     plot(1:size(specdat.data_20s(i,:,:),3),squeeze(specdat.smoothdataloess(i,:,:)))
% %     hold on; plot(1:size(specdat.data_20s(i,:,:),3),specdat.HAC, 'r')
%     title(sprintf('%d-%d %s Spectral Data Smoothed Loess',specdat.ID(1),specdat.STDY(1),specdat.leadorder{i}))
% end

%% OPTIONAL SAVE DATA/GRAPHS




%% Things we'd like for diagnostics 4 things long: 1 per channel
% # of good samps / good times
% # of NaN / good times

% only 1 index for sleep variables
% TSTmin=sleep defined from spec file: HAC > 4 / 15 = minutes;
% Amt of NREM sleep: PRD = 1 (?)
% Amt of REM sleep: 

% consider pulling in CRC Database: SOL; TIB; TSTdb



%% Attempting to get stuff to plot: SG & PLF
%p.tmp1=reshape(p.data(:,1,:),[2 6901]) % this save us both channels at one Hz bin



% for ct=1:31
%     for chan=1:2;
%       samps=3046:6900;
%       hz(chan,ct)=p.data(:,ct,samps)
%     end
% end

% p.c3=reshape(p.data(1,:,1:6900),[31 6900])

% surf(3400:6900,1:31-7,p.c3(8:31,3400:6900))
end
    