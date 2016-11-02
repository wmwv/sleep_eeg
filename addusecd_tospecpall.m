function pall=addusecd_tospecpall(pall, usecdarray)
if nargin<2; usecdarray=load('FZusecdarray.mat'); usecdarray=usecdarray.usecdarray; end %loading as struct for some reason

for i=1:length(pall)
    
    thisid=pall(i).id;
    thisstudy=pall(i).study;
    if ismember([thisid thisstudy],[usecdarray(:,1) usecdarray(:,2)],'rows')
        index=usecdarray(:,1)==thisid & usecdarray(:,2)==thisstudy;
        pall(index).usecd=usecdarray(index,3);
    else
        pall(i).usecd=-999;
    end
end
