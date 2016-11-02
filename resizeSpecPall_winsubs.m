function pall_winsubs=resizeSpecPall_winsubs(pall)

pall([pall.usecd]==0)=[];
%sort pall based on id
[tmp ind]=sort([pall.id]);
pall=pall(ind);

[n,bin]=histc([pall.id], unique([pall.id]));
ct=1;
for i=1:length(bin)
    numinds=sum(bin==bin(i));
    pwinsubs(bin(i)).ind(ct)=i;
    pwinsubs(bin(i)).slp(ct)=pall(i).condnum;
    pwinsubs(bin(i)).night(ct)=pall(i).night;
    pwinsubs(bin(i)).nightcount(ct)=numinds;
    if numinds==ct %reset count if it's the last index of that id
        ct=1;
    else
        ct=ct+1;
    end
end

goodind=[];
badind=[];
j=1;
index=1;
for i=1:length(pwinsubs)
    if pwinsubs(i).nightcount(1)>=3 && ismember(1,pwinsubs(i).slp) && sum(pwinsubs(i).slp==2)==2
        goodind(j)=i;
        j=j+1;
    else
        badind(index)=i;
        index=index+1;
    end
end

pwinsubs(badind)=[];
pallinds=zeros([length(pwinsubs),3]);
index=1;
for i=1:length(pwinsubs)
    seind=max(pwinsubs(i).ind(pwinsubs(i).slp==1));
    srinds=pwinsubs(i).ind(pwinsubs(i).slp==2);
    pallinds(i,:)=[seind srinds];
end

pallinds=reshape(pallinds,[3*length(pwinsubs) 1]);
pall_winsubs=pall(pallinds);
