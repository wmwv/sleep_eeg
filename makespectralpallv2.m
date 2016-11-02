function pall=makespectralpallv2(pall)
if nargin<1, useexisting=0; pall=struct(); 
else
    useexisting=1;
end

badnum=1;
subnum=1;
if useexisting, 
%     pallsmall=pall; 
    %badnum=(length(pallsmall.badfiles))+1; 
    numsubs=length(pall);
end

%get user credentials to log into database
prompt={'Username:', 'Password:'};
dlg_title='Database Logon';
defans={'',''};
wait=1;
while wait
    answer=inputdlg(prompt,dlg_title,1,defans,'on');
    username=answer{1};
    password=answer{2};
    conn=database('Data_PAN2',username,password);
    if isempty(username) || isempty(password)
        h=msgbox('Username and password are required');
        uiwait(h);
    elseif ~isempty(strfind(conn.Message,'Not a valid account name or password'))
        h=msgbox('Not a valid account name or password');
        uiwait(h);
    else wait=0;
    end
end

setdbprefs('DataReturnFormat','cellarray'); 
 %fetch from Query_03_MASTER_CONDITIONS
  pan2dat=fetch(conn,'select [ID], [STUDY], [RUN], [CONDNUM], [DEPORDER], [DAY] from Query_08_all_sleep_nights');
 id=cell2mat(pan2dat(:,1));
 run=cell2mat(pan2dat(:,2));
 study=str2num(cell2mat(pan2dat(:,3)));
 condnum=cell2mat(pan2dat(:,4)); %1=complete, 2=withdrew at T1, 3=withdrew at T2, 9=active
 deporder=cell2mat(pan2dat(:,5));
 night=str2num(cell2mat(pan2dat(:,6)));

 %fetch from Query_02A_DEMOGS_with_ALL
 demogdat=fetch(conn,'select [ID], [studyAGE], [SEX] from Query_02A_DEMOGS_with_ALL');
 demogid=cell2mat(demogdat(:,1));
 demogage=cell2mat(demogdat(:,2)); %age at study
 demogsex=cell2mat(demogdat(:,3));
 

close(conn);
global filelist;
filelist=getallfiles('J:\PAN2\spectral_vertsd','tsdold');
 
for ct=1:length(id)
     gender=demogsex(demogid==id(ct));
     age=demogage(demogid==id(ct));
    if (useexisting)
        if isempty(intersect([[pall.id]' [pall.run]'],[id run],'rows')) %match on id and run
            fprintf('loading new id %d\n',id(ct));
            addtopall=1;
            try
    %             p=readspectralpsg3(id(ct),run(ct));
                p=gatherAllSpecChannels(id(ct),run(ct));
            catch ME1
                errmsg=ME1.message;
                    badmsg{badnum}=errmsg;
                    fprintf('COULD NOT PROCESS %d-%d\n',id(ct),run(ct));
                    badid(badnum)=id(ct); badrun(badnum)=run(ct); badmsg{badnum}=errmsg;
                    addtopall=0;
                    badnum=badnum+1;
                    close all;
            end
            if addtopall
                p.run=run(ct);
                p.deporder=deporder(ct);
                p.condnum=condnum(ct);
                p.night=night(ct);
                p.age=age;
                p.gender=gender;
                pall(numsubs+1)=p;
                numbsubs=numsubs+1;
            end
        else
            fprintf('using existing id %d\n',id(ct));
        end
    else
        fprintf('loading id %d\n',id(ct));
        addtopall=1;
        close all;
        try
%             p=readspectralpsg3(id(ct),run(ct));
            p=gatherAllSpecChannels(id(ct),run(ct));
        catch ME1
            errmsg=ME1.message;
            badmsg{badnum}=errmsg;
            fprintf('COULD NOT PROCESS %d-%d\n',id(ct),run(ct));
            badid(badnum)=id(ct); badrun(badnum)=run(ct); badmsg{badnum}=errmsg;
            fprintf('%s\n',badmsg{:});
            addtopall=0;
            badnum=badnum+1;
            close all;
        end
        if addtopall
            p.run=run(ct);
            p.deporder=deporder(ct);
            p.condnum=condnum(ct);
            p.night=night(ct);
            p.age=age;
            p.gender=gender;
            if subnum==1
                pall=p;
            else
                pall(subnum)=p;
            end
            close all;
            subnum=subnum+1;
        end
    end
end

if exist('badid','var')
    writedir=sprintf('T:/pupil/%s/docs/spectral','pan2');
    cd(writedir);
    fp=fopen(sprintf('%s-spectral-badfiles.txt','pan2'),'w');
    fprintf(fp,'id\trun\tdate_processed\terror_message');
    for i=1:length(badid)
        fprintf(fp,'\n%d\t%d\t%s\t%s',badid(i),badrun(i),datestr(clock),badmsg{i});
    end
    fclose(fp);
end
            
            
        
        
        
            
            