
clear tm;

%!!!!!!a fake 
tm = TrlmsLabs(1);

if(length(who('lab_para')) > 0)
   
    tm.C = lab_para.C;
    tm.A = lab_para.A;
    tm.p_i_zipf = lab_para.zipf;
    tm.I = lab_para.I;
	%tm.skew_range = lab_para.skew_range
    tm.skewness_value = lab_para.skew;
    tm.TOTAL_reqs = lab_para.total_reqs; 
    tm.pop_list_predefine = lab_para.pop_list_pred;
    tm.Diat_seqidx = lab_para.Diat_seqidx;
end

sfname = tm.getsname('data');

%if(exist(sfname) == 2)
if (1 > 2)
    clear tm;
    display(sprintf('TM loaded from file %s',sfname));
    load(sfname,'-mat');
    
else
    display 'TM creating, please wait...';
    tm=tm.init();
    tm=tm.genAll();    
    save(sfname, 'tm','-mat');
    display(sprintf('tm saved to file %s',sfname));
end

%用load(name,'-mat')载入

% myuac = tm.getStat();
% 
% %如果是1，说明uac对每个a，至少有个c uac==1
% if ( min(myuac(1,:)) == 1)
%    
%     display 'OK';
% else
%     display 'ERROR, see data';
% end





